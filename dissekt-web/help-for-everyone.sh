#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Move Help OUTSIDE the isLoggedIn ternary so it shows for everyone, before the ternary.
set -e

python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

# Step 1: remove Help from inside the else branch (the fragment version)
content = content.replace(
    '''              ) : (
                <>
                <a href="/help" style={{ fontSize: 12, color: active === 'Help' ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === 'Help' ? 600 : 500 }}>Help</a>
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
                </>
              )}''',
    '''              ) : (
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
              )}'''
)

# Also handle the case where the fragment fix wasn't applied yet (raw broken version)
content = content.replace(
    '''              ) : (
                <a href="/help" style={{ fontSize: 12, color: active === 'Help' ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === 'Help' ? 600 : 500 }}>Help</a>
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
              )}''',
    '''              ) : (
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
              )}'''
)

# Step 2: add Help BEFORE the ternary (always visible). Find the opening of the
# logged-in/out conditional. It starts with "{isLoggedIn ? (".
import re
m = re.search(r'(\s*)\{isLoggedIn \? \(', content)
if m:
    indent = m.group(1).lstrip('\n')
    help_link = f'{m.group(1)}<a href="/help" style={{{{ fontSize: 12, color: active === \'Help\' ? \'#0d9488\' : \'#888780\', textDecoration: \'none\', fontWeight: active === \'Help\' ? 600 : 500 }}}}>Help</a>'
    content = content[:m.start()] + help_link + content[m.start():]
    print('✅ Help moved before the ternary — now shows for everyone')
else:
    print('⚠️ {isLoggedIn ? ( not found — paste the right-side container')

open('src/components/SiteHeader.tsx', 'w').write(content)
PYEOF

echo ""
echo "Result (lines 76-84):"
sed -n '76,84p' src/components/SiteHeader.tsx
