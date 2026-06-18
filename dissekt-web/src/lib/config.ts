// Fetch platform config and check feature access per tier
import { getTier } from './tier';

let _configCache: Record<string, any> | null = null;
let _cacheTime = 0;

export async function fetchConfig(): Promise<Record<string, any>> {
  if (_configCache && Date.now() - _cacheTime < 30000) return _configCache;
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
    if (!supabaseUrl || !supabaseKey) return getDefaults();

    const res = await fetch(`${supabaseUrl}/rest/v1/platform_config?select=key,value`, {
      headers: { 'apikey': supabaseKey, 'Authorization': `Bearer ${supabaseKey}` },
    });
    if (!res.ok) return getDefaults();

    const rows = await res.json();
    const config: Record<string, any> = {};
    for (const row of rows) config[row.key] = row.value;
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
    member_limits: { brief: 25, detailed: 10 },
    features_free: ['single_scan', 'radar'],
    features_member: ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'image_upload', 'camera_upload'],
    access_months: 6,
  };
}

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
  if (feature === 'help' || feature === 'feedback') return true;
  const key = featureNameMap[feature] || feature;
  const tier = getTier();
  // Support both new (features_member) and legacy (features_invited) config keys
  const tierKey = tier === 'member' ? 'features_member' : 'features_free';
  const features: string[] = config[tierKey] || config[tier === 'member' ? 'features_invited' : 'features_free'] || [];
  return features.includes(key);
}

export function invalidateConfig() {
  _configCache = null;
  _cacheTime = 0;
}
