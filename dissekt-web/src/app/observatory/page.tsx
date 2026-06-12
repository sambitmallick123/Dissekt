'use client';
import Arc from '@/components/Arc';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import { useState } from 'react';

export default function TopicsPage() {
  const [query, setQuery] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    if (query.length < 3) return;
    setLoading(true);
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/topics?q=${encodeURIComponent(query)}&limit=20`);
      setData(await res.json());
    } catch {}
    finally { setLoading(false); }
  };

  const techColor = (name: string) => {
    const colors: Record<string, string> = {
      loaded_language: '#dc2626', cherry_picking: '#d97706', missing_context: '#2563eb',
      appeal_to_authority: '#0d9488', emotional_framing: '#ec4899', hasty_generalization: '#f59e0b',
    };
    return colors[name] || '#888';
  };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader />

      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>📈 Topic Tracking</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>See how a topic has been analyzed over time — techniques used, frequency, evolution.</p>

        <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
          <input type="text" value={query} onChange={e => setQuery(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleSearch()}
            placeholder="Search a topic: vaccines, Modi, climate, 5G..."
            style={{ flex: 1, padding: '12px 16px', border: '1px solid #e5e5e5', borderRadius: 10, fontSize: 14, outline: 'none', background: '#fff' }} />
          <button onClick={handleSearch} disabled={loading || query.length < 3}
            style={{ padding: '12px 24px', background: query.length >= 3 ? '#0d9488' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 14, fontWeight: 600, cursor: query.length >= 3 ? 'pointer' : 'not-allowed' }}>
            {loading ? 'Searching...' : 'Track'}
          </button>
        </div>

        {data && (
          <>
            {/* Summary */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>{data.trends?.total_analyses || 0}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Analyses found</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#2563eb' }}>{Object.keys(data.trends?.technique_frequency || {}).length}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Unique techniques</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#d97706' }}>{data.trends?.time_span_days || 0}d</div>
                <div style={{ fontSize: 11, color: '#888' }}>Time span</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#16a34a' }}>{((data.trends?.avg_similarity || 0) * 100).toFixed(0)}%</div>
                <div style={{ fontSize: 11, color: '#888' }}>Avg similarity</div>
              </div>
            </div>

            {/* Technique frequency */}
            {Object.keys(data.trends?.technique_frequency || {}).length > 0 && (
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Technique frequency</div>
                {Object.entries(data.trends.technique_frequency).map(([name, count]: [string, any]) => (
                  <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                    <span style={{ fontSize: 12, fontWeight: 500, width: 140, flexShrink: 0 }}>{name.replace(/_/g, ' ')}</span>
                    <div style={{ flex: 1, height: 6, background: '#f0f0ee', borderRadius: 3 }}>
                      <div style={{ height: '100%', width: `${Math.min((count / data.trends.total_analyses) * 100, 100)}%`, background: techColor(name), borderRadius: 3 }} />
                    </div>
                    <span style={{ fontSize: 11, fontWeight: 600, color: '#555', width: 24, textAlign: 'right' }}>{count}</span>
                  </div>
                ))}
              </div>
            )}

            {/* Narrative Arc */}
            {data.analyses?.length >= 2 && (
              <Arc analyses={data.analyses} topic={data.topic} />
            )}

            {/* Timeline */}
            {data.analyses?.length > 0 && (
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Analysis timeline</div>
                {data.analyses.map((a: any, i: number) => (
                  <div key={i} style={{ display: 'flex', gap: 10, padding: '8px 0', borderBottom: i < data.analyses.length - 1 ? '1px solid #f0f0ee' : 'none' }}>
                    <div style={{ width: 36, height: 36, borderRadius: 8, background: '#f0fdfa', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <span style={{ fontSize: 11, fontWeight: 700, color: '#0d9488' }}>{Math.round(a.similarity * 100)}%</span>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{a.text_preview}</div>
                      <div style={{ display: 'flex', gap: 4, marginTop: 3, flexWrap: 'wrap' }}>
                        {(a.techniques || []).map((t: string, j: number) => (
                          <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.replace(/_/g, ' ')}</span>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {data.count === 0 && (
              <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>
                No analyses found for "{query}". The knowledge base grows with every scan.
              </div>
            )}
          </>
        )}
      </div>
    <SiteFooter />
    </main>
  );
}
