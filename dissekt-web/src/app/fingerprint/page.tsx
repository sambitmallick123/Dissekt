'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function FingerprintPage() {
  const [sources, setSources] = useState('');
  const [results, setResults] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(false);

  const analyze = async () => {
    if (!sources.trim()) return;
    setLoading(true);
    try {
      const list = sources.split(',').map(s => s.trim()).filter(Boolean);
      const data: Record<string, any> = {};
      for (const src of list.slice(0, 5)) {
        const res = await fetch(`${API_URL}/api/fingerprint?source=${encodeURIComponent(src)}`);
        data[src] = await res.json();
      }
      setResults(data);
    } catch {}
    finally { setLoading(false); }
  };

  const barColors = ['#0d9488', '#2563eb', '#d97706', '#dc2626', '#7c3aed', '#ea580c'];

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>🔬 Source Fingerprinting</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Compare how different outlets use manipulation techniques. Based on all past Dissekt analyses.</p>

        <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
          <input value={sources} onChange={e => setSources(e.target.value)} onKeyDown={e => e.key === 'Enter' && analyze()}
            placeholder="Enter sources comma-separated: bbc, fox, ndtv, reuters"
            style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff' }} />
          <button onClick={analyze} disabled={loading || !sources.trim()}
            style={{ padding: '10px 24px', background: sources.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: sources.trim() ? 'pointer' : 'not-allowed' }}>
            {loading ? 'Analyzing...' : 'Fingerprint'}
          </button>
        </div>

        {Object.keys(results).length > 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {Object.entries(results).map(([src, data]: [string, any], idx) => (
              <div key={src} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12, padding: 18 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <div>
                    <span style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>{src}</span>
                    <span style={{ fontSize: 12, color: '#888', marginLeft: 8 }}>{data.total_analyses} analyses</span>
                  </div>
                  <span style={{ fontSize: 12, color: '#0d9488', fontWeight: 500 }}>{data.unique_techniques || 0} unique techniques</span>
                </div>

                {data.fingerprint_summary && (
                  <div style={{ padding: '8px 12px', background: '#f0fdfa', borderRadius: 8, fontSize: 12, color: '#0f766e', marginBottom: 12 }}>
                    {data.fingerprint_summary}
                  </div>
                )}

                {data.techniques && Object.entries(data.techniques).slice(0, 8).map(([tech, info]: [string, any], i) => (
                  <div key={tech} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                    <span style={{ fontSize: 11, width: 130, color: '#555', flexShrink: 0 }}>{tech.replace(/_/g, ' ')}</span>
                    <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                      <div style={{ height: '100%', width: `${info.rate * 100}%`, background: barColors[idx % barColors.length], borderRadius: 4, minWidth: 4 }} />
                    </div>
                    <span style={{ fontSize: 10, color: '#888', width: 50, textAlign: 'right' }}>{info.count}x ({Math.round(info.rate * 100)}%)</span>
                  </div>
                ))}
              </div>
            ))}
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
