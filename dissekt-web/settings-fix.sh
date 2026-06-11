#!/bin/bash
# Fix SettingsTab: batch save with Apply button, remove System section
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Find and replace the entire SettingsTab function
start = content.find('function SettingsTab')
if start == -1:
    print('❌ SettingsTab not found')
    exit()

# Find the end — it's the last function, so goes to end of file
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
    setSaveMsg('✅ Changes applied across the platform');
    setTimeout(() => setSaveMsg(''), 3000);
  };

  const resetDraft = () => {
    setDraft(JSON.parse(JSON.stringify(config)));
    setDirty(false);
    setSaveMsg('');
  };

  if (loading) return <div style={{ color: '#888', fontSize: 13 }}>Loading...</div>;

  const freeLimits = draft.free_limits || { brief: 3, detailed: 1 };
  const invitedLimits = draft.invited_limits || { brief: 25, detailed: 10 };
  const featuresFree: string[] = draft.features_free || ['single_scan', 'radar', 'help', 'feedback'];
  const featuresInvited: string[] = draft.features_invited || ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'help', 'feedback'];
  const allFeatures = ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'memory', 'journal', 'compass', 'pulse', 'counterfactual', 'claims', 'help', 'feedback'];
  const labels: Record<string, string> = { single_scan: 'Single scan', bulk: 'Bulk CSV', compare: 'Compare', topics: 'Topics', radar: 'Radar', detailed_mode: 'Detailed mode', memory: 'Reader memory', journal: 'Decision journal', compass: 'Compass', pulse: 'Pulse', counterfactual: 'Counterfactual', claims: 'Claims', help: 'Help', feedback: 'Feedback' };
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
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>🔒 Feature access by tier</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>🆓 Free</div>
            {allFeatures.map(f => (<label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresFree.includes(f)} onChange={e => { const u = e.target.checked ? [...featuresFree, f] : featuresFree.filter(x => x !== f); updateDraft('features_free', u); }} />{labels[f] || f}</label>))}
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>🎫 Invited</div>
            {allFeatures.map(f => (<label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresInvited.includes(f)} onChange={e => { const u = e.target.checked ? [...featuresInvited, f] : featuresInvited.filter(x => x !== f); updateDraft('features_invited', u); }} />{labels[f] || f}</label>))}
          </div>
        </div>
      </div>
    </div>
  );
}
'''

content = content[:start] + new_settings
open('src/app/admin/page.tsx', 'w').write(content)
print('✅ SettingsTab: batch save with Apply button, System section removed')
PYEOF

npm run build
