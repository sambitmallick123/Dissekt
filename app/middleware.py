"""
API rate limiting middleware.
Validates X-API-Key header on /api/scan and other protected endpoints.
Free users use tier-based limits (localStorage on frontend).
API key users get server-side rate limiting.
"""
import hashlib
import time
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("dissekt.middleware")


async def validate_and_rate_limit(api_key: str, supabase_url: str, supabase_key: str) -> dict:
    """
    Validate an API key and check rate limits.
    Returns: {"valid": True/False, "user": ..., "error": ...}
    """
    if not api_key or not api_key.startswith("dsk_"):
        return {"valid": False, "error": "Invalid API key format. Keys start with dsk_"}
    
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    
    try:
        from supabase import create_client
        sb = create_client(supabase_url, supabase_key)
        
        result = sb.table("api_keys").select("*").eq("key_hash", key_hash).execute()
        
        if not result.data:
            return {"valid": False, "error": "API key not found"}
        
        row = result.data[0]
        
        if not row.get("active"):
            return {"valid": False, "error": "API key has been revoked"}
        
        # Check rate limit (reset daily)
        last_reset = row.get("last_reset", "")
        now = datetime.utcnow()
        
        try:
            if last_reset:
                last_reset_dt = datetime.fromisoformat(str(last_reset).replace("Z", "+00:00")).replace(tzinfo=None)
                if (now - last_reset_dt).days >= 1:
                    # Reset counter
                    sb.table("api_keys").update({
                        "requests_today": 1,
                        "last_reset": now.isoformat()
                    }).eq("id", row["id"]).execute()
                    return {"valid": True, "user": row["user_email"], "remaining": row["rate_limit"] - 1}
        except:
            pass
        
        if row.get("requests_today", 0) >= row.get("rate_limit", 100):
            return {
                "valid": False,
                "error": f"Rate limit exceeded ({row['rate_limit']}/day). Resets at midnight UTC.",
                "limit": row["rate_limit"],
                "used": row["requests_today"],
            }
        
        # Increment counter
        sb.table("api_keys").update({
            "requests_today": (row.get("requests_today", 0) or 0) + 1,
        }).eq("id", row["id"]).execute()
        
        remaining = row["rate_limit"] - row.get("requests_today", 0) - 1
        
        return {
            "valid": True,
            "user": row["user_email"],
            "tier": row.get("tier", "pro"),
            "remaining": max(remaining, 0),
            "limit": row["rate_limit"],
        }
    except Exception as e:
        logger.warning(f"Rate limit check failed: {e}")
        # Fail open — allow the request if DB is down
        return {"valid": True, "user": "unknown", "error_note": "Rate limit check failed, request allowed"}
