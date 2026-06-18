'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import Reflect from '@/components/Reflect';
import LedgerView from '@/components/Ledger';
import Recall from '@/components/Recall';
import ScanHistory from '@/components/ScanHistory';
import TrustGraph from '@/components/TrustGraph';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

function sc(v: number) { return v >= 0.65 ? '#16a34a' : v >= 0.35 ? '#d97706' : '#dc2626'; }

export default function DashboardPage() {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [tab, setTab] = useState<'insights' | 'activity' | 'apikeys'>('insights');
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

  if (tier !== 'member') {
    return (
      <main style={{ flex: 1, background: '#fafaf8' }}>
        <SiteHeader />
        <div style={{ maxWidth: 440, margin: '80px auto', padding: '0 16px', textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Dashboard requires access</div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Sign in with your invite code to view your personal insights, trust graph, and API keys.</div>
          <a href="/signup" style={{ display: 'inline-block', padding: '10px 24px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Sign in</a>
        </div>
        <SiteFooter />
      </main>
    );
  }

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
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader active="Dashboard" />
      <div style={{ maxWidth: 900, margin: '0 auto', padding: '24px 16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a' }}>Your reading lens</div>
            <div style={{ fontSize: 12, color: '#888' }}>Based on {total} decisions · {tier === 'member' ? '🎫 Invited' : '🆓 Free'}</div>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <button onClick={() => setTab('insights')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'insights' ? '#0d9488' : '#fff', color: tab === 'insights' ? '#fff' : '#555', boxShadow: tab !== 'insights' ? '0 0 0 0.5px #e5eaea' : 'none' }}>📊 Insights</button>
            <button onClick={() => setTab('activity')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'activity' ? '#0d9488' : '#fff', color: tab === 'activity' ? '#fff' : '#555', boxShadow: tab !== 'activity' ? '0 0 0 0.5px #e5eaea' : 'none' }}>📒 My activity</button>
            <button onClick={() => setTab('apikeys')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'apikeys' ? '#0d9488' : '#fff', color: tab === 'apikeys' ? '#fff' : '#555', boxShadow: tab !== 'apikeys' ? '0 0 0 0.5px #e5eaea' : 'none' }}>🔑 API keys</button>
          </div>
        </div>

        {tab === 'insights' && (
          <>
            {/* Community */}
            <div style={{ background: 'linear-gradient(135deg, #0d9488, #0f766e)', borderRadius: 10, padding: 16, marginBottom: 12, color: '#fff' }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>💬 Join the community</div>
              <div style={{ fontSize: 11, opacity: 0.85, marginBottom: 10 }}>Report bugs, share ideas, and follow what we&apos;re building — exclusive to invited members.</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <a href="https://discord.gg/Bkv4zpmdJD" target="_blank" rel="noopener" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: '#fff', textDecoration: 'none', fontWeight: 600 }}>Discord →</a>
                <a href="https://github.com/sambitmallick123/Dissekt" target="_blank" rel="noopener" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: '#fff', textDecoration: 'none', fontWeight: 600 }}>GitHub →</a>
              </div>
            </div>

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

        {tab === 'activity' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Reflect />
            <TrustGraph />
            <LedgerView />
            <Recall onAnalyze={(text: string) => { window.location.href = '/analyze?content=' + encodeURIComponent(text); }} />
            <ScanHistory onReanalyze={(input: string) => { window.location.href = '/analyze?content=' + encodeURIComponent(input); }} />
          </div>
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
