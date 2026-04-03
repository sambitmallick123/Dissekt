"""Dissekt Beacon — Upload scanner and orchestrator.

Primary product surface. User pastes URL or text.
Beacon extracts content, then runs Prism + Trace + Signal in parallel.
"""

import asyncio
import hashlib
import logging
import time
from urllib.parse import urlparse

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


# ============================================
# Content extraction
# ============================================

async def extract_from_url(url: str) -> tuple[str, str]:
    """Fetch URL and extract article text.

    Returns: (extracted_text, page_title)
    Uses readability-lxml for article extraction.
    """
    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; Dissekt/0.1; +https://dissekt.co)"
    }

    try:
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=headers)
            resp.raise_for_status()
            html = resp.text

        doc = ReadabilityDocument(html)
        title = doc.title()
        # Get text content, strip HTML tags
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(doc.summary(), "html.parser")
        text = soup.get_text(separator="\n", strip=True)

        return text[:10000], title  # Cap at 10K chars

    except Exception as e:
        logger.error(f"URL extraction failed for {url}: {e}")
        raise ValueError(f"Could not extract content from URL: {e}")


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
    8. Generate blockchain hash
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
    prism_task = route_and_analyze(extracted_text, mode, heuristics)
    trace_task = run_trace(extracted_text)
    signal_task = asyncio.to_thread(run_signal, extracted_text, source_url)

    prism_raw, trace_raw, signal_raw = await asyncio.gather(
        prism_task, trace_task, signal_task,
        return_exceptions=True,
    )

    # Step 6: Combine results
    # Prism
    if isinstance(prism_raw, Exception):
        logger.error(f"Prism failed: {prism_raw}")
        prism_raw = {"brief": "Analysis engine temporarily unavailable.", "techniques": [], "_model": "error"}

    prism_result = _build_prism_result(prism_raw, mode)

    # Trace
    if isinstance(trace_raw, Exception):
        logger.error(f"Trace failed: {trace_raw}")
        trace_raw = {"fact_checks": [], "spread_timeline": [], "earliest_source": None, "check_worthiness": 0.0}

    trace_result = _build_trace_result(trace_raw)

    # Signal
    if isinstance(signal_raw, Exception):
        logger.error(f"Signal failed: {signal_raw}")
        signal_raw = {"toxicity_score": 0.0, "toxicity_labels": {}, "source_bias": None, "source_factuality": None, "sentiment": "neutral", "sentiment_score": 0.0, "primary_emotion": "neutral", "emotion_scores": {}}

    signal_result = SignalResult(**signal_raw)

    # Blockchain hash
    blockchain = BlockchainProof(
        content_hash=content_hash,
        timestamp=str(int(time.time())),
        proof_status="pending",  # OTS anchoring happens async
    )

    analysis_time = int((time.time() - start_time) * 1000)

    analysis = FullAnalysis(
        id=content_hash[:16],
        input_type=input_type,
        input_content=content[:500],
        extracted_text=extracted_text[:2000],
        prism=prism_result,
        trace=trace_result,
        signal=signal_result,
        blockchain=blockchain,
        cached=False,
        analysis_time_ms=analysis_time,
    )

    # Step 7: Cache result
    await set_cached(content_hash, mode, analysis.model_dump(mode="json"))

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
        # Confidence gating
        if conf < settings.confidence_threshold:
            continue

        # Map category
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
