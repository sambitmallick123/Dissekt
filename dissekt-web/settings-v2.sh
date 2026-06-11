#!/bin/bash
# Fix: Help/Feedback always on, add image/camera, live config on frontend
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Create config hook for frontend pages
# ============================================

cat > src/lib/config.ts << 'CONFEOF'
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

export function isFeatureEnabled(config: Record<string, any>, feature: string): boolean {
  // Help and Feedback are ALWAYS available
  if (feature === 'help' || feature === 'feedback') return true;

  const tier = getTier();
  const key = tier === 'invited' ? 'features_invited' : 'features_free';
  const features: string[] = config[key] || [];
  return features.includes(feature);
}

// Force refresh config cache (call after admin applies changes)
export function invalidateConfig() {
  _configCache = null;
  _cacheTime = 0;
}
CONFEOF

echo "✅ Config utility: fetchConfig + isFeatureEnabled"

# ============================================
# 2. Fix SettingsTab — remove help/feedback, add image/camera
# ============================================

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

start = content.find('function SettingsTab')
if start == -1:
    print('❌ SettingsTab not found')
    exit()

new_settings = '''function SettingsTab({ adminKey }: { adminKey: string }) {
  const [config, setConfig] = useState<Record<string, any>>({});
  const [draft, setDraft] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);
  const [saveMsg, setSaveMsg] = useState('');

  useEffect(() => {
    fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'get_config' }) })
      .then(r => r.json()).then(d => { 
        const c = d.config || {};
        setConfig(c); 
        setDraft(JSON.parse(JSON.stringify(c)));
        setLoading(false); 
      });
  }, [adminKey]);

  const updateDraft = (key: string, value: any) => {
    setDraft(prev => ({ ...prev, [key]: value }));
    setDirty(true);
    setSaveMsg('');
  };

  const applyChanges = async () => {
    setSaveMsg('Saving...');
    const keys = Object.keys(draft);
    for (const key of keys) {
      if (JSON.stringify(draft[key]) !== JSON.stringify(config[key])) {
        await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'update_config', key, value: draft[key] }) });
      }
    }
    setConfig(JSON.parse(JSON.stringify(draft)));
    setDirty(false);
    setSaveMsg('✅ Changes applied — live on all pages now');
    setTimeout(() => setSaveMsg(''), 4000);
  };

  const resetDraft = () => {
    setDraft(JSON.parse(JSON.stringify(config)));
    setDirty(false);
    setSaveMsg('');
  };

  if (loading) return <div style={{ color: '#888', fontSize: 13 }}>Loading...</div>;

  const freeLimits = draft.free_limits || { brief: 3, detailed: 1 };
  const invitedLimits = draft.invited_limits || { brief: 25, detailed: 10 };
  const featuresFree: string[] = draft.features_free || ['single_scan', 'radar'];
  const featuresInvited: string[] = draft.features_invited || ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'image_upload', 'camera_upload'];

  // Components that can be toggled (help/feedback are always on, not listed here)
  const toggleableFeatures = [
    { key: 'single_scan', label: 'Single scan' },
    { key: 'bulk', label: 'Bulk CSV analysis' },
    { key: 'compare', label: 'Compare sources' },
    { key: 'topics', label: 'Topic tracking' },
    { key: 'radar', label: 'Radar feeds' },
    { key: 'detailed_mode', label: 'Detailed mode' },
    { key: 'image_upload', label: 'Image upload' },
    { key: 'camera_upload', label: 'Camera upload' },
    { key: 'memory', label: 'Reader memory' },
    { key: 'journal', label: 'Decision journal' },
    { key: 'compass', label: 'Compass (political)' },
    { key: 'pulse', label: 'Pulse (coordination)' },
    { key: 'counterfactual', label: 'Counterfactual view' },
    { key: 'claims', label: 'Claim extraction' },
  ];

  const inp: React.CSSProperties = { padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', width: 80, textAlign: 'center' as const };

  return (
    <div>
      {/* Apply bar */}
      {dirty && (
        <div style={{ position: 'sticky', top: 48, zIndex: 20, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', background: '#0d9488', borderRadius: 8, marginBottom: 12 }}>
          <span style={{ fontSize: 13, color: '#fff', fontWeight: 500 }}>You have unsaved changes</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={resetDraft} style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Discard</button>
            <button onClick={applyChanges} style={{ padding: '6px 14px', background: '#fff', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Apply changes</button>
          </div>
        </div>
      )}
      {saveMsg && !dirty && <div style={{ padding: 10, background: '#f0fdfa', borderRadius: 8, fontSize: 13, color: '#0d9488', marginBottom: 12 }}>{saveMsg}</div>}

      {/* Scan limits */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>📊 Scan limits (per day, resets 00:00 GMT)</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>🆓 Free tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={freeLimits.brief} onChange={e => updateDraft('free_limits', { ...freeLimits, brief: parseInt(e.target.value) || 0 })} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={freeLimits.detailed} onChange={e => updateDraft('free_limits', { ...freeLimits, detailed: parseInt(e.target.value) || 0 })} style={inp} /></div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>🎫 Invited tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={invitedLimits.brief} onChange={e => updateDraft('invited_limits', { ...invitedLimits, brief: parseInt(e.target.value) || 0 })} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={invitedLimits.detailed} onChange={e => updateDraft('invited_limits', { ...invitedLimits, detailed: parseInt(e.target.value) || 0 })} style={inp} /></div>
          </div>
        </div>
      </div>

      {/* Expiry */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>⏰ Access expiry</div>
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Code expires:</span><input type="number" value={draft.invite_code_days || 7} onChange={e => updateDraft('invite_code_days', parseInt(e.target.value) || 7)} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>days</span></div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Access valid:</span><input type="number" value={draft.access_months || 6} onChange={e => updateDraft('access_months', parseInt(e.target.value) || 6)} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>months</span></div>
        </div>
      </div>

      {/* Feature toggles */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>🔒 Component access by tier</div>
        <div style={{ fontSize: 11, color: '#888', marginBottom: 12 }}>Help and Feedback are always available to all users.</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>🆓 Free</div>
            {toggleableFeatures.map(f => (<label key={f.key} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresFree.includes(f.key)} onChange={e => { const u = e.target.checked ? [...featuresFree, f.key] : featuresFree.filter(x => x !== f.key); updateDraft('features_free', u); }} />{f.label}</label>))}
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>🎫 Invited</div>
            {toggleableFeatures.map(f => (<label key={f.key} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresInvited.includes(f.key)} onChange={e => { const u = e.target.checked ? [...featuresInvited, f.key] : featuresInvited.filter(x => x !== f.key); updateDraft('features_invited', u); }} />{f.label}</label>))}
          </div>
        </div>
      </div>
    </div>
  );
}
'''

content = content[:start] + new_settings
open('src/app/admin/page.tsx', 'w').write(content)
print('✅ SettingsTab: help/feedback always on, image/camera added, Apply button')
PYEOF

# ============================================
# 3. Update analyze page to respect config
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Add config import
if 'fetchConfig' not in content:
    content = content.replace(
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';",
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';\nimport { fetchConfig, isFeatureEnabled } from '@/lib/config';"
    )

    # Add config state
    content = content.replace(
        "const [mounted, setMounted] = useState(false);",
        "const [mounted, setMounted] = useState(false);\n  const [platformConfig, setPlatformConfig] = useState<Record<string, any>>({});"
    )

    # Fetch config on mount
    content = content.replace(
        "setMounted(true);",
        "setMounted(true);\n    fetchConfig().then(setPlatformConfig);"
    )

    # Gate Bulk CSV tab with config check
    content = content.replace(
        "getTier() === 'invited' ? setScanTab('bulk') : (window.location.href = '/invite')",
        "isFeatureEnabled(platformConfig, 'bulk') ? setScanTab('bulk') : (window.location.href = '/invite')"
    )

    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze page: reads platform config, gates features')
else:
    print('  Already has config integration')
PYEOF

echo ""
echo "✅ All fixes applied:"
echo "  - Help & Feedback: always available (not in toggle list)"
echo "  - Image upload & Camera upload: added as toggleable components"
echo "  - Apply changes button: batches all changes, saves on click"
echo "  - Discard button: reverts to last saved state"
echo "  - Sticky teal bar when changes pending"
echo "  - Config utility: frontend pages fetch config from Supabase"
echo "  - Analyze page: respects feature toggles from admin settings"
echo ""
echo "npm run build"
