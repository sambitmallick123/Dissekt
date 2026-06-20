#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Fix: _persist_scan references `settings` which isn't global. Use get_settings().
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

# Inside _persist_scan, add a local settings via get_settings()
old = '''    if not email:
        logger.info("[persist] SKIPPED — no email (free/anonymous)")
        return  # free/anonymous -> not stored (member-only)
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_service_key)'''

new = '''    if not email:
        logger.info("[persist] SKIPPED — no email (free/anonymous)")
        return  # free/anonymous -> not stored (member-only)
    try:
        from supabase import create_client
        _settings = get_settings()
        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)'''

if old in c:
    c = c.replace(old, new)
    print("✅ _persist_scan now uses get_settings()")
else:
    # Fallback: just replace the settings refs inside the function
    print("⚠️ exact block not matched — trying targeted replacement")
    c = c.replace(
        "sb = create_client(settings.supabase_url, settings.supabase_service_key)\n        def g(obj",
        "_settings = get_settings()\n        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)\n        def g(obj"
    )

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"

echo ""
echo "Verify the fix:"
sed -n '/def _persist_scan/,/def g(obj/p' app/main.py | grep -n "settings\|get_settings\|create_client"

echo ""
echo "Confirm get_settings exists in main.py:"
grep -n "def get_settings\|from.*import.*get_settings\|get_settings =" app/main.py | head -3

echo ""
echo "Commit + push:"
echo "  git add app/main.py && git commit -m 'fix: persist uses get_settings()' && git push"
