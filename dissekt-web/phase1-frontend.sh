#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# PHASE 1 frontend: send member's session email with scan request
set -e

python3 << 'PYEOF'
c = open('src/app/analyze/page.tsx').read()

# 1. Ensure getUserEmail imported from tier
import re
m = re.search(r"import \{([^}]*)\} from '@/lib/tier'", c)
if m and 'getUserEmail' not in m.group(1):
    names = m.group(1).rstrip()
    c = c[:m.start(1)] + names + ', getUserEmail ' + c[m.end(1):]
    print("✅ getUserEmail imported")
elif not m:
    print("⚠️ tier import not found")

# 2. Add the X-User-Email header to the scan fetch
old = '''      const res = await fetch(`${API_URL}/api/scan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode, image }),
      });'''
new = '''      const res = await fetch(`${API_URL}/api/scan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-User-Email': getUserEmail() || '' },
        body: JSON.stringify({ content, mode, image }),
      });'''
if old in c:
    c = c.replace(old, new)
    print("✅ X-User-Email header added to scan request")
else:
    print("⚠️ fetch block not matched exactly")

open('src/app/analyze/page.tsx','w').write(c)
PYEOF

echo ""
echo "Verify:"
grep -n "getUserEmail\|X-User-Email" src/app/analyze/page.tsx | head

echo ""
echo "Run: rm -rf .next && npm run build"
