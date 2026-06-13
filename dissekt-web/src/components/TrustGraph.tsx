'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function TrustGraph() {
  const [decisions, setDecisions] = useState<any[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    fetch(`${API_URL}/api/decisions`)
      .then(r => r.json())
      .then(d => { setDecisions(d.decisions || []); setLoaded(true); })
      .catch(() => setLoaded(true));
  }, []);

  if (!loaded || decisions.length < 5) return null;

  // Build trust graph data
  const sourceMap: Record<string, { trust: number; unsure: number; reject: number; total: number }> = {};
  
  for (const d of decisions) {
    const preview = d.input_preview || '';
    // Extract domain or first meaningful words as source key
    const match = preview.match(/https?:\/\/([^\/\s]+)/);
    const source = match ? match[1].replace('www.', '') : preview.split(/\s+/).slice(0, 2).join(' ').slice(0, 20);
    if (!source) continue;
    
    if (!sourceMap[source]) sourceMap[source] = { trust: 0, unsure: 0, reject: 0, total: 0 };
    sourceMap[source][d.decision as 'trust' | 'unsure' | 'reject']++;
    sourceMap[source].total++;
  }

  const sources = Object.entries(sourceMap)
    .filter(([_, v]) => v.total >= 2)
    .sort((a, b) => b[1].total - a[1].total)
    .slice(0, 12);

  if (sources.length < 2) return null;

  const maxTotal = Math.max(...sources.map(s => s[1].total));

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>🕸️</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Trust graph</span>
        <span style={{ fontSize: 12, color: '#888' }}>How you've evaluated different sources</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {sources.map(([source, data]) => {
          const trustPct = Math.round((data.trust / data.total) * 100);
          const unsurePct = Math.round((data.unsure / data.total) * 100);
          const rejectPct = Math.round((data.reject / data.total) * 100);
          const barWidth = (data.total / maxTotal) * 100;

          return (
            <div key={source} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 11, width: 100, color: '#555', flexShrink: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{source}</span>
              <div style={{ flex: 1, display: 'flex', height: 16, borderRadius: 4, overflow: 'hidden', background: '#f0f0ee', maxWidth: `${barWidth}%` }}>
                {trustPct > 0 && <div style={{ width: `${trustPct}%`, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.trust}</span></div>}
                {unsurePct > 0 && <div style={{ width: `${unsurePct}%`, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.unsure}</span></div>}
                {rejectPct > 0 && <div style={{ width: `${rejectPct}%`, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.reject}</span></div>}
              </div>
              <span style={{ fontSize: 10, color: '#888', width: 20, textAlign: 'right' }}>{data.total}</span>
            </div>
          );
        })}
      </div>

      <div style={{ display: 'flex', gap: 12, marginTop: 10, fontSize: 10, color: '#888' }}>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#16a34a', marginRight: 3 }} />Trust</span>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#d97706', marginRight: 3 }} />Unsure</span>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#dc2626', marginRight: 3 }} />Reject</span>
      </div>
    </div>
  );
}
