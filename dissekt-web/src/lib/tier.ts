// Access management — source of truth is the Supabase session.
// Logged in = 'member' (full access). Logged out = 'free' (limited).
import { supabase } from './supabase';

export type Tier = 'free' | 'member';

export const LIMITS = {
  free: { brief: 3, detailed: 1 },
  member: { brief: 25, detailed: 10 },
};

// Cache the member state so synchronous callers (canScan etc.) work.
// Updated by refreshAuth() which should be called on app load + auth changes.
let _isMember = false;
let _userEmail = '';
let _role = 'normal';

export async function refreshAuth(): Promise<boolean> {
  if (typeof window === 'undefined') return false;
  const { data } = await supabase.auth.getSession();
  _isMember = !!data.session;
  _userEmail = data.session?.user?.email || '';
  _role = (data.session?.user?.app_metadata?.role as string) || 'normal';
  return _isMember;
}

export function isMember(): boolean {
  return _isMember;
}

export function getTier(): Tier {
  return _isMember ? 'member' : 'free';
}

export function getUserEmail(): string {
  return _userEmail;
}

export function getRole(): string {
  return _role;
}

export function isAdmin(): boolean {
  return _role === 'admin';
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

// ─── Live limits from server (admin per-user overrides) ───
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export async function fetchLiveLimits(): Promise<{ brief: number; detailed: number; tier: Tier } | null> {
  // Fetch the user's effective limits (admin override from user_metadata, else
  // tier default) and cache into the localStorage keys effectiveLimit() reads.
  if (typeof window === 'undefined') return null;
  await refreshAuth();
  const email = getUserEmail();
  if (!email) {
    localStorage.removeItem('dissekt_live_brief');
    localStorage.removeItem('dissekt_live_detailed');
    return null;
  }
  try {
    const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const res = await fetch(`${API}/api/me/limits?email=${encodeURIComponent(email)}`);
    if (!res.ok) return null;
    const d = await res.json();
    if (typeof d.brief === 'number') localStorage.setItem('dissekt_live_brief', String(d.brief));
    if (typeof d.detailed === 'number') localStorage.setItem('dissekt_live_detailed', String(d.detailed));
    return { brief: d.brief, detailed: d.detailed, tier: (d.tier as Tier) || getTier() };
  } catch { return null; }
}

// Effective limit: admin override (cached from server) or tier default
function effectiveLimit(tier: Tier, mode: 'brief' | 'detailed'): number {
  if (typeof window !== 'undefined' && tier === 'member') {
    const live = localStorage.getItem(mode === 'brief' ? 'dissekt_live_brief' : 'dissekt_live_detailed');
    if (live !== null && live !== 'undefined' && !isNaN(Number(live))) return Number(live);
  }
  return LIMITS[tier][mode];
}
