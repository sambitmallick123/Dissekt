"""Dissekt Signal — lightweight version (no Detoxify/torch)."""

from app.prism.heuristics import lookup_source_credibility, analyze_sentiment


def run_signal(text: str, source_url: str = "") -> dict:
    # Source credibility (MBFC)
    source_bias = None
    source_factuality = None
    if source_url:
        cred = lookup_source_credibility(source_url)
        if cred:
            source_bias = cred["bias"]
            source_factuality = cred["factuality"]

    # Sentiment (VADER - lazy loaded)
    sentiment = analyze_sentiment(text)

    return {
        "toxicity_score": 0.0,
        "toxicity_labels": {},
        "source_bias": source_bias,
        "source_factuality": source_factuality,
        "sentiment": sentiment["label"],
        "sentiment_score": sentiment["compound"],
        "primary_emotion": "neutral",
        "emotion_scores": {},
    }