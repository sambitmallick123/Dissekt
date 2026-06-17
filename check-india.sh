#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Diagnose which India feeds are failing (only 2 of 6 working)
set -e

python3 << 'PYEOF'
import asyncio, httpx, feedparser
from app.scope import FEEDS

async def check(url):
    try:
        async with httpx.AsyncClient(timeout=12, follow_redirects=True) as c:
            r = await c.get(url, headers={"User-Agent": "Mozilla/5.0 (Dissekt scope bot)"})
            d = feedparser.parse(r.text)
            n = len(d.entries)
            return (url, n, "ok" if n > 0 else "EMPTY")
    except Exception as e:
        return (url, 0, f"FAIL: {str(e)[:45]}")

async def main():
    print("[india] current feeds:")
    results = await asyncio.gather(*[check(u) for u in FEEDS["india"]])
    for url, n, status in results:
        mark = "✅" if status=="ok" else ("⚠️ " if status=="EMPTY" else "❌")
        short = url.replace("https://","").replace("www.","")[:50]
        print(f"  {mark} {n:>3}  {short}  {status if status!='ok' else ''}")

    # Test some additional reliable India sources to backfill
    print("\n[india] candidate replacements:")
    candidates = [
        "https://indianexpress.com/section/india/feed/",
        "https://www.livemint.com/rss/news",
        "https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml",
        "https://www.business-standard.com/rss/latest.rss",
        "https://feeds.feedburner.com/ndtvnews-india-news",
        "https://www.deccanherald.com/rss/national.rss",
        "https://frontline.thehindu.com/feeder/default.rss",
        "https://www.thequint.com/stories.rss",
    ]
    results = await asyncio.gather(*[check(u) for u in candidates])
    for url, n, status in results:
        mark = "✅" if status=="ok" else ("⚠️ " if status=="EMPTY" else "❌")
        short = url.replace("https://","").replace("www.","")[:55]
        print(f"  {mark} {n:>3}  {short}  {status if status!='ok' else ''}")

asyncio.run(main())
PYEOF
