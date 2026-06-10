#!/bin/bash
# Dissekt — Sync landing free-tier messaging + uniform footer everywhere
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Update LandingPage free-tier mentions + add footer
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Add SiteFooter import
if 'SiteFooter' not in content:
    # Find the first import line and add after
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('import') and 'react' in line.lower():
            lines.insert(i + 1, "import SiteFooter from './SiteFooter';")
            break
    else:
        # If no react import found, add after 'use client'
        for i, line in enumerate(lines):
            if "'use client'" in line:
                lines.insert(i + 1, "import SiteFooter from './SiteFooter';")
                break
    content = '\n'.join(lines)

# Replace various free-tier mentions with the correct one
replacements = {
    '10 scans per day': '3 brief + 1 detailed scan per day',
    '10 scans/day': '3 brief + 1 detailed/day',
    '10 free scans': '3 free brief scans',
    'Free · 10 scans/day · No signup required': 'Free · 3 brief + 1 detailed scan/day · Resets 00:00 GMT',
    'No account required': 'No account required (beta)',
    'Free: 10 scans/day': 'Free: 3 brief + 1 detailed/day',
}

for old, new in replacements.items():
    content = content.replace(old, new)

# Add SiteFooter before the closing tag of the main/div
# Find the last </div> or </main> and insert footer
if '<SiteFooter' not in content:
    # Try to insert before final closing tag
    if '</main>' in content:
        content = content.rsplit('</main>', 1)
        content = content[0] + '<SiteFooter />\n    </main>' + content[1]
    else:
        # Insert before the last </div> followed by ); 
        idx = content.rfind('</div>')
        if idx != -1:
            # Find the closing of the component return
            content = content[:idx] + '</div>\n      <SiteFooter />' + content[idx+6:]

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ LandingPage: free tier synced + footer added')
PYEOF

# ============================================
# 2. Add SiteFooter to all pages that lack it
# ============================================

python3 << 'PYEOF'
import re, glob

pages = [
    'src/app/analyze/page.tsx',
    'src/app/topics/page.tsx',
    'src/app/compare/page.tsx',
    'src/app/docs/page.tsx',
    'src/app/help/page.tsx',
]

for filepath in pages:
    try:
        content = open(filepath).read()
        changed = False

        # Add import
        if 'SiteFooter' not in content:
            if "import SiteHeader from '@/components/SiteHeader';" in content:
                content = content.replace(
                    "import SiteHeader from '@/components/SiteHeader';",
                    "import SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';"
                )
            else:
                content = content.replace("'use client';", "'use client';\nimport SiteFooter from '@/components/SiteFooter';", 1)
            changed = True

        # Add footer before closing </main>
        if '<SiteFooter' not in content and '</main>' in content:
            parts = content.rsplit('</main>', 1)
            content = parts[0] + '<SiteFooter />\n    </main>' + parts[1]
            changed = True

        if changed:
            open(filepath, 'w').write(content)
            print(f'✅ {filepath}: footer added')
        else:
            print(f'  OK {filepath}')
    except FileNotFoundError:
        print(f'  ⚠️ {filepath} not found')
PYEOF

# ============================================
# 3. Replace custom navs with SiteHeader on pages still using old nav
# ============================================

python3 << 'PYEOF'
import re

pages = [
    'src/app/topics/page.tsx',
    'src/app/compare/page.tsx',
    'src/app/docs/page.tsx',
    'src/app/help/page.tsx',
]

for filepath in pages:
    try:
        content = open(filepath).read()
        
        # Add SiteHeader import if missing
        if 'SiteHeader' not in content:
            content = content.replace(
                "import SiteFooter from '@/components/SiteFooter';",
                "import SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';"
            )
        
        # Replace the old <nav>...</nav> block with <SiteHeader />
        new_content = re.sub(
            r'<nav style=\{\{.*?</nav>',
            '<SiteHeader />',
            content,
            flags=re.DOTALL,
            count=1
        )
        
        if new_content != content:
            open(filepath, 'w').write(new_content)
            print(f'✅ {filepath}: nav → SiteHeader')
        else:
            print(f'  OK {filepath} (no old nav or already done)')
    except FileNotFoundError:
        print(f'  ⚠️ {filepath} not found')
PYEOF

echo ""
echo "✅ Done:"
echo "  - Landing page free-tier messaging synced (3 brief + 1 detailed, resets GMT)"
echo "  - SiteFooter added to: landing, analyze, topics, compare, docs, help"
echo "  - SiteHeader unified across content pages"
echo ""
echo "npm run build"
