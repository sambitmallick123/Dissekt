#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# PHASE 1: Persist member scans (metadata only — techniques, clarity, toxicity)
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

marker = '@app.post("/api/scan", response_model=FullAnalysis)'
helper = '''def _persist_scan(email: str, mode: str, result) -> None:
    """Persist scan METADATA for members only (no raw text). Best-effort."""
    if not email:
        return  # free/anonymous -> not stored (member-only)
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_service_key)
        def g(obj, *path, default=None):
            cur = obj
            for p in path:
                if cur is None: return default
                cur = getattr(cur, p, None) if not isinstance(cur, dict) else cur.get(p)
            return cur if cur is not None else default

        techs_raw = g(result, "prism", "techniques", default=[]) or []
        techniques = []
        for t in techs_raw:
            name = getattr(t, "name", None) if not isinstance(t, dict) else t.get("name")
            conf = getattr(t, "confidence", None) if not isinstance(t, dict) else t.get("confidence")
            if name:
                techniques.append({"name": name, "confidence": conf or 0})

        scoring = g(result, "scoring", default={}) or {}
        clarity = None
        if isinstance(scoring, dict):
            clarity = scoring.get("clarity", scoring.get("score"))

        toxicity = g(result, "signal", "toxicity_score", default=0.0)
        language = g(result, "detected_language", default="en")

        sb.table("scans").insert({
            "user_email": email,
            "mode": mode,
            "language": language,
            "clarity": clarity,
            "techniques": techniques,
            "toxicity": toxicity,
            "entities": [],
        }).execute()
    except Exception as e:
        logger.warning(f"Scan persist failed (non-fatal): {e}")

'''

if '_persist_scan' not in c:
    c = c.replace(marker, helper + marker)
    print("OK persist helper added")

c = c.replace(
    'async def scan_content(request: ScanRequest, x_api_key: str = Header(None, alias="X-API-Key")):',
    'async def scan_content(request: ScanRequest, x_api_key: str = Header(None, alias="X-API-Key"), x_user_email: str = Header(None, alias="X-User-Email")):'
)

old_return = '''        result = await scan(
            content=request.content,
            mode=request.mode.value,
            image=request.image,
        )
        return result'''
new_return = '''        result = await scan(
            content=request.content,
            mode=request.mode.value,
            image=request.image,
        )
        try:
            _persist_scan(x_user_email or "", request.mode.value, result)
        except Exception:
            pass
        return result'''
c = c.replace(old_return, new_return)
print("OK scan_content persists")

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('OK main.py parses')"

echo ""
echo "Verify:"
grep -n "_persist_scan\|x_user_email" app/main.py | head

echo ""
echo "=== Create the scans table in Supabase SQL editor: ==="
cat << 'SQL'
CREATE TABLE IF NOT EXISTS scans (
  id BIGSERIAL PRIMARY KEY,
  user_email TEXT NOT NULL,
  mode TEXT,
  language TEXT,
  clarity REAL,
  techniques JSONB,
  toxicity REAL,
  entities JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE scans DISABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS scans_user_idx ON scans(user_email, created_at DESC);
SQL
