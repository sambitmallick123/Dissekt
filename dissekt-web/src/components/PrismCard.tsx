'use client';
import { useState } from 'react';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const iconBox = (bg: string): React.CSSProperties => ({ width: 30, height: 30, borderRadius: 8, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 });

const catColors: Record<string, { bg: string; text: string }> = {
  framing: { bg: '#f3e8ff', text: '#7c3aed' },
  logical_fallacy: { bg: '#dbeafe', text: '#2563eb' },
  credibility: { bg: '#fef3c7', text: '#b45309' },
  deflection: { bg: '#ffe4e6', text: '#be123c' },
};
const confColor = (c: number) => c >= 0.85 ? '#dc2626' : c >= 0.7 ? '#d97706' : '#eab308';

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);
  const cat = (c: string) => catColors[c] || catColors.framing;

  return (
    <div style={card}>
      <div style={header}>
        <div style={iconBox('#f3e8ff')}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2" strokeLinecap="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040', flex: 1 }}>Prism — techniques</span>
        <span style={{ fontSize: 12, color: '#aaa', fontWeight: 500 }}>{prism.techniques?.length || 0} found</span>
      </div>

      <div style={{ padding: 18, flex: 1 }}>
        {prism.techniques.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '30px 0' }}>
            <div style={{ width: 40, height: 40, borderRadius: 20, background: '#f0fdf4', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>
            </div>
            <span style={{ fontSize: 13, color: '#888' }}>No manipulation detected</span>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {prism.techniques.map((t: any, i: number) => {
              const cc = cat(t.category);
              return (
                <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 14 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 13, fontWeight: 600, textTransform: 'capitalize' }}>{t.name.replace(/_/g, ' ')}</span>
                      <span style={{ fontSize: 10, fontWeight: 600, padding: '2px 10px', borderRadius: 20, background: cc.bg, color: cc.text, textTransform: 'capitalize' }}>
                        {t.category?.replace(/_/g, ' ')}
                      </span>
                    </div>
                    <span style={{ fontSize: 16, fontWeight: 700, color: confColor(t.confidence) }}>{(t.confidence * 100).toFixed(0)}%</span>
                  </div>
                  <div style={{ height: 5, background: '#f0f0ee', borderRadius: 3, overflow: 'hidden', marginBottom: 10 }}>
                    <div style={{ height: '100%', borderRadius: 3, width: `${t.confidence * 100}%`, background: confColor(t.confidence), transition: 'width 0.7s ease' }}/>
                  </div>
                  <p style={{ fontSize: 12, color: '#555', lineHeight: 1.6, margin: 0 }}>{t.explanation}</p>
                  {t.evidence && (
                    <div style={{ marginTop: 8, paddingLeft: 12, borderLeft: '3px solid #fed7aa' }}>
                      <p style={{ fontSize: 12, color: '#888', fontStyle: 'italic', margin: 0 }}>"{t.evidence}"</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {prism.brief && (
          <div style={{ marginTop: 14, padding: 14, background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 10 }}>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#7c3aed', marginBottom: 6 }}>Summary</div>
            <p style={{ fontSize: 12, color: '#404040', lineHeight: 1.7, margin: 0 }}>{prism.brief}</p>
          </div>
        )}

        {prism.detailed && (
          <div style={{ marginTop: 10 }}>
            <button onClick={() => setExpanded(!expanded)}
              style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 500, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
              <span style={{ transform: expanded ? 'rotate(90deg)' : 'none', transition: 'transform 0.2s' }}>▸</span>
              {expanded ? 'Hide detailed analysis' : 'Show detailed analysis'}
            </button>
            {expanded && (
              <div style={{ marginTop: 8, padding: 14, background: '#f8f8f6', border: '1px solid #e5e5e5', borderRadius: 10 }}>
                <p style={{ fontSize: 12, color: '#555', lineHeight: 1.7, margin: 0, whiteSpace: 'pre-wrap' }}>{prism.detailed}</p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
