#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Wires FeedsTab into the admin page as a new tab
set -e

# Copy the component into components/
cp FeedsTab.tsx src/components/FeedsTab.tsx
echo "✅ FeedsTab.tsx copied to components/"

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# 1. Import FeedsTab
if 'FeedsTab' not in content.split('export default')[0]:
    content = content.replace(
        "import SiteHeader from '@/components/SiteHeader';",
        "import SiteHeader from '@/components/SiteHeader';\nimport FeedsTab from '@/components/FeedsTab';"
    )

# 2. Add 'feeds' to Tab type
content = content.replace(
    "| 'sources';",
    "| 'sources' | 'feeds';"
)
# fallback if sources isn't there
if "| 'feeds'" not in content:
    content = content.replace(
        "| 'settings';",
        "| 'settings' | 'feeds';"
    )

# 3. Add to tab labels
if "feeds:" not in content:
    content = content.replace(
        "sources: '📡 Sources',",
        "sources: '📡 Sources', feeds: '📰 Feeds',"
    )
    if "feeds:" not in content:
        content = content.replace(
            "settings: '⚙️ Settings'",
            "settings: '⚙️ Settings', feeds: '📰 Feeds'"
        )

# 4. Render the tab
if "tab === 'feeds'" not in content:
    # Add before sources or settings render
    if "{tab === 'sources'" in content:
        content = content.replace(
            "{tab === 'sources'",
            "{tab === 'feeds' && <FeedsTab />}\n        {tab === 'sources'"
        )
    else:
        content = content.replace(
            "{tab === 'settings'",
            "{tab === 'feeds' && <FeedsTab />}\n        {tab === 'settings'"
        )

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ FeedsTab wired into admin')
PYEOF

echo ""
echo "Run: rm -rf .next && npm run dev"
