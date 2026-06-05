'use client';
import { useState, useEffect } from 'react';

const MARKETS = ['all', 'india', 'germany', 'us', 'uk'];
const FLAGS: Record<string, string> = { india: '🇮🇳', germany: '🇩🇪', us: '🇺🇸', uk: '🇬🇧', all: '🌐' };

export default function RadarPage() {
  const [market, setMarket] = useState('all');
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    fetch(`${apiUrl}/api/radar?market=${market}&limit=20`)
      .then(r => r.json())
      .then(d => { setItems(d.items || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, [market]);

  const analyzeItem = (url: string) => {
    localStorage.setItem("dissekt_analyze", url); window.location.href = "/";
  };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }} onClick={() => window.location.href = '/'}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
            <span style={{ fontSize: 13, color: '#888', marginLeft: 4 }}>Radar</span>
          </div>
          <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>← Back to Scan</a>
        </div>
      </nav>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '24px 24px' }}>
        <div style={{ marginBottom: 20 }}>
          <h1 style={{ fontSize: 22, fontWeight: 600, marginBottom: 4 }}>📡 Radar — News Intelligence</h1>
          <p style={{ fontSize: 14, color: '#888' }}>Real-time feeds from fact-checkers and news sources. Click "Analyze" to scan any article.</p>
        </div>

        <div style={{ display: 'flex', gap: 6, marginBottom: 20, flexWrap: 'wrap' }}>
          {MARKETS.map(m => (
            <button key={m} onClick={() => setMarket(m)}
              style={{ padding: '8px 16px', borderRadius: 8, fontSize: 13, fontWeight: 500, border: 'none', cursor: 'pointer', background: market === m ? '#7c3aed' : '#fff', color: market === m ? '#fff' : '#404040', boxShadow: market === m ? 'none' : '0 0 0 1px #e5e5e5' }}>
              {FLAGS[m]} {m.charAt(0).toUpperCase() + m.slice(1)}
            </button>
          ))}
        </div>

        {loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 12, padding: 16, height: 80 }}>
                <div style={{ height: 12, width: '60%', background: 'linear-gradient(90deg, #f0f0ee 25%, #e8e6e3 50%, #f0f0ee 75%)', backgroundSize: '200% 100%', animation: 'shimmer 1.5s infinite', borderRadius: 4, marginBottom: 8 }} />
                <div style={{ height: 10, width: '40%', background: 'linear-gradient(90deg, #f0f0ee 25%, #e8e6e3 50%, #f0f0ee 75%)', backgroundSize: '200% 100%', animation: 'shimmer 1.5s infinite', borderRadius: 4 }} />
              </div>
            ))}
          </div>
        ) : items.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>No items found for this market.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {items.map((item, i) => (
              <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 12, padding: '14px 18px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', gap: 12 }}>
                  <a href={item.url} target="_blank" rel="noopener" style={{ flex: 1, minWidth: 0, textDecoration: 'none', color: 'inherit' }}>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 4, lineHeight: 1.4 }}>{item.title}</div>
                    {item.summary && <div style={{ fontSize: 12, color: '#888', lineHeight: 1.5, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{item.summary}</div>}
                  </a>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6, flexShrink: 0 }}>
                    <div>
                      <div style={{ fontSize: 11, fontWeight: 600, color: '#7c3aed' }}>{item.source}</div>
                      <div style={{ fontSize: 10, color: '#aaa' }}>{FLAGS[item.market] || '🌐'} {item.published?.split('T')[0] || ''}</div>
                    </div>
                    <button onClick={(e) => { e.stopPropagation(); analyzeItem(item.url); }}
                      style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '5px 12px', background: '#f3e8ff', color: '#7c3aed', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' }}>
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                      Analyze
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
