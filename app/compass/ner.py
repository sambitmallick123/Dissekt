"""Detect politician names in text using matching against databases."""
import json
import os
import re
import logging

logger = logging.getLogger("dissekt.compass.ner")

_dbs = {}

def _load_db(country: str):
    if country not in _dbs:
        db_path = os.path.join(os.path.dirname(__file__), f'{country}_db.json')
        if os.path.exists(db_path):
            with open(db_path) as f:
                _dbs[country] = json.load(f)
        else:
            _dbs[country] = {}
    return _dbs[country]

# Common aliases
ALIASES = {
    "aoc": "alexandria ocasio-cortez",
    "raga": "rahul gandhi",
    "pappu": "rahul gandhi",
    "feku": "narendra modi",
    "namo": "narendra modi",
    "kcr": "k chandrashekar rao",
    "cbn": "chandrababu naidu",
    "mbs": "mamata banerjee",
}

def detect_politicians(text: str, country: str = "all") -> list[dict]:
    """Find politician mentions in text. Searches all country databases."""
    countries = ["india", "us"] if country == "all" else [country]
    
    found = []
    seen = set()
    text_lower = text.lower()
    
    # Check aliases first
    for alias, full_key in ALIASES.items():
        if re.search(rf'\b{re.escape(alias)}\b', text_lower):
            for c in countries:
                db = _load_db(c)
                if full_key in db and db[full_key]["name"] not in seen:
                    profile = dict(db[full_key])
                    profile["country"] = c
                    found.append(profile)
                    seen.add(profile["name"])
    
    # Search each country database
    for c in countries:
        db = _load_db(c)
        for key, profile in db.items():
            if profile["name"] in seen:
                continue
            
            name = profile["name"]
            name_parts = name.split()
            
            # Full name match
            if re.search(rf'\b{re.escape(name)}\b', text, re.IGNORECASE):
                p = dict(profile)
                p["country"] = c
                found.append(p)
                seen.add(name)
                continue
            
            # Last name match
            last_name = name_parts[-1]
            if re.search(rf'\b{re.escape(last_name)}\b', text, re.IGNORECASE):
                p = dict(profile)
                p["country"] = c
                found.append(p)
                seen.add(name)
                continue
            
            # First name match (only if unique enough, >5 chars)
            first_name = name_parts[0]
            if len(first_name) > 5 and re.search(rf'\b{re.escape(first_name)}\b', text, re.IGNORECASE):
                p = dict(profile)
                p["country"] = c
                found.append(p)
                seen.add(name)
    
    return found
