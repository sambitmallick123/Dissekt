'use client';
import { useState, useMemo } from 'react';

interface Technique {
  name: string;
  confidence: number;
  explanation?: string;
  evidence?: string;
}

const TECHNIQUE_COLORS: Record<string, { bg: string; border: string; label: string }> = {
  loaded_language: { bg: '#fef2f2', border: '#fca5a5', label: 'Loaded language' },
  emotional_framing: { bg: '#fef2f2', border: '#fca5a5', label: 'Emotional framing' },
  cherry_picking: { bg: '#fffbeb', border: '#fcd34d', label: 'Cherry picking' },
  missing_context: { bg: '#eff6ff', border: '#93c5fd', label: 'Missing context' },
  appeal_to_authority: { bg: '#f5f3ff', border: '#c4b5fd', label: 'Appeal to authority' },
  appeal_to_fear: { bg: '#fef2f2', border: '#fca5a5', label: 'Appeal to fear' },
  hasty_generalization: { bg: '#fffbeb', border: '#fcd34d', label: 'Hasty generalization' },
  false_equivalence: { bg: '#fffbeb', border: '#fcd34d', label: 'False equivalence' },
  straw_man: { bg: '#fef2f2', border: '#fca5a5', label: 'Straw man' },
  bandwagon: { bg: '#f0fdfa', border: '#5eead4', label: 'Bandwagon' },
  slippery_slope: { bg: '#fffbeb', border: '#fcd34d', label: 'Slippery slope' },
  ad_hominem: { bg: '#fef2f2', border: '#fca5a5', label: 'Ad hominem' },
  whataboutism: { bg: '#fffbeb', border: '#fcd34d', label: 'Whataboutism' },
  false_dilemma: { bg: '#eff6ff', border: '#93c5fd', label: 'False dilemma' },
  appeal_to_emotion: { bg: '#fef2f2', border: '#fca5a5', label: 'Appeal to emotion' },
  circular_reasoning: { bg: '#f5f3ff', border: '#c4b5fd', label: 'Circular reasoning' },
  red_herring: { bg: '#fffbeb', border: '#fcd34d', label: 'Red herring' },
  anecdotal: { bg: '#f0fdfa', border: '#5eead4', label: 'Anecdotal evidence' },
  default: { bg: '#f0f0ee', border: '#d4d4d4', label: 'Technique' },
};

function getColor(name: string) {
  return TECHNIQUE_COLORS[name] || TECHNIQUE_COLORS.default;
}

export default function ReadingMode({ text, techniques, counterfactuals }: {
  text: string;
  techniques: Technique[];
  counterfactuals?: any[];
}) {
  const [hoveredTech, setHoveredTech] = useState<string | null>(null);
  const [showLegend, setShowLegend] = useState(true);

  const annotatedText = useMemo(() => {
    if (!text || !techniques?.length) return [{ text, type: 'plain' as const }];

    const segments: { text: string; type: 'plain' | 'highlight'; technique?: Technique }[] = [];
    const sentences = text.split(/(?<=[.!?])\s+/);
    
    for (const sentence of sentences) {
      const lowerSentence = sentence.toLowerCase();
      let matched = false;

      for (const tech of techniques) {
        const evidence = tech.evidence || '';
        if (evidence && lowerSentence.includes(evidence.toLowerCase().slice(0, 30))) {
          segments.push({ text: sentence + ' ', type: 'highlight', technique: tech });
          matched = true;
          break;
        }
      }

      if (!matched) {
        // Heuristic: match if technique explanation references words in this sentence
        let techMatch: Technique | undefined;
        for (const tech of techniques) {
          const keywords = (tech.explanation || tech.name || '').toLowerCase().split(/\s+/).filter(w => w.length > 5);
          const matchCount = keywords.filter(kw => lowerSentence.includes(kw)).length;
          if (matchCount >= 2) {
            techMatch = tech;
            break;
          }
        }
        if (techMatch) {
          segments.push({ text: sentence + ' ', type: 'highlight', technique: techMatch });
        } else {
          segments.push({ text: sentence + ' ', type: 'plain' });
        }
      }
    }
    return segments;
  }, [text, techniques]);

  const usedTechniques = [...new Set(techniques.map(t => t.name))];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>📖</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Reading mode</span>
          <span style={{ fontSize: 12, color: '#888' }}>Highlighted annotations</span>
        </div>
        <button onClick={() => setShowLegend(!showLegend)}
          style={{ fontSize: 11, color: '#0d9488', background: '#f0fdfa', border: 'none', borderRadius: 5, padding: '3px 10px', cursor: 'pointer', fontWeight: 600 }}>
          {showLegend ? 'Hide' : 'Show'} legend
        </button>
      </div>

      {/* Legend */}
      {showLegend && usedTechniques.length > 0 && (
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14, padding: '8px 10px', background: '#f8fafa', borderRadius: 8 }}>
          {usedTechniques.map(name => {
            const c = getColor(name);
            return (
              <span key={name} onMouseEnter={() => setHoveredTech(name)} onMouseLeave={() => setHoveredTech(null)}
                style={{ fontSize: 10, padding: '2px 8px', borderRadius: 4, background: c.bg, border: `1px solid ${c.border}`, color: '#555', cursor: 'pointer', fontWeight: hoveredTech === name ? 700 : 500 }}>
                {c.label}
              </span>
            );
          })}
        </div>
      )}

      {/* Annotated text */}
      <div style={{ fontSize: 14, lineHeight: 1.9, color: '#333' }}>
        {annotatedText.map((seg, i) => {
          if (seg.type === 'plain') {
            return <span key={i}>{seg.text}</span>;
          }
          const tech = seg.technique!;
          const c = getColor(tech.name);
          const isHovered = hoveredTech === tech.name;
          return (
            <span key={i} style={{ position: 'relative', display: 'inline' }}>
              <span
                onMouseEnter={() => setHoveredTech(tech.name)}
                onMouseLeave={() => setHoveredTech(null)}
                style={{
                  background: isHovered ? c.border : c.bg,
                  borderBottom: `2px solid ${c.border}`,
                  borderRadius: 2,
                  padding: '1px 2px',
                  cursor: 'pointer',
                  transition: 'background 0.2s',
                }}>
                {seg.text}
              </span>
              {isHovered && (
                <span style={{
                  position: 'absolute', bottom: '100%', left: 0, zIndex: 10,
                  background: '#1a1a1a', color: '#fff', padding: '6px 10px', borderRadius: 6,
                  fontSize: 11, lineHeight: 1.4, whiteSpace: 'nowrap', maxWidth: 300,
                  boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                }}>
                  <strong>{c.label}</strong> ({Math.round(tech.confidence * 100)}%)
                  {tech.explanation && <><br />{tech.explanation.slice(0, 100)}</>}
                </span>
              )}
            </span>
          );
        })}
      </div>

      {/* Counterfactual inline */}
      {counterfactuals && counterfactuals.length > 0 && (
        <div style={{ marginTop: 16, padding: '12px 14px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>💡 What this text omits or de-emphasizes:</div>
          {counterfactuals.map((cf, i) => (
            <div key={i} style={{ fontSize: 12, color: '#555', marginBottom: 6, lineHeight: 1.6 }}>
              <span style={{ color: '#0d9488', fontWeight: 600 }}>→</span> {cf.missing_context}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
