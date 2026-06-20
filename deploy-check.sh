#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Confirm code is pushed + clean up the debug file
set -e

echo "═══ 1. Remove the debug throwaway from staging ═══"
git restore --staged debug-persist.sh 2>/dev/null || true
rm -f debug-persist.sh
echo "✅ debug-persist.sh removed"

echo ""
echo "═══ 2. Confirm everything's committed + pushed ═══"
git status --short
echo "(empty above = all committed)"
echo ""
echo "Local vs origin:"
git log --oneline -1
git log --oneline -1 origin/main
echo "(same hash = pushed)"

echo ""
echo "═══ 3. Verify the persist code is in the pushed commit ═══"
git show HEAD:app/main.py | grep -c "_persist_scan" && echo "✅ persist code is in the pushed HEAD" || echo "⚠️ persist code NOT in HEAD — needs commit"
