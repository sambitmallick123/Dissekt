"""Dissekt Beacon — Upload scanner and orchestrator.

Primary product surface. User pastes URL or text.
Beacon extracts content, then runs Prism + Trace + Signal in parallel.
"""

import asyncio
import hashlib
import logging
import time
from urllib.parse import urlparse
import re
import httpx
from app.scoring import compute_full_score
from app.factchecker_db import get_checker_info, tier_label, tier_color
from app.social_scanner import detect_and_extract
from readability import Document as ReadabilityDocument
from app.config import get_settings
from app.models import (
    FullAnalysis, InputType, PrismResult, TraceResult, SignalResult,
    Technique, TechniqueCategory, FactCheck, SourceAppearance, BlockchainProof,
)
from app.prism.heuristics import run_all_heuristics
from app.prism.llm import route_and_analyze
from app.lens import run_lens
from app.spectrum import run_spectrum
from app.cache import get_cached, set_cached

logger = logging.getLogger("dissekt.beacon")


def detect_language(text: str) -> str:
    """Quick language detection based on character ranges and common words."""
    sample = text[:500].lower()

    # Hindi/Devanagari
    devanagari = sum(1 for c in sample if '\u0900' <= c <= '\u097F')
    if devanagari > 20:
        return "hi"

    # German indicators
    german_words = ["der", "die", "das", "und", "ist", "ein", "eine", "nicht", "auf", "mit", "für", "auch", "sich", "nach", "bei"]
    german_count = sum(1 for w in german_words if f" {w} " in f" {sample} ")
    if german_count >= 3:
        return "de"

    return "en"

MAX_TEXT_LENGTH = 5000
# ── Claim extraction (chunked) ──
# Slide a bounded window across the FULL extracted text, extract per chunk in
# parallel, then dedupe. Per-chunk size AND chunk count are capped, so cost stays
# bounded even on a 50k paste: at most MAX_CLAIM_CHUNKS LLM calls regardless of length.
CLAIM_CHUNK_CHARS = 3500      # chars per chunk sent to the LLM
CLAIM_CHUNK_OVERLAP = 400     # overlap so a claim straddling a boundary survives whole in one chunk
MAX_CLAIM_CHUNKS = 5          # hard ceiling on parallel extraction calls (cost ceiling)
CLAIM_TOTAL_CAP = 12          # max claims returned after dedup
# Covered window = MAX_CLAIM_CHUNKS*(CLAIM_CHUNK_CHARS-OVERLAP)+OVERLAP = 15900 chars.
CLAIM_COVERED_CHARS = MAX_CLAIM_CHUNKS * (CLAIM_CHUNK_CHARS - CLAIM_CHUNK_OVERLAP) + CLAIM_CHUNK_OVERLAP
# ============================================
# Content extraction
# ============================================

async def extract_from_url(url: str) -> tuple[str, str]:
    title = ""
    text = ""

    # Method 1: Let trafilatura fetch + extract (its own fetcher is smarter)
    try:
        import trafilatura
        from asyncio import to_thread

        def _trafilatura_extract(url):
            config = trafilatura.settings.use_config()
            config.set("DEFAULT", "USER_AGENTS",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36")

            downloaded = trafilatura.fetch_url(url, config=config)
            if not downloaded:
                import httpx
                headers = {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                    "Accept-Language": "en-US,en;q=0.9",
                    "Accept-Encoding": "gzip, deflate, br",
                    "DNT": "1",
                    "Connection": "keep-alive",
                    "Upgrade-Insecure-Requests": "1",
                    "Sec-Fetch-Dest": "document",
                    "Sec-Fetch-Mode": "navigate",
                    "Sec-Fetch-Site": "none",
                    "Sec-Fetch-User": "?1",
                    "Cache-Control": "max-age=0",
                }
                with httpx.Client(timeout=15, follow_redirects=True) as client:
                    resp = client.get(url, headers=headers)
                    resp.raise_for_status()
                    downloaded = resp.text

            if not downloaded:
                return None, None

            text = trafilatura.extract(downloaded, include_comments=False, include_tables=False) or ""
            metadata = trafilatura.extract_metadata(downloaded)
            title = metadata.title if metadata and metadata.title else ""
            return text, title

        text, title = await to_thread(_trafilatura_extract, url)
        if text and len(text) > 200:
            logger.info(f"Trafilatura extracted {len(text)} chars from {url}")
            return text[:MAX_TEXT_LENGTH], title
    except Exception as e:
        logger.warning(f"Trafilatura fetch failed: {e}")

    # Method 2: httpx fetch + multiple extractors (fallback)
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    try:
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=headers)
            resp.raise_for_status()
            html = resp.text[:100000]

        from bs4 import BeautifulSoup
        import json

        soup = BeautifulSoup(html, "html.parser")

        # Get title
        if not title:
            og = soup.find("meta", property="og:title")
            if og and og.get("content"):
                title = og["content"]
            elif soup.find("title"):
                title = soup.find("title").get_text(strip=True)

        # Method 2a: JSON-LD
        for script in soup.find_all("script", type="application/ld+json"):
            try:
                data = json.loads(script.string)
                items = data if isinstance(data, list) else [data]
                for item in items:
                    if item.get("@type") in ("NewsArticle", "Article", "ReportageNewsArticle", "WebPage"):
                        body = item.get("articleBody", "")
                        if body and len(body) > 200:
                            if not title:
                                title = item.get("headline", "")
                            return body[:MAX_TEXT_LENGTH], title
            except (json.JSONDecodeError, TypeError):
                continue

        # Method 2b: readability
        try:
            doc = ReadabilityDocument(html)
            if not title:
                title = doc.title()
            read_soup = BeautifulSoup(doc.summary(), "html.parser")
            read_text = read_soup.get_text(separator="\n", strip=True)
            if len(read_text) > 200:
                return read_text[:MAX_TEXT_LENGTH], title
        except Exception:
            pass

        # Method 2c: all paragraphs
        paragraphs = soup.find_all("p")
        p_text = "\n".join(
            p.get_text(strip=True) for p in paragraphs
            if len(p.get_text(strip=True)) > 40
        )
        if len(p_text) > 200:
            return p_text[:MAX_TEXT_LENGTH], title

    except ValueError:
        raise
    except Exception as e:
        logger.warning(f"Method 2 (httpx) failed: {e}")

    # Method 3: Playwright headless browser (for bot-blocked sites)
    try:
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            await page.goto(url, wait_until="networkidle", timeout=15000)

            html = await page.content()
            if not title:
                title = await page.title()

            await browser.close()

            import trafilatura
            text = trafilatura.extract(html, include_comments=False, include_tables=False) or ""
            if text and len(text) > 200:
                logger.info(f"Playwright extracted {len(text)} chars from {url}")
                return text[:MAX_TEXT_LENGTH], title
    except ImportError:
        logger.warning("Playwright not installed — skipping JS rendering")
    except Exception as e:
        logger.warning(f"Playwright failed: {e}")

    raise ValueError("Could not extract article content. Try pasting the text directly.")


def detect_input_type(content: str) -> InputType:
    """Detect whether input is a URL or plain text."""
    content = content.strip()
    if content.startswith(("http://", "https://", "www.")):
        return InputType.url
    return InputType.text


def compute_content_hash(text: str) -> str:
    """SHA-256 hash of the content for caching and blockchain."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


# ============================================
# Claim extraction
# ============================================

def _chunk_text(text: str, size: int, overlap: int, max_chunks: int) -> list[str]:
    """Sliding window over the full text, snapping to sentence/paragraph
    boundaries where possible. Bounded by max_chunks (cost ceiling)."""
    text = (text or "").strip()
    if len(text) <= size:
        return [text] if text else []
    chunks, start, n = [], 0, len(text)
    while start < n and len(chunks) < max_chunks:
        end = min(start + size, n)
        if end < n:
            window = text[start:end]
            cut = max(window.rfind(". "), window.rfind("\n"),
                      window.rfind("! "), window.rfind("? "))
            if cut > size * 0.5:          # only snap back if the boundary isn't too early
                end = start + cut + 1
        piece = text[start:end].strip()
        if piece:
            chunks.append(piece)
        if end >= n:
            break
        start = max(end - overlap, start + 1)
    return chunks


def _dedupe_claims(claims: list, cap: int) -> list:
    """Dedupe by normalized claim text — collapses identical re-extractions from
    overlapping chunks — preserving document order and first occurrence."""
    import re as _re
    seen, out = set(), []
    for c in claims:
        if not isinstance(c, dict):
            continue
        txt = (c.get("claim") or "").strip()
        if not txt:
            continue
        key = _re.sub(r"\s+", " ", _re.sub(r"[^a-z0-9 ]", "", txt.lower())).strip()
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(c)
        if len(out) >= cap:
            break
    return out


_CLAIM_SYSTEM = (
    "Extract verifiable factual claims from this text. Return ONLY a JSON array of objects.\n"
    'Each object: {"claim": "the specific factual claim", "type": "statistic|quote|event|prediction|causal"}\n'
    "Only include claims explicitly stated in THIS text that can be fact-checked. "
    "Do not infer claims that are not present. Max 5 claims. No explanations, just the JSON array."
)


async def extract_claims(text: str, mode: str = "brief") -> list[dict]:
    """Extract verifiable claims across the FULL text via bounded parallel chunks.

    Slides a window over the entire extracted text (not just the head), runs each
    chunk through the router model concurrently, then dedupes overlapping results.
    Chunk size and count are capped, so cost stays bounded on very long inputs.
    """
    if not text or len(text.strip()) < 40:
        return []

    chunks = _chunk_text(text, CLAIM_CHUNK_CHARS, CLAIM_CHUNK_OVERLAP, MAX_CLAIM_CHUNKS)
    if not chunks:
        return []

    from app.llm_dispatch import call_model
    import json

    async def _extract_one(chunk: str) -> list:
        try:
            _disp = await call_model("router", system=_CLAIM_SYSTEM, user=chunk, max_tokens=500)
            raw = (_disp.get("text") or "").strip()
            if raw.startswith("```"):
                raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
                raw = raw.rsplit("```", 1)[0]
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, list) else []
        except Exception as e:
            logger.warning(f"Claim chunk extraction failed (non-fatal): {e}")
            return []

    results = await asyncio.gather(*[_extract_one(c) for c in chunks], return_exceptions=True)
    merged = []
    for r in results:
        if isinstance(r, list):
            merged.extend(r)
    claims = _dedupe_claims(merged, CLAIM_TOTAL_CAP)
    logger.info(f"[claims] {len(chunks)} chunk(s) -> {len(merged)} raw -> {len(claims)} deduped")
    return claims


# ============================================
# Counterfactual generation
# ============================================


def _resolve_reframe_model_beacon() -> str:
    """Resolve 'reframe' role for inline openai create() calls in beacon."""
    try:
        from app.models_registry import model_meta
        from app.config import get_settings
        from supabase import create_client
        s = get_settings()
        sb = create_client(s.supabase_url, s.supabase_key)
        rows = sb.table("model_config").select("role, model").eq("role", "reframe").execute()
        if rows.data:
            mid = rows.data[0]["model"]
            if model_meta(mid)["provider"] == "openai":
                return mid
    except Exception:
        pass
    return "gpt-4o-mini"

async def generate_counterfactuals(text: str, mode: str = "brief") -> list[dict]:
    """Generate alternative framings for claims in the text."""
    settings = get_settings()
    import openai

    client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
    try:
        response = await client.chat.completions.create(
            model=_resolve_reframe_model_beacon(),
            max_tokens=600,
            messages=[
                {
                    "role": "system",
                    "content": """You are an information transparency tool. For the given text, identify the 2-3 strongest claims and provide alternative framings that add missing context or present a different perspective.

Return ONLY a JSON array. Each object:
{
  "original": "the claim as stated in the text",
  "alternative": "a more complete or differently-framed version with added context",
  "missing_context": "what the original framing omits or de-emphasizes"
}

Rules:
- Do NOT say the original is "wrong" or "false"
- Show HOW the framing shapes perception, not WHAT to believe
- The alternative should be equally factual, just more complete
- Keep each field under 100 words
- Return only the JSON array, no markdown"""
                },
                {"role": "user", "content": text[:2000]}
            ],
        )
        import json
        raw = response.choices[0].message.content.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
        result = json.loads(raw)
        return result if isinstance(result, list) else []
    except Exception as e:
        logger.warning(f"Counterfactual LLM failed: {e}")
        return []


# ============================================
# Main scan pipeline
# ============================================


async def _generate_synopsis(text: str, mode: str) -> str | None:
    """Neutral 1-2 sentence summary of what the content is about (admin role: synopsis_text).
    Independent of Prism routing, so it also runs on heuristic-only scans. Non-fatal."""
    if not text or len(text.strip()) < 40:
        return None
    try:
        from app.llm_dispatch import call_model
        disp = await call_model(
            "synopsis_text",
            system=("You summarize what a piece of content is ABOUT, for a reader who hasn't seen it. "
                    "1-2 neutral sentences: the subject and its main points. "
                    "Do NOT name manipulation techniques, judge credibility, or use loaded language. "
                    "Plain factual description only."),
            user=text[:3000],
            max_tokens=160,
            temperature=0.2,
        )
        out = (disp.get("text") or "").strip()
        return out or None
    except Exception as e:
        logger.warning(f"Synopsis generation failed (non-fatal): {e}")
        return None


_last_vision_model = None


async def _extract_from_image(image_data_url: str) -> str:
    """Extract text + visual manipulation signals from an image using the admin-selected vision model."""
    try:
        from app.llm_dispatch import call_model
        prompt = (
            "Extract ALL text visible in this image verbatim (headlines, body, captions, overlaid text). "
            "Then on a new line after '---VISUAL---', briefly note any visual manipulation signals "
            "(misleading charts, emotional imagery, out-of-context or doctored photos, missing context). "
            "If there is no text, transcribe what the image depicts."
        )
        result = await call_model("vision", user=prompt, image_url=image_data_url, max_tokens=1000)
        if result.get("error"):
            logger.warning(f"Image vision extraction failed: {result['error']}")
        # Stash which model was used so the report can show it
        global _last_vision_model
        _last_vision_model = result.get("label", result.get("model"))
        return result.get("text", "")
    except Exception as e:
        logger.warning(f"Image vision extraction failed: {e}")
        return ""

async def scan(content: str, mode: str = "brief", image: str | None = None, light: bool = False) -> FullAnalysis:
    """Main entry point: scan content through all engines.

    1. Detect input type (URL vs text)
    2. Extract text if URL
    3. Check cache
    4. Run heuristics
    5. Run Prism + Trace + Signal in parallel
    6. Combine results
    7. Cache result
    8. Store in claim graph
    9. Generate blockchain proof
    """
    # Vision: if an image was supplied, extract its text/signals and prepend to content
    if image:
        _vision_text = await _extract_from_image(image)
        if _vision_text:
            content = (_vision_text + "\n\n" + (content or "")).strip()
        elif not content:
            content = "[Image provided but no text could be extracted]"
    start_time = time.time()
    settings = get_settings()

    # Step 0: Check if social media URL
    if content.startswith('http'):
        social = await detect_and_extract(content)
        if social.get('text') and not social.get('use_beacon'):
            content = social['text']
            # Continue with text analysis (skip URL extraction)
    
    # Step 1: Detect input type
    input_type = detect_input_type(content)
    source_url = ""
    _title = ""

    # Step 2: Extract text if URL
    if input_type == InputType.url:
        source_url = content.strip()
        if not source_url.startswith("http"):
            source_url = "https://" + source_url
        _t_ext = time.time()
        extracted_text, _title = await extract_from_url(source_url)
        logger.info(f"[TIMING] url_extraction: {time.time()-_t_ext:.2f}s")
    else:
        extracted_text = content.strip()

    if len(extracted_text) < 20:
        raise ValueError("Content too short for meaningful analysis (minimum 20 characters)")

    # Step 3: Check cache
    content_hash = compute_content_hash(extracted_text)
    cached = await get_cached(content_hash, mode)
    if cached:
        cached["cached"] = True
        cached["analysis_time_ms"] = int((time.time() - start_time) * 1000)
        return FullAnalysis(**cached)

    # Step 4: Run heuristics (instant, free)
    heuristics = run_all_heuristics(extracted_text, source_url)

    # Step 5: Run all engines in parallel
    detected_lang = detect_language(extracted_text)
    prism_task = route_and_analyze(extracted_text, mode, heuristics, detected_language=detected_lang)
    trace_query = re.split(r'[.!?\n]', extracted_text)[0].strip()[:150]
    trace_task = run_lens(trace_query if len(trace_query) > 20 else extracted_text[:200])
    signal_task = asyncio.to_thread(run_spectrum, extracted_text, source_url)

    synopsis_task = _generate_synopsis(extracted_text, mode)
    _t_core = time.time()
    prism_raw, trace_raw, signal_raw, synopsis_raw = await asyncio.gather(
        prism_task, trace_task, signal_task, synopsis_task,
        return_exceptions=True,
    )
    if isinstance(synopsis_raw, Exception):
        logger.warning(f"Synopsis failed: {synopsis_raw}")
        synopsis_raw = None
    logger.info(f"[TIMING] core_gather (prism+lens+spectrum): {time.time()-_t_core:.2f}s")

    # Step 6: Combine results
    if isinstance(prism_raw, Exception):
        logger.error(f"Prism failed: {prism_raw}")
        prism_raw = {"brief": "Analysis engine temporarily unavailable.", "techniques": [], "_model": "error"}
    prism_result = _build_prism_result(prism_raw, mode)

    if isinstance(trace_raw, Exception):
        logger.error(f"Trace failed: {trace_raw}")
        trace_raw = {"fact_checks": [], "spread_timeline": [], "earliest_source": None, "check_worthiness": 0.0}
    trace_result = _build_trace_result(trace_raw)

    if isinstance(signal_raw, Exception):
        logger.error(f"Signal failed: {signal_raw}")
        signal_raw = {"source_bias": None, "source_factuality": None, "sentiment": "neutral", "sentiment_score": 0.0, "primary_emotion": "neutral", "emotion_scores": {}}
    signal_result = SignalResult(**signal_raw)

    # Step 9: Blockchain hash + OTS anchoring
    if settings.enable_blockchain:
        try:
            from app.anchor import create_timestamp
            blockchain_raw = await create_timestamp(content_hash)
            blockchain = BlockchainProof(
                content_hash=blockchain_raw["content_hash"],
                timestamp=blockchain_raw["timestamp"],
                proof_status=blockchain_raw["proof_status"],
            )
        except Exception as e:
            logger.warning(f"OTS anchoring failed: {e}")
            blockchain = BlockchainProof(
                content_hash=content_hash,
                timestamp=str(int(time.time())),
                proof_status="pending",
            )
    else:
        blockchain = BlockchainProof(
            content_hash=content_hash,
            timestamp=str(int(time.time())),
            proof_status="local",
        )

    analysis_time = int((time.time() - start_time) * 1000)

    analysis = FullAnalysis(
        id=content_hash[:16],
        input_type=input_type,
        input_content=content[:500],
        extracted_text=extracted_text[:3000],
        prism=prism_result,
        trace=trace_result,
        signal=signal_result,
        blockchain=blockchain,
        cached=False,
        analysis_time_ms=analysis_time,
    )

    # Step 8: Store in claim graph (non-blocking, don't fail the response)
    try:
        from app.claim_graph import store_analysis
        await store_analysis(
            extracted_text,
            content_hash[:16],
            {
                "techniques": [t.name for t in prism_result.techniques],
                "source_bias": signal_result.source_bias,
                "timestamp": str(int(time.time())),
            }
        )
    except Exception as e:
        logger.warning(f"Claim graph store failed: {e}")

    # Step 9: Find similar past claims
    try:
        from app.claim_graph import find_similar
        similar = await find_similar(extracted_text[:300])
        # Exclude self (same analysis id)
        analysis.similar_claims = [s for s in similar if s.get("analysis_id") != content_hash[:16]]
    except Exception as e:
        logger.warning(f"Similar claims lookup failed: {e}")

    # Step 10: Political context (Compass)
    _t_compass = time.time()
    if settings.enable_compass and not light:
        try:
            from app.meridian import analyze_political_context
            compass_data = await analyze_political_context(extracted_text)
            analysis.compass = compass_data
        except Exception as e:
            logger.warning(f"Compass failed: {e}")
    logger.info(f"[TIMING] compass: {time.time()-_t_compass:.2f}s")

    # Step 10b: Coordination detection (Pulse)
    if settings.enable_pulse:
        try:
            from app.flare import detect_coordination
            pulse_data = await detect_coordination(extracted_text, analysis.similar_claims)
            analysis.pulse = pulse_data
        except Exception as e:
            logger.warning(f"Pulse failed: {e}")

    # Step 11: Detect language
    analysis.detected_language = detect_language(extracted_text)

    # Representation & language bias signals (lexicon-based, descriptive tags)
    try:
        if get_settings().enable_bias:
            from app.bias_signals import detect_bias_signals
            analysis.bias_signals = detect_bias_signals(extracted_text)
    except Exception as e:
        logger.warning(f"Bias signals failed: {e}")

    # Step 11a: Generate counterfactual views (alternative framing)
    if settings.enable_counterfactual and len(prism_result.techniques) > 0:
        try:
            counterfactuals = await generate_counterfactuals(extracted_text, mode)
            analysis.counterfactuals = counterfactuals
        except Exception as e:
            logger.warning(f"Counterfactual generation failed: {e}")

    # Step 11: Extract individual claims (only if techniques found, to save API cost)
    _t_claims = time.time()
    if settings.enable_claims and not light and len(prism_result.techniques) > 0:
        try:
            claims = await extract_claims(extracted_text, mode)
            analysis.extracted_claims = claims
        except Exception as e:
            logger.warning(f"Claim extraction failed: {e}")
    logger.info(f"[TIMING] claims: {time.time()-_t_claims:.2f}s")

        # Compute System F Clarity Score
    try:
        techs_raw = []
        if hasattr(analysis, 'prism') and analysis.prism:
            raw_techs = analysis.prism.techniques if hasattr(analysis.prism, 'techniques') else (analysis.prism.get('techniques', []) if isinstance(analysis.prism, dict) else [])
        techs_raw = []
        for t in (raw_techs or []):
            if isinstance(t, dict):
                techs_raw.append({'name': t.get('name', ''), 'confidence': t.get('confidence', 0)})
            else:
                techs_raw.append({'name': getattr(t, 'name', ''), 'confidence': getattr(t, 'confidence', 0)})
        fcs_raw = []
        if hasattr(analysis, 'trace') and analysis.trace:
            raw_fcs = analysis.trace.fact_checks if hasattr(analysis.trace, 'fact_checks') else (analysis.trace.get('fact_checks', []) if isinstance(analysis.trace, dict) else [])
        fcs_raw = []
        for fc in (raw_fcs or []):
            if isinstance(fc, dict):
                fcs_raw.append(fc)
            else:
                fcs_raw.append({
                    'rating': getattr(fc, 'rating', '') or getattr(fc, 'textualRating', ''),
                    'textualRating': getattr(fc, 'textualRating', '') or getattr(fc, 'rating', ''),
                    'checker_tier': getattr(fc, 'checker_tier', 'U'),
                    'url': getattr(fc, 'url', ''),
                    'publisher': getattr(fc, 'publisher', {}),
                })
        sent_raw = 0.0
        src_fact = None
        src_bias = None
        if hasattr(analysis, 'signal') and analysis.signal:
            sig = analysis.signal if isinstance(analysis.signal, dict) else analysis.signal.__dict__ if hasattr(analysis.signal, '__dict__') else {}
            sent_raw = sig.get('sentiment_score', 0.0)
            src_fact = sig.get('source_factuality')
            src_bias = sig.get('source_bias')
        
        score_result = compute_full_score(
            techniques=techs_raw, fact_checks=fcs_raw,
            sentiment_compound=sent_raw,
            source_factuality=src_fact, source_bias=src_bias,
            text=content[:5000], source_name="",
        )
        
        if isinstance(analysis, dict):
            analysis['scoring'] = score_result
            analysis['clarity_score'] = score_result['clarity_score']
        else:
            analysis.scoring = score_result
    except Exception as e:
        logger.warning(f"Scoring failed: {e}")

    # Facet — establishing summary card (synopsis + provenance)
    try:
        from urllib.parse import urlparse as _urlparse
        _kind = "image" if image else ("url" if input_type == InputType.url else "text")
        _src = _urlparse(source_url).netloc.replace("www.", "") if source_url else ""
        analysis.facet = {
            "synopsis": synopsis_raw if isinstance(synopsis_raw, str) else None,
            "published_at": None,  # TODO: wire from extract_from_url metadata (.date / datePublished)
            "title": (_title or None),
            "source_name": (_src or None),
            "kind": _kind,
            "claims_partial": len(extracted_text) > CLAIM_COVERED_CHARS,
        }
    except Exception as e:
        logger.warning(f"Facet assembly failed: {e}")

    # Enrich fact-checks with credibility info
    try:
        if hasattr(analysis, 'trace') and analysis.trace and hasattr(analysis.trace, 'fact_checks'):
            for fc in analysis.trace.fact_checks:
                domain = (fc.get('url', '') or '').split('/')[2] if fc.get('url') else ''
                info = get_checker_info(domain)
                fc['checker_tier'] = info.get('tier', 'U')
                fc['checker_tier_label'] = tier_label(info.get('tier', 'U'))
                fc['checker_ifcn'] = info.get('ifcn', False)
                fc['checker_region'] = info.get('region', '')
                fc['checker_notes'] = info.get('notes', '')
    except Exception:
        pass
    
    # Cache the FULLY-enriched result (scoring, facet, compass, claims all attached).
    # Must run last — running it at construction time cached a bare result and
    # cache hits came back with scoring/facet missing.
    try:
        await set_cached(content_hash, mode, analysis.model_dump(mode="json"))
    except Exception as e:
        logger.warning(f"Cache write failed: {e}")

    return analysis


# ============================================
# Result builders
# ============================================

def _build_prism_result(raw: dict, mode: str) -> PrismResult:
    """Build structured PrismResult from raw LLM/heuristic output."""
    settings = get_settings()
    techniques = []

    for t in raw.get("techniques", []):
        conf = float(t.get("confidence", 0.0))
        if conf < settings.confidence_threshold:
            continue

        from app.prism.techniques import TECHNIQUE_BY_NAME
        tech_info = TECHNIQUE_BY_NAME.get(t.get("name", ""), {})
        category = tech_info.get("category", "framing")

        techniques.append(Technique(
            name=t.get("name", "unknown"),
            category=TechniqueCategory(category),
            confidence=conf,
            explanation=t.get("explanation", ""),
            evidence=t.get("evidence", ""),
        ))

    return PrismResult(
        techniques=techniques,
        brief=raw.get("brief", ""),
        detailed=raw.get("detailed", ""),
        model_used=raw.get("_model", "unknown"),
        heuristic_only=raw.get("_heuristic_only", False),
    )


def _build_trace_result(raw: dict) -> TraceResult:
    """Build structured TraceResult from raw trace output."""
    fact_checks = [
        FactCheck(**fc) for fc in raw.get("fact_checks", [])
    ]

    timeline = [
        SourceAppearance(**sa) for sa in raw.get("spread_timeline", [])
    ]

    earliest = None
    if raw.get("earliest_source"):
        earliest = SourceAppearance(**raw["earliest_source"])

    return TraceResult(
        fact_checks=fact_checks,
        earliest_source=earliest,
        spread_timeline=timeline,
        check_worthiness=raw.get("check_worthiness", 0.0),
    )
