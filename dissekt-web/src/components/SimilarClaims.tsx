'use client';

export default function SimilarClaims({ claims }: { claims: any[] }) {
  if (!claims || claims.length === 0) return null;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#f3e8ff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        </div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Similar claims analyzed before</span>
        <span style={{ fontSize: 12, color: '#888' }}>{claims.length} found</span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {claims.map((c, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 10, padding: '8px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8 }}>
            <div style={{ width: 36, height: 36, borderRadius: 8, background: '#ede9fe', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <span style={{ fontSize: 12, fontWeight: 700, color: '#7c3aed' }}>{Math.round(c.similarity * 100)}%</span>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{c.text_preview}</div>
              {c.techniques && c.techniques.length > 0 && (
                <div style={{ display: 'flex', gap: 4, marginTop: 4, flexWrap: 'wrap' }}>
                  {c.techniques.slice(0, 3).map((t: string, j: number) => (
                    <span key={j} style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#f0f0ee', color: '#555' }}>
                      {t.replace(/_/g, ' ')}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
