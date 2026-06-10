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
  const limit = LIMITS[tier];
  return usage[mode] < limit[mode];
}

export function getRemaining(): { brief: number; detailed: number; tier: Tier } {
  const tier = getTier();
  const usage = getUsage();
  const limit = LIMITS[tier];
  return {
    brief: Math.max(0, limit.brief - usage.brief),
    detailed: Math.max(0, limit.detailed - usage.detailed),
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
