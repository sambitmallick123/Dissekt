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
from readability import Document as ReadabilityDocument
from app.config import get_settings
from app.models import (
    FullAnalysis, InputType, PrismResult, TraceResult, SignalResult,
    Technique, TechniqueCategory, FactCheck, SourceAppearance, BlockchainProof,
)
from app.prism.heuristics import run_all_heuristics
from app.prism.llm import route_and_analyze
from app.trace import run_trace
from app.signal import run_signal
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

async def extract_claims(text: str, mode: str = "brief") -> list[dict]:
    """Extract individual verifiable claims from text using LLM."""
    settings = get_settings()
    import openai

    client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=500,
            messages=[
                {
                    "role": "system",
                    "content": """Extract verifiable factual claims from this text. Return ONLY a JSON array of objects.
Each object: {"claim": "the specific factual claim", "type": "statistic|quote|event|prediction|causal"}
Only include claims that can be fact-checked. Max 7 claims. No explanations, just the JSON array."""
                },
                {"role": "user", "content": text[:1500]}
            ],
        )
        import json
        raw = response.choices[0].message.content.strip()
        # Clean markdown fences if present
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
        claims = json.loads(raw)
        return claims if isinstance(claims, list) else []
    except Exception as e:
        logger.warning(f"Claim extraction LLM failed: {e}")
        return []


# ============================================
# Main scan pipeline
# ============================================

async def scan(content: str, mode: str = "brief") -> FullAnalysis:
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
    start_time = time.time()

    # Step 1: Detect input type
    input_type = detect_input_type(content)
    source_url = ""

    # Step 2: Extract text if URL
    if input_type == InputType.url:
        source_url = content.strip()
        if not source_url.startswith("http"):
            source_url = "https://" + source_url
        extracted_text, _ = await extract_from_url(source_url)
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
    trace_task = run_trace(trace_query if len(trace_query) > 20 else extracted_text[:200])
    signal_task = asyncio.to_thread(run_signal, extracted_text, source_url)

    prism_raw, trace_raw, signal_raw = await asyncio.gather(
        prism_task, trace_task, signal_task,
        return_exceptions=True,
    )

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
        signal_raw = {"toxicity_score": 0.0, "toxicity_labels": {}, "source_bias": None, "source_factuality": None, "sentiment": "neutral", "sentiment_score": 0.0, "primary_emotion": "neutral", "emotion_scores": {}}
    signal_result = SignalResult(**signal_raw)

    # Step 9: Blockchain hash + OTS anchoring
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

    # Step 7: Cache result
    await set_cached(content_hash, mode, analysis.model_dump(mode="json"))

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
    try:
        from app.compass import analyze_political_context
        compass_data = await analyze_political_context(extracted_text)
        analysis.compass = compass_data
    except Exception as e:
        logger.warning(f"Compass failed: {e}")

    # Step 10b: Coordination detection (Pulse)
    try:
        from app.pulse import detect_coordination
        pulse_data = await detect_coordination(extracted_text, analysis.similar_claims)
        analysis.pulse = pulse_data
    except Exception as e:
        logger.warning(f"Pulse failed: {e}")

    # Step 11: Detect language
    analysis.detected_language = detect_language(extracted_text)

    # Step 11: Extract individual claims (only if techniques found, to save API cost)
    if len(prism_result.techniques) > 0:
        try:
            claims = await extract_claims(extracted_text, mode)
            analysis.extracted_claims = claims
        except Exception as e:
            logger.warning(f"Claim extraction failed: {e}")

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
