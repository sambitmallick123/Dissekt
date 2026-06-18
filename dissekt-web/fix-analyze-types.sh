#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Fix the remaining 'invited' type annotation + UI labels in analyze
set -e

python3 << 'PYEOF'
c = open('src/app/analyze/page.tsx').read()

# Type annotation: 'free' | 'invited' → 'free' | 'member'
c = c.replace("tier: 'free' | 'invited'", "tier: 'free' | 'member'")

# UI label: the tier badge (line 156-157)
c = c.replace("remaining.tier === 'invited' ? '#0d9488' : '#888'", "remaining.tier === 'member' ? '#0d9488' : '#888'")
c = c.replace("remaining.tier === 'invited' ? '🎫 Invited' : '🆓 Free'", "remaining.tier === 'member' ? '👤 Member' : '🆓 Free'")

open('src/app/analyze/page.tsx','w').write(c)
print("✅ analyze: type annotation + badge label fixed")
PYEOF

echo ""
echo "Any remaining 'invited' in analyze:"
grep -n "invited\|Invited" src/app/analyze/page.tsx || echo "  ✅ none"

echo ""
echo "Run: rm -rf .next && npm run build"
