// Tier management with GMT reset and 6-month expiry

export type Tier = 'free' | 'invited';

export const LIMITS = {
  free: { brief: 3, detailed: 1 },
  invited: { brief: 25, detailed: 10 },
};

export function getTier(): Tier {
  if (typeof window === 'undefined') return 'free';
  
  // Check if invited access expired (6 months)
  const expiry = localStorage.getItem('dissekt_access_expires');
  if (expiry && new Date(expiry) < new Date()) {
    localStorage.removeItem('dissekt_tier');
    localStorage.removeItem('dissekt_access_expires');
    localStorage.removeItem('dissekt_invite_code');
    return 'free';
  }
  
  return localStorage.getItem('dissekt_tier') === 'invited' ? 'invited' : 'free';
}

// Get today's date key in GMT (resets at 0000 GMT)
function getGMTDateKey(): string {
  const now = new Date();
  return `${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
}

export function getUsage(): { brief: number; detailed: number } {
  if (typeof window === 'undefined') return { brief: 0, detailed: 0 };
  const key = getGMTDateKey();
  const stored = localStorage.getItem('dissekt_usage');
  if (stored) {
    try {
      const data = JSON.parse(stored);
      if (data.date === key) return { brief: data.brief || 0, detailed: data.detailed || 0 };
    } catch {}
  }
  return { brief: 0, detailed: 0 };
}

export function incrementUsage(mode: 'brief' | 'detailed') {
  if (typeof window === 'undefined') return;
  const key = getGMTDateKey();
  const usage = getUsage();
  usage[mode]++;
  localStorage.setItem('dissekt_usage', JSON.stringify({ date: key, ...usage }));
}

export function canScan(mode: 'brief' | 'detailed'): boolean {
  const tier = getTier();
  const usage = getUsage();
  return usage[mode] < effectiveLimit(tier, mode);
}

export function getRemaining(): { brief: number; detailed: number; tier: Tier } {
  const tier = getTier();
  const usage = getUsage();
  return {
    brief: Math.max(0, effectiveLimit(tier, 'brief') - usage.brief),
    detailed: Math.max(0, effectiveLimit(tier, 'detailed') - usage.detailed),
    tier,
  };
}

// Time until next GMT midnight reset
export function getResetTime(): string {
  const now = new Date();
  const tomorrow = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0));
  const diff = tomorrow.getTime() - now.getTime();
  const hours = Math.floor(diff / 3600000);
  const mins = Math.floor((diff % 3600000) / 60000);
  return `${hours}h ${mins}m`;
}

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
