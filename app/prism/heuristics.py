"""Dissekt — Prism heuristic pre-filters.

7 statistical models that catch manipulation patterns at ZERO LLM cost.
These run BEFORE any API call. If they find strong signals, the LLM call
can be skipped entirely (for Brief Mode) or informed (for Detailed Mode).

Models:
1. Emotional word density (NRC Emotion Lexicon)
2. Authority phrase detector (regex patterns)
3. Absolute language scorer
4. Claim density estimator (sentence-level)
5. Source credibility scorer (MBFC database)
6. Readability analyzer (Flesch-Kincaid / Gunning Fog)
7. Duplicate detector (MinHash + LSH)
"""

import re
import json
import os
from dataclasses import dataclass, field
from urllib.parse import urlparse
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import textstat


# ============================================
# Data structures
# ============================================

@dataclass
class HeuristicSignal:
    """A signal detected by a heuristic model."""
    model: str
    technique: str  # maps to technique taxonomy name
    confidence: float  # 0.0 - 1.0
    evidence: str  # what triggered it
    detail: str = ""  # extra info


@dataclass
class HeuristicResult:
    """Combined output from all heuristic models."""
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
        """True if heuristics found enough to skip LLM for Brief Mode."""
        return len([s for s in self.signals if s.confidence >= 0.7]) >= 2

    @property
    def signal_count(self) -> int:
        return len(self.signals)


# ============================================
# 1. Emotional word density
# ============================================

# NRC Emotion Lexicon — simplified version
# In production, load the full lexicon from file
# Download: https://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm
EMOTION_WORDS = {
    "anger": {"outrage", "fury", "rage", "angry", "furious", "enraged", "infuriating",
              "disgusting", "appalling", "despicable", "vile", "abhorrent", "revolting",
              "hate", "hatred", "destroy", "attack", "fight", "war", "battle", "enemy"},
    "fear": {"terrifying", "horrifying", "alarming", "dangerous", "threat", "crisis",
             "catastrophe", "disaster", "panic", "horror", "nightmare", "deadly",
             "fatal", "devastating", "shocking", "frightening", "scary", "risk"},
    "sadness": {"tragic", "heartbreaking", "devastating", "painful", "suffering",
                "victim", "loss", "grief", "mourning", "tears", "misery", "despair"},
    "surprise": {"shocking", "stunning", "unbelievable", "incredible", "astonishing",
                 "unprecedented", "bombshell", "explosive", "breaking", "revelation"},
    "disgust": {"disgusting", "sickening", "repulsive", "nauseating", "gross",
                "vile", "filthy", "corrupt", "rotten", "toxic", "putrid"},
}

ALL_EMOTION_WORDS = set()
for words in EMOTION_WORDS.values():
    ALL_EMOTION_WORDS.update(words)


def score_emotional_density(text: str) -> tuple[float, list[str]]:
    """Score emotional word density. Returns (density, matched_words)."""
    words = re.findall(r'\b\w+\b', text.lower())
    if not words:
        return 0.0, []

    matched = [w for w in words if w in ALL_EMOTION_WORDS]
    density = len(matched) / len(words)
    return density, list(set(matched))


# ============================================
# 2. Authority phrase detector
# ============================================

AUTHORITY_PATTERNS = [
    (r'\bexperts?\s+(?:say|claim|believe|warn|agree|confirm|suggest)\b', "experts say"),
    (r'\bstudies?\s+(?:show|prove|confirm|suggest|reveal|indicate|find)\b', "studies show"),
    (r'\bscientists?\s+(?:say|claim|believe|warn|agree|confirm|discover)\b', "scientists say"),
    (r'\bresearchers?\s+(?:say|claim|believe|warn|agree|confirm|find)\b', "researchers say"),
    (r'\baccording\s+to\s+(?:experts?|sources?|reports?|officials?)\b', "according to unnamed source"),
    (r'\b(?:it\s+is|it\'s)\s+(?:well\s+)?known\s+that\b', "it is known that"),
    (r'\beveryone\s+(?:knows?|agrees?|understands?)\b', "everyone knows"),
    (r'\bthe\s+science\s+(?:is\s+)?(?:clear|settled)\b', "the science is clear"),
    (r'\bmany\s+(?:people|experts?|scientists?)\s+(?:believe|say|think)\b', "many people believe"),
    (r'\breports?\s+(?:say|show|indicate|suggest|reveal|confirm)\b', "reports say"),
]


def detect_authority_phrases(text: str) -> list[tuple[str, str]]:
    """Find unnamed authority appeals. Returns list of (matched_text, pattern_name)."""
    matches = []
    text_lower = text.lower()
    for pattern, name in AUTHORITY_PATTERNS:
        found = re.findall(pattern, text_lower)
        for match in found:
            matches.append((match, name))
    return matches


# ============================================
# 3. Absolute language scorer
# ============================================

ABSOLUTE_TERMS = {
    "always", "never", "all", "none", "every", "nobody", "everyone", "everything",
    "nothing", "completely", "totally", "absolutely", "entirely", "impossible",
    "guaranteed", "proven", "undeniable", "unquestionable", "without exception",
    "no doubt", "certainly", "definitely", "obviously", "clearly",
}


def score_absolute_language(text: str) -> tuple[float, list[str]]:
    """Score density of absolute terms. Returns (density_per_sentence, matched_terms)."""
    words = re.findall(r'\b\w+\b', text.lower())
    sentences = [s.strip() for s in re.split(r'[.!?]+', text) if s.strip()]

    if not sentences:
        return 0.0, []

    # Check for multi-word absolute phrases
    text_lower = text.lower()
    matched = []
    for term in ABSOLUTE_TERMS:
        if " " in term:
            if term in text_lower:
                matched.append(term)
        else:
            if term in words:
                matched.append(term)

    density = len(matched) / max(len(sentences), 1)
    return density, list(set(matched))


# ============================================
# 4. Claim density estimator
# ============================================

# Patterns that indicate a verifiable claim
CLAIM_INDICATORS = [
    r'\b\d+\s*(?:%|percent|million|billion|thousand)\b',  # Statistics
    r'\b(?:increased|decreased|rose|fell|dropped|grew|doubled|tripled)\s+(?:by|to)\b',  # Trends
    r'\b(?:according to|based on|data shows?|statistics show)\b',  # Data references
    r'\b(?:is|are|was|were)\s+(?:the\s+)?(?:largest|smallest|highest|lowest|best|worst|first|only)\b',  # Superlatives
    r'\b(?:caused?|leads?\s+to|results?\s+in|linked?\s+to|associated\s+with)\b',  # Causal claims
    r'\b(?:will|shall|going\s+to)\s+(?:be|cause|lead|result|happen)\b',  # Predictions
]


def estimate_claim_density(text: str) -> tuple[float, int]:
    """Estimate how many verifiable claims per sentence. Returns (density, claim_count)."""
    sentences = [s.strip() for s in re.split(r'[.!?]+', text) if len(s.strip()) > 10]
    if not sentences:
        return 0.0, 0

    claim_count = 0
    for sentence in sentences:
        for pattern in CLAIM_INDICATORS:
            if re.search(pattern, sentence, re.IGNORECASE):
                claim_count += 1
                break

    density = claim_count / len(sentences)
    return density, claim_count


# ============================================
# 5. Source credibility scorer (MBFC)
# ============================================

# Media Bias/Fact Check database — subset for MVP
# In production, load full database from file (~6000+ entries)
# Data source: https://mediabiasfactcheck.com/
MBFC_DATABASE = {
    # India
    "thewire.in": {"bias": "left-center", "factuality": "high"},
    "scroll.in": {"bias": "left-center", "factuality": "high"},
    "ndtv.com": {"bias": "left-center", "factuality": "high"},
    "opindia.com": {"bias": "right", "factuality": "mixed"},
    "swarajyamag.com": {"bias": "right", "factuality": "mixed"},
    "theprint.in": {"bias": "center", "factuality": "high"},
    "livemint.com": {"bias": "center", "factuality": "high"},
    "hindustantimes.com": {"bias": "center", "factuality": "high"},
    "indiatoday.in": {"bias": "center", "factuality": "mixed"},
    "timesofindia.indiatimes.com": {"bias": "center", "factuality": "mixed"},
    "republic.in": {"bias": "right", "factuality": "mixed"},
    "newslaundry.com": {"bias": "left-center", "factuality": "high"},

    # Germany
    "tagesschau.de": {"bias": "center", "factuality": "very-high"},
    "spiegel.de": {"bias": "left-center", "factuality": "high"},
    "bild.de": {"bias": "right-center", "factuality": "mixed"},
    "faz.net": {"bias": "right-center", "factuality": "high"},
    "sueddeutsche.de": {"bias": "left-center", "factuality": "high"},
    "zeit.de": {"bias": "left-center", "factuality": "high"},
    "welt.de": {"bias": "right-center", "factuality": "high"},
    "correctiv.org": {"bias": "center", "factuality": "very-high"},
    "taz.de": {"bias": "left", "factuality": "high"},

    # US
    "nytimes.com": {"bias": "left-center", "factuality": "high"},
    "washingtonpost.com": {"bias": "left-center", "factuality": "high"},
    "foxnews.com": {"bias": "right", "factuality": "mixed"},
    "cnn.com": {"bias": "left", "factuality": "mixed"},
    "bbc.com": {"bias": "center", "factuality": "very-high"},
    "reuters.com": {"bias": "center", "factuality": "very-high"},
    "apnews.com": {"bias": "center", "factuality": "very-high"},
    "breitbart.com": {"bias": "far-right", "factuality": "low"},
    "infowars.com": {"bias": "far-right", "factuality": "very-low"},
    "dailywire.com": {"bias": "right", "factuality": "mixed"},
    "huffpost.com": {"bias": "left", "factuality": "mixed"},
    "politico.com": {"bias": "center", "factuality": "high"},
    "theintercept.com": {"bias": "left", "factuality": "high"},

    # UK
    "bbc.co.uk": {"bias": "center", "factuality": "high"},
    "theguardian.com": {"bias": "left-center", "factuality": "high"},
    "dailymail.co.uk": {"bias": "right", "factuality": "low"},
    "telegraph.co.uk": {"bias": "right-center", "factuality": "high"},
    "independent.co.uk": {"bias": "left-center", "factuality": "high"},
    "mirror.co.uk": {"bias": "left-center", "factuality": "mixed"},
    "thesun.co.uk": {"bias": "right", "factuality": "low"},
    "fullfact.org": {"bias": "center", "factuality": "very-high"},
    "channel4.com": {"bias": "center", "factuality": "high"},
}


def lookup_source_credibility(url: str) -> dict | None:
    """Look up source bias and factuality from MBFC database."""
    try:
        domain = urlparse(url).netloc.lower().lstrip("www.")
    except Exception:
        return None

    # Direct match
    if domain in MBFC_DATABASE:
        return MBFC_DATABASE[domain]

    # Try parent domain (e.g., news.bbc.co.uk → bbc.co.uk)
    parts = domain.split(".")
    for i in range(1, len(parts)):
        parent = ".".join(parts[i:])
        if parent in MBFC_DATABASE:
            return MBFC_DATABASE[parent]

    return None


# ============================================
# 6. Readability analyzer
# ============================================

def analyze_readability(text: str) -> dict:
    """Compute readability metrics. Very low scores may indicate
    content designed for emotional impact rather than informing."""
    if len(text) < 50:
        return {"flesch_kincaid": 0.0, "gunning_fog": 0.0, "grade_level": 0.0}

    fk = textstat.flesch_kincaid_grade(text)
    fog = textstat.gunning_fog(text)
    avg_grade = (fk + fog) / 2

    return {
        "flesch_kincaid": round(fk, 1),
        "gunning_fog": round(fog, 1),
        "grade_level": round(avg_grade, 1),
    }


# ============================================
# 7. VADER Sentiment (for Signal, but useful here too)
# ============================================

_vader = SentimentIntensityAnalyzer()


def analyze_sentiment(text: str) -> dict:
    """VADER sentiment analysis. Returns compound score and label."""
    scores = _vader.polarity_scores(text)
    compound = scores["compound"]

    if compound >= 0.05:
        label = "positive"
    elif compound <= -0.05:
        label = "negative"
    else:
        label = "neutral"

    return {
        "compound": round(compound, 3),
        "positive": round(scores["pos"], 3),
        "negative": round(scores["neg"], 3),
        "neutral": round(scores["neu"], 3),
        "label": label,
    }


# ============================================
# Main entry point: run all heuristics
# ============================================

def run_all_heuristics(text: str, source_url: str = "") -> HeuristicResult:
    """Run all 7 heuristic models on the text. Returns combined result."""
    result = HeuristicResult()

    # 1. Emotional word density
    density, emotion_words = score_emotional_density(text)
    result.emotional_density = round(density, 4)
    if density > 0.03:  # More than 3% emotional words
        conf = min(density / 0.06, 1.0)  # Normalize: 6%+ = full confidence
        result.signals.append(HeuristicSignal(
            model="emotional_density",
            technique="loaded_language",
            confidence=round(conf, 2),
            evidence=f"Emotional word density: {density:.1%}",
            detail=f"Words found: {', '.join(emotion_words[:5])}"
        ))

    # 2. Authority phrase detection
    authority_matches = detect_authority_phrases(text)
    result.authority_count = len(authority_matches)
    if len(authority_matches) >= 2:
        conf = min(len(authority_matches) / 4, 1.0)
        result.signals.append(HeuristicSignal(
            model="authority_detector",
            technique="appeal_to_authority",
            confidence=round(conf, 2),
            evidence=f"{len(authority_matches)} unnamed authority references",
            detail="; ".join([m[0] for m in authority_matches[:3]])
        ))

    # 3. Absolute language
    abs_density, abs_terms = score_absolute_language(text)
    result.absolute_count = len(abs_terms)
    if abs_density > 0.5:  # More than 0.5 absolute terms per sentence
        conf = min(abs_density / 1.5, 1.0)
        result.signals.append(HeuristicSignal(
            model="absolute_language",
            technique="hasty_generalization",
            confidence=round(conf, 2),
            evidence=f"Absolute language density: {abs_density:.2f} per sentence",
            detail=f"Terms: {', '.join(abs_terms[:5])}"
        ))

    # 4. Claim density
    claim_density, claim_count = estimate_claim_density(text)
    result.claim_density = round(claim_density, 2)

    # 5. Source credibility
    if source_url:
        cred = lookup_source_credibility(source_url)
        if cred:
            result.source_bias = cred["bias"]
            result.source_factuality = cred["factuality"]
            if cred["factuality"] in ("low", "very-low"):
                result.signals.append(HeuristicSignal(
                    model="source_credibility",
                    technique="missing_context",
                    confidence=0.5,
                    evidence=f"Source rated '{cred['factuality']}' factuality by MBFC",
                    detail=f"Bias: {cred['bias']}"
                ))

    # 6. Readability
    readability = analyze_readability(text)
    result.readability_grade = readability["grade_level"]

    # 7. Sentiment
    sentiment = analyze_sentiment(text)
    result.sentiment_compound = sentiment["compound"]

    return result
