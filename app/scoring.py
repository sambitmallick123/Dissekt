"""
Dissekt Scoring Engine — Ensemble System (0.0 to 1.0 scale)

3 Dimensions, 10 Metrics:
  Construction (red)   — Rhetoric, Argumentation, Completeness
  Verification (blue)  — Evidence, Source, Diversity, Temporal
  Intent (amber)       — Tone, Manipulation, Narrative Direction

Headline: Clarity = geometric_mean(Construction, Verification, Intent)

Scale: 0.0 (opaque) → 1.0 (transparent)

Thresholds:
  0.00-0.35  LOW TRANSPARENCY    #dc2626 (red)
  0.35-0.65  MODERATE            #d97706 (amber)
  0.65-1.00  HIGH TRANSPARENCY   #16a34a (green)

References:
  Da San Martino et al., EMNLP 2019 — technique severity
  Baly et al., EMNLP 2018 — multi-dimensional credibility
  UNDP HDI — geometric mean for composite indices
  Wachsmuth et al., ACL 2017 — argumentation quality
  Card et al., ACL 2018 — media framing
  Pavlopoulos et al., EACL 2021 — context-aware toxicity
  Sap et al., ALW 2020 — hostile framing
  Cialdini, 2007 — persuasion mechanics
  Schuster et al., NAACL 2022 — temporal fact verification
"""
import re
import math
import logging

logger = logging.getLogger("dissekt.scoring")

# ── Technique severity weights (SemEval-derived) ──
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

FACTUALITY_MAP = {
    "very low": 0.10, "low": 0.30, "mixed": 0.50,
    "mostly factual": 0.65, "high": 0.80, "very high": 0.95,
}

CHECKER_TIER_WEIGHT = {"A": 1.0, "B": 0.7, "C": 0.4, "U": 0.2}

VERDICT_SCORE = {
    "true": 1.0, "correct": 1.0, "accurate": 1.0,
    "mostly true": 0.5, "mostly correct": 0.5,
    "mixed": 0.0, "partly true": 0.0, "unproven": 0.0,
    "mostly false": -0.5, "misleading": -0.5, "exaggerated": -0.5,
    "false": -1.0, "pants on fire": -1.0, "incorrect": -1.0,
}

GENRE_BASELINES = {
    "wire_report": 0.03, "news_article": 0.06, "editorial": 0.12,
    "opinion": 0.12, "sports": 0.10, "social_media": 0.15,
    "press_release": 0.02, "unknown": 0.06,
}

AGGRESSION_WORDS = {
    "destroy", "attack", "slam", "blast", "crush", "demolish", "savage",
    "eviscerate", "skewer", "gut", "torpedo", "annihilate", "obliterate",
    "rip apart", "tear apart", "decimate", "ravage", "pummel", "batter",
    "assail", "lambaste", "excoriate", "denounce", "condemn", "rebuke",
    "lash out", "fire back", "hit back", "strike back", "fight back",
    "shocking", "outrageous", "disgraceful", "shameful", "appalling",
    "catastrophic", "devastating", "disastrous", "ruinous", "crippling",
}

EMOTIVE_WORDS = {
    "fear", "anger", "disgust", "sadness", "joy", "trust", "surprise",
    "afraid", "angry", "furious", "terrified", "horrified", "outraged",
    "heartbreaking", "tragic", "devastating", "wonderful", "amazing",
    "terrible", "horrible", "incredible", "unacceptable", "alarming",
    "desperate", "urgent", "critical", "crisis", "chaos", "panic",
    "triumph", "victory", "defeat", "betrayal", "sacrifice", "miracle",
}

URGENCY_PHRASES = [
    "act now", "before it's too late", "time is running out", "don't wait",
    "immediately", "breaking", "urgent", "this changes everything",
    "you need to know", "share this", "spread the word", "wake up",
]

def _clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))

def _round(v, d=3):
    return round(v, d)

def score_label(s):
    if s >= 0.65: return "HIGH TRANSPARENCY"
    if s >= 0.35: return "MODERATE"
    return "LOW TRANSPARENCY"

def score_color(s):
    if s >= 0.65: return "#16a34a"
    if s >= 0.35: return "#d97706"
    return "#dc2626"


# ═══════════════════════════════════════════
# DIMENSION 1: CONSTRUCTION
# ═══════════════════════════════════════════

def compute_rhetoric(techniques: list) -> dict:
    if not techniques:
        return {"score": 1.0, "penalty": 0.0, "weighted": []}
    weighted = []
    total_penalty = 0
    for t in techniques:
        name = t.get("name", "unknown")
        conf = t.get("confidence", 0)
        sev = SEVERITY.get(name, 4)
        pen = sev * conf
        total_penalty += pen
        weighted.append({"name": name, "confidence": _round(conf), "severity": sev, "penalty": _round(pen, 1)})
    capped = min(total_penalty / 30.0, 1.0)
    score = _clamp(1.0 - capped, 0.05)
    return {"score": _round(score), "penalty": _round(capped), "weighted": sorted(weighted, key=lambda x: -x["penalty"])}


def compute_argumentation(text: str, techniques: list, claims: list = None) -> dict:
    claims = claims or []
    words = text.split()
    sentences = re.split(r'[.!?]+', text)
    sentences = [s.strip() for s in sentences if len(s.strip()) > 10]
    total_claims = max(len(claims), 1)
    supported = sum(1 for c in claims if c.get("evidence") or c.get("type") == "statistic")
    claim_support = supported / total_claims if claims else 0.5
    fallacy_count = sum(1 for t in techniques if t.get("name") in ("circular_reasoning", "straw_man", "false_dilemma", "false_causation", "hasty_generalization"))
    coherence = max(1.0 - (fallacy_count / max(len(techniques), 1)) * 1.3, 0.0) if techniques else 0.65
    has_conclusion = any(w in text[-200:].lower() for w in ("therefore", "thus", "in conclusion", "this shows", "this means", "ultimately"))
    conclusion = 0.8 if has_conclusion else 0.5
    score = _clamp(claim_support * 0.4 + coherence * 0.35 + conclusion * 0.25, 0.05)
    return {"score": _round(score), "claim_support": _round(claim_support), "coherence": _round(coherence), "conclusion": _round(conclusion)}


def compute_completeness(text: str, claims: list = None) -> dict:
    claims = claims or []
    import re as _re
    entities = len(set(_re.findall(r'[A-Z][a-z]+ [A-Z][a-z]+', text[:2000])))
    who = min(entities / 3.0, 1.0)
    evidence_words = sum(1 for w in ("data", "study", "report", "survey", "research", "statistics", "percent", "%", "according") if w in text.lower())
    what = min(evidence_words / 4.0, 1.0)
    time_words = sum(1 for w in ("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december", "2024", "2025", "2026", "yesterday", "last week", "last month") if w in text.lower())
    when = 1.0 if time_words >= 1 else 0.0
    source_patterns = len(_re.findall(r'according to|said|stated|reported|confirmed|cited', text.lower()))
    sources = min(source_patterns / 3.0, 1.0)
    counter_words = sum(1 for w in ("however", "on the other hand", "critics", "opponents", "but some", "alternatively", "in contrast", "disagree") if w in text.lower())
    counter = 1.0 if counter_words >= 1 else 0.0
    score = _clamp(who * 0.2 + what * 0.25 + when * 0.15 + sources * 0.25 + counter * 0.15, 0.05)
    return {"score": _round(score), "who": _round(who), "what": _round(what), "when": _round(when), "sources": _round(sources), "counter_view": _round(counter)}


def compute_construction(rhetoric: dict, argumentation: dict, completeness: dict) -> dict:
    r, a, c = max(rhetoric["score"], 0.01), max(argumentation["score"], 0.01), max(completeness["score"], 0.01)
    score = _clamp((r ** 0.40) * (a ** 0.35) * (c ** 0.25), 0.01)
    return {"score": _round(score), "rhetoric": rhetoric, "argumentation": argumentation, "completeness": completeness}


# ═══════════════════════════════════════════
# DIMENSION 2: VERIFICATION
# ═══════════════════════════════════════════

def compute_evidence(fact_checks: list) -> dict:
    if not fact_checks:
        return {"score": 0.65, "status": "no_checks", "checks": 0, "has_data": False}
    total_weight = 0
    weighted_sum = 0
    for fc in fact_checks:
        tier = fc.get("checker_tier", "U")
        rating = (fc.get("rating", "") or fc.get("textualRating", "")).lower()
        tw = CHECKER_TIER_WEIGHT.get(tier, 0.2)
        verdict = 0
        for key, val in VERDICT_SCORE.items():
            if key in rating:
                verdict = val
                break
        weighted_sum += tw * verdict
        total_weight += tw
    if total_weight == 0:
        return {"score": 0.60, "status": "unrated", "checks": len(fact_checks), "has_data": False}
    avg = weighted_sum / total_weight
    score = _clamp(0.50 + avg * 0.50, 0.0)
    status = "confirmed" if score >= 0.65 else "disputed" if score <= 0.35 else "mixed"
    return {"score": _round(score), "status": status, "checks": len(fact_checks)}


def compute_source(factuality: str = None, bias: str = None) -> dict:
    if not factuality:
        return {"score": 0.60, "factuality": "unknown", "bias": bias or "unknown", "has_data": False}
    s = FACTUALITY_MAP.get(factuality.lower(), 0.50)
    return {"score": _round(s), "factuality": factuality, "bias": bias or "unknown"}


def compute_diversity(text: str) -> dict:
    import re as _re
    attributions = _re.findall(r'according to|said|stated|reported|confirmed|cited|told|noted|argued|claimed', text.lower())
    named = len(_re.findall(r'[A-Z][a-z]+ [A-Z][a-z]+(?:\s(?:said|stated|told|reported|argued))', text[:3000]))
    anonymous = sum(1 for w in ("sources say", "sources said", "insiders", "unnamed", "anonymous") if w in text.lower())
    total = max(len(attributions), 1)
    named_ratio = min(named / total, 1.0) if named > 0 else 0.3
    anon_penalty = min(anonymous / total, 0.5)
    categories = set()
    if any(w in text.lower() for w in ("government", "ministry", "official", "department")): categories.add("govt")
    if any(w in text.lower() for w in ("study", "research", "university", "professor", "journal")): categories.add("academic")
    if any(w in text.lower() for w in ("reported", "newspaper", "media", "channel")): categories.add("media")
    if any(w in text.lower() for w in ("ngo", "organization", "foundation", "charity")): categories.add("ngo")
    cat_score = min(len(categories) / 4.0, 1.0)
    score = _clamp(cat_score * 0.40 + named_ratio * 0.35 + (1.0 - anon_penalty) * 0.25, 0.05)
    return {"score": _round(score), "categories": len(categories), "named_ratio": _round(named_ratio), "anonymous_count": anonymous}


def compute_temporal() -> dict:
    return {"score": 0.60, "status": "insufficient_data", "has_data": False, "note": "Requires accumulated analysis history"}


def compute_verification(evidence: dict, source: dict, diversity: dict, temporal: dict) -> dict:
    # Weight only axes that have actual data — don't dilute with 0.5/0.6 placeholders
    axes = [
        (evidence["score"], 0.40, evidence.get("has_data", True)),
        (source["score"], 0.25, source.get("has_data", True)),
        (diversity["score"], 0.20, diversity.get("has_data", True)),
        (temporal["score"], 0.15, temporal.get("has_data", True)),
    ]
    active = [(s, w) for s, w, has in axes if has]
    if not active:
        # No real data at all — use evidence default only
        score = evidence["score"]
    else:
        total_w = sum(w for _, w in active)
        # Weighted geometric mean over active axes only
        log_sum = sum((w / total_w) * math.log(max(s, 0.01)) for s, w in active)
        score = _clamp(math.exp(log_sum), 0.01)
    return {"score": _round(score), "evidence": evidence, "source": source, "diversity": diversity, "temporal": temporal}


# ═══════════════════════════════════════════
# DIMENSION 3: INTENT
# ═══════════════════════════════════════════

def detect_genre(text: str, source_name: str = "") -> str:
    lower = text[:500].lower()
    sl = source_name.lower()
    if sl in ("ap", "reuters", "afp", "associated press"): return "wire_report"
    if "opinion" in lower or "editorial" in lower: return "editorial"
    if any(w in lower for w in ("i think", "i believe", "in my view")): return "opinion"
    if any(w in sl for w in ("espn", "sport")): return "sports"
    if any(w in lower for w in ("twitter", "reddit", "posted", "tweeted")): return "social_media"
    if any(w in lower for w in ("press release", "is pleased to")): return "press_release"
    return "news_article"


def extract_quoted_speech(text: str) -> tuple:
    quotes = re.findall(r'["\u201c\u201d\u2018\u2019\xab\xbb]([^"\u201c\u201d\u2018\u2019\xab\xbb]{10,})["\u201c\u201d\u2018\u2019\xab\xbb]', text)
    editorial = text
    for q in quotes:
        editorial = editorial.replace(q, "")
    return editorial.strip(), " ".join(quotes)


def compute_tone(text: str, raw_toxicity: float, sentiment_compound: float, source_name: str = "") -> dict:
    editorial, quoted = extract_quoted_speech(text)
    genre = detect_genre(text, source_name)
    baseline = GENRE_BASELINES.get(genre, 0.06)
    adjusted_tox = max(raw_toxicity - baseline, 0) / max(1.0 - baseline, 0.01)
    quote_ratio = len(quoted) / max(len(text), 1)
    editorial_tox = adjusted_tox * (1.0 - quote_ratio * 0.6)
    words = text.lower().split()
    agg = sum(1 for w in words if w.strip(".,!?;:") in AGGRESSION_WORDS)
    bigrams = [f"{words[i]} {words[i+1]}" for i in range(len(words)-1)] if len(words) > 1 else []
    agg += sum(1 for b in bigrams if b in AGGRESSION_WORDS)
    hostility = _clamp(agg / max(len(words), 1) * 20, 0, 1.0)
    tox_pen = editorial_tox * 0.30
    host_pen = hostility * 0.40
    sent_pen = abs(sentiment_compound) * 0.30
    score = _clamp(1.0 - tox_pen - host_pen - sent_pen, 0.05)
    return {"score": _round(score), "raw_toxicity": _round(raw_toxicity), "adjusted_toxicity": _round(editorial_tox), "hostility": _round(hostility), "sentiment_extremity": _round(abs(sentiment_compound)), "genre": genre, "quote_ratio": _round(quote_ratio), "penalties": {"toxicity": _round(tox_pen), "hostility": _round(host_pen), "sentiment": _round(sent_pen)}}


def compute_manipulation(text: str) -> dict:
    lower = text.lower()
    words = lower.split()
    sentences = [s.strip() for s in re.split(r'[.!?]+', text) if len(s.strip()) > 5]
    urgency = sum(1 for p in URGENCY_PHRASES if p in lower) / max(len(sentences), 1)
    cta = 1.0 if any(w in lower for w in ("sign the petition", "call your", "share this", "donate", "subscribe", "join us", "take action")) else 0.0
    emo_words = sum(1 for w in words if w.strip(".,!?;:") in EMOTIVE_WORDS)
    if len(sentences) >= 4:
        first_q = sentences[:len(sentences)//4]
        last_q = sentences[-len(sentences)//4:]
        first_emo = sum(1 for s in first_q for w in s.lower().split() if w.strip(".,!?;:") in EMOTIVE_WORDS) / max(len(first_q), 1)
        last_emo = sum(1 for s in last_q for w in s.lower().split() if w.strip(".,!?;:") in EMOTIVE_WORDS) / max(len(last_q), 1)
        escalation = _clamp(last_emo - first_emo, 0, 1.0)
    else:
        escalation = 0.0
    binary = sum(1 for p in ("either you", "you're either", "with us or", "no middle ground", "only two", "us vs them", "us versus them") if p in lower)
    binary_score = min(binary * 0.3, 1.0)
    # Aggression density — hostile framing IS manipulation pressure
    agg_count = sum(1 for w in words if w.strip(".,!?;:") in AGGRESSION_WORDS)
    agg_density = min(agg_count / max(len(words), 1) * 15, 1.0)
    raw = (urgency * 0.20 + cta * 0.15 + escalation * 0.20 + binary_score * 0.10
           + min(emo_words / max(len(words), 1) * 10, 1.0) * 0.15 + agg_density * 0.20)
    pressure = _clamp(raw, 0, 1.0)
    score = _clamp(1.0 - pressure, 0.05)
    return {"score": _round(score), "pressure": _round(pressure), "urgency": _round(urgency), "cta": cta > 0, "escalation": _round(escalation), "binary_framing": _round(binary_score)}


def compute_narrative_direction(text: str, sentiment_compound: float) -> dict:
    lower = text.lower()
    trust_words = sum(1 for w in ("confirmed", "proven", "established", "verified", "evidence shows", "data confirms") if w in lower)
    skeptic_words = sum(1 for w in ("questions remain", "unverified", "alleged", "so-called", "disputed", "doubtful", "skeptics") if w in lower)
    hope_words = sum(1 for w in ("progress", "improvement", "breakthrough", "success", "opportunity", "growth", "promising") if w in lower)
    fear_words = sum(1 for w in ("threat", "danger", "risk", "crisis", "catastrophe", "collapse", "emergency", "alarming") if w in lower)
    horizontal = _clamp((trust_words - skeptic_words) / 5.0, -1.0, 1.0)
    vertical = _clamp((hope_words - fear_words) / 5.0, -1.0, 1.0)
    magnitude = min(math.sqrt(horizontal**2 + vertical**2), 1.414) / 1.414
    score = _clamp(1.0 - magnitude * 1.5, 0.05)
    direction = ""
    if abs(horizontal) > 0.2 or abs(vertical) > 0.2:
        h_label = "trusting" if horizontal > 0.2 else "skeptical" if horizontal < -0.2 else ""
        v_label = "hopeful" if vertical > 0.2 else "fearful" if vertical < -0.2 else ""
        direction = f"{v_label} + {h_label}".strip(" +") if h_label or v_label else "neutral"
    else:
        direction = "neutral"
    return {"score": _round(score), "horizontal": _round(horizontal), "vertical": _round(vertical), "magnitude": _round(magnitude), "direction": direction}


def compute_intent(tone: dict, manipulation: dict, narrative: dict) -> dict:
    t, m, n = max(tone["score"], 0.01), max(manipulation["score"], 0.01), max(narrative["score"], 0.01)
    score = _clamp((t ** 0.35) * (m ** 0.40) * (n ** 0.25), 0.01)
    return {"score": _round(score), "tone": tone, "manipulation": manipulation, "narrative": narrative}


# ═══════════════════════════════════════════
# HEADLINE: CLARITY SCORE
# ═══════════════════════════════════════════

def compute_full_score(techniques: list, fact_checks: list, toxicity_score: float,
                       sentiment_compound: float, source_factuality: str = None,
                       source_bias: str = None, text: str = "", source_name: str = "",
                       claims: list = None) -> dict:
    # Dimension 1: Construction
    rhetoric = compute_rhetoric(techniques)
    argumentation = compute_argumentation(text, techniques, claims)
    completeness = compute_completeness(text, claims)
    construction = compute_construction(rhetoric, argumentation, completeness)

    # Dimension 2: Verification
    evidence = compute_evidence(fact_checks)
    source = compute_source(source_factuality, source_bias)
    diversity = compute_diversity(text)
    temporal = compute_temporal()
    verification = compute_verification(evidence, source, diversity, temporal)

    # Dimension 3: Intent
    tone = compute_tone(text, toxicity_score, sentiment_compound, source_name)
    manipulation = compute_manipulation(text)
    narrative = compute_narrative_direction(text, sentiment_compound)
    intent = compute_intent(tone, manipulation, narrative)

    # Headline
    c, v, i = max(construction["score"], 0.01), max(verification["score"], 0.01), max(intent["score"], 0.01)
    clarity = _clamp((c * v * i) ** (1/3), 0.01)

    # Confidence
    if techniques:
        avg_conf = sum(t.get("confidence", 0) for t in techniques) / len(techniques)
    else:
        avg_conf = 0
    band = "high" if avg_conf >= 0.8 else "medium" if avg_conf >= 0.5 else "low" if techniques else "n/a"

    return {
        "clarity_score": _round(clarity),
        "label": score_label(clarity),
        "color": score_color(clarity),
        "construction": construction,
        "verification": verification,
        "intent": intent,
        "confidence_band": band,
        "avg_confidence": _round(avg_conf),
        "scale": "0.0-1.0",
        "thresholds": {"high": 0.65, "moderate": 0.35, "low": 0.0},
    }
