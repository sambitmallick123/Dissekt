#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ── Add a live-limits fetcher to tier.ts (keeps defaults as fallback) ──
python3 << 'PYEOF'
content = open('src/lib/tier.ts').read()

if 'fetchLiveLimits' not in content:
    addition = '''

// ─── Live limits from server (admin overrides) ───
// Defaults above are the fallback; the server is the source of truth.
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export async function fetchLiveLimits(): Promise<{ brief: number; detailed: number; tier: Tier; expires: string | null } | null> {
  if (typeof window === 'undefined') return null;
  const email = localStorage.getItem('dissekt_email');
  if (!email) return null;
  try {
    const res = await fetch(`${API_URL}/api/user/access?email=${encodeURIComponent(email)}`);
    if (!res.ok) return null;
    const d = await res.json();
    // Cache server values so canScan/getRemaining use them
    localStorage.setItem('dissekt_live_brief', String(d.brief_limit));
    localStorage.setItem('dissekt_live_detailed', String(d.detailed_limit));
    localStorage.setItem('dissekt_tier', d.tier);
    if (d.access_expires_at) localStorage.setItem('dissekt_access_expires', d.access_expires_at);
    return { brief: d.brief_limit, detailed: d.detailed_limit, tier: d.tier, expires: d.access_expires_at };
  } catch {
    return null;
  }
}

// Read effective limit: admin override (cached from server) or tier default
function effectiveLimit(tier: Tier, mode: 'brief' | 'detailed'): number {
  if (typeof window !== 'undefined') {
    const live = localStorage.getItem(mode === 'brief' ? 'dissekt_live_brief' : 'dissekt_live_detailed');
    if (live !== null && live !== 'undefined' && !isNaN(Number(live))) return Number(live);
  }
  return LIMITS[tier][mode];
}
'''
    content = content.rstrip() + addition

    # Rewire canScan + getRemaining to use effectiveLimit instead of LIMITS directly
    content = content.replace(
        '''export function canScan(mode: 'brief' | 'detailed'): boolean {
  const tier = getTier();
  const usage = getUsage();
  const limit = LIMITS[tier];
  return usage[mode] < limit[mode];
}''',
        '''export function canScan(mode: 'brief' | 'detailed'): boolean {
  const tier = getTier();
  const usage = getUsage();
  return usage[mode] < effectiveLimit(tier, mode);
}'''
    )

    content = content.replace(
        '''export function getRemaining(): { brief: number; detailed: number; tier: Tier } {
  const tier = getTier();
  const usage = getUsage();
  const limit = LIMITS[tier];
  return {
    brief: Math.max(0, limit.brief - usage.brief),
    detailed: Math.max(0, limit.detailed - usage.detailed),
    tier,
  };
}''',
        '''export function getRemaining(): { brief: number; detailed: number; tier: Tier } {
  const tier = getTier();
  const usage = getUsage();
  return {
    brief: Math.max(0, effectiveLimit(tier, 'brief') - usage.brief),
    detailed: Math.max(0, effectiveLimit(tier, 'detailed') - usage.detailed),
    tier,
  };
}'''
    )

    open('src/lib/tier.ts', 'w').write(content)
    print('✅ tier.ts: fetchLiveLimits + effectiveLimit (defaults as fallback)')
else:
    print('  already added')
PYEOF

# ── Call fetchLiveLimits on Analyze page load so display + canScan sync ──
python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Import fetchLiveLimits
if 'fetchLiveLimits' not in content:
    content = content.replace(
        "from '@/lib/tier';",
        ", fetchLiveLimits } from '@/lib/tier';"
    ).replace(
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS , fetchLiveLimits }",
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS, fetchLiveLimits }"
    )

# In the mount effect, fetch live limits then refresh remaining
if 'fetchLiveLimits()' not in content:
    content = content.replace(
        "setRemaining(getRemaining());\n    setResetIn(getResetTime());",
        "fetchLiveLimits().then(() => setRemaining(getRemaining()));\n    setRemaining(getRemaining());\n    setResetIn(getResetTime());"
    )

open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze page fetches live limits on load')
PYEOF

echo "Run: rm -rf .next && npm run build"
