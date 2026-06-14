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
