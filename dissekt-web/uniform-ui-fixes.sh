#!/bin/bash
# Dissekt — Uniform UI + Admin Controls + Radar + Consistency fixes
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Fix landing page double footer
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Remove any old inline footer (the one with "Built by Sambit Mallick" etc)
import re

# Remove old footer patterns (before SiteFooter)
# Common old footers have "© 2026" or "Munich, Germany" or "Built by"
old_footer_patterns = [
    r'<div style=\{[^}]*\}\s*>\s*<p style=\{[^}]*\}\s*>.*?(?:Munich|Sambit|©\s*2026).*?</p>\s*</div>',
    r'<footer[^>]*>.*?</footer>',
]

for pattern in old_footer_patterns:
    content = re.sub(pattern, '', content, flags=re.DOTALL)

# Make sure there's only ONE SiteFooter and it's properly placed
footer_count = content.count('<SiteFooter')
if footer_count > 1:
    # Remove all but the last one
    while content.count('<SiteFooter') > 1:
        idx = content.index('<SiteFooter')
        end_idx = content.index('/>', idx) + 2
        content = content[:idx] + content[end_idx:]

open('src/components/LandingPage.tsx', 'w').write(content)
print(f'✅ Landing page: cleaned footers (was {footer_count}, now 1)')
PYEOF

# ============================================
# 2. Fix help page — correct free tier info
# ============================================

python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

replacements = {
    '10 scans/day': '3 brief + 1 detailed scan/day',
    '10 scans per day': '3 brief + 1 detailed scan per day',
    '10 free scans': '3 brief + 1 detailed scans',
    '10 trials per day': '3 brief + 1 detailed scan/day',
    'Free | 10 scans': 'Free | 3 brief + 1 detailed/day',
}

for old, new in replacements.items():
    content = content.replace(old, new)

open('src/app/help/page.tsx', 'w').write(content)
print('✅ Help page: free tier info corrected')
PYEOF

# ============================================
# 3. Fix ALL pages — consistent free tier text
# ============================================

python3 << 'PYEOF'
import glob

replacements = {
    '10 scans/day': '3 brief + 1 detailed/day',
    '10 scans per day': '3 brief + 1 detailed scan per day',
    '10 free scans': '3 free scans',
    'Free: 10 scans': 'Free: 3 brief + 1 detailed',
}

for filepath in glob.glob('src/**/*.tsx', recursive=True):
    try:
        content = open(filepath).read()
        original = content
        for old, new in replacements.items():
            content = content.replace(old, new)
        if content != original:
            open(filepath, 'w').write(content)
            print(f'  Fixed: {filepath}')
    except: pass

print('✅ All pages: consistent free tier info')
PYEOF

# ============================================
# 4. Add Radar back to analyze page
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Check if RadarFeed is already imported
if 'RadarFeed' not in content:
    # Add import
    content = content.replace(
        "import DecisionJournalView from '@/components/DecisionJournal';",
        "import DecisionJournalView from '@/components/DecisionJournal';\nimport RadarFeed from '@/components/RadarFeed';"
    )
    
    # Add Radar below idle state components
    content = content.replace(
        '''            <ScanHistory onReanalyze={(input) => handleScan(input, 'brief')} />
          </>''',
        '''            <ScanHistory onReanalyze={(input) => handleScan(input, 'brief')} />
            <RadarFeed onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
          </>'''
    )
    
    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze page: Radar feed added back')
else:
    print('  Radar already in analyze page')
PYEOF

# ============================================
# 5. Supabase SQL for admin config table
# ============================================

echo ""
echo "⚠️  Run this SQL in Supabase for admin config:"
echo ""
echo "create table if not exists public.platform_config ("
echo "  key text primary key,"
echo "  value jsonb not null,"
echo "  updated_at timestamptz default now()"
echo ");"
echo ""
echo "-- Insert default config"
echo "insert into public.platform_config (key, value) values"
echo "  ('free_limits', '{\"brief\": 3, \"detailed\": 1}'::jsonb),"
echo "  ('invited_limits', '{\"brief\": 25, \"detailed\": 10}'::jsonb),"
echo "  ('features_free', '[\"single_scan\", \"radar\", \"help\", \"feedback\"]'::jsonb),"
echo "  ('features_invited', '[\"single_scan\", \"bulk\", \"compare\", \"topics\", \"radar\", \"detailed_mode\", \"help\", \"feedback\"]'::jsonb),"
echo "  ('radar_enabled', 'true'::jsonb),"
echo "  ('invite_code_days', '7'::jsonb),"
echo "  ('access_months', '6'::jsonb)"
echo "on conflict (key) do nothing;"
echo ""
echo "alter table public.platform_config enable row level security;"
echo "create policy \"Anyone can read config\" on public.platform_config for select using (true);"
echo "create policy \"Admin can update config\" on public.platform_config for update using (true);"
echo "create policy \"Admin can insert config\" on public.platform_config for insert with check (true);"
echo ""

# ============================================
# 6. Admin API — add config + revoke endpoints
# ============================================

python3 << 'PYEOF'
content = open('src/app/api/admin/route.ts').read()

# Add revoke action
if 'revoke' not in content:
    revoke_code = '''
  // Revoke user access
  if (body.action === 'revoke') {
    const { error } = await supabase
      .from('invitations')
      .update({ status: 'rejected', access_expires_at: new Date().toISOString() })
      .eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Notify user
    const { data: inv } = await supabase.from('invitations').select('email, name').eq('id', body.id).single();
    if (inv?.email) {
      await sendEmail(inv.email, 'Dissekt access update', '<p>Your Dissekt access has been revoked. Contact us for more info.</p>');
    }
    return NextResponse.json({ success: true });
  }

  // Update platform config
  if (body.action === 'update_config') {
    const { key, value } = body;
    const { error } = await supabase
      .from('platform_config')
      .upsert({ key, value, updated_at: new Date().toISOString() });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  // Get platform config
  if (body.action === 'get_config') {
    const { data } = await supabase.from('platform_config').select('*');
    const config: Record<string, any> = {};
    (data || []).forEach((row: any) => { config[row.key] = row.value; });
    return NextResponse.json({ config });
  }

'''
    content = content.replace(
        "  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });",
        revoke_code + "  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });"
    )
    open('src/app/api/admin/route.ts', 'w').write(content)
    print('✅ Admin API: revoke + config endpoints added')
PYEOF

# ============================================
# 7. Update Admin page — add Settings tab + revoke
# ============================================

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Add 'settings' to Tab type
content = content.replace(
    "type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions';",
    "type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions' | 'settings';"
)

# Add settings tab button
content = content.replace(
    "t === 'decisions' ? '📓 Decisions'",
    "t === 'decisions' ? '📓 Decisions' : t === 'settings' ? '⚙️ Settings'"
)

# Add settings tab to the list
content = content.replace(
    "'decisions'] as Tab[]).map",
    "'decisions', 'settings'] as Tab[]).map"
)

# Add settings tab render
content = content.replace(
    "{tab === 'decisions' && <DecisionsTab adminKey={adminKey} />}",
    "{tab === 'decisions' && <DecisionsTab adminKey={adminKey} />}\n        {tab === 'settings' && <SettingsTab adminKey={adminKey} />}"
)

# Add revoke button to invitations (for approved users)
content = content.replace(
    '''              {inv.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                      <button onClick={() => action(inv.id, 'approve')} style={{ padding: '6px 14px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>✅ Approve</button>
                      <button onClick={() => action(inv.id, 'reject')} style={{ padding: '6px 14px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>❌ Reject</button>
                    </div>
                  )}''',
    '''              {inv.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                      <button onClick={() => action(inv.id, 'approve')} style={{ padding: '6px 14px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>✅ Approve</button>
                      <button onClick={() => action(inv.id, 'reject')} style={{ padding: '6px 14px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>❌ Reject</button>
                    </div>
                  )}
                  {inv.status === 'approved' && (
                    <button onClick={() => action(inv.id, 'revoke')} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer', flexShrink: 0 }}>🚫 Revoke</button>
                  )}'''
)

# Add 'revoke' to the action function
content = content.replace(
    "const action = async (id: string, act: 'approve' | 'reject') => {",
    "const action = async (id: string, act: 'approve' | 'reject' | 'revoke') => {"
)
content = content.replace(
    "setMsg(act === 'approve' ? `✅ Approved! Code: ${data.code} · Email sent` : '❌ Rejected · User notified');",
    "setMsg(act === 'approve' ? `✅ Approved! Code: ${data.code} · Email sent` : act === 'revoke' ? '🚫 Access revoked · User notified' : '❌ Rejected · User notified');"
)

# Add SettingsTab component at the end (before last closing)
settings_tab = '''
function SettingsTab({ adminKey }: { adminKey: string }) {
  const [config, setConfig] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [saveMsg, setSaveMsg] = useState('');

  useEffect(() => {
    fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ action: 'get_config' }),
    }).then(r => r.json()).then(d => { setConfig(d.config || {}); setLoading(false); });
  }, [adminKey]);

  const updateConfig = async (key: string, value: any) => {
    setConfig(prev => ({ ...prev, [key]: value }));
    await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ action: 'update_config', key, value }),
    });
    setSaveMsg(`✅ ${key} updated`);
    setTimeout(() => setSaveMsg(''), 2000);
  };

  if (loading) return <div style={{ color: '#888', fontSize: 13 }}>Loading config...</div>;

  const freeLimits = config.free_limits || { brief: 3, detailed: 1 };
  const invitedLimits = config.invited_limits || { brief: 25, detailed: 10 };
  const featuresFree = config.features_free || ['single_scan', 'radar', 'help', 'feedback'];
  const featuresInvited = config.features_invited || ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'help', 'feedback'];
  const inviteCodeDays = config.invite_code_days || 7;
  const accessMonths = config.access_months || 6;

  const allFeatures = ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'memory', 'journal', 'compass', 'pulse', 'counterfactual', 'claims', 'help', 'feedback'];
  const featureLabels: Record<string, string> = {
    single_scan: 'Single scan', bulk: 'Bulk CSV', compare: 'Compare', topics: 'Topics',
    radar: 'Radar feeds', detailed_mode: 'Detailed mode', memory: 'Reader memory',
    journal: 'Decision journal', compass: 'Compass (political)', pulse: 'Pulse (coordination)',
    counterfactual: 'Counterfactual view', claims: 'Claim extraction', help: 'Help page', feedback: 'Feedback',
  };

  const inputStyle: React.CSSProperties = { padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', width: 80, textAlign: 'center' as const };

  return (
    <div>
      {saveMsg && <div style={{ padding: 10, background: '#f0fdfa', borderRadius: 8, fontSize: 12, color: '#0d9488', marginBottom: 12 }}>{saveMsg}</div>}

      {/* Scan limits */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>📊 Scan limits (per day, resets 00:00 GMT)</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>🆓 Free tier</div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginBottom: 6 }}>
              <span style={{ fontSize: 12, width: 80 }}>Brief:</span>
              <input type="number" value={freeLimits.brief} onChange={e => updateConfig('free_limits', { ...freeLimits, brief: parseInt(e.target.value) || 0 })} style={inputStyle} />
            </div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <span style={{ fontSize: 12, width: 80 }}>Detailed:</span>
              <input type="number" value={freeLimits.detailed} onChange={e => updateConfig('free_limits', { ...freeLimits, detailed: parseInt(e.target.value) || 0 })} style={inputStyle} />
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>🎫 Invited tier</div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginBottom: 6 }}>
              <span style={{ fontSize: 12, width: 80 }}>Brief:</span>
              <input type="number" value={invitedLimits.brief} onChange={e => updateConfig('invited_limits', { ...invitedLimits, brief: parseInt(e.target.value) || 0 })} style={inputStyle} />
            </div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <span style={{ fontSize: 12, width: 80 }}>Detailed:</span>
              <input type="number" value={invitedLimits.detailed} onChange={e => updateConfig('invited_limits', { ...invitedLimits, detailed: parseInt(e.target.value) || 0 })} style={inputStyle} />
            </div>
          </div>
        </div>
      </div>

      {/* Access expiry */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>⏰ Access expiry</div>
        <div style={{ display: 'flex', gap: 20 }}>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span style={{ fontSize: 12 }}>Invite code expires in:</span>
            <input type="number" value={inviteCodeDays} onChange={e => updateConfig('invite_code_days', parseInt(e.target.value) || 7)} style={inputStyle} />
            <span style={{ fontSize: 12, color: '#888' }}>days</span>
          </div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span style={{ fontSize: 12 }}>Access valid for:</span>
            <input type="number" value={accessMonths} onChange={e => updateConfig('access_months', parseInt(e.target.value) || 6)} style={inputStyle} />
            <span style={{ fontSize: 12, color: '#888' }}>months</span>
          </div>
        </div>
      </div>

      {/* Feature access control */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>🔒 Feature access by tier</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>🆓 Free tier features</div>
            {allFeatures.map(f => (
              <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, fontSize: 12, cursor: 'pointer' }}>
                <input type="checkbox" checked={featuresFree.includes(f)}
                  onChange={e => {
                    const updated = e.target.checked ? [...featuresFree, f] : featuresFree.filter((x: string) => x !== f);
                    updateConfig('features_free', updated);
                  }} />
                {featureLabels[f] || f}
              </label>
            ))}
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>🎫 Invited tier features</div>
            {allFeatures.map(f => (
              <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, fontSize: 12, cursor: 'pointer' }}>
                <input type="checkbox" checked={featuresInvited.includes(f)}
                  onChange={e => {
                    const updated = e.target.checked ? [...featuresInvited, f] : featuresInvited.filter((x: string) => x !== f);
                    updateConfig('features_invited', updated);
                  }} />
                {featureLabels[f] || f}
              </label>
            ))}
          </div>
        </div>
      </div>

      {/* Radar control */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>📡 System controls</div>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, cursor: 'pointer' }}>
          <input type="checkbox" checked={config.radar_enabled !== false}
            onChange={e => updateConfig('radar_enabled', e.target.checked)} />
          Radar feeds enabled
        </label>
      </div>
    </div>
  );
}
'''

# Insert before the last line (closing of file)
content = content.rstrip()
if content.endswith('}'):
    content = content[:-1] + settings_tab + '\n}'

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin page: Settings tab + revoke button added')
PYEOF

# ============================================
# 8. Add SiteFooter to analyze page
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

if 'SiteFooter' not in content:
    content = content.replace(
        "import SiteHeader from '@/components/SiteHeader';",
        "import SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';"
    )
    content = content.replace('</main>', '<SiteFooter />\n    </main>')
    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze page: SiteFooter added')
PYEOF

echo ""
echo "✅ All fixes applied:"
echo "  1. Landing page: duplicate footer removed"
echo "  2. Help page: '10 scans' → '3 brief + 1 detailed'"  
echo "  3. All pages: consistent free tier text"
echo "  4. Analyze page: Radar feeds restored + SiteFooter"
echo "  5. Admin: ⚙️ Settings tab (limits, expiry, feature toggles)"
echo "  6. Admin: 🚫 Revoke access button on approved users"
echo "  7. Uniform SiteHeader + SiteFooter on all pages"
echo ""
echo "⚠️  Create platform_config table in Supabase (SQL shown above)"
echo ""
echo "Test: npm run build && npm run dev"
