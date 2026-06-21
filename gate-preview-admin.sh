#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Gate the constellation preview bypass behind the admin key
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

# Change the signature to also accept an admin key header
old_sig = 'async def constellation(email: str, preview: bool = False):'
new_sig = 'async def constellation(email: str, preview: bool = False, x_admin_key: str = Header(default="")):'
if old_sig in c:
    c = c.replace(old_sig, new_sig)
    print("✅ added x_admin_key header param")
else:
    print("⚠️ signature not matched")

# Gate the preview bypass: preview only honored if admin key matches
old_gate = '''        THRESHOLD = 10
        if len(scans) < THRESHOLD and not preview:
            return {"ready": False, "count": len(scans), "needed": THRESHOLD, "nodes": [], "edges": []}'''
new_gate = '''        THRESHOLD = 10
        _settings_admin = get_settings()
        admin_preview = preview and x_admin_key and x_admin_key == getattr(_settings_admin, "dissekt_admin_key", None)
        if len(scans) < THRESHOLD and not admin_preview:
            return {"ready": False, "count": len(scans), "needed": THRESHOLD, "nodes": [], "edges": []}'''
if old_gate in c:
    c = c.replace(old_gate, new_gate)
    print("✅ preview now requires admin key")
else:
    print("⚠️ gate block not matched")

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"

echo ""
echo "Check Header is imported:"
grep -n "from fastapi import.*Header\|^from fastapi import\|import Header" app/main.py | head -3

echo ""
echo "Check admin key field name in config:"
grep -n "admin_key\|dissekt_admin" app/config.py | head

echo ""
echo "Verify:"
grep -n "x_admin_key\|admin_preview" app/main.py | head
