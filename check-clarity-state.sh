#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
set -e

echo "=== Is the clarity_score fix in the local file? ==="
grep -n "clarity_score" app/main.py | head

echo ""
echo "=== Is it committed + pushed? ==="
git show HEAD:app/main.py | grep -c "clarity_score" && echo "✅ in HEAD" || echo "⚠️ NOT in HEAD — needs commit+push"
git status --short | head
echo "--- HEAD vs origin ---"
git log --oneline -1
git log --oneline -1 origin/main

echo ""
echo "=== Does result.scoring actually exist? Test compute path ==="
python3 << 'PYEOF'
# Check if FullAnalysis.scoring gets populated by looking at where scan() sets it
import subprocess
r = subprocess.run(['grep', '-rn', 'scoring', 'app/beacon/__init__.py', 'app/__init__.py'],
                   capture_output=True, text=True)
lines = [l for l in r.stdout.split('\n') if 'scoring' in l.lower()][:10]
if lines:
    print("scoring references in pipeline:")
    for l in lines: print("  ", l)
else:
    print("No 'scoring' in beacon — checking where scan() builds the result...")
    r2 = subprocess.run(['grep', '-rln', 'compute_full_score\|FullAnalysis\|"scoring"\|scoring=',
                         'app/'], capture_output=True, text=True)
    print("Files referencing scoring/compute_full_score:")
    print(r2.stdout)
PYEOF
