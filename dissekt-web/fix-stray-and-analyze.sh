#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ── 1. Delete the stray root-level tier.ts (real one is in src/lib/) ──
if [ -f tier.ts ]; then
  rm -f tier.ts
  echo "✅ Deleted stray ./tier.ts (real one is src/lib/tier.ts)"
fi
# Also check for other stray copies in root
for f in config.ts FeatureGate.tsx supabase.ts; do
  [ -f "$f" ] && rm -f "$f" && echo "✅ Deleted stray ./$f"
done

# ── 2. Fix remaining analyze: /invite → /signup, "🎫 Invited" label ──
python3 << 'PYEOF'
c = open('src/app/analyze/page.tsx').read()

# /invite redirects → /signup
c = c.replace("window.location.href = '/invite'", "window.location.href = '/signup'")
c = c.replace("? '/compare' : '/invite'", "? '/compare' : '/signup'")

# The badge label that still says Invited
c = c.replace("remaining.tier === 'member' ? '🎫 Invited' : '🆓 Free'", "remaining.tier === 'member' ? '👤 Member' : '🆓 Free'")

open('src/app/analyze/page.tsx','w').write(c)
print("✅ analyze: /invite→/signup, badge→Member")
PYEOF

echo ""
echo "Verify no stray root files + no /invite in analyze:"
ls tier.ts config.ts FeatureGate.tsx supabase.ts 2>/dev/null && echo "  ⚠️ stray files remain" || echo "  ✅ no stray root files"
grep -n "/invite\|🎫 Invited" src/app/analyze/page.tsx || echo "  ✅ analyze clean"

echo ""
echo "Run: rm -rf .next && npm run build"
