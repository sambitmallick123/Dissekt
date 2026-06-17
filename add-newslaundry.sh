#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Add Newslaundry via Google News feed, with source relabeling
set -e

python3 << 'PYEOF'
content = open('app/scope/__init__.py').read()

# 1. Add the Newslaundry Google News feed to India
old_india = '''    "india": [
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml",
        "https://www.livemint.com/rss/news",
        "https://feeds.feedburner.com/ndtvnews-india-news",
        "https://frontline.thehindu.com/feeder/default.rss",
        "https://www.altnews.in/feed/",
    ],'''

new_india = '''    "india": [
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml",
        "https://www.livemint.com/rss/news",
        "https://feeds.feedburner.com/ndtvnews-india-news",
        "https://frontline.thehindu.com/feeder/default.rss",
        "https://www.altnews.in/feed/",
        "https://news.google.com/rss/search?q=site:newslaundry.com&hl=en-IN&gl=IN&ceid=IN:en",
    ],'''

content = content.replace(old_india, new_india)
print('✅ Added Newslaundry (via Google News) to India')

# 2. Relabel Google News items: clean "Title - Publisher" → title + set source to publisher
# Find where items are appended and add relabeling. The source_name is set from feed title.
# For Google News feeds, d.feed.title is '"site:..." - Google News'. We detect by feed_url.
old_append = '''                source_name = d.feed.get("title", feed_url)
                for entry in d.entries[:15]:'''

new_append = '''                source_name = d.feed.get("title", feed_url)
                _is_gnews = "news.google.com" in feed_url
                # Derive a clean source label for Google News aggregated feeds
                _gnews_label = ""
                if _is_gnews:
                    import re as _re
                    m = _re.search(r"site:([\\w.]+)", feed_url)
                    if m:
                        dom = m.group(1).replace("www.", "").split(".")[0]
                        _gnews_label = dom.capitalize()  # newslaundry → Newslaundry
                for entry in d.entries[:15]:'''

content = content.replace(old_append, new_append)

# 3. In the item dict, use the cleaned source + title for Google News items
old_item = '''                    items.append({
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "published": published,
                        "source": source_name,'''

new_item = '''                    _title = entry.get("title", "")
                    _src = source_name
                    if _is_gnews:
                        # Google News titles look like "Article title - Publisher"
                        if " - " in _title:
                            _title = _title.rsplit(" - ", 1)[0]
                        _src = _gnews_label or "Newslaundry"
                    items.append({
                        "title": _title,
                        "url": entry.get("link", ""),
                        "published": published,
                        "source": _src,'''

content = content.replace(old_item, new_item)
print('✅ Google News items relabeled to publisher name + cleaned titles')

open('app/scope/__init__.py', 'w').write(content)
PYEOF

python3 -c "import ast; ast.parse(open('app/scope/__init__.py').read()); print('✅ scope parses')"

echo ""
echo "═══ TEST: India feed now includes Newslaundry ═══"
python3 << 'PYEOF'
import asyncio
from app.scope import get_scope_feed
items = asyncio.run(get_scope_feed(market='india', limit=25))
print(f'india: {len(items)} items')
from collections import Counter
for src, n in Counter(it['source'] for it in items).most_common():
    print(f'  {n}  {src}')
# Show a Newslaundry item if present
nl = [it for it in items if 'newslaundry' in it['source'].lower()]
if nl:
    print(f'\nNewslaundry sample: "{nl[0]["title"][:60]}"')
    print(f'  url: {nl[0]["url"][:60]}')
PYEOF
