#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Removes personal features from Analyze, keeps scan + result + Scope
set -e

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Remove the personal-component render block, keep Scope
old_block = '''            <TrustGraph />
            <Reflect />
            <LedgerView />
            <Recall onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
            <ScanHistory onReanalyze={(input: string) => handleScan(input, 'brief')} />
            <Scope onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />'''

new_block = '''            <Scope onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />'''

if old_block in content:
    content = content.replace(old_block, new_block)
    print('✅ Removed TrustGraph/Reflect/Ledger/Recall/ScanHistory from Analyze')
else:
    print('⚠️ render block differs — paste lines 173-181')

# Remove now-unused imports (keep ScanHistory's addToHistory — still used in handleScan)
content = content.replace("import Recall from '@/components/Recall';\n", "")
content = content.replace("import LedgerView from '@/components/Ledger';\n", "")
content = content.replace("import Reflect from '@/components/Reflect';\n", "")
content = content.replace("import TrustGraph from '@/components/TrustGraph';\n", "")
# Keep ScanHistory import but only for addToHistory — change to named-only import
content = content.replace(
    "import ScanHistory, { addToHistory } from '@/components/ScanHistory';",
    "import { addToHistory } from '@/components/ScanHistory';"
)
print('✅ Cleaned unused imports (kept addToHistory)')

open('src/app/analyze/page.tsx', 'w').write(content)
PYEOF

echo "Run frontend build after dashboard script too."
