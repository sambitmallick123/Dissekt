'use client';
import { useState } from 'react';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };

const ratingStyle = (r: string) => {
  const s = (r||'').toLowerCase();
  if (s.includes('false') || s.includes('pinocchio') || s.includes('wrong')) return { bg: '#fef2f2', color: '#b91c1c', border: '#fecaca' };
  if (s.includes('true')) return { bg: '#f0fdf4', color: '#166534', border: '#bbf7d0' };
  if (s.includes('context') || s.includes('mixed') || s.includes('misleading')) return { bg: '#fffbeb', color: '#92400e', border: '#fde68a' };
  return { bg: '#f5f5f4', color: '#555', border: '#e5e5e5' };
};

const dotColor = (p: string) => {
  const s = (p||'').toLowerCase();
  if (s.includes('reddit')) return '#ef4444'; if (s.includes('facebook')) return '#3b82f6';
  if (s.includes('youtube')) return '#dc2626'; if (s.includes('twitter')) return '#1a1a1a';
  if (s.includes('whatsapp')) return '#22c55e'; if (s.includes('instagram')) return '#e879f9';
  return '#aaa';
};

export default function LensCard({ trace }: { trace: any }) {
  const [showAllFC, setShowAllFC] = useState(false);
  const [showAllTL, setShowAllTL] = useState(false);
  const hasFC = trace.fact_checks?.length > 0;
  const hasTL = trace.spread_timeline?.length > 0;
  const visibleFC = showAllFC ? trace.fact_checks : trace.fact_checks?.slice(0, 4);
  const visibleTL = showAllTL ? trace.spread_timeline : trace.spread_timeline?.slice(0, 4);

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040', flex: 1 }}>Lens — cross-references</span>
        <span style={{ fontSize: 12, color: '#aaa' }}>
          {hasFC && `${trace.fact_checks.length} checks`}{hasFC && hasTL && ' · '}{hasTL && `${trace.spread_timeline.length} sources`}
        </span>
      </div>

      <div style={{ padding: 18, flex: 1 }}>
        {hasFC && (
          <div style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 10 }}>Existing cross-references</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {visibleFC.map((fc: any, i: number) => {
                const rs = ratingStyle(fc.rating);
                return (
                  <a key={i} href={fc.url} target="_blank" rel="noopener"
                    style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 10, textDecoration: 'none', color: 'inherit', gap: 10 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{fc.publisher}</div>
                      <div style={{ fontSize: 11, color: '#aaa', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{fc.title}</div>
                    </div>
                    <span title={fc.rating} style={{ flexShrink: 0, maxWidth: 120, fontSize: 10, fontWeight: 600, padding: '4px 10px', borderRadius: 6, background: rs.bg, color: rs.color, border: `1px solid ${rs.border}`, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {fc.rating}
                    </span>
                  </a>
                );
              })}
            </div>
            {trace.fact_checks.length > 4 && (
              <button onClick={() => setShowAllFC(!showAllFC)}
                style={{ display: 'block', margin: '8px auto 0', fontSize: 12, fontWeight: 500, color: '#2563eb', background: 'none', border: 'none', cursor: 'pointer', padding: '4px 8px' }}>
                {showAllFC ? `− Show fewer` : `+ ${trace.fact_checks.length - 4} more cross-references`}
              </button>
            )}
          </div>
        )}

        {hasTL && (
          <div>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 10 }}>Spread timeline</div>
            <div style={{ position: 'relative', paddingLeft: 18 }}>
              <div style={{ position: 'absolute', left: 5, top: 6, bottom: 6, width: 1, background: '#e5e5e5' }}/>
              {visibleTL.map((s: any, i: number) => (
                <a key={i} href={s.url} target="_blank" rel="noopener"
                  style={{ display: 'flex', alignItems: 'start', gap: 10, padding: '6px 0', textDecoration: 'none', color: 'inherit', position: 'relative' }}>
                  <div style={{ width: 10, height: 10, borderRadius: 5, background: dotColor(s.platform), border: '2px solid #fff', position: 'absolute', left: -17, top: 9, zIndex: 1 }}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{s.title || '(untitled)'}</div>
                    <div style={{ fontSize: 10, color: '#aaa' }}>{s.platform}{s.date ? ` · ${s.date}` : ''}</div>
                  </div>
                </a>
              ))}
            </div>
            {trace.spread_timeline.length > 4 && (
              <button onClick={() => setShowAllTL(!showAllTL)}
                style={{ fontSize: 12, fontWeight: 500, color: '#2563eb', background: 'none', border: 'none', cursor: 'pointer', marginTop: 8, padding: 0 }}>
                {showAllTL ? '− Show fewer' : `+ ${trace.spread_timeline.length - 4} more sources`}
              </button>
            )}
          </div>
        )}

        {!hasFC && !hasTL && <div style={{ textAlign: 'center', padding: 30, fontSize: 13, color: '#aaa' }}>No cross-references found</div>}
      </div>
    </div>
  );
}
