"""Detect politician names in text using fuzzy matching against database."""
import json
import os
import re
import logging

logger = logging.getLogger("dissekt.compass.ner")

_db = None

def _load_db():
    global _db
    if _db is None:
        db_path = os.path.join(os.path.dirname(__file__), 'india_db.json')
        with open(db_path) as f:
            _db = json.load(f)
    return _db

def detect_politicians(text: str, country: str = "india") -> list[dict]:
    """Find politician mentions in text. Returns list of matched profiles."""
    if country != "india":
        return []
    
    db = _load_db()
    text_lower = text.lower()
    found = []
    seen = set()
    
    for key, profile in db.items():
        # Match full name or last name
        name_parts = key.split()
        full_name = key
        last_name = name_parts[-1] if len(name_parts) > 1 else key
        
        # Check for full name match
        if full_name in text_lower and full_name not in seen:
            found.append(profile)
            seen.add(full_name)
        # Check for "Mr./Shri/PM + last name" patterns
        elif last_name in text_lower and len(last_name) > 4:
            # Avoid false positives on short names
            patterns = [
                rf'\b{re.escape(last_name)}\b',
                rf'\b{re.escape(profile["name"])}\b',
            ]
            for p in patterns:
                if re.search(p, text, re.IGNORECASE):
                    if full_name not in seen:
                        found.append(profile)
                        seen.add(full_name)
                    break
    
    return found
