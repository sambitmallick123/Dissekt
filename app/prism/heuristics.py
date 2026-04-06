"""Dissekt — Prism heuristic pre-filters (memory-optimized)."""

import re
from dataclasses import dataclass, field
from urllib.parse import urlparse


@dataclass
class HeuristicSignal:
    model: str
    technique: str
    confidence: float
    evidence: str
    detail: str = ""


@dataclass
class HeuristicResult:
    signals: list[HeuristicSignal] = field(default_factory=list)
    emotional_density: float = 0.0
    authority_count: int = 0
    absolute_count: int = 0
    claim_density: float = 0.0
    readability_grade: float = 0.0
    source_bias: str | None = None
    source_factuality: str | None = None
    sentiment_compound: float = 0.0
    is_duplicate: bool = False
    duplicate_similarity: float = 0.0

    @property
    def has_strong_signals(self) -> bool:
        return len([s for s in self.signals if s.confidence >= 0.7]) >= 2

    @property
    def signal_count(self) -> int:
        return len(self.signals)


# ============================================
# Emotion words (inline, no file loading)
# ============================================

EMOTION_WORDS = {
    "outrage", "fury", "rage", "angry", "furious", "disgusting", "appalling",
    "despicable", "vile", "hate", "hatred", "destroy", "attack", "enemy",
    "terrifying", "horrifying", "alarming", "dangerous", "threat", "crisis",
    "catastrophe", "disaster", "panic", "horror", "nightmare", "deadly",
    "devastating", "shocking", "frightening", "tragic", "heartbreaking",
    "suffering", "victim", "stunning", "unbelievable", "incredible",
    "unprecedented", "bombshell", "explosive", "sickening", "repulsive",
    "nauseating", "corrupt", "rotten", "toxic",
}


def score_emotional_density(text: str) -> tuple[float, list[str]]:
    words = re.findall(r'\b\w+\b', text.lower())
    if not words:
        return 0.0, []
    matched = [w for w in words if w in EMOTION_WORDS]
    density = len(matched) / len(words)
    return density, list(set(matched))


# ============================================
# Authority phrase detector
# ============================================

AUTHORITY_PATTERNS = [
    (r'\bexperts?\s+(?:say|claim|believe|warn|agree|confirm|suggest)\b', "experts say"),
    (r'\bstudies?\s+(?:show|prove|confirm|suggest|reveal|indicate|find)\b', "studies show"),
    (r'\bscientists?\s+(?:say|claim|believe|warn|agree|confirm)\b', "scientists say"),
    (r'\bresearchers?\s+(?:say|claim|believe|warn|agree|confirm|find)\b', "researchers say"),
    (r'\baccording\s+to\s+(?:experts?|sources?|reports?|officials?)\b', "according to unnamed"),
    (r'\beveryone\s+(?:knows?|agrees?|understands?)\b', "everyone knows"),
    (r'\bthe\s+science\s+(?:is\s+)?(?:clear|settled)\b', "science is settled"),
]


def detect_authority_phrases(text: str) -> list[tuple[str, str]]:
    matches = []
    text_lower = text.lower()
    for pattern, name in AUTHORITY_PATTERNS:
        found = re.findall(pattern, text_lower)
        for match in found:
            matches.append((match, name))
    return matches


# ============================================
# Absolute language scorer
# ============================================

ABSOLUTE_TERMS = {
    "always", "never", "all", "none", "every", "nobody", "everyone",
    "everything", "nothing", "completely", "totally", "absolutely",
    "entirely", "impossible", "guaranteed", "proven", "undeniable",
    "certainly", "definitely", "obviously", "clearly",
}


def score_absolute_language(text: str) -> tuple[float, list[str]]:
    words = re.findall(r'\b\w+\b', text.lower())
    sentences = [s.strip() for s in re.split(r'[.!?]+', text) if s.strip()]
    if not sentences:
        return 0.0, []
    matched = [w for w in words if w in ABSOLUTE_TERMS]
    density = len(matched) / max(len(sentences), 1)
    return density, list(set(matched))


# ============================================
# Source credibility (MBFC - inline dict)
# ============================================

MBFC_DATABASE = {
    "thewire.in": {"bias": "left-center", "factuality": "high"},
    "scroll.in": {"bias": "left-center", "factuality": "high"},
    "ndtv.com": {"bias": "left-center", "factuality": "high"},
    "opindia.com": {"bias": "right", "factuality": "mixed"},
    "theprint.in": {"bias": "center", "factuality": "high"},
    "republic.in": {"bias": "right", "factuality": "mixed"},
    "tagesschau.de": {"bias": "center", "factuality": "very-high"},
    "spiegel.de": {"bias": "left-center", "factuality": "high"},
    "bild.de": {"bias": "right-center", "factuality": "mixed"},
    "correctiv.org": {"bias": "center", "factuality": "very-high"},
    "nytimes.com": {"bias": "left-center", "factuality": "high"},
    "foxnews.com": {"bias": "right", "factuality": "mixed"},
    "cnn.com": {"bias": "left", "factuality": "mixed"},
    "bbc.com": {"bias": "center", "factuality": "very-high"},
    "reuters.com": {"bias": "center", "factuality": "very-high"},
    "apnews.com": {"bias": "center", "factuality": "very-high"},
    "breitbart.com": {"bias": "far-right", "factuality": "low"},
    "dailymail.co.uk": {"bias": "right", "factuality": "low"},
    "theguardian.com": {"bias": "left-center", "factuality": "high"},
    "bbc.co.uk": {"bias": "center", "factuality": "high"},
    "fullfact.org": {"bias": "center", "factuality": "very-high"},
}


def lookup_source_credibility(url: str) -> dict | None:
    try:
        domain = urlparse(url).netloc.lower().lstrip("www.")
    except Exception:
        return None
    if domain in MBFC_DATABASE:
        return MBFC_DATABASE[domain]
    parts = domain.split(".")
    for i in range(1, len(parts)):
        parent = ".".join(parts[i:])
        if parent in MBFC_DATABASE:
            return MBFC_DATABASE[parent]
    return None


# ============================================
# Sentiment (lazy-loaded VADER)
# ============================================

_vader = None

def analyze_sentiment(text: str) -> dict:
    global _vader
    if _vader is None:
        from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        _vader = SentimentIntensityAnalyzer()

    scores = _vader.polarity_scores(text)
    compound = scores["compound"]
    if compound >= 0.05:
        label = "positive"
    elif compound <= -0.05:
        label = "negative"
    else:
        label = "neutral"
    return {"compound": round(compound, 3), "label": label}


# ============================================
# Readability (lazy-loaded)
# ============================================

def analyze_readability(text: str) -> dict:
    if len(text) < 50:
        return {"grade_level": 0.0}
    try:
        import textstat
        fk = textstat.flesch_kincaid_grade(text)
        return {"grade_level": round(fk, 1)}
    except Exception:
        return {"grade_level": 0.0}


# ============================================
# Main: run all heuristics
# ============================================

def run_all_heuristics(text: str, source_url: str = "") -> HeuristicResult:
    result = HeuristicResult()

    # 1. Emotional density
    density, emotion_words = score_emotional_density(text)
    result.emotional_density = round(density, 4)
    if density > 0.03:
        conf = min(density / 0.06, 1.0)
        result.signals.append(HeuristicSignal(
            model="emotional_density", technique="loaded_language",
            confidence=round(conf, 2),
            evidence=f"Emotional word density: {density:.1%}",
            detail=f"Words: {', '.join(emotion_words[:5])}"
        ))

    # 2. Authority phrases
    authority_matches = detect_authority_phrases(text)
    result.authority_count = len(authority_matches)
    if len(authority_matches) >= 2:
        conf = min(len(authority_matches) / 4, 1.0)
        result.signals.append(HeuristicSignal(
            model="authority_detector", technique="appeal_to_authority",
            confidence=round(conf, 2),
            evidence=f"{len(authority_matches)} unnamed authority references",
            detail="; ".join([m[0] for m in authority_matches[:3]])
        ))

    # 3. Absolute language
    abs_density, abs_terms = score_absolute_language(text)
    result.absolute_count = len(abs_terms)
    if abs_density > 0.5:
        conf = min(abs_density / 1.5, 1.0)
        result.signals.append(HeuristicSignal(
            model="absolute_language", technique="hasty_generalization",
            confidence=round(conf, 2),
            evidence=f"Absolute language: {abs_density:.2f} per sentence",
            detail=f"Terms: {', '.join(abs_terms[:5])}"
        ))

    # 4. Source credibility
    if source_url:
        cred = lookup_source_credibility(source_url)
        if cred:
            result.source_bias = cred["bias"]
            result.source_factuality = cred["factuality"]
            if cred["factuality"] in ("low", "very-low"):
                result.signals.append(HeuristicSignal(
                    model="source_credibility", technique="missing_context",
                    confidence=0.5,
                    evidence=f"Source rated '{cred['factuality']}' factuality",
                    detail=f"Bias: {cred['bias']}"
                ))

    # 5. Sentiment
    sentiment = analyze_sentiment(text)
    result.sentiment_compound = sentiment["compound"]

    return result