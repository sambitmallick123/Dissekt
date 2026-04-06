"""Dissekt Beacon — memory-optimized orchestrator."""

import asyncio
import hashlib
import logging
import time
from urllib.parse import urlparse

import httpx
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

MAX_TEXT_LENGTH = 3000


async def extract_from_url(url: str) -> tuple[str, str]:
    headers = {"User-Agent": "Mozilla/5.0 (compatible; Dissekt/0.1)"}
    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=headers)
            resp.raise_for_status()
            html = resp.text[:50000]

        from readability import Document as ReadabilityDocument
        from bs4 import BeautifulSoup
        doc = ReadabilityDocument(html)
        title = doc.title()
        soup = BeautifulSoup(doc.summary(), "html.parser")
        text = soup.get_text(separator="\n", strip=True)
        return text[:MAX_TEXT_LENGTH], title

    except Exception as e:
        logger.error(f"URL extraction failed for {url}: {e}")
        raise ValueError(f"Could not extract content from URL: {e}")


def detect_input_type(content: str) -> InputType:
    content = content.strip()
    if content.startswith(("http://", "https://", "www.")):
        return InputType.url
    return InputType.text


def compute_content_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


async def scan(content: str, mode: str = "brief") -> FullAnalysis:
    start_time = time.time()

    input_type = detect_input_type(content)
    source_url = ""

    if input_type == InputType.url:
        source_url = content.strip()
        if not source_url.startswith("http"):
            source_url = "https://" + source_url
        extracted_text, _ = await extract_from_url(source_url)
    else:
        extracted_text = content.strip()[:MAX_TEXT_LENGTH]

    if len(extracted_text) < 20:
        raise ValueError("Content too short (minimum 20 characters)")

    content_hash = compute_content_hash(extracted_text)
    cached = await get_cached(content_hash, mode)
    if cached:
        cached["cached"] = True
        cached["analysis_time_ms"] = int((time.time() - start_time) * 1000)
        return FullAnalysis(**cached)

    heuristics = run_all_heuristics(extracted_text, source_url)

    # Run engines - Trace async, Signal sync (lightweight), Prism async
    prism_result_raw = await route_and_analyze(extracted_text, mode, heuristics)
    trace_result_raw = await run_trace(extracted_text)
    signal_result_raw = run_signal(extracted_text, source_url)

    # Build Prism result
    settings = get_settings()
    techniques = []
    for t in prism_result_raw.get("techniques", []):
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

    prism = PrismResult(
        techniques=techniques,
        brief=prism_result_raw.get("brief", ""),
        detailed=prism_result_raw.get("detailed", ""),
        model_used=prism_result_raw.get("_model", "unknown"),
        heuristic_only=prism_result_raw.get("_heuristic_only", False),
    )

    # Build Trace result
    fact_checks = [FactCheck(**fc) for fc in trace_result_raw.get("fact_checks", [])]
    timeline = [SourceAppearance(**sa) for sa in trace_result_raw.get("spread_timeline", [])]
    earliest = None
    if trace_result_raw.get("earliest_source"):
        earliest = SourceAppearance(**trace_result_raw["earliest_source"])

    trace = TraceResult(
        fact_checks=fact_checks,
        earliest_source=earliest,
        spread_timeline=timeline,
        check_worthiness=trace_result_raw.get("check_worthiness", 0.0),
    )

    signal = SignalResult(**signal_result_raw)

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
        extracted_text=extracted_text[:1000],
        prism=prism,
        trace=trace,
        signal=signal,
        blockchain=blockchain,
        cached=False,
        analysis_time_ms=analysis_time,
    )

    await set_cached(content_hash, mode, analysis.model_dump(mode="json"))

    return analysis