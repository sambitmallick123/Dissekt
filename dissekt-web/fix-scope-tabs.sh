#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

python3 << 'PYEOF'
content = open('src/components/Scope.tsx').read()

# Add intl + substack to the Market type
content = content.replace(
    "type Market = 'all' | 'india' | 'us' | 'germany' | 'uk';",
    "type Market = 'all' | 'india' | 'us' | 'germany' | 'uk' | 'intl' | 'substack';"
)

# Add them to the tab list
content = content.replace(
    "(['all', 'india', 'us', 'germany', 'uk'] as Market[])",
    "(['all', 'india', 'us', 'germany', 'uk', 'intl', 'substack'] as Market[])"
)

# Fix the label rendering to show "Intl" nicely
content = content.replace(
    "{m === 'all' ? 'All' : m === 'us' ? 'US' : m === 'uk' ? 'UK' : m.charAt(0).toUpperCase() + m.slice(1)}",
    "{m === 'all' ? 'All' : m === 'us' ? 'US' : m === 'uk' ? 'UK' : m === 'intl' ? 'Intl' : m.charAt(0).toUpperCase() + m.slice(1)}"
)

open('src/components/Scope.tsx', 'w').write(content)
print('✅ Scope tabs now include Intl + Substack')
PYEOF

echo "Run: rm -rf .next && npm run dev"
