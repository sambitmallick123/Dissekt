'use client';
import { useState } from 'react';

export default function ClaimsCard({ claims, sourceUrl, fromOpening }: { claims: any[]; sourceUrl?: string; fromOpening?: boolean }) {
  const [expanded, setExpanded] = useState(false);
  if (!claims || claims.length === 0) return null;

  const visible = expanded ? claims : claims.slice(0, 4);
  const typeColors: Record<string, { bg: string; color: string }> = {
    statistic: { bg: '#dbeafe', color: '#1e40af' },
    quote: { bg: '#f0fdfa', color: '#115e59' },
    event: { bg: '#fef3c7', color: '#92400e' },
    prediction: { bg: '#fce7f3', color: '#9d174d' },
    causal: { bg: '#f0fdf4', color: '#166534' },
  };


  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="2"/></svg>
        </div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Verifiable claims extracted</span>
        <span style={{ fontSize: 12, color: '#888' }}>{claims.length} found{fromOpening ? ' · from the opening of the article' : ''}</span>
        {sourceUrl && sourceUrl.startsWith('http') && (
          <a href={sourceUrl} target="_blank" rel="noopener" style={{ marginLeft: 'auto', fontSize: 11, color: '#0d9488', textDecoration: 'none', fontWeight: 500, display: 'flex', alignItems: 'center', gap: 4 }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><path d="M15 3h6v6M10 14L21 3"/></svg>
            View source article
          </a>
        )}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {visible.map((c, i) => {
          const tc = typeColors[c.type] || { bg: '#f0f0ee', color: '#555' };
          return (
            <div key={i} style={{ padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 8 }}>
              <div style={{ display: 'flex', alignItems: 'start', gap: 8 }}>
                <span style={{ fontSize: 12, fontWeight: 700, color: '#aaa', flexShrink: 0, marginTop: 2 }}>{i + 1}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: '#1a1a1a', lineHeight: 1.5 }}>{c.claim}</div>
                </div>
                <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 4, background: tc.bg, color: tc.color, flexShrink: 0, whiteSpace: 'nowrap' }}>
                  {c.type}
                </span>
              </div>
            </div>
          );
        })}
      </div>
      {claims.length > 4 && (
        <button onClick={() => setExpanded(!expanded)} style={{ fontSize: 12, color: '#0d9488', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500, marginTop: 8 }}>
          {expanded ? 'Show less' : `+ ${claims.length - 4} more claims`}
        </button>
      )}
    </div>
  );
}
