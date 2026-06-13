'use client';

const TIER_INFO: Record<string, { label: string; color: string; bg: string }> = {
  A: { label: 'Gold standard', color: '#16a34a', bg: '#f0fdf4' },
  B: { label: 'Established', color: '#2563eb', bg: '#eff6ff' },
  C: { label: 'Emerging', color: '#d97706', bg: '#fffbeb' },
  U: { label: 'Unrated', color: '#888', bg: '#f8fafa' },
};

export default function FactCheckSection({ data }: { data: any }) {
  const factChecks = data?.lens?.fact_checks || data?.trace?.fact_checks || [];
  const spread = data?.lens?.spread || data?.trace?.spread || [];

  // Calculate aggregate reliability
  const tiers = factChecks.map((fc: any) => fc.checker_tier || 'U');
  const tierACount = tiers.filter((t: string) => t === 'A').length;
  const tierBCount = tiers.filter((t: string) => t === 'B').length;
  const totalRated = tiers.filter((t: string) => t !== 'U').length;
  
  let reliabilityScore = 0;
  let reliabilityLabel = 'No data';
  let reliabilityColor = '#888';
  
  if (factChecks.length > 0) {
    reliabilityScore = Math.round(((tierACount * 100 + tierBCount * 70) / Math.max(factChecks.length, 1)));
    if (reliabilityScore >= 80) { reliabilityLabel = 'High confidence'; reliabilityColor = '#16a34a'; }
    else if (reliabilityScore >= 50) { reliabilityLabel = 'Moderate confidence'; reliabilityColor = '#d97706'; }
    else if (reliabilityScore > 0) { reliabilityLabel = 'Low confidence'; reliabilityColor = '#dc2626'; }
    else { reliabilityLabel = 'Unrated sources'; reliabilityColor = '#888'; }
  }

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>✅</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>What fact-checkers say</span>
          <span style={{ fontSize: 12, color: '#888' }}>
            {factChecks.length > 0 ? `${factChecks.length} verification${factChecks.length !== 1 ? 's' : ''}` : 'None found'}
          </span>
        </div>
        {factChecks.length > 0 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 10, color: '#888' }}>Source reliability:</span>
            <span style={{ fontSize: 11, fontWeight: 600, color: reliabilityColor, padding: '2px 8px', background: reliabilityScore >= 80 ? '#f0fdf4' : reliabilityScore >= 50 ? '#fffbeb' : '#fef2f2', borderRadius: 4 }}>
              {reliabilityLabel}
            </span>
          </div>
        )}
      </div>

      {factChecks.length === 0 && (
        <div style={{ padding: '14px 16px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 10, fontSize: 13, color: '#555', lineHeight: 1.6 }}>
          No fact-checking organizations have published verification for these claims yet. This does not mean the content is accurate or inaccurate.
        </div>
      )}

      {factChecks.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {factChecks.map((fc: any, i: number) => {
            const rating = (fc.rating || fc.textualRating || '').toLowerCase();
            const ratingColor = rating.includes('false') || rating.includes('misleading') || rating.includes('pants') ? '#dc2626'
              : rating.includes('true') || rating.includes('correct') ? '#16a34a'
              : rating.includes('mixed') || rating.includes('partly') ? '#d97706' : '#555';
            
            const tier = fc.checker_tier || 'U';
            const tierInfo = TIER_INFO[tier] || TIER_INFO.U;

            return (
              <div key={i} style={{ padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 10, borderLeft: `3px solid ${ratingColor}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8, marginBottom: 4 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                      <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>
                        {fc.publisher?.name || fc.claimant || 'Fact-checker'}
                      </span>
                      <span style={{ fontSize: 9, fontWeight: 600, color: tierInfo.color, background: tierInfo.bg, padding: '1px 6px', borderRadius: 3 }}>
                        {tierInfo.label}
                      </span>
                      {fc.checker_ifcn && (
                        <span style={{ fontSize: 9, fontWeight: 600, color: '#0d9488', background: '#f0fdfa', padding: '1px 6px', borderRadius: 3 }}>IFCN ✓</span>
                      )}
                    </div>
                    <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{fc.text || fc.title || fc.claim || ''}</div>
                    {fc.checker_notes && (
                      <div style={{ fontSize: 10, color: '#888', marginTop: 3 }}>{fc.checker_notes}</div>
                    )}
                  </div>
                  <span style={{ fontSize: 10, fontWeight: 600, color: '#fff', background: ratingColor, padding: '2px 8px', borderRadius: 4, flexShrink: 0 }}>
                    {fc.rating || fc.textualRating || 'Reviewed'}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  {fc.checker_region && <span style={{ fontSize: 9, color: '#888' }}>{fc.checker_region}</span>}
                  {fc.url && <a href={fc.url} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none' }}>Read full fact-check ↗</a>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Tier legend */}
      {factChecks.length > 0 && (
        <div style={{ display: 'flex', gap: 10, marginTop: 10, flexWrap: 'wrap' }}>
          {Object.entries(TIER_INFO).map(([key, info]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10 }}>
              <div style={{ width: 8, height: 8, borderRadius: 2, background: info.color }} />
              <span style={{ color: '#888' }}>{info.label}</span>
            </div>
          ))}
          <a href="https://ifcncodeofprinciples.poynter.org/signatories" target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', marginLeft: 4 }}>What is IFCN? ↗</a>
        </div>
      )}

      {spread.length > 0 && (
        <div style={{ marginTop: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Claim spread</div>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            {spread.slice(0, 8).map((s: any, i: number) => (
              <a key={i} href={s.url || '#'} target="_blank" rel="noopener"
                style={{ fontSize: 10, padding: '3px 8px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 4, color: '#555', textDecoration: 'none' }}>
                {s.source || s.domain || `Source ${i + 1}`}
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
