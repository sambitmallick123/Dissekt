#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Reverts get_radar_feed to use hardcoded FEEDS (Scope works as before)
set -e

python3 << 'PYEOF'
content = open('app/radar/__init__.py').read()

# Revert get_radar_feed to use hardcoded FEEDS instead of _load_feeds_from_db
new_select = '''    active_feeds = _load_feeds_from_db()
    feeds = []
    if market == "all":
        for m in active_feeds:
            feeds.extend([(url, m) for url in active_feeds[m]])
    elif market in active_feeds:
        feeds = [(url, market) for url in active_feeds[market]]
    else:
        return []'''

old_select = '''    feeds = []
    if market == "all":
        for m in FEEDS:
            feeds.extend([(url, m) for url in FEEDS[m]])
    elif market in FEEDS:
        feeds = [(url, market) for url in FEEDS[market]]
    else:
        return []'''

if new_select in content:
    content = content.replace(new_select, old_select)
    open('app/radar/__init__.py', 'w').write(content)
    print('✅ Rolled back: get_radar_feed uses hardcoded FEEDS again')
else:
    print('⚠️ DB-loader version not found — checking current state')
    if old_select in content:
        print('   Already on hardcoded FEEDS — no change needed')
    else:
        print('   Unexpected state — paste lines 126-135 of app/radar/__init__.py')
PYEOF

python3 -c "import ast; ast.parse(open('app/radar/__init__.py').read()); print('✅ radar parses')"

echo ""
echo "Restart uvicorn. Scope will work as before (hardcoded feeds)."
echo "The _load_feeds_from_db helper + admin Feeds tab + DB table stay in place,"
echo "just not wired to the live feed — resume later."
