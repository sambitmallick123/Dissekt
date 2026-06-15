#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ═══ FIX EMOJI + HARDCODED VALUES IN ADMIN ═══
python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()
content = content.replace('\\ud83d\\udd11', '🔑')
content = content.replace('\\u2699', '⚙')
content = content.replace('\\u2709', '✉')
content = content.replace('\\u2191', '↑')
content = content.replace('\\u2014', '—')
content = content.replace(
    "Number(stats.avg_clarity ?? 0.54).toFixed(2)",
    "stats.avg_clarity != null ? Number(stats.avg_clarity).toFixed(2) : '—'"
)
# Ensure admin main has flex:1
content = content.replace("<main style={{ background: '#fafaf8' }}>", "<main style={{ flex: 1, background: '#fafaf8' }}>")
open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin: emoji fixed, hardcoded 0.54 removed, main has flex:1')
PYEOF

# ═══ BULLETPROOF FOOTER: add flex:1 to EVERY page's main ═══
# Match any <main with a style object and inject flex:1 if missing
python3 << 'PYEOF'
import os, re, glob

count = 0
for path in glob.glob('src/app/**/page.tsx', recursive=True) + glob.glob('src/components/*.tsx'):
    try:
        c = open(path).read()
    except:
        continue
    orig = c
    # For any <main style={{ ... }} that lacks flex
    def add_flex(m):
        inner = m.group(1)
        if 'flex:' in inner or 'flex :' in inner:
            return m.group(0)
        return '<main style={{ flex: 1, ' + inner + '}}'
    c = re.sub(r'<main style=\{\{ ([^}]*?)\}\}', add_flex, c)
    if c != orig:
        open(path, 'w').write(c)
        count += 1
print(f'✅ Added flex:1 to <main> in {count} files')
PYEOF

# ═══ GLOBALS.CSS: ensure the flex chain is correct ═══
python3 << 'PYEOF'
content = open('src/app/globals.css').read()
import re
# Remove any previous sticky footer block
content = re.sub(r'/\* =+ STICKY FOOTER.*?(?=\n/\*|\Z)', '', content, flags=re.DOTALL)
content = re.sub(r'/\* Sticky footer.*?footer \{[^}]*\}', '', content, flags=re.DOTALL)

content = content.rstrip() + '''

/* ===== STICKY FOOTER ===== */
html, body { height: 100%; margin: 0; }
body { min-height: 100vh; display: flex; flex-direction: column; }
main { flex: 1 0 auto; }
footer { flex-shrink: 0; margin-top: auto; }
'''
open('src/app/globals.css', 'w').write(content)
print('✅ globals.css: clean sticky footer rules')
PYEOF

echo ""
echo "Run: rm -rf .next && npm run build  (or npm run dev)"
