#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt  (PROJECT ROOT, not dissekt-web)
set -e

echo "=== STEP 1: Supabase table SQL (run this in Supabase SQL editor) ==="
cat << 'SQLEOF'

-- Run this in Supabase → SQL Editor:
CREATE TABLE IF NOT EXISTS scope_feeds (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL UNIQUE,
  market TEXT NOT NULL DEFAULT 'international',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

SQLEOF

echo ""
echo "=== STEP 2: Backend changes ==="

# ── 2a. Add feed CRUD endpoints to main.py ──
python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/admin/feeds' not in content:
    endpoint = '''

@app.get("/api/admin/feeds")
async def admin_list_feeds():
    """List all Scope feeds from DB (falls back to defaults if empty)."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    try:
        res = sb.table("scope_feeds").select("*").order("market").execute()
        feeds = res.data or []
        if not feeds:
            # Seed from hardcoded defaults on first use
            from app.radar import FEEDS as DEFAULT_FEEDS
            seed = []
            for market, feed_list in DEFAULT_FEEDS.items():
                for item in feed_list:
                    if isinstance(item, dict):
                        seed.append({"name": item.get("name", item.get("url", "")), "url": item.get("url", ""), "market": market, "active": True})
                    elif isinstance(item, (list, tuple)) and len(item) >= 2:
                        seed.append({"name": item[0], "url": item[1], "market": market, "active": True})
                    else:
                        seed.append({"name": str(item), "url": str(item), "market": market, "active": True})
            if seed:
                sb.table("scope_feeds").insert(seed).execute()
                res = sb.table("scope_feeds").select("*").order("market").execute()
                feeds = res.data or []
        return {"feeds": feeds}
    except Exception as e:
        from app.radar import FEEDS as DEFAULT_FEEDS
        flat = []
        for market, feed_list in DEFAULT_FEEDS.items():
            for item in feed_list:
                url = item.get("url") if isinstance(item, dict) else (item[1] if isinstance(item, (list, tuple)) else str(item))
                name = item.get("name") if isinstance(item, dict) else (item[0] if isinstance(item, (list, tuple)) else str(item))
                flat.append({"name": name, "url": url, "market": market, "active": True})
        return {"feeds": flat, "fallback": True, "error": str(e)}


@app.post("/api/admin/feeds")
async def admin_manage_feed(body: dict):
    """Add, update, or remove a Scope feed."""
    settings = get_settings()
    from supabase import create_client
    from fastapi import HTTPException
    sb = create_client(settings.supabase_url, settings.supabase_key)

    if body.get("adminKey") != settings.dissekt_admin_key:
        raise HTTPException(401, "Unauthorized")

    action = body.get("action")
    if action == "add":
        sb.table("scope_feeds").insert({
            "name": body.get("name", ""),
            "url": body.get("url", ""),
            "market": body.get("market", "international"),
            "active": True,
        }).execute()
    elif action == "update":
        sb.table("scope_feeds").update({
            "name": body.get("name"),
            "url": body.get("url"),
            "market": body.get("market"),
            "active": body.get("active", True),
        }).eq("id", body.get("id")).execute()
    elif action == "delete":
        sb.table("scope_feeds").delete().eq("id", body.get("id")).execute()
    elif action == "toggle":
        sb.table("scope_feeds").update({"active": body.get("active")}).eq("id", body.get("id")).execute()
    else:
        raise HTTPException(400, "Invalid action")

    res = sb.table("scope_feeds").select("*").order("market").execute()
    return {"success": True, "feeds": res.data or []}

'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + endpoint, 1)
    open('app/main.py', 'w').write(content)
    print('✅ Added /api/admin/feeds endpoints')
else:
    print('  feeds endpoints already exist')
PYEOF

# ── 2b. Make radar read from DB ──
python3 << 'PYEOF'
content = open('app/radar/__init__.py').read()

if 'def _load_feeds_from_db' not in content:
    helper = '''

def _load_feeds_from_db():
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
    return FEEDS

'''
    # Insert after the FEEDS dict definition (after its closing brace at column 0)
    import re
    # Find end of FEEDS = { ... }
    m = re.search(r'\nFEEDS = \{.*?\n\}\n', content, flags=re.DOTALL)
    if m:
        idx = m.end()
        content = content[:idx] + helper + content[idx:]
        open('app/radar/__init__.py', 'w').write(content)
        print('✅ Added _load_feeds_from_db helper')
    else:
        print('⚠️  Could not locate FEEDS dict end — add helper manually')
else:
    print('  helper already exists')
PYEOF

# Verify parse
python3 -c "import ast; ast.parse(open('app/main.py').read()); ast.parse(open('app/radar/__init__.py').read()); print('✅ backend parses')"

echo ""
echo "=== STEP 3: Done. Restart uvicorn. Frontend admin tab next. ==="
