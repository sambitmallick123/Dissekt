"""Dissekt Pulse — Coordination Detection.

Detects when multiple similar claims appear in a short time window,
suggesting coordinated amplification (bot farms, astroturfing, troll armies).
"""
import logging
import time
from datetime import datetime, timezone, timedelta

logger = logging.getLogger("dissekt.pulse")


async def detect_coordination(text: str, similar_claims: list[dict]) -> dict:
    """Analyze similar claims for coordination patterns.
    
    Signals:
    - Temporal clustering: many similar claims in < 24 hours
    - Source diversity: same claim from very different source types
    - Volume spike: unusual number of similar claims
    """
    if not similar_claims or len(similar_claims) < 2:
        return {"detected": False, "signals": [], "risk_level": "none"}
    
    signals = []
    
    # 1. Volume check: how many similar claims exist?
    count = len(similar_claims)
    if count >= 5:
        signals.append({
            "type": "volume_spike",
            "detail": f"{count} similar claims detected in the knowledge base",
            "severity": "high" if count >= 10 else "medium",
        })
    elif count >= 3:
        signals.append({
            "type": "volume_notable",
            "detail": f"{count} similar claims found — this narrative is spreading",
            "severity": "low",
        })
    
    # 2. Similarity clustering: are they very similar (>85%)?
    high_similarity = [c for c in similar_claims if c.get("similarity", 0) > 0.85]
    if len(high_similarity) >= 2:
        signals.append({
            "type": "near_duplicate",
            "detail": f"{len(high_similarity)} near-identical versions of this claim detected (>85% similarity)",
            "severity": "high",
        })
    
    # 3. Temporal clustering: check timestamps
    timestamps = []
    for c in similar_claims:
        ts = c.get("timestamp") or c.get("metadata", {}).get("timestamp")
        if ts:
            try:
                timestamps.append(float(ts))
            except (ValueError, TypeError):
                pass
    
    if len(timestamps) >= 2:
        timestamps.sort()
        time_span = timestamps[-1] - timestamps[0]
        if time_span < 86400 and len(timestamps) >= 3:  # <24 hours, 3+ claims
            signals.append({
                "type": "temporal_burst",
                "detail": f"{len(timestamps)} similar claims within {time_span/3600:.1f} hours — possible coordinated push",
                "severity": "high",
            })
        elif time_span < 604800 and len(timestamps) >= 3:  # <7 days
            signals.append({
                "type": "temporal_cluster",
                "detail": f"{len(timestamps)} similar claims within {time_span/86400:.1f} days",
                "severity": "medium",
            })
    
    # 4. Technique overlap: do all similar claims use the same techniques?
    all_techniques = []
    for c in similar_claims:
        techs = c.get("techniques", [])
        all_techniques.extend(techs)
    
    if all_techniques:
        from collections import Counter
        tech_counts = Counter(all_techniques)
        dominant = tech_counts.most_common(1)[0]
        if dominant[1] >= 3:
            signals.append({
                "type": "technique_pattern",
                "detail": f"'{dominant[0].replace('_', ' ')}' appears in {dominant[1]} similar claims — consistent manipulation pattern",
                "severity": "medium",
            })
    
    # Determine overall risk
    high_count = len([s for s in signals if s["severity"] == "high"])
    med_count = len([s for s in signals if s["severity"] == "medium"])
    
    if high_count >= 2:
        risk_level = "high"
    elif high_count >= 1 or med_count >= 2:
        risk_level = "medium"
    elif signals:
        risk_level = "low"
    else:
        risk_level = "none"
    
    return {
        "detected": len(signals) > 0,
        "signals": signals,
        "risk_level": risk_level,
        "similar_count": count,
    }
