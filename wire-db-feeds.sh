#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
set -e

python3 << 'PYEOF'
content = open('app/radar/__init__.py').read()

# 1. Make _load_feeds_from_db return {market: [url, ...]} to match FEEDS shape
old_helper = '''def _load_feeds_from_db():
    """Load active feeds from Supabase, fall back to hardcoded FEEDS."""
    try:
        from app.config import get_settings
        from supabase import create_client
        s = get_settings()
        sb = create_client(s.supabase_url, s.supabase_key)
        res = sb.table("scope_feeds").select("*").eq("active", True).execute()
        if res.data:
            by_market = {}
            for row in res.data:
                by_market.setdefault(row["market"], []).append((row["name"], row["url"]))
            return by_market
    except Exception:
        pass
    return FEEDS'''

new_helper = '''def _load_feeds_from_db():
    """Load active feeds from Supabase as {market: [url,...]}. Falls back to hardcoded FEEDS."""
    try:
        from app.config import get_settings
        from supabase import create_client
        s = get_settings()
        sb = create_client(s.supabase_url, s.supabase_key)
        res = sb.table("scope_feeds").select("*").eq("active", True).execute()
        if res.data:
            by_market = {}
            for row in res.data:
                by_market.setdefault(row["market"], []).append(row["url"])
            return by_market
    except Exception as e:
        logger.warning(f"Feed DB load failed, using defaults: {e}")
    return FEEDS'''

content = content.replace(old_helper, new_helper)

# 2. Make get_radar_feed USE the DB loader instead of hardcoded FEEDS
old_select = '''    feeds = []
    if market == "all":
        for m in FEEDS:
            feeds.extend([(url, m) for url in FEEDS[m]])
    elif market in FEEDS:
        feeds = [(url, market) for url in FEEDS[market]]
    else:
        return []'''

new_select = '''    active_feeds = _load_feeds_from_db()
    feeds = []
    if market == "all":
        for m in active_feeds:
            feeds.extend([(url, m) for url in active_feeds[m]])
    elif market in active_feeds:
        feeds = [(url, market) for url in active_feeds[market]]
    else:
        return []'''

content = content.replace(old_select, new_select)

open('app/radar/__init__.py', 'w').write(content)
print('✅ get_radar_feed now reads from DB (admin edits go live)')
PYEOF

python3 -c "import ast; ast.parse(open('app/radar/__init__.py').read()); print('✅ radar parses')"

echo ""
echo "=== Now align the market name: international -> intl ==="
echo "Run this in Supabase SQL editor:"
echo ""
echo "  UPDATE scope_feeds SET market = 'intl' WHERE market = 'international';"
echo ""
