#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# The MOBILE menu has the same adjacent-siblings issue (Help + Get access). Fix it.
set -e

python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

# Mobile broken pair (display: 'block' style)
broken = '''              ) : (
                <a href="/help" style={{ display: 'block', padding: '10px 24px', fontSize: 14, color: active === 'Help' ? '#0d9488' : '#555', textDecoration: 'none', fontWeight: active === 'Help' ? 600 : 400, borderBottom: '0.5px solid #f0efec' }}>Help</a>
                <a href="/invite" style={{ display: 'block', textAlign: 'center', padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>
              )}'''

# Move Help out: keep only Get access in the ternary, Help goes before it (always shown in mobile)
fixed = '''              ) : (
                <a href="/invite" style={{ display: 'block', textAlign: 'center', padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>
              )}'''

if broken in content:
    content = content.replace(broken, fixed)
    print('✅ Removed Help from mobile ternary else-branch')
else:
    print('⚠️ mobile broken pair not matched — paste lines 110-125')

# Now add Help before the mobile ternary (mirror desktop). The mobile conditional
# also starts with {isLoggedIn ? ( — find the SECOND occurrence (mobile menu).
import re
occurrences = [m.start() for m in re.finditer(r'\{isLoggedIn \? \(', content)]
if len(occurrences) >= 2:
    # second one is mobile
    pos = occurrences[1]
    # find indentation of that line
    line_start = content.rfind('\n', 0, pos) + 1
    indent = content[line_start:pos]
    help_link = f'{indent}<a href="/help" style={{{{ display: \'block\', padding: \'10px 24px\', fontSize: 14, color: active === \'Help\' ? \'#0d9488\' : \'#555\', textDecoration: \'none\', fontWeight: active === \'Help\' ? 600 : 400, borderBottom: \'0.5px solid #f0efec\' }}}}>Help</a>\n{indent}'
    content = content[:line_start] + help_link + content[line_start:]
    print('✅ Added Help before mobile ternary')
elif len(occurrences) == 1:
    print('  only one isLoggedIn ternary (desktop) — mobile may use different structure')
else:
    print('⚠️ no isLoggedIn ternary found for mobile')

open('src/components/SiteHeader.tsx', 'w').write(content)
PYEOF

python3 -c "print('Checking JSX balance via build is the real test')"
echo ""
echo "All adjacent-anchor pairs (should be NONE now):"
grep -n 'Help</a>' src/components/SiteHeader.tsx

echo ""
echo "Run: rm -rf .next && npm run build"
