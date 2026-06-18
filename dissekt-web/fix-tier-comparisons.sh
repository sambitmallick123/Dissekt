#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Fix the tier === 'invited' comparisons surfaced by the compiler.
set -e

# This exact pattern: tier === 'invited' ? 'features_invited' : 'features_free'
for f in src/app/analyze/page.tsx src/app/compare/page.tsx src/app/dashboard/page.tsx src/components/WelcomeBar.tsx; do
  [ -f "$f" ] || continue
  python3 - "$f" << 'PYEOF'
import sys
f = sys.argv[1]
c = open(f).read(); o = c

# The specific feature-key pattern
c = c.replace(
    "tier === 'invited' ? 'features_invited' : 'features_free'",
    "tier === 'member' ? 'features_member' : 'features_free'"
)
# Any remaining tier === 'invited' comparisons
c = c.replace("=== 'invited'", "=== 'member'")
c = c.replace("!== 'invited'", "!== 'member'")
# UI strings "Invited" → "Member" (word boundary-ish, conservative)
c = c.replace(">Invited<", ">Member<")
c = c.replace("'Invited'", "'Member'").replace('"Invited"', '"Member"')
# /invite links → /signup
c = c.replace('href="/invite"', 'href="/signup"').replace("href='/invite'", "href='/signup'")
# features_invited config key → features_member (with the same fallback already in config.ts)
c = c.replace("'features_invited'", "'features_member'").replace('"features_invited"', '"features_member"')

if c != o:
    open(f,'w').write(c); print(f"✅ fixed {f}")
else:
    print(f"— no change {f}")
PYEOF
done

echo ""
echo "Remaining 'invited' comparisons in consumers:"
grep -rn "=== 'invited'\|features_invited\|'invited'" src/app/analyze src/app/compare src/app/dashboard src/components/WelcomeBar.tsx 2>/dev/null | grep -v node_modules || echo "  ✅ none"

echo ""
echo "Run: rm -rf .next && npm run build"
