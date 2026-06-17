#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Try Newslaundry topic RSS + Google News fallback
set -e

python3 << 'PYEOF'
import asyncio, httpx, feedparser

async def check(url):
    try:
        async with httpx.AsyncClient(timeout=12, follow_redirects=True) as c:
            r = await c.get(url, headers={"User-Agent": "Mozilla/5.0 (Dissekt scope bot)"})
            d = feedparser.parse(r.text)
            n = len(d.entries)
            title = d.feed.get("title", "?")
            sample = d.entries[0].get("title","")[:50] if n else ""
            return (url, n, title, sample, "ok" if n > 0 else "EMPTY")
    except Exception as e:
        return (url, 0, "", "", f"FAIL: {str(e)[:40]}")

async def main():
    candidates = [
        # topic-based RSS paths
        "https://www.newslaundry.com/topic/rss",
        "https://www.newslaundry.com/section/reports/rss",
        "https://www.newslaundry.com/reports/rss",
        # Google News feed for newslaundry.com (public articles, last 24h-ish)
        "https://news.google.com/rss/search?q=site:newslaundry.com&hl=en-IN&gl=IN&ceid=IN:en",
        "https://news.google.com/rss/search?q=when:7d+allinurl:newslaundry.com&hl=en-IN&gl=IN&ceid=IN:en",
    ]
    results = await asyncio.gather(*[check(u) for u in candidates])
    print("Newslaundry feed candidates:")
    for url, n, title, sample, status in results:
        mark = "✅" if status=="ok" else ("⚠️ " if status=="EMPTY" else "❌")
        print(f"  {mark} {n:>3}  {url[:60]}")
        if status == "ok":
            print(f'         └ "{title[:40]}" | e.g. "{sample}"')

asyncio.run(main())
PYEOF
