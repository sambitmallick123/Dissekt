#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
set -e

python3 << 'PYEOF'
content = open('app/scoring.py').read()

# ── BUG 1: Rhetoric cap too high (90). Lower to 30 so techniques bite. ──
content = content.replace(
    'capped = min(total_penalty / 90.0, 1.0)',
    'capped = min(total_penalty / 30.0, 1.0)'
)

# ── BUG 2: Manipulation ignores hostility. Add aggression density. ──
old_manip = '''    raw = urgency * 0.25 + cta * 0.20 + escalation * 0.25 + binary_score * 0.15 + min(emo_words / max(len(words), 1) * 10, 1.0) * 0.15
    pressure = _clamp(raw, 0, 1.0)
    score = _clamp(1.0 - pressure, 0.05)'''

new_manip = '''    # Aggression density — hostile framing IS manipulation pressure
    agg_count = sum(1 for w in words if w.strip(".,!?;:") in AGGRESSION_WORDS)
    agg_density = min(agg_count / max(len(words), 1) * 15, 1.0)
    raw = (urgency * 0.20 + cta * 0.15 + escalation * 0.20 + binary_score * 0.10
           + min(emo_words / max(len(words), 1) * 10, 1.0) * 0.15 + agg_density * 0.20)
    pressure = _clamp(raw, 0, 1.0)
    score = _clamp(1.0 - pressure, 0.05)'''

content = content.replace(old_manip, new_manip)

# ── BUG 3: Narrative too lenient. Sharpen the magnitude penalty. ──
content = content.replace(
    'magnitude = min(math.sqrt(horizontal**2 + vertical**2), 1.414) / 1.414\n    score = _clamp(1.0 - magnitude, 0.05)',
    'magnitude = min(math.sqrt(horizontal**2 + vertical**2), 1.414) / 1.414\n    score = _clamp(1.0 - magnitude * 1.5, 0.05)'
)

# ── BUG 4: Argumentation defaults too generous. ──
# When no claims provided, claim_support defaults to 0.5 — fine.
# But coherence defaults to 0.7 with no techniques. Lower base.
content = content.replace(
    'coherence = max(1.0 - (fallacy_count / max(len(techniques), 1)), 0.0) if techniques else 0.7',
    'coherence = max(1.0 - (fallacy_count / max(len(techniques), 1)) * 1.3, 0.0) if techniques else 0.65'
)

open('app/scoring.py', 'w').write(content)
print('✅ Recalibrated: rhetoric cap 90→30, manipulation+aggression, narrative ×1.5, argumentation tighter')
PYEOF

echo ""
echo "Re-test:"
python3 -c "
from app.scoring import compute_full_score
import json

tests = {
  'Manipulative forward': {
    'techniques': [{'name':'loaded_language','confidence':0.8},{'name':'cherry_picking','confidence':0.7},{'name':'appeal_to_fear','confidence':0.75}],
    'fact_checks': [], 'toxicity_score': 0.4, 'sentiment_compound': -0.6,
    'text': 'BREAKING: The government slammed the opposition over its disastrous and shocking budget. Critics call it a catastrophe. Share this before they delete it! Act now!',
  },
  'Clean wire report': {
    'techniques': [], 'fact_checks': [], 'toxicity_score': 0.02, 'sentiment_compound': 0.1,
    'text': 'The finance ministry published its quarterly budget on Tuesday. According to the report, spending rose 3 percent. The opposition said it would review the figures. Economists at the university noted the data aligns with projections.',
  },
  'Opinion piece': {
    'techniques': [{'name':'loaded_language','confidence':0.5}],
    'fact_checks': [], 'toxicity_score': 0.15, 'sentiment_compound': -0.3,
    'text': 'In my view, the policy is misguided. The government claims success, but the numbers tell a different story. We should question these decisions carefully.',
  },
}

for name, t in tests.items():
    r = compute_full_score(techniques=t['techniques'], fact_checks=t['fact_checks'], toxicity_score=t['toxicity_score'], sentiment_compound=t['sentiment_compound'], source_factuality=None, source_bias=None, text=t['text'], source_name='')
    print(f\"{name:24s} clarity={r['clarity_score']:.2f}  C={r['construction']['score']:.2f} V={r['verification']['score']:.2f} I={r['intent']['score']:.2f}\")
"
