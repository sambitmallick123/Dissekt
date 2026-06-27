from app.config import get_settings
from supabase import create_client
s = get_settings()
sb = create_client(s.supabase_url, s.supabase_service_key)
resp = sb.auth.admin.list_users()
users = resp if isinstance(resp, list) else getattr(resp, "users", [])
me = next((u for u in users if (getattr(u, "email","") or "").lower() == "sambitmallick123@gmail.com"), None)
assert me, "user not found"
existing = dict(getattr(me, "app_metadata", {}) or {})
existing["role"] = "admin"
sb.auth.admin.update_user_by_id(me.id, {"app_metadata": existing})
print(f"done — {me.email} app_metadata.role = admin")
