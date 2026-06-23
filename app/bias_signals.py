"""
Dissekt — Representation & language signal tags (lexicon-based, descriptive).

These are DESCRIPTIVE tags, not scores. Each tag reports a linguistic pattern
that is present in the text, with the exact terms that triggered it, so a
journalist can judge for themselves. Nothing here feeds the Clarity Score.

Design principles:
  - Descriptive, never a verdict. "Doubt-casting language: 'so-called'" — not "biased".
  - Always carry evidence (the matched terms) so the tag is explainable.
  - Lexicon-based = fast, free, transparent, and language-explicit (English only).

References:
  Recasens, Danescu-Niculescu-Mizil & Jurafsky, ACL 2013 —
    "Linguistic Models for Analyzing and Detecting Biased Language"
    framing bias (subjective / one-sided terms) + epistemological bias
    (factive / assertive verbs, hedges that modify believability)
    https://aclanthology.org/P13-1162/
  Hooper, 1975 — factive / assertive verb classes
  Hyland, 2005 — hedging
  (Detoxify toxicity sub-labels are surfaced separately, from the Spectrum signal;
   see Borkan et al., WWW 2019 — https://arxiv.org/abs/1903.04561)
"""
import re
import logging

logger = logging.getLogger("dissekt.bias_signals")

# ── Epistemological bias: doubt-casting (undermine credibility) ──
DOUBT_MARKERS = {
    "so-called", "so called", "alleged", "allegedly", "claimed", "purported",
    "purportedly", "supposed", "supposedly", "would-be", "self-proclaimed",
    "self-styled", "ostensibly", "apparent", "reportedly",
}

# ── Epistemological bias: asserted certainty (boost credibility) ──
FACTIVE_ASSERT = {
    "revealed", "exposed", "proved", "proven", "confirmed", "demonstrated",
    "debunked", "uncovered", "established that", "the fact that",
}

# ── Epistemological bias: hedging (soften / distance) ──
HEDGES = {
    "may", "might", "could", "possibly", "perhaps", "apparently", "seemingly",
    "arguably", "somewhat", "relatively", "fairly", "largely", "in some sense",
    "to some extent", "it seems", "it appears",
}

# ── Framing bias: subjective intensifiers / one-sided certainty ──
SUBJECTIVE_INTENSIFIERS = {
    "clearly", "obviously", "undoubtedly", "undeniably", "surely", "naturally",
    "of course", "blatantly", "outrageously", "shockingly", "remarkably",
    "incredibly", "stunningly", "predictably", "inevitably", "unsurprisingly",
}

# ── Dehumanizing metaphor (group-as-threat) ──
DEHUMANIZING = {
    "flood", "floods", "flooding", "wave", "waves", "swarm", "swarms", "swarming",
    "infest", "infested", "infestation", "horde", "hordes", "invasion", "invading",
    "vermin", "parasite", "parasites", "plague", "plagued", "cancer", "scourge",
    "breeding", "overrun", "influx",
}

# group nouns used for generalization / dehumanization context
GROUP_NOUNS = {
    "immigrants", "migrants", "refugees", "muslims", "christians", "jews", "hindus",
    "women", "men", "blacks", "whites", "asians", "foreigners", "liberals",
    "conservatives", "elites", "politicians", "the poor", "the rich", "millennials",
    "boomers", "protesters", "activists", "minorities",
}

UNIVERSAL_QUANTIFIERS = {"all", "every", "always", "never", "none", "no", "they all", "those people"}


def _find_terms(text_lower: str, terms: set, limit: int = 4) -> list:
    """Return up to `limit` distinct terms from `terms` that appear in text (word-boundary)."""
    found = []
    for t in terms:
        # phrase or word; use boundaries for single tokens
        pat = re.escape(t)
        if " " in t:
            if t in text_lower:
                found.append(t)
        else:
            if re.search(rf"\b{pat}\b", text_lower):
                found.append(t)
        if len(found) >= limit:
            break
    return found


def _density(text_lower: str, terms: set) -> int:
    """Total occurrences of any term (rough density proxy)."""
    n = 0
    for t in terms:
        if " " in t:
            n += text_lower.count(t)
        else:
            n += len(re.findall(rf"\b{re.escape(t)}\b", text_lower))
    return n


def _detect_generalizations(text: str) -> list:
    """Find sweeping group generalizations: quantifier + group noun, or 'GROUP are/always'."""
    low = text.lower()
    hits = []
    for g in GROUP_NOUNS:
        # "<group> are/always/never/tend to ..."
        if re.search(rf"\b{re.escape(g)}\b\s+(are|always|never|tend to|all|can't|cannot|don't)\b", low):
            hits.append(g)
        # "all/every <group>"
        for q in ("all", "every", "those", "these"):
            if re.search(rf"\b{q}\s+{re.escape(g)}\b", low):
                hits.append(g)
    return list(dict.fromkeys(hits))[:4]


def detect_bias_signals(text: str) -> list:
    """
    Return a list of descriptive language-signal tags.

    Each tag:
      {
        "id": str,
        "label": str,           # short pill label
        "category": str,        # epistemological | framing | dehumanizing | generalization
        "severity": "info"|"warn",
        "evidence": [str, ...], # the terms that triggered it
        "explanation": str,     # one line for the expand view
      }
    """
    if not text or len(text.split()) < 30:
        return []
    low = text.lower()
    word_count = max(len(low.split()), 1)
    tags = []

    doubt = _find_terms(low, DOUBT_MARKERS)
    if doubt:
        tags.append({
            "id": "epi_doubt", "label": "Doubt-casting language", "category": "epistemological",
            "severity": "info", "evidence": doubt,
            "explanation": "Words that subtly question credibility without making a claim outright (epistemological bias).",
        })

    assertcert = _find_terms(low, FACTIVE_ASSERT)
    if assertcert:
        tags.append({
            "id": "epi_assert", "label": "Asserted certainty", "category": "epistemological",
            "severity": "info", "evidence": assertcert,
            "explanation": "Factive/assertive verbs that present contested points as settled fact (epistemological bias).",
        })

    hedge_n = _density(low, HEDGES)
    if hedge_n / word_count > 0.012:  # noticeably hedged
        tags.append({
            "id": "epi_hedge", "label": "Heavily hedged", "category": "epistemological",
            "severity": "info", "evidence": _find_terms(low, HEDGES),
            "explanation": "Frequent hedging softens or distances claims; can signal uncertainty or deniability.",
        })

    subj = _find_terms(low, SUBJECTIVE_INTENSIFIERS)
    if len(subj) >= 2:
        tags.append({
            "id": "frame_subj", "label": "One-sided framing", "category": "framing",
            "severity": "info", "evidence": subj,
            "explanation": "Subjective intensifiers that assume agreement and push a single viewpoint (framing bias).",
        })

    dehum = _find_terms(low, DEHUMANIZING)
    # only flag dehumanizing when a group is also present (avoid 'flood' in a weather story)
    if dehum and any(re.search(rf"\b{re.escape(g)}\b", low) for g in GROUP_NOUNS):
        tags.append({
            "id": "dehumanizing", "label": "Dehumanizing metaphor", "category": "dehumanizing",
            "severity": "warn", "evidence": dehum,
            "explanation": "Threat/vermin/disaster metaphors applied to groups of people.",
        })

    gens = _detect_generalizations(text)
    if gens:
        tags.append({
            "id": "generalization", "label": "Sweeping generalization", "category": "generalization",
            "severity": "warn", "evidence": gens,
            "explanation": "Broad claims about an entire group; overlaps with hasty generalization.",
        })

    return tags
