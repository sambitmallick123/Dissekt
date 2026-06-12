'use client';

export default function Mirror({ counterfactuals }: { counterfactuals: any[] }) {
  if (!counterfactuals || counterfactuals.length === 0) return null;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>🔄</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Alternative framings</span>
        <span style={{ fontSize: 12, color: '#888' }}>How else could this be framed?</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {counterfactuals.map((cf, i) => (
          <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, overflow: 'hidden' }}>
            {/* Original */}
            <div style={{ padding: '10px 14px', background: '#fef2f2', borderBottom: '1px solid #fecaca' }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#b91c1c', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>As stated</div>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{cf.original}</div>
            </div>

            {/* Alternative */}
            <div style={{ padding: '10px 14px', background: '#f0fdf4', borderBottom: '1px solid #dcfce7' }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#166534', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>With more context</div>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{cf.alternative}</div>
            </div>

            {/* Missing context */}
            {cf.missing_context && (
              <div style={{ padding: '8px 14px', background: '#f8f8f6' }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 2 }}>What the original framing omits</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.5 }}>{cf.missing_context}</div>
              </div>
            )}
          </div>
        ))}
      </div>

      <div style={{ marginTop: 10, fontSize: 10, color: '#aaa', lineHeight: 1.5 }}>
        Alternative framings show how the same information can be presented differently. Neither framing is necessarily "correct" — the comparison reveals what each version emphasizes and omits.
      </div>
    </div>
  );
}
