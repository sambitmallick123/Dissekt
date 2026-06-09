#!/bin/bash
# Dissekt — Positioning Pivot + Counterfactual View
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. BACKEND: Counterfactual View (alternative framing)
# ============================================

python3 << 'PYEOF'
content = open('app/beacon/__init__.py').read()

if 'generate_counterfactual' not in content:
    # Add counterfactual generation after claim extraction
    old = '    # Step 11: Extract individual claims'
    new = '''    # Step 11a: Generate counterfactual views (alternative framing)
    if len(prism_result.techniques) > 0:
        try:
            counterfactuals = await generate_counterfactuals(extracted_text, mode)
            analysis.counterfactuals = counterfactuals
        except Exception as e:
            logger.warning(f"Counterfactual generation failed: {e}")

    # Step 11: Extract individual claims'''
    
    content = content.replace(old, new)

    # Add the function
    if 'async def generate_counterfactuals' not in content:
        content = content.replace(
            '# ============================================\n# Main scan pipeline',
            '''# ============================================
# Counterfactual generation
# ============================================

async def generate_counterfactuals(text: str, mode: str = "brief") -> list[dict]:
    """Generate alternative framings for claims in the text."""
    settings = get_settings()
    import openai

    client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=600,
            messages=[
                {
                    "role": "system",
                    "content": """You are an information transparency tool. For the given text, identify the 2-3 strongest claims and provide alternative framings that add missing context or present a different perspective.

Return ONLY a JSON array. Each object:
{
  "original": "the claim as stated in the text",
  "alternative": "a more complete or differently-framed version with added context",
  "missing_context": "what the original framing omits or de-emphasizes"
}

Rules:
- Do NOT say the original is "wrong" or "false"
- Show HOW the framing shapes perception, not WHAT to believe
- The alternative should be equally factual, just more complete
- Keep each field under 100 words
- Return only the JSON array, no markdown"""
                },
                {"role": "user", "content": text[:2000]}
            ],
        )
        import json
        raw = response.choices[0].message.content.strip()
        if raw.startswith("```"):
            raw = raw.split("\\n", 1)[1] if "\\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
        result = json.loads(raw)
        return result if isinstance(result, list) else []
    except Exception as e:
        logger.warning(f"Counterfactual LLM failed: {e}")
        return []


# ============================================
# Main scan pipeline'''
        )

    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ Beacon: counterfactual generation added')
else:
    print('Already has counterfactuals')

# Add counterfactuals field to models
content2 = open('app/models.py').read()
if 'counterfactuals' not in content2:
    content2 = content2.replace(
        '    extracted_claims: list[dict]',
        '    counterfactuals: list[dict] = Field(default_factory=list, description="Alternative framings for key claims")\n    extracted_claims: list[dict]'
    )
    open('app/models.py', 'w').write(content2)
    print('✅ models.py: counterfactuals field added')
PYEOF

echo "✅ Backend: Counterfactual view"

# ============================================
# 2. FRONTEND: Counterfactual Card
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/CounterfactualCard.tsx << 'CFEOF'
'use client';

export default function CounterfactualCard({ counterfactuals }: { counterfactuals: any[] }) {
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
CFEOF

echo "✅ CounterfactualCard component created"

# ============================================
# 3. RENAME: Threat Score → Transparency Score
# ============================================

cat > src/components/ThreatScore.tsx << 'TSEOF'
'use client';
import { useState } from 'react';

export default function ThreatScore({ data }: { data: any }) {
  const [showFormula, setShowFormula] = useState(false);

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  const techScore = techs.length > 0 ? Math.round(maxConf * 40) : 0;
  const fcScore = Math.min(fcs.length * 4, 30);
  const toxScore = Math.round(tox * 20);
  const bonusScore = fcs.length >= 3 ? 10 : 0;
  const rawScore = Math.min(techScore + fcScore + toxScore + bonusScore, 100);

  // Invert: high raw = low transparency
  const transparencyScore = 100 - rawScore;
  const scoreColor = transparencyScore <= 30 ? '#dc2626' : transparencyScore <= 60 ? '#d97706' : '#16a34a';
  const scoreLabel = transparencyScore <= 30 ? 'LOW TRANSPARENCY' : transparencyScore <= 60 ? 'MODERATE' : 'HIGH TRANSPARENCY';

  const avgConf = techs.length > 0
    ? techs.reduce((sum: number, t: any) => sum + (t.confidence || 0), 0) / techs.length
    : 0;
  const confLabel = avgConf >= 0.8 ? 'High' : avgConf >= 0.5 ? 'Medium' : techs.length > 0 ? 'Low' : 'N/A';
  const confColor = avgConf >= 0.8 ? '#dc2626' : avgConf >= 0.5 ? '#d97706' : '#16a34a';

  const circumference = 2 * Math.PI * 54;
  const dashOffset = circumference - (transparencyScore / 100) * circumference;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        <div style={{ position: 'relative', width: 120, height: 120, flexShrink: 0 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="54" fill="none" stroke="#f0f0ee" strokeWidth="6" />
            <circle cx="60" cy="60" r="54" fill="none" stroke={scoreColor} strokeWidth="6"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 60 60)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: scoreColor, lineHeight: 1 }}>{transparencyScore}</span>
            <span style={{ fontSize: 8, fontWeight: 600, color: scoreColor, textAlign: 'center', maxWidth: 80 }}>{scoreLabel}</span>
          </div>
        </div>

        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Techniques</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Cross-refs</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Evidence</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{data.signal?.source_bias ? '✓' : '—'}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Toxicity</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(1)}%</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Sentiment</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{data.signal?.sentiment || 'Neutral'}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Model</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{(data.prism?.model_used || '').replace('gpt-4o-mini', 'GPT-4o').replace('claude-sonnet-4', 'Claude')}</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12, paddingTop: 10, borderTop: '1px solid #f0f0ee' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 11, color: '#888' }}>Confidence:</span>
          <span style={{ fontSize: 11, fontWeight: 600, color: confColor, padding: '2px 8px', borderRadius: 4, background: confLabel === 'High' ? '#fef2f2' : confLabel === 'Medium' ? '#fffbeb' : '#f0fdf4' }}>
            {confLabel}
          </span>
          {confLabel === 'Low' && <span style={{ fontSize: 10, color: '#aaa' }}>— signals detected but not definitive</span>}
          {confLabel === 'Medium' && <span style={{ fontSize: 10, color: '#aaa' }}>— moderate signals found</span>}
          {confLabel === 'High' && <span style={{ fontSize: 10, color: '#aaa' }}>— strong signals detected</span>}
        </div>
        <button onClick={() => setShowFormula(!showFormula)}
          style={{ fontSize: 10, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
          {showFormula ? 'Hide' : 'How is this calculated?'}
        </button>
      </div>

      {showFormula && (
        <div style={{ marginTop: 8, padding: '10px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, marginBottom: 4, color: '#7c3aed' }}>Transparency = 100 − manipulation signals</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: '2px 10px', alignItems: 'center' }}>
            <span style={{ color: '#888' }}>Technique confidence</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(techScore / 40 * 100, 100)}%`, background: '#7c3aed', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>−{techScore}</span>
            <span style={{ color: '#888' }}>Cross-reference matches</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(fcScore / 30 * 100, 100)}%`, background: '#2563eb', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>−{fcScore}</span>
            <span style={{ color: '#888' }}>Toxicity level</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(toxScore / 20 * 100, 100)}%`, background: '#d97706', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>−{toxScore}</span>
            <span style={{ color: '#888' }}>Disputed content bonus</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${bonusScore > 0 ? 100 : 0}%`, background: '#dc2626', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>−{bonusScore}</span>
          </div>
          <div style={{ marginTop: 6, fontSize: 10, color: '#888' }}>
            100 − ({techScore} + {fcScore} + {toxScore} + {bonusScore}) = <strong style={{ color: scoreColor }}>{transparencyScore}/100</strong>
          </div>
        </div>
      )}
    </div>
  );
}
TSEOF

echo "✅ ThreatScore → Transparency Score (inverted, renamed)"

# ============================================
# 4. Update AnalysisResult — add Counterfactual
# ============================================

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

if 'CounterfactualCard' not in content:
    content = content.replace(
        "import ExtractedClaims from './ExtractedClaims';",
        "import ExtractedClaims from './ExtractedClaims';\nimport CounterfactualCard from './CounterfactualCard';"
    )
    
    # Add counterfactual card after extracted claims
    content = content.replace(
        '''      {data.extracted_claims?.length > 0 && (
        <div className="anim-fade anim-d3"><ExtractedClaims claims={data.extracted_claims} /></div>
      )}''',
        '''      {data.counterfactuals?.length > 0 && (
        <div className="anim-fade anim-d2"><CounterfactualCard counterfactuals={data.counterfactuals} /></div>
      )}

      {data.extracted_claims?.length > 0 && (
        <div className="anim-fade anim-d3"><ExtractedClaims claims={data.extracted_claims} /></div>
      )}'''
    )

open('src/components/AnalysisResult.tsx', 'w').write(content)
print('✅ AnalysisResult: CounterfactualCard added')
PYEOF

# ============================================
# 5. Rename Signal card — evidence provenance
# ============================================

python3 << 'PYEOF'
content = open('src/components/SignalCard.tsx').read()

# Rename header
content = content.replace('Signal — credibility', 'Signal — evidence')

# Check if we can add provenance info
if 'independent' not in content:
    # Add provenance summary at top of card
    content = content.replace(
        "const signal = props?.signal || props;",
        """const signal = props?.signal || props;
  const hasBias = signal?.source_bias;
  const hasFact = signal?.source_factuality;
  const provenanceCount = (hasBias ? 1 : 0) + (hasFact ? 1 : 0) + (signal?.toxicity_score < 0.1 ? 1 : 0);"""
    )

open('src/components/SignalCard.tsx', 'w').write(content)
print('✅ SignalCard: renamed to evidence')
PYEOF

# ============================================
# 6. Update landing page tagline
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Update hero
content = content.replace(
    "Don\\'t get played. Understand how content is designed to influence you.",
    "See how information is constructed. Understand what content says — and what it leaves out."
)
content = content.replace(
    "Don't get played. Understand how content is designed to influence you.",
    "See how information is constructed. Understand what content says — and what it leaves out."
)

# Update subtitle
content = content.replace(
    "Headlines are engineered. Claims are crafted. Now you can see the playbook.",
    "Every article frames information differently. Dissekt makes that framing visible."
)

# Update CTA
content = content.replace(
    "See through the noise",
    "Inspect any content"
)
content = content.replace(
    "Stop scrolling blind. Start seeing the playbook.",
    "Information transparency for everyone."
)
content = content.replace(
    "See the playbook behind the content",
    "Information transparency and argument inspection"
)

# Update footer
content = content.replace(
    "See the playbook behind the content",
    "Information transparency and argument inspection"
)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Landing page: new tagline + messaging')
PYEOF

# ============================================
# 7. Update scan page idle text
# ============================================

python3 << 'PYEOF'
content = open('src/app/page.tsx').read()

content = content.replace(
    "Paste anything — URL, text, screenshot, or claim",
    "Paste any article, claim, or URL to inspect"
)
content = content.replace(
    "Or pick something from Radar below and see the playbook.",
    "Or pick something from Radar below to analyze."
)

open('src/app/page.tsx', 'w').write(content)
print('✅ Scan page: updated idle text')
PYEOF

# ============================================
# 8. Update Telegram bot messaging
# ============================================

python3 << 'PYEOF'
content = open('../app/telegram_bot/__init__.py').read()

content = content.replace('DISSEKT ANALYSIS', 'DISSEKT — INFORMATION TRANSPARENCY')
content = content.replace('Threat Score:', 'Transparency Score:')

# Invert score for Telegram too
content = content.replace(
    '''    score = min(100, (
        (round(max_conf * 40) if techs else 0) +
        min(len(fcs) * 4, 30) +
        round(tox * 20) +
        (10 if len(fcs) >= 3 else 0)
    ))

    emoji = "🔴" if score >= 70 else "🟡" if score >= 40 else "🟢"
    label = "HIGH RISK" if score >= 70 else "MEDIUM RISK" if score >= 40 else "LOW RISK"''',
    '''    raw = min(100, (
        (round(max_conf * 40) if techs else 0) +
        min(len(fcs) * 4, 30) +
        round(tox * 20) +
        (10 if len(fcs) >= 3 else 0)
    ))
    score = 100 - raw

    emoji = "🔴" if score <= 30 else "🟡" if score <= 60 else "🟢"
    label = "LOW TRANSPARENCY" if score <= 30 else "MODERATE" if score <= 60 else "HIGH TRANSPARENCY"'''
)

open('../app/telegram_bot/__init__.py', 'w').write(content)
print('✅ Telegram: transparency score + new messaging')
PYEOF

echo ""
echo "✅ All positioning changes applied:"
echo "  🔄 Counterfactual View — alternative framings for each claim"
echo "  📊 Threat Score → Transparency Score (inverted: 100 = fully transparent)"
echo "  🏷️ HIGH RISK → LOW TRANSPARENCY"
echo "  📰 Signal → evidence provenance framing"
echo "  ✏️ Landing: 'See how information is constructed'"
echo "  🤖 Telegram: updated messaging"
echo ""
echo "Test: cd dissekt-web && npm run build && npm run dev"
echo "Then scan: 'Modi promised 2 crore jobs but unemployment is 8%'"
echo "→ See Transparency Score + Counterfactual View + alternative framings"
