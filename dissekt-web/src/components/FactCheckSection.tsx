'use client';

export default function FactCheckSection({ data }: { data: any }) {
  const factChecks = data?.lens?.fact_checks || data?.trace?.fact_checks || [];
  const spread = data?.lens?.spread || data?.trace?.spread || [];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>✅</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>What fact-checkers say</span>
        <span style={{ fontSize: 12, color: '#888' }}>
          {factChecks.length > 0 ? `${factChecks.length} verification${factChecks.length !== 1 ? 's' : ''} found` : 'No existing fact-checks found'}
        </span>
      </div>
      {factChecks.length === 0 && (
        <div style={{ padding: '14px 16px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 10, fontSize: 13, color: '#166534', lineHeight: 1.6 }}>
          No fact-checking organizations have published verification for these claims yet. This does not mean the content is accurate or inaccurate.
        </div>
      )}
      {factChecks.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {factChecks.map((fc: any, i: number) => {
            const rating = (fc.rating || fc.textualRating || '').toLowerCase();
            const color = rating.includes('false') || rating.includes('misleading') ? '#dc2626' : rating.includes('true') || rating.includes('correct') ? '#16a34a' : rating.includes('mixed') ? '#d97706' : '#555';
            return (
              <div key={i} style={{ padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 10, borderLeft: `3px solid ${color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a', marginBottom: 2 }}>{fc.claimant || fc.publisher?.name || 'Fact-checker'}</div>
                    <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{fc.text || fc.title || fc.claim || ''}</div>
                  </div>
                  <span style={{ fontSize: 10, fontWeight: 600, color: '#fff', background: color, padding: '2px 8px', borderRadius: 4, flexShrink: 0 }}>{fc.rating || fc.textualRating || 'Reviewed'}</span>
                </div>
                {fc.url && <a href={fc.url} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', marginTop: 4, display: 'inline-block' }}>Read full fact-check ↗</a>}
              </div>
            );
          })}
        </div>
      )}
      {spread.length > 0 && (
        <div style={{ marginTop: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Claim spread</div>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            {spread.slice(0, 8).map((s: any, i: number) => (
              <a key={i} href={s.url || '#'} target="_blank" rel="noopener" style={{ fontSize: 10, padding: '3px 8px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 4, color: '#555', textDecoration: 'none' }}>{s.source || s.domain || `Source ${i + 1}`}</a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
