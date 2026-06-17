#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Find a working Newslaundry RSS feed
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
            return (url, n, title, "ok" if n > 0 else "EMPTY")
    except Exception as e:
        return (url, 0, "", f"FAIL: {str(e)[:45]}")

async def main():
    candidates = [
        "https://www.newslaundry.com/feed",
        "https://www.newslaundry.com/rss",
        "https://www.newslaundry.com/stories.rss",
        "https://newslaundry.com/feed",
        "https://www.newslaundry.com/feed/all",
        "https://www.newslaundry.com/rss/all",
    ]
    results = await asyncio.gather(*[check(u) for u in candidates])
    print("Newslaundry RSS candidates:")
    for url, n, title, status in results:
        mark = "✅" if status=="ok" else ("⚠️ " if status=="EMPTY" else "❌")
        print(f"  {mark} {n:>3}  {url}")
        if status == "ok":
            print(f'         └ feed title: "{title}"')

asyncio.run(main())
PYEOF
