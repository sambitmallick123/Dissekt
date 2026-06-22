'use client';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '10px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 4 };

export default function MetaCard({ data }: { data: any }) {
  const items = [
    { l: 'Time', v: `${(data.analysis_time_ms / 1000).toFixed(1)}s` },
    { l: 'Model', v: data.prism?.model_used || '—' },
    { l: 'Cache', v: data.cached ? 'Hit' : 'Fresh', c: data.cached ? '#16a34a' : undefined },
    { l: 'Heuristic', v: data.prism?.heuristic_only ? 'Yes (€0)' : 'No', c: data.prism?.heuristic_only ? '#16a34a' : undefined },
  ];

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#f0f0ee', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#888" strokeWidth="2" strokeLinecap="round"><path d="M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z"/><path d="M13 2v7h7"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Analysis metadata</span>
      </div>
      <div style={{ padding: 18, flex: 1 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {items.map(m => (
            <div key={m.l} style={metricBox}>
              <div style={metricLabel}>{m.l}</div>
              <div style={{ fontSize: 13, fontWeight: 500, color: m.c || '#404040' }}>{m.v}</div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid #e5e5e5' }}>
          <div style={metricLabel}>Content hash (SHA-256)</div>
          <div style={{ fontSize: 11, fontFamily: 'monospace', color: '#888', wordBreak: 'break-all', lineHeight: 1.5 }}>
            {data.blockchain?.content_hash || '—'}
          </div>
        </div>
      </div>
    </div>
  );
}
