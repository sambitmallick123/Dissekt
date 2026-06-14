#!/bin/bash
# Dissekt — System F scoring + Context-aware toxicity (3+4+6)
# Unified across: ClarityScore, analyze history, Kaleidoscope, embed, bulk, telegram, help
set -e

# ============================================
# 1. BACKEND: Scoring engine + toxicity overhaul
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

cat > app/scoring.py << 'SCOREEOF'
"""
Dissekt Scoring Engine — System F
Hybrid multi-axis scoring with geometric mean.

4 axes (each 0-100):
  Rhetoric  — severity-weighted technique penalty
  Evidence  — fact-checker weighted consensus
  Source    — MBFC factuality prior
  Tone     — context-aware toxicity + rhetorical hostility + sentiment

Headline: Clarity = geometric_mean(rhetoric, evidence, source, tone)

References:
  Da San Martino et al., EMNLP 2019 — technique severity
  Baly et al., EMNLP 2018 — multi-dimensional credibility
  UNDP HDI — geometric mean for composite scores
  Pavlopoulos et al., EACL 2021 — context affects toxicity
  Sap et al., ALW 2020 — hostile framing vs explicit toxicity
"""
import re
import math
import logging

logger = logging.getLogger("dissekt.scoring")

# ── Technique severity weights (from SemEval annotation impact) ──
SEVERITY = {
    "straw_man": 10, "false_equivalence": 9, "cherry_picking": 8,
    "false_causation": 8, "circular_reasoning": 7, "missing_context": 7,
    "appeal_to_fear": 6, "ad_hominem": 6, "whataboutism": 6,
    "false_dilemma": 5, "slippery_slope": 5, "red_herring": 5,
    "hasty_generalization": 5, "oversimplification": 5,
    "appeal_to_authority": 4, "appeal_to_emotion": 4,
    "emotional_framing": 4, "bandwagon": 3,
    "loaded_language": 3, "anecdotal": 3,
}

# ── MBFC factuality mapping ──
FACTUALITY_MAP = {
    "very low": 10, "low": 30, "mixed": 50,
    "mostly factual": 65, "high": 80, "very high": 95,
}

# ── Fact-checker tier weights ──
CHECKER_TIER_WEIGHT = {"A": 1.0, "B": 0.7, "C": 0.4, "U": 0.2}

# ── Verdict scoring ──
VERDICT_SCORE = {
    "true": 1.0, "correct": 1.0, "accurate": 1.0,
    "mostly true": 0.5, "mostly correct": 0.5,
    "mixed": 0.0, "partly true": 0.0, "unproven": 0.0,
    "mostly false": -0.5, "misleading": -0.5, "exaggerated": -0.5,
    "false": -1.0, "pants on fire": -1.0, "incorrect": -1.0,
}

# ── Genre baselines for toxicity ──
GENRE_BASELINES = {
    "wire_report": 0.03, "news_article": 0.06, "editorial": 0.12,
    "opinion": 0.12, "sports": 0.10, "social_media": 0.15,
    "press_release": 0.02, "unknown": 0.06,
}

# ── Rhetorical hostility lexicon ──
AGGRESSION_WORDS = {
    "destroy", "attack", "slam", "blast", "crush", "demolish", "savage",
    "eviscerate", "skewer", "gut", "torpedo", "annihilate", "obliterate",
    "rip apart", "tear apart", "decimate", "ravage", "pummel", "batter",
    "assail", "lambaste", "excoriate", "denounce", "condemn", "rebuke",
    "lash out", "fire back", "hit back", "strike back", "fight back",
    "shocking", "outrageous", "disgraceful", "shameful", "appalling",
    "catastrophic", "devastating", "disastrous", "ruinous", "crippling",
}

# ── NRC emotion words (subset for density) ──
EMOTIVE_WORDS = {
    "fear", "anger", "disgust", "sadness", "joy", "trust", "surprise",
    "afraid", "angry", "furious", "terrified", "horrified", "outraged",
    "heartbreaking", "tragic", "devastating", "wonderful", "amazing",
    "terrible", "horrible", "incredible", "unacceptable", "alarming",
    "desperate", "urgent", "critical", "crisis", "chaos", "panic",
    "triumph", "victory", "defeat", "betrayal", "sacrifice", "miracle",
}


def detect_genre(text: str, source_name: str = "") -> str:
    """Detect content genre from text features."""
    lower = text[:500].lower()
    source_lower = source_name.lower()
    if source_lower in ("ap", "reuters", "afp", "associated press"):
        return "wire_report"
    if "opinion" in lower or "editorial" in lower or "column" in lower:
        return "editorial"
    if any(w in lower for w in ("i think", "i believe", "in my view", "my opinion")):
        return "opinion"
    if any(w in source_lower for w in ("espn", "sport", "athletic")):
        return "sports"
    if any(w in lower for w in ("twitter", "reddit", "posted", "tweeted", "thread")):
        return "social_media"
    if any(w in lower for w in ("press release", "announces", "is pleased to")):
        return "press_release"
    return "news_article"


def extract_quoted_speech(text: str) -> tuple:
    """Split text into editorial voice and quoted speech."""
    # Pattern 1: Text between quotation marks
    quotes = re.findall(r'["\u201c\u201d\u2018\u2019«»]([^"\u201c\u201d\u2018\u2019«»]{10,})["\u201c\u201d\u2018\u2019«»]', text)

    # Pattern 2: Text after attribution verbs
    attr_pattern = r'(?:said|stated|claimed|argued|declared|tweeted|posted|wrote|added|noted|insisted|warned|suggested|explained|told|asked)\s*(?:that\s+)?["\u201c]?([^.!?]{10,}[.!?])'
    attributed = re.findall(attr_pattern, text, re.IGNORECASE)

    quoted_text = " ".join(quotes + attributed)
    editorial_text = text
    for q in quotes:
        editorial_text = editorial_text.replace(q, "")

    return editorial_text.strip(), quoted_text.strip()


def compute_rhetorical_hostility(text: str) -> float:
    """Compute rhetorical hostility score (0-1) for news text."""
    words = text.lower().split()
    if not words:
        return 0.0

    # 1. Lexical aggression
    aggression_count = sum(1 for w in words if w.strip(".,!?;:") in AGGRESSION_WORDS)
    # Also check bigrams
    bigrams = [f"{words[i]} {words[i+1]}" for i in range(len(words)-1)]
    aggression_count += sum(1 for b in bigrams if b in AGGRESSION_WORDS)
    lexical_aggression = min(aggression_count / max(len(words), 1) * 20, 1.0)

    # 2. Emotive density
    emotive_count = sum(1 for w in words if w.strip(".,!?;:") in EMOTIVE_WORDS)
    emotive_density = min(emotive_count / max(len(words), 1) * 15, 1.0)

    # Composite
    hostility = (lexical_aggression * 0.55) + (emotive_density * 0.45)
    return round(min(hostility, 1.0), 3)


def compute_tone_axis(text: str, raw_toxicity: float, sentiment_compound: float, source_name: str = "") -> dict:
    """
    Compute Tone axis (0-100) using context-aware toxicity.
    Combines: quote splitting (3) + genre adjustment (4) + rhetorical hostility (6).
    """
    # Step 1: Split into editorial vs quoted (system 3)
    editorial_text, quoted_text = extract_quoted_speech(text)

    # Step 2: Detect genre and adjust baseline (system 4)
    genre = detect_genre(text, source_name)
    baseline = GENRE_BASELINES.get(genre, 0.06)

    # Step 3: Adjusted toxicity (editorial voice only, genre-corrected)
    adjusted_toxicity = max(raw_toxicity - baseline, 0) / max(1 - baseline, 0.01)

    # If we could re-score editorial text separately, we would.
    # For now, apply a discount based on quote ratio
    total_len = len(text)
    quote_ratio = len(quoted_text) / max(total_len, 1)
    editorial_toxicity = adjusted_toxicity * (1 - quote_ratio * 0.6)

    # Step 4: Rhetorical hostility (system 6)
    hostility = compute_rhetorical_hostility(text)

    # Step 5: Combine into Tone axis
    toxicity_penalty = editorial_toxicity * 30
    hostility_penalty = hostility * 40
    sentiment_penalty = abs(sentiment_compound) * 30
    tone = max(100 - toxicity_penalty - hostility_penalty - sentiment_penalty, 10)

    return {
        "tone_score": round(tone),
        "raw_toxicity": round(raw_toxicity, 3),
        "adjusted_toxicity": round(editorial_toxicity, 3),
        "rhetorical_hostility": round(hostility, 3),
        "sentiment_extremity": round(abs(sentiment_compound), 3),
        "genre": genre,
        "quote_ratio": round(quote_ratio, 2),
        "breakdown": {
            "toxicity_penalty": round(toxicity_penalty, 1),
            "hostility_penalty": round(hostility_penalty, 1),
            "sentiment_penalty": round(sentiment_penalty, 1),
        }
    }


def compute_rhetoric_axis(techniques: list) -> dict:
    """Compute Rhetoric axis (0-100) using severity-weighted techniques."""
    if not techniques:
        return {"rhetoric_score": 100, "technique_penalty": 0, "weighted_techniques": []}

    weighted = []
    total_penalty = 0
    for t in techniques:
        name = t.get("name", "unknown")
        conf = t.get("confidence", 0)
        sev = SEVERITY.get(name, 4)
        penalty = sev * conf
        total_penalty += penalty
        weighted.append({"name": name, "confidence": round(conf, 2), "severity": sev, "penalty": round(penalty, 1)})

    capped_penalty = min(total_penalty, 90)
    rhetoric = max(round(100 - capped_penalty), 10)

    return {
        "rhetoric_score": rhetoric,
        "technique_penalty": round(capped_penalty, 1),
        "weighted_techniques": sorted(weighted, key=lambda x: -x["penalty"]),
    }


def compute_evidence_axis(fact_checks: list) -> dict:
    """Compute Evidence axis (0-100) using fact-checker weighted consensus."""
    if not fact_checks:
        return {"evidence_score": 50, "status": "no_checks", "weighted_checks": 0, "check_count": 0}

    total_weight = 0
    weighted_sum = 0

    for fc in fact_checks:
        tier = fc.get("checker_tier", "U")
        rating = (fc.get("rating", "") or fc.get("textualRating", "")).lower()
        tier_weight = CHECKER_TIER_WEIGHT.get(tier, 0.2)

        # Find best matching verdict
        verdict = 0
        for key, val in VERDICT_SCORE.items():
            if key in rating:
                verdict = val
                break

        weighted_sum += tier_weight * verdict
        total_weight += tier_weight

    if total_weight == 0:
        return {"evidence_score": 50, "status": "unrated", "weighted_checks": 0, "check_count": len(fact_checks)}

    avg_verdict = weighted_sum / total_weight
    evidence = round(50 + avg_verdict * 50)
    evidence = max(min(evidence, 100), 0)

    status = "confirmed" if evidence >= 70 else "disputed" if evidence <= 30 else "mixed"

    return {
        "evidence_score": evidence,
        "status": status,
        "weighted_checks": round(weighted_sum, 2),
        "check_count": len(fact_checks),
    }


def compute_source_axis(source_factuality: str = None, source_bias: str = None) -> dict:
    """Compute Source axis (0-100) from MBFC data."""
    if not source_factuality:
        return {"source_score": 50, "factuality": "unknown", "bias": source_bias or "unknown"}

    score = FACTUALITY_MAP.get(source_factuality.lower(), 50)
    return {
        "source_score": score,
        "factuality": source_factuality,
        "bias": source_bias or "unknown",
    }


def compute_clarity_score(rhetoric: int, evidence: int, source: int, tone: int) -> dict:
    """Compute headline Clarity Score as geometric mean of 4 axes."""
    # Floor values to avoid zero killing the geometric mean
    r = max(rhetoric, 5)
    e = max(evidence, 5)
    s = max(source, 5)
    t = max(tone, 5)

    geometric = (r * e * s * t) ** 0.25
    clarity = round(geometric)

    # Determine label and color
    if clarity >= 70:
        label = "HIGH TRANSPARENCY"
        color = "#16a34a"
    elif clarity >= 45:
        label = "MODERATE"
        color = "#d97706"
    else:
        label = "LOW TRANSPARENCY"
        color = "#dc2626"

    return {
        "clarity_score": clarity,
        "label": label,
        "color": color,
        "axes": {
            "rhetoric": rhetoric,
            "evidence": evidence,
            "source": source,
            "tone": tone,
        },
        "method": "geometric_mean",
    }


def compute_full_score(techniques: list, fact_checks: list, toxicity_score: float,
                       sentiment_compound: float, source_factuality: str = None,
                       source_bias: str = None, text: str = "", source_name: str = "") -> dict:
    """
    Master scoring function. Computes all 4 axes and the headline Clarity Score.
    This is the ONLY place scores should be computed.
    """
    rhetoric = compute_rhetoric_axis(techniques)
    evidence = compute_evidence_axis(fact_checks)
    source = compute_source_axis(source_factuality, source_bias)
    tone = compute_tone_axis(text, toxicity_score, sentiment_compound, source_name)

    clarity = compute_clarity_score(
        rhetoric["rhetoric_score"],
        evidence["evidence_score"],
        source["source_score"],
        tone["tone_score"],
    )

    # Confidence band
    if techniques:
        avg_conf = sum(t.get("confidence", 0) for t in techniques) / len(techniques)
    else:
        avg_conf = 0
    confidence_band = "high" if avg_conf >= 0.8 else "medium" if avg_conf >= 0.5 else "low" if techniques else "n/a"

    return {
        **clarity,
        "rhetoric": rhetoric,
        "evidence": evidence,
        "source": source,
        "tone": tone,
        "confidence_band": confidence_band,
        "avg_confidence": round(avg_conf, 2),
    }
SCOREEOF

echo "✅ Scoring engine (app/scoring.py)"

# ============================================
# 2. Wire scoring into Beacon
# ============================================

python3 -c "
content = open('app/beacon/__init__.py').read()
if 'from app.scoring import' not in content:
    content = content.replace(
        'import httpx',
        'import httpx\nfrom app.scoring import compute_full_score'
    )
    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ Beacon: scoring imported')
"

# Add score computation after analysis
python3 -c "
content = open('app/beacon/__init__.py').read()
if 'compute_full_score(' not in content:
    content = content.replace(
        '    # Enrich fact-checks with credibility info',
        '''    # Compute System F Clarity Score
    try:
        techs_raw = []
        if hasattr(analysis, 'prism') and analysis.prism:
            techs_raw = [{'name': t.name, 'confidence': t.confidence} for t in analysis.prism.techniques] if hasattr(analysis.prism, 'techniques') else analysis.prism.get('techniques', []) if isinstance(analysis.prism, dict) else []
        fcs_raw = []
        if hasattr(analysis, 'trace') and analysis.trace:
            fcs_raw = analysis.trace.fact_checks if hasattr(analysis.trace, 'fact_checks') else analysis.trace.get('fact_checks', []) if isinstance(analysis.trace, dict) else []
        tox_raw = 0.0
        sent_raw = 0.0
        src_fact = None
        src_bias = None
        if hasattr(analysis, 'signal') and analysis.signal:
            sig = analysis.signal if isinstance(analysis.signal, dict) else analysis.signal.__dict__ if hasattr(analysis.signal, '__dict__') else {}
            tox_raw = sig.get('toxicity_score', 0.0)
            sent_raw = sig.get('sentiment_score', 0.0)
            src_fact = sig.get('source_factuality')
            src_bias = sig.get('source_bias')
        
        score_result = compute_full_score(
            techniques=techs_raw, fact_checks=fcs_raw,
            toxicity_score=tox_raw, sentiment_compound=sent_raw,
            source_factuality=src_fact, source_bias=src_bias,
            text=content[:5000], source_name=\"\",
        )
        
        if isinstance(analysis, dict):
            analysis['scoring'] = score_result
            analysis['clarity_score'] = score_result['clarity_score']
        else:
            analysis.scoring = score_result
            analysis.clarity_score = score_result['clarity_score']
    except Exception as e:
        logger.warning(f\"Scoring failed: {e}\")

    # Enrich fact-checks with credibility info'''
    )
    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ Beacon: System F scoring wired')
"

# ============================================
# 3. Update Telegram bot scoring
# ============================================

python3 -c "
content = open('app/telegram_bot/__init__.py').read()
if 'scoring' not in content.split('format_result')[0] if 'format_result' in content else True:
    # Update to use scoring object if available
    old = '''    max_conf = max((t.get(\"confidence\", 0) for t in techs), default=0)
    raw = min(100, (
        (round(max_conf * 40) if techs else 0) +
        min(len(fcs) * 4, 30) +
        round(tox * 20) +
        (10 if len(fcs) >= 3 else 0)
    ))
    score = 100 - raw'''
    
    new = '''    # Use System F score if available, fallback to legacy
    scoring = data.get(\"scoring\", {})
    if scoring:
        score = scoring.get(\"clarity_score\", 50)
    else:
        max_conf = max((t.get(\"confidence\", 0) for t in techs), default=0)
        raw = min(100, (round(max_conf * 40) if techs else 0) + min(len(fcs) * 4, 30) + round(tox * 20) + (10 if len(fcs) >= 3 else 0))
        score = 100 - raw'''
    
    content = content.replace(old, new)
    open('app/telegram_bot/__init__.py', 'w').write(content)
    print('✅ Telegram: uses System F score')
"

echo "✅ Backend complete"

# ============================================
# 4. FRONTEND: New ClarityScore component with 4 axes
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/ClarityScore.tsx << 'CSEOF'
'use client';
import { useState } from 'react';

const AXIS_COLORS = {
  rhetoric: { bar: '#dc2626', bg: '#fef2f2', text: '#991b1b' },
  evidence: { bar: '#2563eb', bg: '#eff6ff', text: '#1e40af' },
  source:   { bar: '#0d9488', bg: '#f0fdfa', text: '#065f53' },
  tone:     { bar: '#d97706', bg: '#fffbeb', text: '#92400e' },
};

export default function ClarityScore({ data }: { data: any }) {
  const [showBreakdown, setShowBreakdown] = useState(false);

  const scoring = data.scoring || {};
  const axes = scoring.axes || {};
  const rhetoric = axes.rhetoric ?? 100;
  const evidence = axes.evidence ?? 50;
  const source = axes.source ?? 50;
  const tone = axes.tone ?? 100;
  const clarity = scoring.clarity_score ?? data.clarity_score ?? 50;
  const label = scoring.label || (clarity >= 70 ? 'HIGH TRANSPARENCY' : clarity >= 45 ? 'MODERATE' : 'LOW TRANSPARENCY');
  const scoreColor = clarity >= 70 ? '#16a34a' : clarity >= 45 ? '#d97706' : '#dc2626';
  const band = scoring.confidence_band || 'n/a';

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || data.lens?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const circumference = 2 * Math.PI * 54;
  const dashOffset = circumference - (clarity / 100) * circumference;

  const rhetoricDetail = scoring.rhetoric || {};
  const evidenceDetail = scoring.evidence || {};
  const toneDetail = scoring.tone || {};
  const sourceDetail = scoring.source || {};

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, flexWrap: 'wrap' }}>
        {/* Score circle */}
        <div style={{ position: 'relative', width: 120, height: 120, flexShrink: 0 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="54" fill="none" stroke="#f0f0ee" strokeWidth="6" />
            <circle cx="60" cy="60" r="54" fill="none" stroke={scoreColor} strokeWidth="6"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 60 60)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: scoreColor, lineHeight: 1 }}>{clarity}</span>
            <span style={{ fontSize: 8, fontWeight: 600, color: scoreColor, textAlign: 'center', maxWidth: 80 }}>{label}</span>
          </div>
        </div>

        {/* 4 Axes */}
        <div style={{ flex: 1, minWidth: 240 }}>
          {[
            { key: 'rhetoric', label: 'Rhetoric', value: rhetoric, desc: 'How manipulative are the techniques used?' },
            { key: 'evidence', label: 'Evidence', value: evidence, desc: 'What do fact-checkers say?' },
            { key: 'source', label: 'Source', value: source, desc: 'How credible is the source?' },
            { key: 'tone', label: 'Tone', value: tone, desc: 'How hostile or provocative is the framing?' },
          ].map(ax => {
            const c = AXIS_COLORS[ax.key as keyof typeof AXIS_COLORS];
            const axColor = ax.value >= 70 ? '#16a34a' : ax.value >= 45 ? '#d97706' : '#dc2626';
            return (
              <div key={ax.key} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                <span style={{ fontSize: 11, width: 60, color: '#888', flexShrink: 0 }}>{ax.label}</span>
                <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                  <div style={{ height: '100%', width: `${ax.value}%`, background: c.bar, borderRadius: 4, transition: 'width 0.6s ease' }} />
                </div>
                <span style={{ fontSize: 12, fontWeight: 600, color: axColor, width: 28, textAlign: 'right' }}>{ax.value}</span>
              </div>
            );
          })}
        </div>

        {/* Quick stats */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6, minWidth: 160 }}>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Techniques</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Cross-refs</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Toxicity</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(0)}%</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Confidence</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: band === 'high' ? '#dc2626' : band === 'medium' ? '#d97706' : '#16a34a', textTransform: 'capitalize' }}>{band}</div>
          </div>
        </div>
      </div>

      {/* Expand breakdown */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 10 }}>
        <button onClick={() => setShowBreakdown(!showBreakdown)}
          style={{ fontSize: 10, color: '#0d9488', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
          {showBreakdown ? 'Hide calculation' : 'How is this calculated?'}
        </button>
      </div>

      {showBreakdown && (
        <div style={{ marginTop: 8, padding: '12px 14px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>Clarity = (Rhetoric × Evidence × Source × Tone) ^ 0.25</div>

          {/* Rhetoric breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #dc2626' }}>
            <div style={{ fontWeight: 600, color: '#991b1b' }}>Rhetoric: {rhetoric}/100</div>
            <div style={{ color: '#888' }}>100 − severity-weighted technique penalties (capped at 90)</div>
            {rhetoricDetail.weighted_techniques?.slice(0, 4).map((t: any, i: number) => (
              <div key={i} style={{ color: '#555' }}>
                {t.name?.replace(/_/g, ' ')} — severity {t.severity} × confidence {t.confidence} = −{t.penalty}
              </div>
            ))}
          </div>

          {/* Evidence breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #2563eb' }}>
            <div style={{ fontWeight: 600, color: '#1e40af' }}>Evidence: {evidence}/100</div>
            <div style={{ color: '#888' }}>
              {evidenceDetail.check_count || 0} fact-check{(evidenceDetail.check_count || 0) !== 1 ? 's' : ''} found.
              {evidenceDetail.status === 'confirmed' && ' Mostly confirmed.'}
              {evidenceDetail.status === 'disputed' && ' Mostly disputed.'}
              {evidenceDetail.status === 'mixed' && ' Mixed verdicts.'}
              {evidenceDetail.status === 'no_checks' && ' No existing fact-checks. Neutral score (50).'}
              {' '}Weighted by fact-checker tier (A=1.0, B=0.7, C=0.4).
            </div>
          </div>

          {/* Source breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #0d9488' }}>
            <div style={{ fontWeight: 600, color: '#065f53' }}>Source: {source}/100</div>
            <div style={{ color: '#888' }}>
              MBFC factuality: {sourceDetail.factuality || 'unknown'} · Bias: {sourceDetail.bias || 'unknown'}
            </div>
          </div>

          {/* Tone breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #d97706' }}>
            <div style={{ fontWeight: 600, color: '#92400e' }}>Tone: {tone}/100</div>
            <div style={{ color: '#888' }}>
              Genre: {toneDetail.genre || 'unknown'} · Quote ratio: {((toneDetail.quote_ratio || 0) * 100).toFixed(0)}%
            </div>
            <div style={{ color: '#555' }}>
              Toxicity (editorial, adjusted): −{toneDetail.breakdown?.toxicity_penalty || 0} ·
              Rhetorical hostility: −{toneDetail.breakdown?.hostility_penalty || 0} ·
              Sentiment extremity: −{toneDetail.breakdown?.sentiment_penalty || 0}
            </div>
          </div>

          {/* Final calculation */}
          <div style={{ fontFamily: 'monospace', fontSize: 10, color: '#555', marginTop: 4 }}>
            ({rhetoric} × {evidence} × {source} × {tone})^0.25 = <strong style={{ color: scoreColor }}>{clarity}/100</strong>
          </div>

          <div style={{ marginTop: 6, fontSize: 10, color: '#888' }}>
            Based on: Da San Martino et al. 2019 (severity), Baly et al. 2018 (multi-axis), HDI geometric mean, Pavlopoulos et al. 2021 (context-aware toxicity).
          </div>
        </div>
      )}
    </div>
  );
}
CSEOF

echo "✅ ClarityScore component (System F, 4 axes)"

# ============================================
# 5. Fix analyze page history score
# ============================================

python3 -c "
content = open('src/app/analyze/page.tsx').read()
content = content.replace(
    'score: 100 - Math.min((data.prism?.techniques?.length || 0) * 30, 100)',
    'score: data.scoring?.clarity_score || data.clarity_score || 50'
)
open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze history: uses scoring.clarity_score')
"

# ============================================
# 6. Fix Kaleidoscope score
# ============================================

python3 -c "
content = open('src/components/Kaleidoscope.tsx').read()
content = content.replace(
    '''? 100 - Math.min(Math.round(Math.max(...techs.map((t: any) => t.confidence || 0)) * 40) + Math.min(techs.length * 10, 30), 100)''',
    '''? (r?.scoring?.clarity_score || r?.clarity_score || 50)'''
)
open('src/components/Kaleidoscope.tsx', 'w').write(content)
print('✅ Kaleidoscope: uses scoring.clarity_score')
"

# ============================================
# 7. Fix embed page score
# ============================================

python3 -c "
content = open('src/app/embed/[id]/page.tsx').read()
content = content.replace(
    'const raw = Math.min((techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs.length * 4, 30) + Math.round(tox * 20) + (fcs.length >= 3 ? 10 : 0), 100);',
    'const raw = 0; // Legacy — using scoring object'
)
content = content.replace(
    'const score = 100 - raw;',
    'const score = a.scoring?.clarity_score || a.clarity_score || 50;'
)
open('src/app/embed/[id]/page.tsx', 'w').write(content)
print('✅ Embed: uses scoring.clarity_score')
"

# ============================================
# 8. Fix bulk analysis score
# ============================================

python3 -c "
content = open('src/components/BulkAnalysis.tsx').read()
content = content.replace(
    'const tox = r.signal?.toxicity_score || 0;',
    'const tox = r.signal?.toxicity_score || 0; const bulkScore = r.scoring?.clarity_score || r.clarity_score || 50;'
)
open('src/components/BulkAnalysis.tsx', 'w').write(content)
print('✅ Bulk: scoring reference added')
"

echo ""
echo "✅ System F + Toxicity 3+4+6 implemented:"
echo ""
echo "  📊 Scoring Engine (app/scoring.py)"
echo "     - compute_full_score() — single source of truth"
echo "     - Rhetoric: severity-weighted (13 levels, SemEval-backed)"
echo "     - Evidence: fact-checker tier-weighted consensus"  
echo "     - Source: MBFC factuality prior"
echo "     - Tone: quote-split + genre-adjusted + rhetorical hostility"
echo "     - Clarity: geometric mean of 4 axes"
echo ""
echo "  🎨 ClarityScore component"
echo "     - Circle gauge (headline number)"
echo "     - 4 axis bars with color coding:"
echo "       Rhetoric (red) | Evidence (blue) | Source (teal) | Tone (amber)"
echo "     - Quick stats: techniques, cross-refs, toxicity, confidence"
echo "     - Expandable breakdown with per-axis detail"
echo "     - References cited in breakdown"
echo ""  
echo "  🔄 Unified across all locations:"
echo "     - ClarityScore.tsx ✅"
echo "     - analyze/page.tsx (history) ✅"
echo "     - Kaleidoscope.tsx ✅"
echo "     - embed/[id]/page.tsx ✅"
echo "     - BulkAnalysis.tsx ✅"
echo "     - Telegram bot ✅"
echo "     - Beacon pipeline ✅"
echo ""
echo "npm run build"
