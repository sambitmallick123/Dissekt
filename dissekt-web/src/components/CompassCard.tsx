'use client';

const PARTY_COLORS: Record<string, { bg: string; color: string }> = {
  BJP: { bg: '#fff7ed', color: '#c2410c' },
  INC: { bg: '#eff6ff', color: '#1d4ed8' },
  AAP: { bg: '#ecfdf5', color: '#047857' },
  TMC: { bg: '#f0fdf4', color: '#15803d' },
};

export default function CompassCard({ compass }: { compass: any }) {
  if (!compass?.politicians?.length) return null;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>🏛</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Compass — Political Context</span>
        <span style={{ fontSize: 12, color: '#888' }}>{compass.politicians.length} politician{compass.politicians.length > 1 ? 's' : ''} detected</span>
      </div>

      {compass.politicians.map((pol: any, i: number) => {
        const pc = PARTY_COLORS[pol.party] || { bg: '#f5f5f4', color: '#555' };
        return (
          <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 14, marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: pc.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>🏛</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{pol.name}</div>
                <div style={{ fontSize: 11, color: '#888' }}>
                  <span style={{ padding: '1px 6px', borderRadius: 4, background: pc.bg, color: pc.color, fontWeight: 600, fontSize: 10, marginRight: 4 }}>{pol.party}</span>
                  {pol.position}
                </div>
              </div>
            </div>

            <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6, marginBottom: 6 }}>
              <span style={{ fontWeight: 600 }}>Constituency:</span> {pol.constituency} · <span style={{ fontWeight: 600 }}>Terms:</span> {pol.terms}
            </div>

            {pol.key_votes?.length > 0 && (
              <div style={{ marginBottom: 6 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>Key votes</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {pol.key_votes.map((v: string, j: number) => (
                    <span key={j} style={{ fontSize: 10, padding: '2px 8px', borderRadius: 4, background: '#f0f0ee', color: '#404040' }}>{v}</span>
                  ))}
                </div>
              </div>
            )}

            {pol.key_promises?.length > 0 && (
              <div>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>Key promises</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {pol.key_promises.slice(0, 4).map((p: string, j: number) => (
                    <span key={j} style={{ fontSize: 10, padding: '2px 8px', borderRadius: 4, background: '#fef3c7', color: '#92400e' }}>{p}</span>
                  ))}
                </div>
              </div>
            )}
          </div>
        );
      })}

      {compass.context?.length > 0 && (
        <div style={{ marginTop: 8 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#404040', marginBottom: 6 }}>📎 Factual Context</div>
          {compass.context.map((c: any, i: number) => (
            <div key={i} style={{ display: 'flex', gap: 8, padding: '6px 10px', border: '1px solid #e5e5e5', borderRadius: 6, marginBottom: 4, fontSize: 11 }}>
              <span style={{ fontWeight: 600, color: '#7c3aed', flexShrink: 0 }}>{c.politician}</span>
              <span style={{ color: '#555' }}>{c.detail}</span>
              <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 3, background: c.type === 'controversy_referenced' ? '#fef2f2' : '#f0f0ee', color: c.type === 'controversy_referenced' ? '#b91c1c' : '#888', flexShrink: 0 }}>
                {c.type.replace('_', ' ')}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
