#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Add a recency time window (past month) to keyword search — keeps general web, adds freshness
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

# Add tbs=qdr:m (past month) to the _serpapi_broad params, keeping general web search.
old = '''    params = {"api_key": api_key, "q": query[:120], "num": num, "sort": "date"}'''
new = '''    params = {"api_key": api_key, "q": query[:120], "num": num, "sort": "date",
              "tbs": "qdr:m"}  # qdr:m = past month (keeps general web, adds recency)'''

if old in c:
    c = c.replace(old, new)
    print("✅ added recency window (past month) to keyword search")
else:
    print("⚠️ params line not matched — current _serpapi_broad params:")
    import re
    m = re.search(r'params = \{[^}]*\}', c)
    if m: print("   ", m.group(0))

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"
python3 -c "import app.main; print('✅ imports cleanly')" 2>&1 | grep -v pkg_resources | grep -v UserWarning | tail -1

echo ""
echo "Verify:"
grep -n 'qdr:m\|tbs' app/main.py | head

echo ""
echo "Commit + push:"
echo "  git add app/main.py && git commit -m 'feat: keyword search recency window (past month)' && git push"
