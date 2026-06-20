#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Fix: clarity key is "clarity_score" not "clarity"/"score"
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

old = '''        scoring = g(result, "scoring", default={}) or {}
        clarity = None
        if isinstance(scoring, dict):
            clarity = scoring.get("clarity", scoring.get("score"))'''
new = '''        scoring = g(result, "scoring", default={}) or {}
        clarity = None
        if isinstance(scoring, dict):
            clarity = scoring.get("clarity_score", scoring.get("clarity", scoring.get("score")))'''

if old in c:
    c = c.replace(old, new)
    print("✅ clarity now reads 'clarity_score' (the real key)")
else:
    print("⚠️ block not matched — trying simpler swap")
    c = c.replace(
        'clarity = scoring.get("clarity", scoring.get("score"))',
        'clarity = scoring.get("clarity_score", scoring.get("clarity", scoring.get("score")))'
    )
    print("  applied simpler swap")

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"
grep -n "clarity_score" app/main.py | head

echo ""
echo "Commit + push:"
echo "  git add app/main.py && git commit -m 'fix: persist clarity_score key' && git push"
