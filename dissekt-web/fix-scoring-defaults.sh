#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Fixes the "everything is 0.5" problem by excluding no-data axes from the mean
set -e

python3 << 'PYEOF'
content = open('app/scoring.py').read()

# ── FIX 1: Evidence — no fact-checks should not drag to 0.5 ──
# Absence of disputes is weakly positive, not neutral
content = content.replace(
    'return {"score": 0.50, "status": "no_checks", "checks": 0}',
    'return {"score": 0.65, "status": "no_checks", "checks": 0, "has_data": False}'
)
content = content.replace(
    'return {"score": 0.50, "status": "unrated", "checks": len(fact_checks)}',
    'return {"score": 0.60, "status": "unrated", "checks": len(fact_checks), "has_data": False}'
)

# ── FIX 2: Source — unknown source is slightly-better-than-neutral ──
content = content.replace(
    'return {"score": 0.50, "factuality": "unknown", "bias": bias or "unknown"}',
    'return {"score": 0.60, "factuality": "unknown", "bias": bias or "unknown", "has_data": False}'
)

# ── FIX 3: Temporal — always no data currently, exclude it ──
content = content.replace(
    'return {"score": 0.50, "status": "insufficient_data", "note": "Requires accumulated analysis history"}',
    'return {"score": 0.60, "status": "insufficient_data", "has_data": False, "note": "Requires accumulated analysis history"}'
)

# ── FIX 4: Verification — weight only the axes that have real data ──
old_ver = '''def compute_verification(evidence: dict, source: dict, diversity: dict, temporal: dict) -> dict:
    e, s, d, t = max(evidence["score"], 0.01), max(source["score"], 0.01), max(diversity["score"], 0.01), max(temporal["score"], 0.01)
    score = _clamp((e ** 0.35) * (s ** 0.25) * (d ** 0.20) * (t ** 0.20), 0.01)
    return {"score": _round(score), "evidence": evidence, "source": source, "diversity": diversity, "temporal": temporal}'''

new_ver = '''def compute_verification(evidence: dict, source: dict, diversity: dict, temporal: dict) -> dict:
    # Weight only axes that have actual data — don't dilute with 0.5/0.6 placeholders
    axes = [
        (evidence["score"], 0.40, evidence.get("has_data", True)),
        (source["score"], 0.25, source.get("has_data", True)),
        (diversity["score"], 0.20, diversity.get("has_data", True)),
        (temporal["score"], 0.15, temporal.get("has_data", True)),
    ]
    active = [(s, w) for s, w, has in axes if has]
    if not active:
        # No real data at all — use evidence default only
        score = evidence["score"]
    else:
        total_w = sum(w for _, w in active)
        # Weighted geometric mean over active axes only
        log_sum = sum((w / total_w) * math.log(max(s, 0.01)) for s, w in active)
        score = _clamp(math.exp(log_sum), 0.01)
    return {"score": _round(score), "evidence": evidence, "source": source, "diversity": diversity, "temporal": temporal}'''

content = content.replace(old_ver, new_ver)

open('app/scoring.py', 'w').write(content)
print('✅ Scoring defaults fixed — no-data axes excluded from mean')
PYEOF

echo ""
echo "What changed:"
echo "  Evidence (no fact-checks): 0.50 → 0.65 + flagged has_data:false"
echo "  Source (unknown):          0.50 → 0.60 + flagged has_data:false"
echo "  Temporal (always):         0.50 → 0.60 + flagged has_data:false"
echo "  Verification: now weights ONLY axes with real data"
echo ""
echo "Result: a clean article with no fact-checks + unknown source"
echo "        now scores by its Diversity (real data) + positive defaults,"
echo "        instead of collapsing to 0.5"
