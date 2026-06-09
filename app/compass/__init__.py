"""Dissekt Compass — Political Accountability Engine.

Detects politicians in content and cross-references claims
against voting records, promises, and factual data.
"""
import logging
from app.compass.ner import detect_politicians

logger = logging.getLogger("dissekt.compass")


async def analyze_political_context(text: str, country: str = "india") -> dict:
    """Find politicians mentioned and check claims against their record."""
    politicians = detect_politicians(text, country)
    
    if not politicians:
        return {"politicians": [], "contradictions": [], "context": []}
    
    contradictions = []
    context_notes = []
    
    text_lower = text.lower()
    
    for pol in politicians:
        # Check if any key promises are referenced
        for promise in pol.get("key_promises", []):
            promise_keywords = [w.lower() for w in promise.split() if len(w) > 3]
            if any(kw in text_lower for kw in promise_keywords[:2]):
                context_notes.append({
                    "politician": pol["name"],
                    "type": "promise_referenced",
                    "detail": f"Promise: {promise}",
                    "party": pol["party"],
                })
        
        # Check factual notes that might contradict claims
        for note in pol.get("factual_notes", []):
            context_notes.append({
                "politician": pol["name"],
                "type": "factual_context",
                "detail": note,
                "party": pol["party"],
            })
        
        # Check controversies
        for controversy in pol.get("controversies", []):
            controversy_keywords = [w.lower() for w in controversy.split() if len(w) > 3]
            if any(kw in text_lower for kw in controversy_keywords[:2]):
                context_notes.append({
                    "politician": pol["name"],
                    "type": "controversy_referenced",
                    "detail": controversy,
                    "party": pol["party"],
                })
    
    # Format politician profiles for response
    profiles = []
    for pol in politicians:
        profiles.append({
            "name": pol["name"],
            "party": pol["party"],
            "position": pol["position"],
            "constituency": pol.get("constituency", ""),
            "terms": pol.get("terms", ""),
            "key_votes": pol.get("key_votes", []),
            "key_promises": pol.get("key_promises", []),
        })
    
    return {
        "politicians": profiles,
        "contradictions": contradictions,
        "context": context_notes,
    }
