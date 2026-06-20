#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Verify NER actually populated the entities column on recent scans
set -e

python3 << 'PYEOF'
from app.config import get_settings
from supabase import create_client
import json

s = get_settings()
sb = create_client(s.supabase_url, s.supabase_service_key)

# Get the most recent scans
r = sb.table("scans").select("id, mode, language, clarity, toxicity, techniques, entities, created_at").order("created_at", desc=True).limit(5).execute()

print(f"=== {len(r.data)} most recent scans ===\n")
for row in r.data:
    ents = row.get("entities") or []
    techs = row.get("techniques") or []
    print(f"Scan #{row['id']} ({row['mode']}, {row.get('language','?')}) — {row['created_at'][:19]}")
    print(f"  clarity={row.get('clarity')}  toxicity={row.get('toxicity')}")
    print(f"  techniques ({len(techs)}): {[t.get('name') for t in techs][:5]}")
    if ents:
        print(f"  ✅ entities ({len(ents)}):")
        for e in ents:
            print(f"     - {e.get('name')} [{e.get('type')}]")
    else:
        print(f"  ⚠️ entities: EMPTY (NER may have failed or this scan predates Phase 2)")
    print()
PYEOF
