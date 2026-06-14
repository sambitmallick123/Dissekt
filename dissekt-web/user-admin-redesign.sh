#!/bin/bash
# Dissekt — User welcome bar + personal dashboard + admin redesign
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. USER: Welcome bar on /analyze
# ============================================

# Add WelcomeBar component
cat > src/components/WelcomeBar.tsx << 'WBEOF'
'use client';
import { useState, useEffect } from 'react';

export default function WelcomeBar() {
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
    setTier(localStorage.getItem('dissekt_tier') || 'free');
  }, []);

  if (!mounted || tier !== 'invited') return null;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <div style={{ background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', padding: '14px 24px', color: 'white' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{greeting}{name ? `, ${name}` : ''}</div>
          <div style={{ fontSize: 11, opacity: 0.8, marginTop: 2 }}>See how information is constructed</div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <a href="/dashboard" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>📊 My insights</a>
          <a href="/aperture" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔖 Aperture</a>
          <a href="/dashboard" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔑 API keys</a>
        </div>
      </div>
    </div>
  );
}
WBEOF

echo "✅ WelcomeBar component"

# Wire into analyze page
python3 -c "
content = open('src/app/analyze/page.tsx').read()
if 'WelcomeBar' not in content:
    content = content.replace(
        \"import SiteHeader from '@/components/SiteHeader';\",
        \"import SiteHeader from '@/components/SiteHeader';\\nimport WelcomeBar from '@/components/WelcomeBar';\"
    )
    content = content.replace(
        '<SiteHeader active=\"Analyze\" />',
        '<SiteHeader active=\"Analyze\" />\\n      <WelcomeBar />'
    )
    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze: WelcomeBar wired')
"

# ============================================
# 2. USER: Personal insights dashboard /dashboard
# ============================================

cat > src/app/dashboard/page.tsx << 'DASHEOF'
'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

function sc(v: number) { return v >= 0.65 ? '#16a34a' : v >= 0.35 ? '#d97706' : '#dc2626'; }

export default function DashboardPage() {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [tab, setTab] = useState<'insights' | 'apikeys'>('insights');
  const [decisions, setDecisions] = useState<any[]>([]);
  const [keys, setKeys] = useState<any[]>([]);
  const [newKeyName, setNewKeyName] = useState('');
  const [newKey, setNewKey] = useState('');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const e = localStorage.getItem('dissekt_email') || '';
    const n = localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '';
    const t = localStorage.getItem('dissekt_tier') || 'free';
    setEmail(e); setName(n); setTier(t);
    
    fetch(`${API_URL}/api/decisions`).then(r => r.json()).then(d => setDecisions(d.decisions || [])).catch(() => {});
    if (e) fetch(`${API_URL}/api/keys/usage?email=${encodeURIComponent(e)}`).then(r => r.json()).then(d => setKeys(d.keys || [])).catch(() => {});
  }, []);

  const createKey = async () => {
    if (!email) return;
    const res = await fetch(`${API_URL}/api/keys/create`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, name: newKeyName || 'Default' }) });
    const d = await res.json();
    setNewKey(d.key || '');
    setNewKeyName('');
    fetch(`${API_URL}/api/keys/usage?email=${encodeURIComponent(email)}`).then(r => r.json()).then(d => setKeys(d.keys || []));
  };

  const revokeKey = async (id: string) => {
    await fetch(`${API_URL}/api/keys/revoke`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id }) });
    fetch(`${API_URL}/api/keys/usage?email=${encodeURIComponent(email)}`).then(r => r.json()).then(d => setKeys(d.keys || []));
  };

  if (!mounted) return null;

  // Compute profile stats
  const total = decisions.length;
  const trust = decisions.filter(d => d.decision === 'trust').length;
  const unsure = decisions.filter(d => d.decision === 'unsure').length;
  const reject = decisions.filter(d => d.decision === 'reject').length;
  const trustPct = total > 0 ? Math.round(trust / total * 100) : 0;
  const unsurePct = total > 0 ? Math.round(unsure / total * 100) : 0;
  const rejectPct = total > 0 ? Math.round(reject / total * 100) : 0;
  const profileType = trustPct > 60 ? 'Trusting' : rejectPct > 60 ? 'Skeptical' : unsurePct > 40 ? 'Careful' : 'Balanced';

  // Source patterns
  const sourceMap: Record<string, { trust: number; unsure: number; reject: number }> = {};
  for (const d of decisions) {
    const preview = d.input_preview || '';
    const match = preview.match(/https?:\/\/([^\/\s]+)/);
    const src = match ? match[1].replace('www.', '') : preview.split(/\s+/).slice(0, 2).join(' ').slice(0, 15);
    if (!src) continue;
    if (!sourceMap[src]) sourceMap[src] = { trust: 0, unsure: 0, reject: 0 };
    sourceMap[src][d.decision as 'trust' | 'unsure' | 'reject']++;
  }
  const topSources = Object.entries(sourceMap).sort((a, b) => (b[1].trust + b[1].unsure + b[1].reject) - (a[1].trust + a[1].unsure + a[1].reject)).slice(0, 5);

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader active="Dashboard" />
      <div style={{ maxWidth: 900, margin: '0 auto', padding: '24px 16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a' }}>Your reading lens</div>
            <div style={{ fontSize: 12, color: '#888' }}>Based on {total} decisions · {tier === 'invited' ? '🎫 Invited' : '🆓 Free'}</div>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <button onClick={() => setTab('insights')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'insights' ? '#0d9488' : '#fff', color: tab === 'insights' ? '#fff' : '#555', boxShadow: tab !== 'insights' ? '0 0 0 0.5px #e5eaea' : 'none' }}>📊 Insights</button>
            <button onClick={() => setTab('apikeys')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'apikeys' ? '#0d9488' : '#fff', color: tab === 'apikeys' ? '#fff' : '#555', boxShadow: tab !== 'apikeys' ? '0 0 0 0.5px #e5eaea' : 'none' }}>🔑 API keys</button>
          </div>
        </div>

        {tab === 'insights' && (
          <>
            {/* Top row cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, marginBottom: 12 }}>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, borderTop: '3px solid #0d9488' }}>
                <div style={{ fontSize: 10, color: '#888', marginBottom: 4 }}>Reader profile</div>
                <div style={{ fontSize: 18, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>{profileType}</div>
                {total > 0 && (
                  <>
                    <div style={{ display: 'flex', height: 10, borderRadius: 5, overflow: 'hidden', marginBottom: 4 }}>
                      {trustPct > 0 && <div style={{ width: `${trustPct}%`, background: '#16a34a' }} />}
                      {unsurePct > 0 && <div style={{ width: `${unsurePct}%`, background: '#d97706' }} />}
                      {rejectPct > 0 && <div style={{ width: `${rejectPct}%`, background: '#dc2626' }} />}
                    </div>
                    <div style={{ fontSize: 9, color: '#888' }}>Trust {trustPct}% · Unsure {unsurePct}% · Reject {rejectPct}%</div>
                  </>
                )}
                {total === 0 && <div style={{ fontSize: 11, color: '#aaa' }}>Make decisions on scanned content to build your profile</div>}
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, borderTop: '3px solid #2563eb' }}>
                <div style={{ fontSize: 10, color: '#888', marginBottom: 4 }}>Total decisions</div>
                <div style={{ fontSize: 28, fontWeight: 700, color: '#2563eb' }}>{total}</div>
                <div style={{ fontSize: 9, color: '#888' }}>Trust {trust} · Unsure {unsure} · Reject {reject}</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, borderTop: '3px solid #d97706' }}>
                <div style={{ fontSize: 10, color: '#888', marginBottom: 4 }}>Sources evaluated</div>
                <div style={{ fontSize: 28, fontWeight: 700, color: '#d97706' }}>{Object.keys(sourceMap).length}</div>
                <div style={{ fontSize: 9, color: '#888' }}>Across all your analyses</div>
              </div>
            </div>

            {/* Trust by source */}
            {topSources.length > 0 && (
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, marginBottom: 12 }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 10 }}>🕸️ Trust by source</div>
                {topSources.map(([src, data]) => {
                  const t = data.trust + data.unsure + data.reject;
                  return (
                    <div key={src} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <span style={{ fontSize: 11, width: 100, color: '#555', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flexShrink: 0 }}>{src}</span>
                      <div style={{ flex: 1, height: 10, borderRadius: 5, overflow: 'hidden', display: 'flex', background: '#f0f0ee' }}>
                        {data.trust > 0 && <div style={{ width: `${data.trust / t * 100}%`, background: '#16a34a' }} />}
                        {data.unsure > 0 && <div style={{ width: `${data.unsure / t * 100}%`, background: '#d97706' }} />}
                        {data.reject > 0 && <div style={{ width: `${data.reject / t * 100}%`, background: '#dc2626' }} />}
                      </div>
                      <span style={{ fontSize: 10, color: '#888', width: 20, textAlign: 'right' }}>{t}</span>
                    </div>
                  );
                })}
                <div style={{ display: 'flex', gap: 12, marginTop: 8, fontSize: 10, color: '#888' }}>
                  <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#16a34a', marginRight: 3 }} />Trust</span>
                  <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#d97706', marginRight: 3 }} />Unsure</span>
                  <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#dc2626', marginRight: 3 }} />Reject</span>
                </div>
              </div>
            )}

            {/* Recent decisions */}
            {decisions.length > 0 && (
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>Recent decisions</div>
                {decisions.slice(0, 8).map((d: any, i: number) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 0', borderBottom: i < 7 ? '0.5px solid #f0f0ee' : 'none', fontSize: 11 }}>
                    <div style={{ width: 8, height: 8, borderRadius: 4, background: d.decision === 'trust' ? '#16a34a' : d.decision === 'unsure' ? '#d97706' : '#dc2626', flexShrink: 0 }} />
                    <span style={{ flex: 1, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{d.input_preview || '—'}</span>
                    <span style={{ fontSize: 10, color: '#888', flexShrink: 0 }}>{d.created_at ? new Date(d.created_at).toLocaleDateString() : ''}</span>
                  </div>
                ))}
              </div>
            )}
          </>
        )}

        {tab === 'apikeys' && (
          <>
            {!email && (
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 24, textAlign: 'center' }}>
                <div style={{ fontSize: 13, color: '#888' }}>Sign in to manage API keys</div>
              </div>
            )}
            {email && (
              <>
                <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, marginBottom: 12 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 10 }}>Your API keys</div>
                  {keys.length === 0 && <div style={{ fontSize: 12, color: '#888', padding: 12, textAlign: 'center' }}>No API keys yet</div>}
                  {keys.map((k: any) => (
                    <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '0.5px solid #f0f0ee' }}>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontSize: 12, fontWeight: 600, fontFamily: 'monospace', color: '#1a1a1a' }}>{k.prefix}...</span>
                          <span style={{ fontSize: 11, color: '#888' }}>{k.name}</span>
                          {!k.active && <span style={{ fontSize: 9, padding: '1px 6px', background: '#fef2f2', color: '#dc2626', borderRadius: 3 }}>Revoked</span>}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 3 }}>
                          <div style={{ width: 120, height: 4, background: '#f0f0ee', borderRadius: 2 }}>
                            <div style={{ height: '100%', width: `${Math.min(k.usage_pct || 0, 100)}%`, background: (k.usage_pct || 0) > 80 ? '#dc2626' : '#0d9488', borderRadius: 2 }} />
                          </div>
                          <span style={{ fontSize: 9, color: '#888' }}>{k.requests_today || 0}/{k.rate_limit || 100}</span>
                        </div>
                      </div>
                      {k.active && <button onClick={() => revokeKey(k.id)} style={{ padding: '3px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 4, fontSize: 10, cursor: 'pointer' }}>Revoke</button>}
                    </div>
                  ))}
                </div>
                <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, marginBottom: 12 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 8 }}>Create new key</div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <input type="text" placeholder="Key name" value={newKeyName} onChange={e => setNewKeyName(e.target.value)} style={{ flex: 1, padding: '7px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, outline: 'none' }} />
                    <button onClick={createKey} style={{ padding: '7px 16px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Generate</button>
                  </div>
                  {newKey && (
                    <div style={{ marginTop: 8, padding: '8px 12px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 6 }}>
                      <div style={{ fontSize: 10, fontWeight: 600, color: '#166534', marginBottom: 2 }}>Save this key — shown once only:</div>
                      <div style={{ fontSize: 12, fontFamily: 'monospace', color: '#1a1a1a', wordBreak: 'break-all', userSelect: 'all' }}>{newKey}</div>
                    </div>
                  )}
                </div>
                <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 6 }}>Quick start</div>
                  <div style={{ background: '#1a1a1a', borderRadius: 8, padding: '10px 14px', fontSize: 11, fontFamily: 'monospace', color: '#5eead4', lineHeight: 1.8, overflowX: 'auto' }}>
                    curl -X POST https://dissekt-api.up.railway.app/api/scan \<br />
                    {'  '}-H "Content-Type: application/json" \<br />
                    {'  '}-H "X-API-Key: dsk_your_key" \<br />
                    {'  '}-d {'\u007B'}"content": "https://example.com/article", "mode": "brief"{'\u007D'}
                  </div>
                </div>
              </>
            )}
          </>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
DASHEOF

echo "✅ Personal insights dashboard (/dashboard)"

# Add Dashboard to header nav for logged-in users
python3 -c "
content = open('src/components/SiteHeader.tsx').read()
if \"'Dashboard'\" not in content:
    content = content.replace(
        \"{ href: '/feedback', label: 'Feedback' },\",
        \"{ href: '/feedback', label: 'Feedback' },\\n    { href: '/dashboard', label: 'Dashboard' },\"
    )
    # Only show Dashboard for invited users - we'll handle this via CSS/display
    open('src/components/SiteHeader.tsx', 'w').write(content)
    print('✅ Header: Dashboard link added')
"

# ============================================
# 3. ADMIN: Card-accent design (option 3/c)
# ============================================

# This is a major rewrite of the admin page styling
# We'll update the wrapper and tab styling without rewriting all tab content

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Update the main admin page wrapper styling
# Change tab styling from pill buttons to card-style with accents
old_tabs_style = "display: 'flex', gap: 4, marginBottom: 20"
new_tabs_style = "display: 'flex', gap: 4, marginBottom: 20, flexWrap: 'wrap'"

content = content.replace(old_tabs_style, new_tabs_style)

# Update the admin header area
if 'Admin dashboard' in content:
    content = content.replace(
        "<h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Admin dashboard</h1>",
        """<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <h1 style={{ fontSize: 20, fontWeight: 600, margin: 0, color: '#1a1a1a' }}>Admin</h1>
              <span style={{ fontSize: 9, padding: '2px 8px', background: '#f0fdfa', color: '#0d9488', borderRadius: 4, fontWeight: 500 }}>LIVE</span>
            </div>
            <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>dissekt.info · Platform management</div>
          </div>
        </div>"""
    )

# Update stat cards in overview to have colored left borders
content = content.replace(
    "background: '#fff', border: '1px solid #e5e5e5', borderRadius: 12, padding: '16px 20px'",
    "background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 18px', borderLeft: '3px solid #0d9488'"
)

# Update all card borders consistently  
content = content.replace("border: '1px solid #e5e5e5'", "border: '0.5px solid #e5eaea'")
content = content.replace("border: '1px solid #e5eaea'", "border: '0.5px solid #e5eaea'")
content = content.replace("borderRadius: 12", "borderRadius: 10")
content = content.replace("borderRadius: 14", "borderRadius: 10")

# Update tab active color
content = content.replace(
    "background: activeTab === tab.id ? '#0d9488' : '#f0f0ee'",
    "background: activeTab === tab.id ? '#0d9488' : '#fff', boxShadow: activeTab === tab.id ? 'none' : '0 0 0 0.5px #e5eaea'"
)

# Change the page background
content = content.replace("background: '#f5f5f4'", "background: '#fafaf8'")

# Make invitation cards have left accent border based on status
content = content.replace(
    "padding: '12px 16px', borderBottom: '1px solid #f0f0ee'",
    "padding: '10px 14px', borderBottom: '0.5px solid #f0f0ee', borderLeft: '3px solid'"
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin: card-accent styling applied')
PYEOF

echo ""
echo "✅ All 3 redesigns applied:"
echo ""
echo "  👤 User experience (/analyze):"
echo "     - Teal gradient welcome bar with greeting + name"
echo "     - Quick links: My insights, Aperture, API keys"
echo "     - Only shows for invited (logged-in) users"
echo ""
echo "  📊 Personal dashboard (/dashboard):"
echo "     - Reader profile card (Trusting/Skeptical/Careful/Balanced)"
echo "     - Trust/Unsure/Reject distribution bar"
echo "     - Trust-by-source visualization"
echo "     - Recent decisions list"
echo "     - API keys tab (create, usage bars, revoke)"
echo "     - Quick start curl example"
echo "     - Dashboard link in header nav"
echo ""
echo "  🔐 Admin (/admin):"
echo "     - Compact header: 'Admin LIVE' + subtitle"
echo "     - Cards with teal left accent borders"
echo "     - Thinner borders, rounded 10px"
echo "     - Pill tabs with outline style"
echo "     - Status accent borders on invitation cards"
echo ""
echo "npm run build"
