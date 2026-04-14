"""Dissekt Signal — Bias, toxicity, and emotion radar.

All models run locally — zero API cost:
1. Detoxify (toxicity classification, ~440MB, CPU)
2. MBFC database (source bias lookup)
3. VADER (sentiment analysis)
4. Emotional word scoring (NRC-based, in heuristics module)
"""

import logging
from app.prism.heuristics import lookup_source_credibility, analyze_sentiment

logger = logging.getLogger("dissekt.signal")

# Lazy-load Detoxify to avoid slow startup
_detoxify_model = None


def _get_detoxify():
    """Lazy-load Detoxify model on first use."""
    global _detoxify_model
    if _detoxify_model is None:
        try:
            from detoxify import Detoxify
            _detoxify_model = Detoxify("original")
            logger.info("Detoxify model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load Detoxify: {e}")
            _detoxify_model = "failed"
    return _detoxify_model if _detoxify_model != "failed" else None


def analyze_toxicity(text: str) -> dict:
    """Run Detoxify toxicity classification.

    Returns scores for: toxicity, severe_toxicity, obscene,
    threat, insult, identity_attack (all 0.0-1.0).
    """
    model = _get_detoxify()
    if model is None:
        return {"toxicity": 0.0, "labels": {}}

    try:
        results = model.predict(text[:2000])  # Limit input length
        # Results come as {label: [score]} — flatten
        labels = {k: round(float(v[0]) if isinstance(v, list) else float(v), 4)
                  for k, v in results.items()}
        toxicity = labels.get("toxicity", 0.0)
        return {"toxicity": toxicity, "labels": labels}
    except Exception as e:
        logger.error(f"Detoxify error: {e}")
        return {"toxicity": 0.0, "labels": {}}


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
        "toxicity_score": tox["toxicity"],
        "toxicity_labels": tox["labels"],
        "source_bias": source_bias,
        "source_factuality": source_factuality,
        "sentiment": sentiment["label"],
        "sentiment_score": sentiment["compound"],
        "primary_emotion": "neutral",  # TODO: XLM-RoBERTa in Stage 2
        "emotion_scores": {},
    }
