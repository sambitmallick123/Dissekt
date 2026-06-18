#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Admin user-management endpoints using the Supabase service_role key.
set -e

python3 << 'PYEOF'
content = open('app/main.py').read()

# Find a good insertion point — after the models POST endpoint (before line ~150 send-message area).
# We'll append the new endpoints near the other admin endpoints. Insert before the send-message endpoint.
marker = '@app.post("/api/admin/send-message")'

if marker not in content:
    print('⚠️ send-message marker not found; appending at end instead')
    insert_at = len(content)
    before, after = content, ''
else:
    idx = content.index(marker)
    # back up to the decorator line start
    before = content[:idx]
    after = content[idx:]

endpoints = '''# ─────────────────────────────────────────────────────────────
# ADMIN: Supabase Auth user management (service_role key required)
# ─────────────────────────────────────────────────────────────
def _admin_sb():
    """Supabase client with the SERVICE ROLE key (full admin access)."""
    from supabase import create_client
    return create_client(settings.supabase_url, settings.supabase_service_key)

def _check_admin(adminKey: str):
    if adminKey != settings.dissekt_admin_key:
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="Invalid admin key")

@app.get("/api/admin/users")
async def admin_list_users(adminKey: str, page: int = 1, per_page: int = 100):
    """List all Supabase Auth users."""
    _check_admin(adminKey)
    try:
        sb = _admin_sb()
        resp = sb.auth.admin.list_users(page=page, per_page=per_page)
        # resp may be a list or have .users depending on sdk version
        users = resp if isinstance(resp, list) else getattr(resp, "users", [])
        out = []
        for u in users:
            meta = getattr(u, "user_metadata", {}) or {}
            out.append({
                "id": getattr(u, "id", ""),
                "email": getattr(u, "email", ""),
                "name": meta.get("name", ""),
                "created_at": str(getattr(u, "created_at", "")),
                "last_sign_in_at": str(getattr(u, "last_sign_in_at", "") or ""),
                "banned_until": str(getattr(u, "banned_until", "") or ""),
                "confirmed": bool(getattr(u, "email_confirmed_at", None)),
            })
        return {"users": out, "count": len(out)}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"List users failed: {e}")

@app.post("/api/admin/users/delete")
async def admin_delete_user(body: dict):
    """Delete a Supabase Auth user by id."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        _admin_sb().auth.admin.delete_user(uid)
        return {"success": True, "action": "deleted", "user_id": uid}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Delete failed: {e}")

@app.post("/api/admin/users/ban")
async def admin_ban_user(body: dict):
    """Ban or unban a user. ban=True sets a long ban; ban=False lifts it."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    ban = body.get("ban", True)
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        # ban_duration: a duration string; "876000h" ~ 100 years; "none" lifts the ban
        dur = "876000h" if ban else "none"
        _admin_sb().auth.admin.update_user_by_id(uid, {"ban_duration": dur})
        return {"success": True, "action": "banned" if ban else "unbanned", "user_id": uid}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Ban failed: {e}")

@app.post("/api/admin/users/reset-password")
async def admin_reset_password(body: dict):
    """Trigger a password-reset email for a user."""
    _check_admin(body.get("adminKey", ""))
    email = body.get("email")
    if not email:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="email required")
    try:
        # generate a recovery link / send reset email
        _admin_sb().auth.admin.generate_link({"type": "recovery", "email": email})
        return {"success": True, "action": "reset_sent", "email": email}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Reset failed: {e}")

@app.post("/api/admin/users/set-limits")
async def admin_set_user_limits(body: dict):
    """Adjust a user's per-day limits. Stored in user_metadata."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    brief = body.get("brief_limit")
    detailed = body.get("detailed_limit")
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        sb = _admin_sb()
        # fetch current metadata, merge limits
        u = sb.auth.admin.get_user_by_id(uid)
        user_obj = getattr(u, "user", u)
        meta = dict(getattr(user_obj, "user_metadata", {}) or {})
        if brief is not None: meta["brief_limit"] = brief
        if detailed is not None: meta["detailed_limit"] = detailed
        sb.auth.admin.update_user_by_id(uid, {"user_metadata": meta})
        return {"success": True, "action": "limits_set", "user_id": uid, "brief_limit": brief, "detailed_limit": detailed}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Set limits failed: {e}")

@app.get("/api/admin/users/activity")
async def admin_user_activity(adminKey: str, email: str):
    """View a user's scan activity. GATED by admin_can_view_activity flag (off after test period)."""
    _check_admin(adminKey)
    # Config flag: read from a simple config table; default True for now
    try:
        sb_anon = create_client_anon()
        flag = sb_anon.table("app_config").select("value").eq("key", "admin_can_view_activity").execute()
        can_view = True  # default
        if flag.data:
            can_view = str(flag.data[0]["value"]).lower() in ("true", "1", "yes")
    except Exception:
        can_view = True  # if table/flag missing, default to allowing during test
    if not can_view:
        return {"enabled": False, "message": "Activity viewing is disabled.", "scans": []}
    try:
        sb = _admin_sb()
        # scans/usage keyed by user_email (existing pattern)
        result = sb.table("scans").select("*").eq("user_email", email).order("created_at", desc=True).limit(50).execute()
        return {"enabled": True, "scans": result.data or [], "count": len(result.data or [])}
    except Exception as e:
        # scans table may not exist yet; return empty rather than erroring
        return {"enabled": True, "scans": [], "count": 0, "note": str(e)[:80]}

def create_client_anon():
    from supabase import create_client
    return create_client(settings.supabase_url, settings.supabase_key)

'''

content = before + endpoints + after
open('app/main.py', 'w').write(content)
print('✅ User-management endpoints added')
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ main.py parses')"

echo ""
echo "═══ TEST: list users via service key ═══"
python3 << 'PYEOF'
import asyncio
from app.config import Settings
settings = Settings()
from supabase import create_client
try:
    sb = create_client(settings.supabase_url, settings.supabase_service_key)
    resp = sb.auth.admin.list_users()
    users = resp if isinstance(resp, list) else getattr(resp, "users", [])
    print(f'✅ service key works — {len(users)} users found')
    for u in users[:5]:
        meta = getattr(u, "user_metadata", {}) or {}
        print(f'  - {getattr(u,"email","?")}  (name: {meta.get("name","-")})')
except Exception as e:
    print(f'❌ {e}')
PYEOF
