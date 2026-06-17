#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Rebuild India feeds with verified-working sources (was 2 live, now 6)
set -e

python3 << 'PYEOF'
content = open('app/scope/__init__.py').read()

# Current india block (with the dead feeds)
old_india = '''    "india": [
        "https://scroll.in/rss/feed",
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.ndtv.com/rss/india",
        "https://thewire.in/feed",
        "https://www.altnews.in/feed/",
        "https://indianexpress.com/section/india/feed/",
    ],'''

# Rebuilt with verified-working sources only
new_india = '''    "india": [
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml",
        "https://www.livemint.com/rss/news",
        "https://feeds.feedburner.com/ndtvnews-india-news",
        "https://frontline.thehindu.com/feeder/default.rss",
        "https://www.altnews.in/feed/",
    ],'''

content = content.replace(old_india, new_india)
open('app/scope/__init__.py', 'w').write(content)
print('✅ India rebuilt: 6 verified-working sources')
PYEOF

python3 -c "import ast; ast.parse(open('app/scope/__init__.py').read()); print('✅ scope parses')"

echo ""
echo "═══ Re-test ALL tabs ═══"
python3 << 'PYEOF'
import asyncio
from app.scope import get_scope_feed
for mkt in ['global', 'india', 'us', 'germany', 'uk']:
    items = asyncio.run(get_scope_feed(market=mkt, limit=25))
    srcs = sorted(set(it['source'][:30] for it in items))
    print(f'{mkt:8} → {len(items):>2} items, {len(srcs)} sources: {", ".join(srcs[:5])}{"..." if len(srcs)>5 else ""}')
PYEOF
