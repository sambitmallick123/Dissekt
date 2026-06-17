#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Revert the broken Newslaundry/relabeling change. Restore working 6-source India.
set -e

python3 << 'PYEOF'
content = open('app/scope/__init__.py').read()

# 1. Remove Newslaundry from India feed list
content = content.replace(
    '''        "https://www.altnews.in/feed/",
        "https://news.google.com/rss/search?q=site:newslaundry.com&hl=en-IN&gl=IN&ceid=IN:en",
    ],''',
    '''        "https://www.altnews.in/feed/",
    ],'''
)

# 2. Remove the _is_gnews relabeling block — restore original source_name line
content = content.replace(
    '''                source_name = d.feed.get("title", feed_url)
                _is_gnews = "news.google.com" in feed_url
                # Derive a clean source label for Google News aggregated feeds
                _gnews_label = ""
                if _is_gnews:
                    import re as _re
                    m = _re.search(r"site:([\\w.]+)", feed_url)
                    if m:
                        dom = m.group(1).replace("www.", "").split(".")[0]
                        _gnews_label = dom.capitalize()  # newslaundry → Newslaundry
                for entry in d.entries[:15]:''',
    '''                source_name = d.feed.get("title", feed_url)
                for entry in d.entries[:15]:'''
)

# 3. Restore the original item append (remove _title/_src relabeling)
content = content.replace(
    '''                    _title = entry.get("title", "")
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
                        "source": _src,''',
    '''                    items.append({
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "published": published,
                        "source": source_name,'''
)

open('app/scope/__init__.py', 'w').write(content)
print('✅ Reverted Newslaundry + relabeling. India back to 6 working sources.')
PYEOF

python3 -c "import ast; ast.parse(open('app/scope/__init__.py').read()); print('✅ scope parses')"

echo ""
echo "═══ Verify all tabs work again ═══"
python3 << 'PYEOF'
import asyncio
from app.scope import get_scope_feed
for mkt in ['global', 'india', 'us', 'germany', 'uk']:
    items = asyncio.run(get_scope_feed(market=mkt, limit=25))
    srcs = len(set(it['source'] for it in items))
    print(f'{mkt:8} → {len(items):>2} items, {srcs} sources')
PYEOF
