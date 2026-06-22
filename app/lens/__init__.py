"""Dissekt Trace — Source origin finder.

Searches fact-check databases and traces claim origins:
1. Google Fact Check API (free, 100+ organizations globally)
2. ClaimBuster check-worthiness scoring
3. Web search for origin tracing (SerpAPI or Brave)
4. Internal claim graph (Qdrant similarity search)
"""

import logging
import httpx
from app.config import get_settings
import re
from datetime import datetime

logger = logging.getLogger("dissekt.trace")


_RATING_LABELS = [
    ("pants on fire", "Pants on Fire"), ("four pinocchios", "False"),
    ("three pinocchios", "Mostly False"), ("two pinocchios", "Half True"),
    ("one pinocchio", "Mostly True"),
    ("mostly false", "Mostly False"), ("mostly true", "Mostly True"),
    ("half true", "Half True"), ("partly false", "Partly False"),
    ("misleading", "Misleading"), ("missing context", "Missing Context"),
    ("out of context", "Out of Context"), ("unproven", "Unproven"),
    ("unsupported", "Unsupported"), ("no evidence", "No Evidence"),
    ("mixture", "Mixture"), ("mixed", "Mixture"), ("satire", "Satire"),
    ("scam", "Scam"), ("altered", "Altered"), ("fake", "Fake"),
    ("incorrect", "Incorrect"), ("inaccurate", "Inaccurate"),
    ("false", "False"), ("true", "True"), ("correct", "Correct"),
    ("accurate", "Accurate"),
]


def _short_rating(text: str) -> str:
    """Collapse a free-text fact-check verdict into a short chip label."""
    t = (text or "").strip()
    if not t:
        return ""
    low = t.lower()
    for needle, label in _RATING_LABELS:
        if needle in low:
            return label
    # No known verdict word: fall back to a trimmed first fragment.
    first = t.split(".")[0].strip()
    if len(first) <= 24:
        return first
    return first[:24].rstrip() + "…"


async def search_fact_checks(claim_text: str) -> list[dict]:
    """Search Google Fact Check API for existing fact-checks.

    Free tier: 10,000 queries/day.
    Searches 100+ fact-checking orgs including:
    India: Vishvas News, Factly, Alt News, BOOM Live
    Germany: Correctiv, dpa-Faktencheck
    US: PolitiFact, Snopes, FactCheck.org
    UK: Full Fact, BBC Reality Check
    """
    settings = get_settings()
    if not settings.google_factcheck_api_key:
        logger.warning("GOOGLE_FACTCHECK_API_KEY not set — skipping fact-check search")
        return []

    url = "https://factchecktools.googleapis.com/v1alpha1/claims:search"
    params = {
        "key": settings.google_factcheck_api_key,
        "query": claim_text[:200],  # API query limit
        "languageCode": "en",
        "pageSize": 10,
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()

        results = []
        for claim in data.get("claims", []):
            for review in claim.get("claimReview", []):
                _raw_rating = review.get("textualRating", "")
                results.append({
                    "title": review.get("title", claim.get("text", "")),
                    "publisher": review.get("publisher", {}).get("name", "Unknown"),
                    "url": review.get("url", ""),
                    "rating": _short_rating(_raw_rating),
                    "rating_detail": _raw_rating,
                    "date": review.get("reviewDate", ""),
                })

        return results

    except Exception as e:
        logger.error(f"Fact Check API error: {e}")
        return []


async def search_web_for_origin(claim_text: str) -> list[dict]:
    """Search the web for earliest appearances of this claim.

    Uses SerpAPI (paid) or Brave Search API (free tier).
    """
    settings = get_settings()

    # Try SerpAPI first
    if settings.serpapi_key:
        return await _search_serpapi(claim_text, settings.serpapi_key)

    # Fallback to Brave Search
    if settings.brave_search_api_key:
        return await _search_brave(claim_text, settings.brave_search_api_key)

    logger.warning("No search API configured — skipping origin tracing")
    return []


async def _search_serpapi(query: str, api_key: str) -> list[dict]:
    """Search via SerpAPI (Google search results)."""
    url = "https://serpapi.com/search"
    params = {
        "api_key": api_key,
        "q": f'"{query[:100]}"',  # Exact match search
        "num": 10,
        "sort": "date",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()

        results = []
        for item in data.get("organic_results", []):
            results.append({
                "url": item.get("link", ""),
                "title": item.get("title", ""),
                "date": item.get("date", ""),
                "platform": _extract_platform(item.get("link", "")),
            })

        return results

    except Exception as e:
        logger.error(f"SerpAPI error: {e}")
        return []


async def _search_brave(query: str, api_key: str) -> list[dict]:
    """Search via Brave Search API (free tier: 2000 queries/month)."""
    url = "https://api.search.brave.com/res/v1/web/search"
    headers = {
        "X-Subscription-Token": api_key,
        "Accept": "application/json",
    }
    params = {
        "q": query[:200],
        "count": 10,
        "freshness": "py",  # Past year
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, headers=headers, params=params)
            resp.raise_for_status()
            data = resp.json()

        results = []
        for item in data.get("web", {}).get("results", []):
            results.append({
                "url": item.get("url", ""),
                "title": item.get("title", ""),
                "date": item.get("age", ""),
                "platform": _extract_platform(item.get("url", "")),
            })

        return results

    except Exception as e:
        logger.error(f"Brave Search error: {e}")
        return []


def _extract_platform(url: str) -> str:
    """Extract platform name from URL."""
    domain = url.lower()
    if "twitter.com" in domain or "x.com" in domain:
        return "X/Twitter"
    if "reddit.com" in domain:
        return "Reddit"
    if "facebook.com" in domain or "fb.com" in domain:
        return "Facebook"
    if "youtube.com" in domain or "youtu.be" in domain:
        return "YouTube"
    if "instagram.com" in domain:
        return "Instagram"
    if "t.me" in domain or "telegram" in domain:
        return "Telegram"
    if "whatsapp" in domain:
        return "WhatsApp"
    return "Web"


async def run_lens(text: str) -> dict:
    """Run the full Trace pipeline on a text.

    Returns: fact_checks, spread_timeline, check_worthiness
    """
    import asyncio

    # Run fact-check search and web search in parallel
    fact_checks_task = search_fact_checks(text)
    web_results_task = search_web_for_origin(text)

    fact_checks, web_results = await asyncio.gather(
        fact_checks_task,
        web_results_task,
        return_exceptions=True,
    )

    # Handle exceptions
    if isinstance(fact_checks, Exception):
        logger.error(f"Fact check search failed: {fact_checks}")
        fact_checks = []
    if isinstance(web_results, Exception):
        logger.error(f"Web search failed: {web_results}")
        web_results = []

    # Find earliest source
    earliest = web_results[0] if web_results else None

    web_results = _enrich_with_platform_dates(web_results)

    return {
        "fact_checks": fact_checks,
        "spread_timeline": web_results,
        "earliest_source": earliest,
        "check_worthiness": 0.0,  # TODO: ClaimBuster integration
    }



def _enrich_with_platform_dates(results: list[dict]) -> list[dict]:
    """Extract dates from social media URLs where possible."""
    for item in results:
        if item.get("date"):
            continue
        url = item.get("url", "")
        
        # Twitter/X: Snowflake ID encodes timestamp
        if "x.com" in url or "twitter.com" in url:
            match = re.search(r'/status/(\d+)', url)
            if match:
                tweet_id = int(match.group(1))
                try:
                    timestamp_ms = (tweet_id >> 22) + 1288834974657
                    dt = datetime.fromtimestamp(timestamp_ms / 1000)
                    item["date"] = dt.strftime("%b %d, %Y %H:%M")
                except Exception:
                    pass
        
        # Threads
        if "threads.com" in url:
            item["platform"] = "Threads"
    
    return results