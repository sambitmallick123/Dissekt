'use client';

interface Technique {
  name: string;
  confidence: number;
  explanation?: string;
}

export default function Polish({ data }: { data: any }) {
  const techs: Technique[] = data?.prism?.techniques || [];
  const score = data?.clarity_score ?? 100;
  
  if (techs.length === 0) return (
    <div style={{ background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 14, padding: 20, marginTop: 16, textAlign: 'center' }}>
      <div style={{ fontSize: 24, marginBottom: 8 }}>✅</div>
      <div style={{ fontSize: 16, fontWeight: 600, color: '#166534' }}>Clean draft</div>
      <div style={{ fontSize: 13, color: '#888', marginTop: 4 }}>No manipulation techniques detected. Your writing reads as transparent and evidence-based.</div>
    </div>
  );

  const scoreColor = score >= 70 ? '#16a34a' : score >= 40 ? '#d97706' : '#dc2626';

  const suggestions: Record<string, string> = {
    loaded_language: 'Replace emotionally charged words with neutral equivalents. "Devastating blow" → "Significant setback".',
    emotional_framing: 'Lead with facts before emotional context. Let readers form their own emotional response.',
    cherry_picking: 'Include counter-evidence or acknowledge limitations of the data you\'re citing.',
    missing_context: 'Add historical context, opposing viewpoints, or relevant caveats that provide a fuller picture.',
    appeal_to_authority: 'Cite the evidence itself, not just who said it. "Studies show X" is stronger than "Expert Y says X".',
    appeal_to_fear: 'Present risks proportionally. Include likelihood alongside consequence.',
    hasty_generalization: 'Qualify your claims. "Some" instead of "all", "suggests" instead of "proves".',
    false_equivalence: 'Acknowledge the difference in scale or significance between the things being compared.',
    straw_man: 'Represent the opposing view accurately before addressing it.',
    ad_hominem: 'Address the argument, not the person making it.',
    whataboutism: 'Address the current topic directly before drawing comparisons.',
    anecdotal: 'Support individual stories with broader data or trends.',
  };

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>✍️</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Polish</span>
        <span style={{ fontSize: 12, color: '#888' }}>How your draft reads to others</span>
      </div>

      {/* Score */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '12px 16px', background: '#f8fafa', borderRadius: 10, marginBottom: 14 }}>
        <div style={{ width: 48, height: 48, borderRadius: 24, border: `3px solid ${scoreColor}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 18, fontWeight: 700, color: scoreColor }}>{score}</span>
        </div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, color: scoreColor }}>
            {score >= 70 ? 'Strong transparency' : score >= 40 ? 'Some issues to address' : 'Needs revision'}
          </div>
          <div style={{ fontSize: 11, color: '#888' }}>
            {techs.length} technique{techs.length !== 1 ? 's' : ''} detected that may undermine credibility
          </div>
        </div>
      </div>

      {/* Suggestions */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {techs.map((tech, i) => {
          const suggestion = suggestions[tech.name] || 'Consider whether this technique is intentional. If not, rephrase for clarity.';
          return (
            <div key={i} style={{ border: '0.5px solid #e5eaea', borderRadius: 10, overflow: 'hidden' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', background: '#f8fafa' }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{tech.name.replace(/_/g, ' ')}</span>
                <span style={{ fontSize: 11, fontWeight: 600, color: tech.confidence >= 0.8 ? '#dc2626' : '#d97706' }}>{Math.round(tech.confidence * 100)}%</span>
              </div>
              {tech.explanation && (
                <div style={{ padding: '6px 12px', fontSize: 11, color: '#888', borderBottom: '0.5px solid #f0f0ee' }}>
                  {tech.explanation}
                </div>
              )}
              <div style={{ padding: '8px 12px', background: '#f0fdfa' }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#0d9488', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 3 }}>Suggestion</div>
                <div style={{ fontSize: 12, color: '#0f766e', lineHeight: 1.5 }}>{suggestion}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
