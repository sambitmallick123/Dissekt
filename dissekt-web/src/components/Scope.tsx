'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type Market = 'global' | 'india' | 'us' | 'germany' | 'uk' | 'intl' | 'substack';

export default function Scope({ onAnalyze }: { onAnalyze?: (text: string) => void }) {
  const [items, setItems] = useState<any[]>([]);
  const [market, setMarket] = useState<Market>('global');
  const [loading, setLoading] = useState(false);

  const loadFeed = async (m: Market, refresh = false) => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/scope?market=${m}${refresh ? '&refresh=true' : ''}`);
      const data = await res.json();
      setItems(data.items || []);
    } catch { setItems([]); }
    finally { setLoading(false); }
  };

  useEffect(() => { loadFeed(market); }, [market]);

  const riskColor = (level: string) => level === 'high' ? '#dc2626' : level === 'medium' ? '#d97706' : level === 'low' ? '#2563eb' : '#16a34a';
  const riskBadge = (level: string) => level === 'high' ? '🔴' : level === 'medium' ? '🟡' : level === 'low' ? '🔵' : '🟢';

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10, flexWrap: 'wrap', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>🔭</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Scope</span>
          <span style={{ fontSize: 12, color: '#888' }}>Latest news to analyze</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {/* Color legend */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 10, color: '#888' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><span style={{ width: 7, height: 7, borderRadius: 4, background: '#16a34a' }} />Clear</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><span style={{ width: 7, height: 7, borderRadius: 4, background: '#2563eb' }} />Low</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><span style={{ width: 7, height: 7, borderRadius: 4, background: '#d97706' }} />Medium</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><span style={{ width: 7, height: 7, borderRadius: 4, background: '#dc2626' }} />High</span>
          </div>
          <button onClick={() => loadFeed(market, true)} style={{ fontSize: 10, padding: '3px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>Refresh</button>
        </div>
      </div>

      <div style={{ fontSize: 10, color: '#aaa', marginBottom: 10 }}>Color reflects surface manipulation signals in the headline — not a verdict. Analyze for the full picture.</div>

      <div style={{ display: 'flex', gap: 4, marginBottom: 12, flexWrap: 'wrap' }}>
        {(['global', 'india', 'us', 'germany', 'uk'] as Market[]).map(m => (
          <button key={m} onClick={() => setMarket(m)}
            style={{ padding: '4px 12px', borderRadius: 5, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: market === m ? '#0d9488' : '#f0f0ee', color: market === m ? '#fff' : '#555', textTransform: 'capitalize' }}>
            {m === 'global' ? '🌐 Global' : m === 'us' ? 'US' : m === 'uk' ? 'UK' : m === 'intl' ? 'Intl' : m.charAt(0).toUpperCase() + m.slice(1)}
          </button>
        ))}
      </div>

      {loading && <div style={{ textAlign: 'center', padding: 16, color: '#888', fontSize: 12 }}>Loading feeds...</div>}

      {!loading && items.length === 0 && <div style={{ textAlign: 'center', padding: 16, color: '#888', fontSize: 12 }}>No items. Scope feeds update every 6 hours.</div>}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {items.slice(0, 8).map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 8, padding: '8px 10px', borderRadius: 8, border: '0.5px solid #f0f0ee', borderLeft: `3px solid ${riskColor(item.risk || 'none')}` }}>
            <span style={{ fontSize: 11, marginTop: 2 }}>{riskBadge(item.risk || 'none')}</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <a href={item.url || item.link || '#'} target="_blank" rel="noopener" style={{ textDecoration: 'none' }}><div style={{ fontSize: 12, color: '#1a4d8f', lineHeight: 1.5, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{item.title}</div></a>
              <div style={{ display: 'flex', gap: 8, marginTop: 3, fontSize: 10, color: '#aaa', alignItems: 'center' }}>
                {item.risk_label && item.risk_label !== 'Clear' && item.risk !== 'none' && (
                  <span style={{ fontSize: 9, fontWeight: 600, color: riskColor(item.risk || 'none'), padding: '1px 5px', borderRadius: 3, background: item.risk === 'high' ? '#fef2f2' : item.risk === 'medium' ? '#fffbeb' : '#eff6ff' }}>{item.risk_label}</span>
                )}
                <span>{item.source}</span>
                {item.published && <span>· {new Date(item.published).toLocaleDateString()}</span>}
              </div>
            </div>
            {onAnalyze && (
              <button onClick={() => onAnalyze(item.url || item.link || item.title)}
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
