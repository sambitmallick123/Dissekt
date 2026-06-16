#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Adds "My activity" tab to Dashboard with Reflect/Ledger/Memory/Recent scans
set -e

python3 << 'PYEOF'
content = open('src/app/dashboard/page.tsx').read()

# 1. Add imports for the moved components
if "import Reflect" not in content:
    content = content.replace(
        "import SiteFooter from '@/components/SiteFooter';",
        """import SiteFooter from '@/components/SiteFooter';
import Reflect from '@/components/Reflect';
import LedgerView from '@/components/Ledger';
import Recall from '@/components/Recall';
import ScanHistory from '@/components/ScanHistory';
import TrustGraph from '@/components/TrustGraph';"""
    )

# 2. Add 'activity' to the tab type
content = content.replace(
    "const [tab, setTab] = useState<'insights' | 'apikeys'>('insights');",
    "const [tab, setTab] = useState<'insights' | 'activity' | 'apikeys'>('insights');"
)

# 3. Add the tab button (between Insights and API keys)
content = content.replace(
    '''<button onClick={() => setTab('apikeys')}''',
    '''<button onClick={() => setTab('activity')} style={{ padding: '5px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'activity' ? '#0d9488' : '#fff', color: tab === 'activity' ? '#fff' : '#555', boxShadow: tab !== 'activity' ? '0 0 0 0.5px #e5eaea' : 'none' }}>📒 My activity</button>
            <button onClick={() => setTab('apikeys')}'''
)

# 4. Add the activity tab content (before the apikeys tab block)
activity_block = '''        {tab === 'activity' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Reflect />
            <TrustGraph />
            <LedgerView />
            <Recall onAnalyze={(text: string) => { window.location.href = '/analyze?content=' + encodeURIComponent(text); }} />
            <ScanHistory onReanalyze={(input: string) => { window.location.href = '/analyze?content=' + encodeURIComponent(input); }} />
          </div>
        )}

'''
content = content.replace(
    "        {tab === 'apikeys' && (",
    activity_block + "        {tab === 'apikeys' && (",
    1
)

open('src/app/dashboard/page.tsx', 'w').write(content)
print('✅ Dashboard: added My activity tab with Reflect/TrustGraph/Ledger/Memory/Recent')
PYEOF

echo "Run: rm -rf .next && npm run build"
