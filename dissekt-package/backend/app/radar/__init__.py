"""Dissekt Radar — Proactive news intelligence feed.

Scans RSS feeds from 4 markets, returns curated items.
MVP: Return RSS items. Full auto-analysis in Week 3.
"""
import logging
import feedparser
import httpx

logger = logging.getLogger("dissekt.radar")

FEEDS = {
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


async def get_radar_feed(market: str = "all", limit: int = 20) -> list[dict]:
    """Fetch and merge RSS feeds for a market."""
    feeds = []
    if market == "all":
        for m in FEEDS:
            feeds.extend(FEEDS[m])
    elif market in FEEDS:
        feeds = FEEDS[market]
    else:
        return []

    items = []
    for feed_url in feeds:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(feed_url)
                d = feedparser.parse(resp.text)
                for entry in d.entries[:5]:
                    items.append({
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "published": entry.get("published", ""),
                        "source": d.feed.get("title", feed_url),
                        "summary": entry.get("summary", "")[:200],
                        "market": market if market != "all" else _detect_market(feed_url),
                    })
        except Exception as e:
            logger.warning(f"Failed to fetch {feed_url}: {e}")

    items.sort(key=lambda x: x.get("published", ""), reverse=True)
    return items[:limit]


def _detect_market(url: str) -> str:
    for market, feeds in FEEDS.items():
        if url in feeds:
            return market
    return "global"
