"""Dissekt Spectrum — Source credibility and sentiment.

Runs locally — zero API cost:
1. MBFC database (source bias lookup)
2. VADER (sentiment analysis)
"""
import json
import os
import logging
from app.prism.heuristics import lookup_source_credibility, analyze_sentiment

logger = logging.getLogger("dissekt.signal")


def run_spectrum(text: str, source_url: str = "") -> dict:
    """Run the Spectrum pipeline. Returns: source credibility, sentiment."""
    source_bias = None
    source_factuality = None
    if source_url:
        cred = lookup_source_credibility(source_url)
        if cred:
            source_bias = cred["bias"]
            source_factuality = cred["factuality"]

    sentiment = analyze_sentiment(text)

    return {
        "source_bias": source_bias,
        "source_factuality": source_factuality,
        "sentiment": sentiment["label"],
        "sentiment_score": sentiment["compound"],
        "primary_emotion": "neutral",
        "emotion_scores": {},
    }


_MBFC_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'mbfc_database.json')


def _load_mbfc():
    try:
        with open(_MBFC_PATH) as f:
            return json.load(f)
    except Exception as e:
        logger.warning(f"Failed to load MBFC database: {e}")
        return {}


MBFC_DATABASE = _load_mbfc()
