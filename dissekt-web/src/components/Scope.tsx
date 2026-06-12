'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type Market = 'all' | 'india' | 'us' | 'germany' | 'uk';

export default function Scope({ onAnalyze }: { onAnalyze?: (text: string) => void }) {
  const [items, setItems] = useState<any[]>([]);
  const [market, setMarket] = useState<Market>('all');
  const [loading, setLoading] = useState(false);

  const loadFeed = async (m: Market) => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/radar?market=${m}`);
      const data = await res.json();
      setItems(data.items || []);
    } catch { setItems([]); }
    finally { setLoading(false); }
  };

  useEffect(() => { loadFeed(market); }, [market]);

  const riskColor = (score: number) => score >= 7 ? '#dc2626' : score >= 4 ? '#d97706' : '#16a34a';
  const riskBadge = (score: number) => score >= 7 ? '🔴' : score >= 4 ? '🟡' : '🟢';

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>📡</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Scope</span>
          <span style={{ fontSize: 12, color: '#888' }}>Latest news to analyze</span>
        </div>
        <button onClick={() => loadFeed(market)} style={{ fontSize: 10, padding: '3px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>Refresh</button>
      </div>

      <div style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
        {(['all', 'india', 'us', 'germany', 'uk'] as Market[]).map(m => (
          <button key={m} onClick={() => setMarket(m)}
            style={{ padding: '4px 12px', borderRadius: 5, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: market === m ? '#0d9488' : '#f0f0ee', color: market === m ? '#fff' : '#555', textTransform: 'capitalize' }}>
            {m === 'all' ? 'All' : m === 'us' ? 'US' : m === 'uk' ? 'UK' : m.charAt(0).toUpperCase() + m.slice(1)}
          </button>
        ))}
      </div>

      {loading && <div style={{ textAlign: 'center', padding: 16, color: '#888', fontSize: 12 }}>Loading feeds...</div>}

      {!loading && items.length === 0 && <div style={{ textAlign: 'center', padding: 16, color: '#888', fontSize: 12 }}>No items. Scope feeds update every 6 hours.</div>}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {items.slice(0, 8).map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 8, padding: '8px 10px', borderRadius: 8, border: '0.5px solid #f0f0ee' }}>
            <span style={{ fontSize: 12, marginTop: 2 }}>{riskBadge(item.risk_score || 0)}</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{item.title}</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 3, fontSize: 10, color: '#aaa' }}>
                <span>{item.source}</span>
                {item.published && <span>{new Date(item.published).toLocaleDateString()}</span>}
              </div>
            </div>
            {onAnalyze && (
              <button onClick={() => onAnalyze(item.link || item.title)}
                style={{ fontSize: 10, padding: '3px 8px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600, flexShrink: 0 }}>
                Analyze
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
