#!/bin/bash
# Dissekt — Quick wins: Similar claims, Multi-language, Claim extraction
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. Update models.py — add new fields
# ============================================

python3 << 'PYEOF'
content = open('app/models.py').read()

# Add new fields to FullAnalysis
old = '    cached: bool = False'
new = '''    similar_claims: list[dict] = Field(default_factory=list, description="Similar past analyses from Qdrant")
    detected_language: str = Field(default="en", description="Detected input language")
    extracted_claims: list[dict] = Field(default_factory=list, description="Individual verifiable claims extracted")
    cached: bool = False'''

content = content.replace(old, new)
open('app/models.py', 'w').write(content)
print('✅ models.py updated')
PYEOF

# ============================================
# 2. Update beacon — add similar claims + language + claims
# ============================================

python3 << 'PYEOF'
content = open('app/beacon/__init__.py').read()

# Add language detection import at top
if 'detect_language' not in content:
    content = content.replace(
        'logger = logging.getLogger("dissekt.beacon")',
        '''logger = logging.getLogger("dissekt.beacon")


def detect_language(text: str) -> str:
    """Quick language detection based on character ranges and common words."""
    sample = text[:500].lower()

    # Hindi/Devanagari
    devanagari = sum(1 for c in sample if '\\u0900' <= c <= '\\u097F')
    if devanagari > 20:
        return "hi"

    # German indicators
    german_words = ["der", "die", "das", "und", "ist", "ein", "eine", "nicht", "auf", "mit", "für", "auch", "sich", "nach", "bei"]
    german_count = sum(1 for w in german_words if f" {w} " in f" {sample} ")
    if german_count >= 3:
        return "de"

    return "en"'''
    )

# Add similar claims + language + claim extraction to scan function
# Insert after cache step, before return

old_return = '''    # Step 8: Store in claim graph (non-blocking, don\'t fail the response)
    try:
        from app.claim_graph import store_analysis
        await store_analysis(
            extracted_text,
            content_hash[:16],
            {
                "techniques": [t.name for t in prism_result.techniques],
                "source_bias": signal_result.source_bias,
                "timestamp": str(int(time.time())),
            }
        )
    except Exception as e:
        logger.warning(f"Claim graph store failed: {e}")

    return analysis'''

new_return = '''    # Step 8: Store in claim graph (non-blocking, don't fail the response)
    try:
        from app.claim_graph import store_analysis
        await store_analysis(
            extracted_text,
            content_hash[:16],
            {
                "techniques": [t.name for t in prism_result.techniques],
                "source_bias": signal_result.source_bias,
                "timestamp": str(int(time.time())),
            }
        )
    except Exception as e:
        logger.warning(f"Claim graph store failed: {e}")

    # Step 9: Find similar past claims
    try:
        from app.claim_graph import find_similar
        similar = await find_similar(extracted_text[:300])
        # Exclude self (same analysis id)
        analysis.similar_claims = [s for s in similar if s.get("analysis_id") != content_hash[:16]]
    except Exception as e:
        logger.warning(f"Similar claims lookup failed: {e}")

    # Step 10: Detect language
    analysis.detected_language = detect_language(extracted_text)

    # Step 11: Extract individual claims (only if techniques found, to save API cost)
    if len(prism_result.techniques) > 0:
        try:
            claims = await extract_claims(extracted_text, mode)
            analysis.extracted_claims = claims
        except Exception as e:
            logger.warning(f"Claim extraction failed: {e}")

    return analysis'''

content = content.replace(old_return, new_return)

# Add extract_claims function before the scan function
if 'async def extract_claims' not in content:
    content = content.replace(
        '# ============================================\n# Main scan pipeline',
        '''# ============================================
# Claim extraction
# ============================================

async def extract_claims(text: str, mode: str = "brief") -> list[dict]:
    """Extract individual verifiable claims from text using LLM."""
    settings = get_settings()
    import openai

    client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=500,
            messages=[
                {
                    "role": "system",
                    "content": """Extract verifiable factual claims from this text. Return ONLY a JSON array of objects.
Each object: {"claim": "the specific factual claim", "type": "statistic|quote|event|prediction|causal"}
Only include claims that can be fact-checked. Max 7 claims. No explanations, just the JSON array."""
                },
                {"role": "user", "content": text[:1500]}
            ],
        )
        import json
        raw = response.choices[0].message.content.strip()
        # Clean markdown fences if present
        if raw.startswith("```"):
            raw = raw.split("\\n", 1)[1] if "\\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
        claims = json.loads(raw)
        return claims if isinstance(claims, list) else []
    except Exception as e:
        logger.warning(f"Claim extraction LLM failed: {e}")
        return []


# ============================================
# Main scan pipeline'''
    )

open('app/beacon/__init__.py', 'w').write(content)
print('✅ beacon updated with similar claims + language + claim extraction')
PYEOF

# ============================================
# 3. Frontend — Similar Claims component
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/SimilarClaims.tsx << 'SCEOF'
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
SCEOF

# ============================================
# 4. Frontend — Extracted Claims component
# ============================================

cat > src/components/ExtractedClaims.tsx << 'ECEOF'
'use client';
import { useState } from 'react';

export default function ExtractedClaims({ claims }: { claims: any[] }) {
  const [expanded, setExpanded] = useState(false);
  if (!claims || claims.length === 0) return null;

  const visible = expanded ? claims : claims.slice(0, 4);
  const typeColors: Record<string, { bg: string; color: string }> = {
    statistic: { bg: '#dbeafe', color: '#1e40af' },
    quote: { bg: '#f3e8ff', color: '#6b21a8' },
    event: { bg: '#fef3c7', color: '#92400e' },
    prediction: { bg: '#fce7f3', color: '#9d174d' },
    causal: { bg: '#f0fdf4', color: '#166534' },
  };

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="2"/></svg>
        </div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Verifiable claims extracted</span>
        <span style={{ fontSize: 12, color: '#888' }}>{claims.length} found</span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {visible.map((c, i) => {
          const tc = typeColors[c.type] || { bg: '#f0f0ee', color: '#555' };
          return (
            <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 8, padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 8 }}>
              <span style={{ fontSize: 12, fontWeight: 700, color: '#aaa', flexShrink: 0, marginTop: 2 }}>{i + 1}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: '#1a1a1a', lineHeight: 1.5 }}>{c.claim}</div>
              </div>
              <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 4, background: tc.bg, color: tc.color, flexShrink: 0, whiteSpace: 'nowrap' }}>
                {c.type}
              </span>
            </div>
          );
        })}
      </div>
      {claims.length > 4 && (
        <button onClick={() => setExpanded(!expanded)} style={{ fontSize: 12, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500, marginTop: 8 }}>
          {expanded ? 'Show less' : `+ ${claims.length - 4} more claims`}
        </button>
      )}
    </div>
  );
}
ECEOF

# ============================================
# 5. Update AnalysisResult to show all 3
# ============================================

cat > src/components/AnalysisResult.tsx << 'AREOF'
'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';
import MetaCard from './MetaCard';
import SimilarClaims from './SimilarClaims';
import ExtractedClaims from './ExtractedClaims';

const LANG_NAMES: Record<string, string> = { en: 'English', hi: 'Hindi', de: 'German', es: 'Spanish', fr: 'French' };

export default function AnalysisResult({ data, onShare }: { data: any; onShare?: () => void }) {
  const lang = data.detected_language;
  const langName = LANG_NAMES[lang] || lang;

  return (
    <div>
      {/* Top bar: language + share */}
      <div className="anim-fade" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {lang && lang !== 'en' && (
            <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: '#dbeafe', color: '#1e40af', fontWeight: 500 }}>
              Detected: {langName}
            </span>
          )}
        </div>
        {onShare && (
          <button onClick={onShare} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 12, fontWeight: 500, cursor: 'pointer', color: '#7c3aed' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg>
            Share report
          </button>
        )}
      </div>

      <div className="anim-fade"><ThreatScore data={data} /></div>

      <div className="result-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        <div className="anim-fade anim-d1"><PrismCard prism={data.prism} /></div>
        <div className="anim-fade anim-d2"><TraceCard trace={data.trace} /></div>
        <div className="anim-fade anim-d3"><SignalCard signal={data.signal} /></div>
        <div className="anim-fade anim-d4"><MetaCard data={data} /></div>
      </div>

      {/* Extracted claims */}
      {data.extracted_claims?.length > 0 && (
        <div className="anim-fade anim-d3">
          <ExtractedClaims claims={data.extracted_claims} />
        </div>
      )}

      {/* Similar past claims */}
      {data.similar_claims?.length > 0 && (
        <div className="anim-fade anim-d4">
          <SimilarClaims claims={data.similar_claims} />
        </div>
      )}
    </div>
  );
}
AREOF

echo ""
echo "✅ All 3 quick wins built:"
echo "  1. Similar claims — Qdrant find_similar after each scan, shown below results"
echo "  2. Multi-language — auto-detects Hindi/German, shows language badge"
echo "  3. Claim extraction — GPT-4o mini extracts up to 7 verifiable claims with types"
echo ""
echo "Test: cd dissekt-web && npm run dev"
echo "Then: cd .. && git add -A && git commit -m 'feat: similar claims, language detection, claim extraction' && git push"
