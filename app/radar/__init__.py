"""Dissekt Radar — Proactive news intelligence feed.
Scans RSS feeds from 4 markets, returns curated items sorted by time.
"""
import logging
import time
from datetime import datetime, timezone
import feedparser
import httpx

logger = logging.getLogger("dissekt.radar")

FEEDS = {
    "substack": [
        "https://on.substack.com/feed",
        "https://www.slowboring.com/feed",
        "https://heathercoxrichardson.substack.com/feed",
    ],
    "intl": [
        "https://feeds.propublica.org/propublica/main",
        "https://www.bellingcat.com/feed/",
        "https://www.aljazeera.com/xml/rss/all.xml",
        "https://feeds.arstechnica.com/arstechnica/index",
    ],
    "india": [
        "https://scroll.in/rss/feed",
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.ndtv.com/rss/india",
        "https://thewire.in/feed",
        "https://www.altnews.in/feed/",
    ],
    "germany": [
        "https://www.spiegel.de/schlagzeilen/index.rss",
        "https://www.tagesschau.de/xml/rss2/",
        "https://correctiv.org/feed/",
        "https://www.faz.net/rss/aktuell/",
    ],
    "us": [
        "https://feeds.apnews.com/rss/apf-topnews",
        "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
        "https://www.politifact.com/rss/factchecks/",
    ],
    "uk": [
        "https://www.theguardian.com/world/rss",
        "https://feeds.bbci.co.uk/news/rss.xml",
        "https://fullfact.org/feed/",
    ],
}


def _parse_date(entry) -> str:
    """Extract a consistent ISO datetime string from an RSS entry."""
    # feedparser provides parsed time tuples
    for field in ("published_parsed", "updated_parsed", "created_parsed"):
        parsed = entry.get(field)
        if parsed:
            try:
                dt = datetime(*parsed[:6], tzinfo=timezone.utc)
                return dt.isoformat()
            except Exception:
                continue

    # Fallback: try raw string
    for field in ("published", "updated", "created"):
        raw = entry.get(field, "")
        if raw:
            # Try common formats
            for fmt in (
                "%a, %d %b %Y %H:%M:%S %z",    # RFC 2822
                "%a, %d %b %Y %H:%M:%S %Z",    # RFC 2822 with TZ name
                "%Y-%m-%dT%H:%M:%S%z",          # ISO 8601
                "%Y-%m-%dT%H:%M:%SZ",           # ISO 8601 UTC
                "%Y-%m-%d %H:%M:%S",            # Simple
            ):
                try:
                    dt = datetime.strptime(raw.strip(), fmt)
                    if dt.tzinfo is None:
                        dt = dt.replace(tzinfo=timezone.utc)
                    return dt.isoformat()
                except ValueError:
                    continue

    return ""



def _quick_risk_score(title: str, summary: str) -> str:
    """Quick heuristic risk badge based on title/summary keywords."""
    text = (title + " " + summary).lower()
    high_risk = ["breaking", "shocking", "exposed", "conspiracy", "hoax", "fake",
                 "they don't want you to know", "secret", "banned", "cover-up",
                 "exposed", "urgent", "you won't believe", "mainstream media"]
    medium_risk = ["claim", "alleged", "reportedly", "sources say", "unverified",
                   "controversial", "debunk", "misleading", "false", "rumor",
                   "fact-check", "disputed"]

    high_count = sum(1 for w in high_risk if w in text)
    med_count = sum(1 for w in medium_risk if w in text)

    if high_count >= 2:
        return "high"
    elif high_count >= 1 or med_count >= 2:
        return "medium"
    elif med_count >= 1:
        return "low"
    return "none"

async def get_radar_feed(market: str = "all", limit: int = 20) -> list[dict]:
    """Fetch and merge RSS feeds for a market, sorted newest first."""
    feeds = []
    if market == "all":
        for m in FEEDS:
            feeds.extend([(url, m) for url in FEEDS[m]])
    elif market in FEEDS:
        feeds = [(url, market) for url in FEEDS[market]]
    else:
        return []

    items = []
    for feed_url, feed_market in feeds:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(feed_url)
                d = feedparser.parse(resp.text)
                source_name = d.feed.get("title", feed_url)

                for entry in d.entries[:8]:
                    published = _parse_date(entry)
                    items.append({
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "published": published,
                        "source": source_name,
                        "summary": (entry.get("summary", "") or "")[:200],
                        "market": feed_market,
                        "risk": _quick_risk_score(entry.get("title", ""), (entry.get("summary", "") or "")[:200]),
                    })
        except Exception as e:
            logger.warning(f"Failed to fetch {feed_url}: {e}")

    # Sort by ISO date string (works because ISO format sorts alphabetically)
    items.sort(key=lambda x: x.get("published", ""), reverse=True)
    return items[:limit]


def _detect_market(url: str) -> str:
    for market, feeds in FEEDS.items():
        if url in feeds:
            return market
    return "global"
