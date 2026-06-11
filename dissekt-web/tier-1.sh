#!/bin/bash
# Dissekt — Tier 1: Features that change perception
# 1. Reading Mode (inline annotations)
# 2. Pre-publish Check (writer mode)
# 3. Source Comparison Matrix
# 4. Narrative Arc Tracking
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Reading Mode — inline text annotations
# ============================================

cat > src/components/ReadingMode.tsx << 'READEOF'
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
READEOF

echo "✅ ReadingMode component"

# ============================================
# 2. Pre-publish Check mode
# ============================================

cat > src/components/PrePublishCheck.tsx << 'PREPUBEOF'
'use client';

interface Technique {
  name: string;
  confidence: number;
  explanation?: string;
}

export default function PrePublishCheck({ data }: { data: any }) {
  const techs: Technique[] = data?.prism?.techniques || [];
  const score = data?.transparency_score ?? 100;
  
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
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Pre-publish check</span>
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
PREPUBEOF

echo "✅ PrePublishCheck component"

# ============================================
# 3. Source Comparison Matrix
# ============================================

cat > src/components/SourceMatrix.tsx << 'MATRIXEOF'
'use client';
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function SourceMatrix() {
  const [claim, setClaim] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [analyzed, setAnalyzed] = useState(false);

  const analyze = async () => {
    if (!claim || claim.length < 10) return;
    setLoading(true); setAnalyzed(false);
    try {
      // Analyze the claim from multiple angles using the existing scan API
      const sources = [
        claim,
        `According to conservative media, ${claim}`,
        `According to liberal media, ${claim}`,
        `International perspective on: ${claim}`,
        `Fact-checkers say about: ${claim}`,
      ];

      const analyses = await Promise.all(
        sources.map(async (src, i) => {
          try {
            const res = await fetch(`${API_URL}/api/scan`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ content: src, mode: 'brief' }),
            });
            return await res.json();
          } catch { return null; }
        })
      );

      setResults(analyses.filter(Boolean));
      setAnalyzed(true);
    } catch {}
    finally { setLoading(false); }
  };

  const labels = ['Original claim', 'Conservative framing', 'Liberal framing', 'International view', 'Fact-checker view'];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>📊</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Source comparison matrix</span>
        <span style={{ fontSize: 12, color: '#888' }}>How would different outlets frame this?</span>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <input type="text" value={claim} onChange={e => setClaim(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && analyze()}
          placeholder="Enter a claim to compare across perspectives..."
          style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 13, outline: 'none', background: '#f8fafa' }} />
        <button onClick={analyze} disabled={loading || claim.length < 10}
          style={{ padding: '10px 20px', background: claim.length >= 10 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: claim.length >= 10 ? 'pointer' : 'not-allowed' }}>
          {loading ? 'Analyzing...' : 'Compare'}
        </button>
      </div>

      {loading && (
        <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13 }}>
          Analyzing across 5 perspectives... (this takes ~30 seconds)
        </div>
      )}

      {analyzed && results.length > 0 && (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 11 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #e5eaea' }}>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Perspective</th>
                <th style={{ padding: '8px 10px', textAlign: 'center', color: '#888', fontWeight: 600 }}>Score</th>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Top techniques</th>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Brief</th>
              </tr>
            </thead>
            <tbody>
              {results.map((r, i) => {
                const techs = r?.prism?.techniques || [];
                const techScore = techs.length > 0
                  ? 100 - Math.min(Math.round(Math.max(...techs.map((t: any) => t.confidence || 0)) * 40) + Math.min(techs.length * 10, 30), 100)
                  : 100;
                const scoreColor = techScore >= 70 ? '#16a34a' : techScore >= 40 ? '#d97706' : '#dc2626';
                return (
                  <tr key={i} style={{ borderBottom: '0.5px solid #f0f0ee' }}>
                    <td style={{ padding: '8px 10px', fontWeight: 600, color: '#404040' }}>{labels[i] || `Source ${i + 1}`}</td>
                    <td style={{ padding: '8px 10px', textAlign: 'center' }}>
                      <span style={{ fontWeight: 700, color: scoreColor }}>{techScore}</span>
                    </td>
                    <td style={{ padding: '8px 10px' }}>
                      <div style={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                        {techs.slice(0, 3).map((t: any, j: number) => (
                          <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.name?.replace(/_/g, ' ')}</span>
                        ))}
                        {techs.length === 0 && <span style={{ color: '#aaa' }}>None</span>}
                      </div>
                    </td>
                    <td style={{ padding: '8px 10px', color: '#888', maxWidth: 200 }}>
                      {(r?.prism?.brief || '').slice(0, 80)}{(r?.prism?.brief || '').length > 80 ? '...' : ''}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
MATRIXEOF

echo "✅ SourceMatrix component"

# ============================================
# 4. Narrative Arc component (for topics page)
# ============================================

cat > src/components/NarrativeArc.tsx << 'ARCEOF'
'use client';

export default function NarrativeArc({ analyses, topic }: { analyses: any[]; topic: string }) {
  if (!analyses || analyses.length < 2) return null;

  // Group by week
  const weeks: Record<string, { count: number; techniques: Record<string, number>; avgSimilarity: number }> = {};
  
  for (const a of analyses) {
    const ts = a.timestamp ? new Date(parseFloat(a.timestamp) * 1000) : new Date();
    const weekKey = `${ts.getFullYear()}-W${Math.ceil((ts.getDate()) / 7)}`;
    
    if (!weeks[weekKey]) weeks[weekKey] = { count: 0, techniques: {}, avgSimilarity: 0 };
    weeks[weekKey].count++;
    weeks[weekKey].avgSimilarity += a.similarity || 0;
    
    for (const t of (a.techniques || [])) {
      weeks[weekKey].techniques[t] = (weeks[weekKey].techniques[t] || 0) + 1;
    }
  }

  const weekKeys = Object.keys(weeks).sort();
  const maxCount = Math.max(...weekKeys.map(k => weeks[k].count));

  // Find dominant technique across all analyses
  const allTechs: Record<string, number> = {};
  for (const a of analyses) {
    for (const t of (a.techniques || [])) {
      allTechs[t] = (allTechs[t] || 0) + 1;
    }
  }
  const topTechs = Object.entries(allTechs).sort((a, b) => b[1] - a[1]).slice(0, 5);

  const barColors = ['#0d9488', '#2563eb', '#d97706', '#dc2626', '#7c3aed'];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>📈</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Narrative arc</span>
        <span style={{ fontSize: 12, color: '#888' }}>How "{topic}" coverage evolved</span>
      </div>

      {/* Volume timeline */}
      <div style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Analysis volume over time</div>
        <div style={{ display: 'flex', alignItems: 'end', gap: 4, height: 60 }}>
          {weekKeys.map((k, i) => {
            const h = (weeks[k].count / maxCount) * 100;
            return (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                <span style={{ fontSize: 9, color: '#888' }}>{weeks[k].count}</span>
                <div style={{ width: '100%', height: `${h}%`, background: '#0d9488', borderRadius: '3px 3px 0 0', minHeight: 4 }} />
                <span style={{ fontSize: 8, color: '#aaa' }}>{k.split('-W')[1] ? `W${k.split('-W')[1]}` : k}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Technique distribution */}
      {topTechs.length > 0 && (
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Most used techniques</div>
          {topTechs.map(([name, count], i) => (
            <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <span style={{ fontSize: 11, width: 120, color: '#555' }}>{name.replace(/_/g, ' ')}</span>
              <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                <div style={{ height: '100%', width: `${(count / analyses.length) * 100}%`, background: barColors[i % barColors.length], borderRadius: 4 }} />
              </div>
              <span style={{ fontSize: 10, fontWeight: 600, color: '#555', width: 24 }}>{count}</span>
            </div>
          ))}
        </div>
      )}

      {/* Summary */}
      <div style={{ marginTop: 14, padding: '10px 12px', background: '#f8fafa', borderRadius: 8, fontSize: 12, color: '#555', lineHeight: 1.6 }}>
        <strong>{analyses.length}</strong> analyses found for "{topic}" across <strong>{weekKeys.length}</strong> time period{weekKeys.length !== 1 ? 's' : ''}.
        {topTechs[0] && <> Most common technique: <strong>{topTechs[0][0].replace(/_/g, ' ')}</strong> ({topTechs[0][1]} occurrences).</>}
      </div>
    </div>
  );
}
ARCEOF

echo "✅ NarrativeArc component"

# ============================================
# 5. Wire Reading Mode + PrePublish into AnalysisResult
# ============================================

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

if 'ReadingMode' not in content:
    # Add imports
    content = content.replace(
        "import CounterfactualCard from './CounterfactualCard';",
        "import CounterfactualCard from './CounterfactualCard';\nimport ReadingMode from './ReadingMode';\nimport PrePublishCheck from './PrePublishCheck';"
    )

    # Add view toggle state — find the component function
    if 'useState' in content and 'export default function' in content:
        # Add state for view mode
        content = content.replace(
            "export default function AnalysisResult(",
            "export default function AnalysisResult("
        )
        
        # Add Reading Mode + PrePublish after the main result but before counterfactual
        insert_point = "      {data.counterfactuals?.length > 0 && ("
        if insert_point in content:
            reading_mode_block = """      {/* View mode toggle */}
      <div style={{ display: 'flex', gap: 6, marginTop: 12, marginBottom: 4 }}>
        <button onClick={() => {
          const el = document.getElementById('reading-mode');
          if (el) el.style.display = el.style.display === 'none' ? 'block' : 'none';
        }} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>
          📖 Reading mode
        </button>
        <button onClick={() => {
          const el = document.getElementById('prepub-check');
          if (el) el.style.display = el.style.display === 'none' ? 'block' : 'none';
        }} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>
          ✍️ Pre-publish check
        </button>
      </div>

      <div id="reading-mode" style={{ display: 'none' }}>
        <ReadingMode
          text={data.extracted_text || data.input_content || ''}
          techniques={data.prism?.techniques || []}
          counterfactuals={data.counterfactuals}
        />
      </div>

      <div id="prepub-check" style={{ display: 'none' }}>
        <PrePublishCheck data={data} />
      </div>

"""
            content = content.replace(insert_point, reading_mode_block + '      ' + insert_point)

    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ AnalysisResult: Reading Mode + PrePublish wired')
else:
    print('  Already has ReadingMode')
PYEOF

# ============================================
# 6. Wire NarrativeArc into Topics page
# ============================================

python3 << 'PYEOF'
content = open('src/app/topics/page.tsx').read()

if 'NarrativeArc' not in content:
    content = content.replace(
        "'use client';",
        "'use client';\nimport NarrativeArc from '@/components/NarrativeArc';"
    )

    # Add NarrativeArc after technique frequency section
    if 'Analysis timeline' in content:
        content = content.replace(
            "            {/* Timeline */}",
            """            {/* Narrative Arc */}
            {data.analyses?.length >= 2 && (
              <NarrativeArc analyses={data.analyses} topic={data.topic} />
            )}

            {/* Timeline */}"""
        )

    open('src/app/topics/page.tsx', 'w').write(content)
    print('✅ Topics page: NarrativeArc wired')
else:
    print('  Already has NarrativeArc')
PYEOF

# ============================================
# 7. Add Source Matrix to Compare page
# ============================================

python3 << 'PYEOF'
content = open('src/app/compare/page.tsx').read()

if 'SourceMatrix' not in content:
    content = content.replace(
        "'use client';",
        "'use client';\nimport SourceMatrix from '@/components/SourceMatrix';"
    )

    # Add after SiteHeader
    if '<SiteHeader' in content:
        content = content.replace(
            '<SiteFooter />',
            '''        <div style={{ maxWidth: 900, margin: '0 auto', padding: '0 24px 32px' }}>
          <SourceMatrix />
        </div>
        <SiteFooter />'''
        )

    open('src/app/compare/page.tsx', 'w').write(content)
    print('✅ Compare page: SourceMatrix added')
else:
    print('  Already has SourceMatrix')
PYEOF

echo ""
echo "✅ Tier 1 complete:"
echo ""
echo "  📖 Reading Mode"
echo "     - Inline annotations on original text"
echo "     - Color-coded by technique type"
echo "     - Hover tooltips with explanation + confidence"
echo "     - Legend showing which techniques appear"
echo "     - Toggle button on analysis results"
echo ""
echo "  ✍️ Pre-publish Check"
echo "     - Writer-friendly mode for checking your own drafts"
echo "     - Score framed as 'transparency' not 'threat'"
echo "     - Per-technique rewrite suggestions"
echo "     - Clean draft congratulations when no issues"
echo "     - Toggle button on analysis results"
echo ""
echo "  📊 Source Comparison Matrix"
echo "     - Enter a claim → analyze across 5 perspectives"
echo "     - Table: score, techniques, brief per perspective"
echo "     - Added to /compare page"
echo ""
echo "  📈 Narrative Arc"
echo "     - Volume timeline (bar chart by week)"
echo "     - Top technique distribution (bar chart)"
echo "     - Summary stats"
echo "     - Added to /topics page after search"
echo ""
echo "npm run build && npm run dev"
