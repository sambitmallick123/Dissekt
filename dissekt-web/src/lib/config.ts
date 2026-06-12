// Fetch platform config and check feature access per tier
import { getTier } from './tier';

let _configCache: Record<string, any> | null = null;
let _cacheTime = 0;

export async function fetchConfig(): Promise<Record<string, any>> {
  // Cache for 30 seconds
  if (_configCache && Date.now() - _cacheTime < 30000) return _configCache;

  try {
    const apiUrl = typeof window !== 'undefined'
      ? (process.env.NEXT_PUBLIC_SUPABASE_URL ? '' : '')
      : '';

    // Fetch from Supabase directly (platform_config is public read)
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

    if (!supabaseUrl || !supabaseKey) {
      return getDefaults();
    }

    const res = await fetch(`${supabaseUrl}/rest/v1/platform_config?select=key,value`, {
      headers: { 'apikey': supabaseKey, 'Authorization': `Bearer ${supabaseKey}` },
    });

    if (!res.ok) return getDefaults();

    const rows = await res.json();
    const config: Record<string, any> = {};
    for (const row of rows) {
      config[row.key] = row.value;
    }

    _configCache = config;
    _cacheTime = Date.now();
    return config;
  } catch {
    return getDefaults();
  }
}

function getDefaults(): Record<string, any> {
  return {
    free_limits: { brief: 3, detailed: 1 },
    invited_limits: { brief: 25, detailed: 10 },
    features_free: ['single_scan', 'radar'],
    features_invited: ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'image_upload', 'camera_upload'],
    invite_code_days: 7,
    access_months: 6,
  };
}

// Map display names to config keys
const featureNameMap: Record<string, string> = {
  'Bulk CSV analysis': 'bulk',
  'Bulk CSV': 'bulk',
  'Compare sources': 'compare',
  'Compare': 'compare',
  'Topic tracking': 'topics',
  'Observatory': 'topics',
  'Detailed mode': 'detailed_mode',
  'Scope feeds': 'radar',
  'Radar': 'radar',
  'Image upload': 'image_upload',
  'Camera upload': 'camera_upload',
  'Reader memory': 'memory',
  'Recall': 'memory',
  'Decision journal': 'journal',
  'Ledger': 'journal',
  'Meridian': 'compass',
  'Flare': 'pulse',
  'Mirror view': 'counterfactual',
  'Facet extraction': 'claims',
  'Imprint': 'imprint',
  'Thread': 'thread',
};

export function isFeatureEnabled(config: Record<string, any>, feature: string): boolean {
  // Help and Feedback are ALWAYS available
  if (feature === 'help' || feature === 'feedback') return true;
  // Resolve display name to config key
  const key = featureNameMap[feature] || feature;

  const tier = getTier();
  const tierKey = tier === 'invited' ? 'features_invited' : 'features_free';
  const features: string[] = config[tierKey] || [];
  return features.includes(key);
}

// Force refresh config cache (call after admin applies changes)
export function invalidateConfig() {
  _configCache = null;
  _cacheTime = 0;
}
