'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function LifecyclePage() {
  const [claim, setClaim] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const track = async () => {
    if (claim.length < 10) return;
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/claim-lifecycle?claim=${encodeURIComponent(claim)}`);
      setData(await res.json());
    } catch {}
    finally { setLoading(false); }
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>🔄 Claim Lifecycle</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Track how a claim spread, evolved, and was addressed over time.</p>

        <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
          <input value={claim} onChange={e => setClaim(e.target.value)} onKeyDown={e => e.key === 'Enter' && track()}
            placeholder="Enter a claim to track: vaccines cause autism, Modi promised 2 crore jobs..."
            style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff' }} />
          <button onClick={track} disabled={loading || claim.length < 10}
            style={{ padding: '10px 24px', background: claim.length >= 10 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: claim.length >= 10 ? 'pointer' : 'not-allowed' }}>
            {loading ? 'Tracking...' : 'Track'}
          </button>
        </div>

        {data && (
          <div>
            {/* Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 10, marginBottom: 16 }}>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>{data.total_appearances}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Appearances</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#2563eb' }}>{data.spread_days || 0}d</div>
                <div style={{ fontSize: 11, color: '#888' }}>Spread duration</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#555' }}>{data.first_seen || '—'}</div>
                <div style={{ fontSize: 11, color: '#888' }}>First seen</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#555' }}>{data.last_seen || '—'}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Last seen</div>
              </div>
            </div>

            {/* Technique evolution */}
            {data.technique_evolution && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
                <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>Early coverage techniques</div>
                  {Object.entries(data.technique_evolution.early || {}).map(([t, c]: [string, any]) => (
                    <div key={t} style={{ fontSize: 11, color: '#555', marginBottom: 2 }}>{t.replace(/_/g, ' ')} — {c}x</div>
                  ))}
                  {Object.keys(data.technique_evolution.early || {}).length === 0 && <div style={{ fontSize: 11, color: '#aaa' }}>No data</div>}
                </div>
                <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>Later coverage techniques</div>
                  {Object.entries(data.technique_evolution.late || {}).map(([t, c]: [string, any]) => (
                    <div key={t} style={{ fontSize: 11, color: '#555', marginBottom: 2 }}>{t.replace(/_/g, ' ')} — {c}x</div>
                  ))}
                  {Object.keys(data.technique_evolution.late || {}).length === 0 && <div style={{ fontSize: 11, color: '#aaa' }}>No data</div>}
                </div>
              </div>
            )}

            {/* Timeline */}
            {data.timeline?.length > 0 && (
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12, padding: 16 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Timeline</div>
                {data.timeline.map((item: any, i: number) => (
                  <div key={i} style={{ display: 'flex', gap: 10, padding: '8px 0', borderBottom: i < data.timeline.length - 1 ? '0.5px solid #f0f0ee' : 'none' }}>
                    <div style={{ width: 8, height: 8, borderRadius: 4, background: '#0d9488', marginTop: 5, flexShrink: 0 }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{item.text_preview}</div>
                      <div style={{ display: 'flex', gap: 6, marginTop: 3, flexWrap: 'wrap' }}>
                        {item.techniques?.map((t: string, j: number) => (
                          <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.replace(/_/g, ' ')}</span>
                        ))}
                        {item.date && <span style={{ fontSize: 9, color: '#aaa' }}>{item.date}</span>}
                        <span style={{ fontSize: 9, color: '#0d9488' }}>{Math.round(item.similarity * 100)}% match</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {data.total_appearances === 0 && (
              <div style={{ textAlign: 'center', padding: 40, color: '#888', fontSize: 13 }}>No past analyses match this claim. The knowledge base grows with every scan.</div>
            )}
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
