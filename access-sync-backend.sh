#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
set -e

echo "════════════════════════════════════════"
echo " STEP 1 — Supabase columns (run in SQL editor):"
echo "════════════════════════════════════════"
cat << 'SQLEOF'

ALTER TABLE invitations ADD COLUMN IF NOT EXISTS brief_limit INT;
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS detailed_limit INT;
-- access_expires_at already exists
-- NULL means "use default" — never overwritten unless admin sets it

SQLEOF

echo "════════════════════════════════════════"
echo " STEP 2 — Backend endpoints"
echo "════════════════════════════════════════"

python3 << 'PYEOF'
content = open('app/main.py').read()

# ── Defaults (single source of truth on backend) ──
if 'TIER_DEFAULTS' not in content:
    defaults = '''
# Tier default limits — used when admin has NOT set a per-user override
TIER_DEFAULTS = {
    "free": {"brief": 3, "detailed": 1},
    "invited": {"brief": 25, "detailed": 10},
}
'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + defaults, 1)

# ── User-facing: GET /api/user/access ──
if '/api/user/access' not in content:
    endpoint = '''

@app.get("/api/user/access")
async def get_user_access(email: str):
    """Return live access limits + expiry for a user. Falls back to tier defaults if no admin override."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    try:
        res = sb.table("invitations").select("status, access_expires_at, brief_limit, detailed_limit").eq("email", email).eq("status", "approved").execute()
        if not res.data:
            # Not an approved invited user → free tier defaults
            return {"tier": "free", "brief_limit": TIER_DEFAULTS["free"]["brief"], "detailed_limit": TIER_DEFAULTS["free"]["detailed"], "access_expires_at": None}
        row = res.data[0]
        # Check expiry
        expires = row.get("access_expires_at")
        if expires:
            from datetime import datetime, timezone
            try:
                exp_dt = datetime.fromisoformat(expires.replace("Z", "+00:00"))
                if exp_dt < datetime.now(timezone.utc):
                    return {"tier": "free", "brief_limit": TIER_DEFAULTS["free"]["brief"], "detailed_limit": TIER_DEFAULTS["free"]["detailed"], "access_expires_at": expires, "expired": True}
            except Exception:
                pass
        # Use admin override if set, else default
        brief = row.get("brief_limit") if row.get("brief_limit") is not None else TIER_DEFAULTS["invited"]["brief"]
        detailed = row.get("detailed_limit") if row.get("detailed_limit") is not None else TIER_DEFAULTS["invited"]["detailed"]
        return {"tier": "invited", "brief_limit": brief, "detailed_limit": detailed, "access_expires_at": expires}
    except Exception as e:
        logger.warning(f"User access lookup failed: {e}")
        # Safe fallback to invited defaults
        return {"tier": "invited", "brief_limit": TIER_DEFAULTS["invited"]["brief"], "detailed_limit": TIER_DEFAULTS["invited"]["detailed"], "access_expires_at": None, "fallback": True}


@app.post("/api/admin/set-limits")
async def admin_set_limits(body: dict):
    """Admin: override a user's brief/detailed limits and/or expiry. Null clears override (back to default)."""
    settings = get_settings()
    from supabase import create_client
    from fastapi import HTTPException
    sb = create_client(settings.supabase_url, settings.supabase_key)

    if body.get("adminKey") != settings.dissekt_admin_key:
        raise HTTPException(401, "Unauthorized")

    email = body.get("email")
    if not email:
        raise HTTPException(400, "email required")

    update = {}
    # Only include fields the admin actually sent (so unset = leave as-is)
    if "brief_limit" in body:
        update["brief_limit"] = body["brief_limit"]  # can be int or null
    if "detailed_limit" in body:
        update["detailed_limit"] = body["detailed_limit"]
    if "access_expires_at" in body:
        update["access_expires_at"] = body["access_expires_at"]

    if not update:
        raise HTTPException(400, "nothing to update")

    sb.table("invitations").update(update).eq("email", email).execute()
    return {"success": True, "email": email, "updated": update}

'''
    # Insert after TIER_DEFAULTS block
    content = content.replace(defaults, defaults + endpoint)
    print('✅ Added /api/user/access + /api/admin/set-limits')

open('app/main.py', 'w').write(content)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ main.py parses')"
echo ""
echo "STEP 3 — enforcement at scan time (next script)"
