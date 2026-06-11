#!/bin/bash
# Dissekt — Tier 0: Ship It
# Run this AFTER creating Supabase tables and setting env vars
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

echo "================================"
echo "TIER 0 — Pre-deploy checklist"
echo "================================"
echo ""

# ============================================
# 1. Find and fix old positioning language
# ============================================

echo "🔍 Scanning for old positioning language..."
echo ""

echo "--- 'manipulation' ---"
grep -rn --include="*.tsx" --include="*.ts" -i "manipulation" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'threat' (as in Threat Score/Intelligence) ---"
grep -rn --include="*.tsx" --include="*.ts" -i "threat" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'detect manipulation' / 'detect' ---"
grep -rn --include="*.tsx" --include="*.ts" -i "detect manipulation\|detect fraud\|detection platform" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'don't get played' / 'playbook' ---"
grep -rn --include="*.tsx" --include="*.ts" -i "don't get played\|playbook\|get played" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'HIGH RISK' / 'MEDIUM RISK' / 'LOW RISK' ---"
grep -rn --include="*.tsx" --include="*.ts" "HIGH RISK\|MEDIUM RISK\|LOW RISK" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'Threat Score' / 'threat_score' ---"
grep -rn --include="*.tsx" --include="*.ts" -i "threat.score\|threatScore\|Threat Score" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- 'fact-check' (should be 'cross-reference') ---"
grep -rn --include="*.tsx" --include="*.ts" "fact-check\|fact_check\|factCheck" src/ | grep -v node_modules | grep -v ".next" | grep -v "FactCheck.org\|Google Fact Check\|fact-checking organizations\|fact-check API\|factcheck" || echo "  ✅ None found (legitimate refs excluded)"
echo ""

echo "--- '10 scans' (should be '3 brief + 1 detailed') ---"
grep -rn --include="*.tsx" --include="*.ts" "10 scans\|10 free\|10 trials" src/ | grep -v node_modules | grep -v ".next" || echo "  ✅ None found"
echo ""

echo "--- Meta tags ---"
grep -n "title\|description" src/app/layout.tsx
echo ""

echo "================================"
echo "Now fixing any issues found..."
echo "================================"

# Fix meta tags if still old
python3 << 'PYEOF'
content = open('src/app/layout.tsx').read()
changes = 0

old_new = {
    'Dissekt — Threat Intelligence for Content': 'Dissekt — See how information is constructed',
    'Detect manipulation. Trace claims. Export evidence.': 'Information transparency tool. Inspect how articles frame claims, what evidence supports them, and what context is missing.',
    'Threat Intelligence for Content': 'See how information is constructed',
}

for old, new in old_new.items():
    if old in content:
        content = content.replace(old, new)
        changes += 1

if changes > 0:
    open('src/app/layout.tsx', 'w').write(content)
    print(f'✅ layout.tsx: fixed {changes} meta tag(s)')
else:
    print('✅ layout.tsx: meta tags already correct')
PYEOF

# Fix any remaining old language across all files
python3 << 'PYEOF'
import glob

replacements = {
    'Threat Intelligence for Content': 'See how information is constructed',
    'Threat Score': 'Transparency Score',
    'threat_score': 'transparency_score',
    'threatScore': 'transparencyScore',
    'HIGH RISK': 'LOW TRANSPARENCY',
    'MEDIUM RISK': 'MODERATE',
    'LOW RISK': 'HIGH TRANSPARENCY',
    "Don't get played": 'See how information is constructed',
    'See the playbook': 'Inspect any content',
    'manipulation detection': 'information transparency',
    'manipulation-detection': 'information-transparency',
    '10 scans/day': '3 brief + 1 detailed/day',
    '10 scans per day': '3 brief + 1 detailed scan per day',
    '10 free scans': '3 free scans',
}

fixed_files = 0
for filepath in glob.glob('src/**/*.tsx', recursive=True) + glob.glob('src/**/*.ts', recursive=True):
    try:
        content = open(filepath).read()
        original = content
        for old, new in replacements.items():
            content = content.replace(old, new)
        if content != original:
            open(filepath, 'w').write(content)
            fixed_files += 1
    except: pass

print(f'✅ Fixed old language in {fixed_files} files')
PYEOF

# Also check backend
echo ""
echo "🔍 Scanning backend for old language..."
cd /mnt/d/Startup\ Ideas/Dissekt

echo "--- Backend: 'Threat Score' ---"
grep -rn --include="*.py" "Threat Score\|threat_score\|HIGH RISK\|MEDIUM RISK\|LOW RISK" app/ | grep -v __pycache__ || echo "  ✅ None found"
echo ""

echo "--- Backend: 'manipulation detection' ---"
grep -rn --include="*.py" "manipulation detection\|manipulation-detection" app/ | grep -v __pycache__ || echo "  ✅ None found"
echo ""

# Fix Telegram bot if still has old language
python3 << 'PYEOF'
try:
    content = open('app/telegram_bot/__init__.py').read()
    changes = 0
    old_new = {
        'DISSEKT ANALYSIS': 'DISSEKT — INFORMATION TRANSPARENCY',
        'Threat Score:': 'Transparency Score:',
        'HIGH RISK': 'LOW TRANSPARENCY',
        'MEDIUM RISK': 'MODERATE',
        'LOW RISK': 'HIGH TRANSPARENCY',
    }
    for old, new in old_new.items():
        if old in content:
            content = content.replace(old, new)
            changes += 1
    if changes > 0:
        open('app/telegram_bot/__init__.py', 'w').write(content)
        print(f'✅ Telegram bot: fixed {changes} instances')
    else:
        print('✅ Telegram bot: already correct')
except FileNotFoundError:
    print('  ⚠️ Telegram bot file not found')
PYEOF

echo ""
echo "================================"
echo "✅ Language scan complete"
echo "================================"
echo ""
echo "MANUAL STEPS REMAINING:"
echo ""
echo "1. SUPABASE — Run this SQL in SQL Editor:"
echo "   (Copy from the status report above)"
echo ""
echo "2. RAILWAY — Set environment variables:"
echo "   DISSEKT_ADMIN_KEY = dissekt-sambit-2026"
echo "   RESEND_API_KEY = (your Resend key)"
echo ""
echo "3. VERCEL — Set environment variables:"
echo "   DISSEKT_ADMIN_KEY = dissekt-sambit-2026"
echo "   RESEND_API_KEY = (your Resend key)"
echo ""
echo "4. BUILD + DEPLOY:"
echo "   cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web"
echo "   npm run build && vercel --prod"
echo ""
echo "   cd /mnt/d/Startup\ Ideas/Dissekt"
echo "   git add -A"
echo "   git commit -m 'deploy: tier 0 complete'"
echo "   git push"
