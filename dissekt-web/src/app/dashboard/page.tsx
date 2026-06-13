'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function DashboardPage() {
  const [email, setEmail] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [newKeyName, setNewKeyName] = useState('');
  const [newKey, setNewKey] = useState('');
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    const stored = typeof window !== 'undefined' ? localStorage.getItem('dissekt_email') : '';
    if (stored) { setEmail(stored); loadUsage(stored); }
  }, []);

  const loadUsage = async (e: string) => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/keys/usage?email=${encodeURIComponent(e)}`);
      setData(await res.json());
    } catch {}
    finally { setLoading(false); }
  };

  const createKey = async () => {
    if (!email) return;
    setCreating(true);
    try {
      const res = await fetch(`${API_URL}/api/keys/create`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, name: newKeyName || 'Default' }),
      });
      const d = await res.json();
      setNewKey(d.key || '');
      setNewKeyName('');
      loadUsage(email);
    } catch {}
    finally { setCreating(false); }
  };

  const revokeKey = async (id: string) => {
    await fetch(`${API_URL}/api/keys/revoke`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id }),
    });
    loadUsage(email);
  };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>🔑 API Dashboard</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Manage your API keys and monitor usage.</p>

        {!email && (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Enter your email to view API keys</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input type="email" placeholder="your@email.com" value={email} onChange={e => setEmail(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && loadUsage(email)}
                style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none' }} />
              <button onClick={() => loadUsage(email)} disabled={!email}
                style={{ padding: '10px 20px', background: email ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                Load
              </button>
            </div>
          </div>
        )}

        {data && (
          <>
            {/* Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 10, marginBottom: 20 }}>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>{data.total_keys}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Total keys</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#16a34a' }}>{data.active_keys}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Active</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#2563eb' }}>{data.total_requests_today}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Requests today</div>
              </div>
            </div>

            {/* Keys list */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Your API keys</div>
              {data.keys?.length === 0 && (
                <div style={{ padding: 20, textAlign: 'center', color: '#888', fontSize: 13 }}>No API keys yet. Create one below.</div>
              )}
              {data.keys?.map((k: any) => (
                <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '0.5px solid #f0f0ee' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                      <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'monospace', color: '#1a1a1a' }}>{k.prefix}...</span>
                      <span style={{ fontSize: 11, color: '#888' }}>{k.name}</span>
                      {!k.active && <span style={{ fontSize: 9, padding: '1px 6px', background: '#fef2f2', color: '#dc2626', borderRadius: 3, fontWeight: 600 }}>Revoked</span>}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{ flex: 1, maxWidth: 200, height: 6, background: '#f0f0ee', borderRadius: 3 }}>
                        <div style={{ height: '100%', width: `${Math.min(k.usage_pct, 100)}%`, background: k.usage_pct > 80 ? '#dc2626' : k.usage_pct > 50 ? '#d97706' : '#0d9488', borderRadius: 3 }} />
                      </div>
                      <span style={{ fontSize: 10, color: '#888' }}>{k.requests_today}/{k.rate_limit} today</span>
                    </div>
                  </div>
                  {k.active && (
                    <button onClick={() => revokeKey(k.id)}
                      style={{ padding: '4px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 5, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>
                      Revoke
                    </button>
                  )}
                </div>
              ))}
            </div>

            {/* Create new key */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Create new key</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <input type="text" placeholder="Key name (e.g., My App)" value={newKeyName} onChange={e => setNewKeyName(e.target.value)}
                  style={{ flex: 1, padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none' }} />
                <button onClick={createKey} disabled={creating}
                  style={{ padding: '8px 18px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
                  {creating ? '...' : 'Generate'}
                </button>
              </div>
              {newKey && (
                <div style={{ marginTop: 10, padding: '10px 14px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 8 }}>
                  <div style={{ fontSize: 11, fontWeight: 600, color: '#166534', marginBottom: 4 }}>Save this key — it cannot be shown again:</div>
                  <div style={{ fontSize: 13, fontFamily: 'monospace', color: '#1a1a1a', wordBreak: 'break-all', userSelect: 'all' }}>{newKey}</div>
                </div>
              )}
            </div>

            {/* Usage example */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Quick start</div>
              <div style={{ background: '#1a1a1a', borderRadius: 8, padding: '14px 16px', fontSize: 12, fontFamily: 'monospace', color: '#5eead4', lineHeight: 1.8, overflowX: 'auto' }}>
                <span style={{ color: '#888' }}>{'# Analyze content'}</span><br />
                curl -X POST https://dissekt-api.up.railway.app/api/scan \<br />
                {'  '}-H "Content-Type: application/json" \<br />
                {'  '}-H "X-API-Key: dsk_your_key_here" \<br />
                {'  '}-d {"'{'}"}{"\"content\": \"https://example.com/article\", \"mode\": \"brief\""}{"'}'"}
              </div>
            </div>
          </>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
