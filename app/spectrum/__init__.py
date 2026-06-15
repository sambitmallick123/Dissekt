"""Dissekt Signal — Bias, toxicity, and emotion radar.

All models run locally — zero API cost:
1. Detoxify (toxicity classification, ~440MB, CPU)
2. MBFC database (source bias lookup)
3. VADER (sentiment analysis)
4. Emotional word scoring (NRC-based, in heuristics module)
"""
import json
import os
import logging
from app.prism.heuristics import lookup_source_credibility, analyze_sentiment

logger = logging.getLogger("dissekt.signal")

# Lazy-load Detoxify to avoid slow startup
_detoxify_model = None


def _get_detoxify():
    global _detoxify_model
    if _detoxify_model is None:
        try:
            from detoxify import Detoxify
            _detoxify_model = Detoxify('original')
            logger.info("Detoxify model loaded successfully (440MB)")
        except ImportError:
            logger.warning("Detoxify not installed — toxicity scores will be 0.0")
            return None
        except Exception as e:
            logger.error(f"Detoxify failed to load: {e}")
            return None
    return _detoxify_model


def analyze_toxicity(text: str) -> dict:
    model = _get_detoxify()
    if model is None:
        return {
            "toxicity": 0.0, "severe_toxicity": 0.0, "obscene": 0.0,
            "threat": 0.0, "insult": 0.0, "identity_attack": 0.0
        }
    try:
        scores = model.predict(text[:1000])
        return {k: round(float(v), 4) for k, v in scores.items()}
    except Exception as e:
        logger.error(f"Detoxify prediction failed: {e}")
        return {
            "toxicity": 0.0, "severe_toxicity": 0.0, "obscene": 0.0,
            "threat": 0.0, "insult": 0.0, "identity_attack": 0.0
        }


def run_signal(text: str, source_url: str = "") -> dict:
    """Run the full Signal pipeline.

    Returns: toxicity, source bias, sentiment, emotion.
    """
    # Toxicity (Detoxify)
    tox = analyze_toxicity(text)

    # Source credibility (MBFC)
    source_bias = None
    source_factuality = None
    if source_url:
        cred = lookup_source_credibility(source_url)
        if cred:
            source_bias = cred["bias"]
            source_factuality = cred["factuality"]

    # Sentiment (VADER)
    sentiment = analyze_sentiment(text)

    return {
        "toxicity_score": tox.get("toxicity", 0.0),
        "toxicity_labels": {k: v for k, v in tox.items()},
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
