"""Detect politician names in text using matching against database."""
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
    """Find politician mentions in text."""
    if country != "india":
        return []
    
    db = _load_db()
    found = []
    seen = set()
    
    for key, profile in db.items():
        if key in seen:
            continue
        
        name = profile["name"]
        name_parts = name.split()
        
        # Match full name (case insensitive)
        if re.search(rf'\b{re.escape(name)}\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        
        # Match last name alone (e.g. "Modi", "Shah", "Kejriwal")
        last_name = name_parts[-1]
        if re.search(rf'\b{re.escape(last_name)}\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        
        # Match first name if unique enough (>5 chars)
        first_name = name_parts[0]
        if len(first_name) > 5 and re.search(rf'\b{re.escape(first_name)}\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
    
    return found
