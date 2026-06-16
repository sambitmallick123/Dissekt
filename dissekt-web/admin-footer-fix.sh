#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Admin auth is React-state only. Add a localStorage flag on login/logout so SiteFooter can detect admin.
set -e

# ── 1. Admin page: set localStorage flag on login, clear on sign out ──
python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# On successful login (line 97): set the flag
content = content.replace(
    "if (data.success) { setAuthenticated(true); setAdminKey(password); }",
    "if (data.success) { setAuthenticated(true); setAdminKey(password); if (typeof window !== 'undefined') localStorage.setItem('dissekt_admin', 'true'); }"
)

# On sign out (line 136): clear the flag
content = content.replace(
    "onClick={() => { setAuthenticated(false); setAdminKey(''); }}",
    "onClick={() => { setAuthenticated(false); setAdminKey(''); if (typeof window !== 'undefined') localStorage.removeItem('dissekt_admin'); }}"
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin page sets/clears dissekt_admin flag on login/logout')
PYEOF

# ── 2. SiteFooter: show community links for invited OR admin ──
python3 << 'PYEOF'
content = open('src/components/SiteFooter.tsx').read()

old = "    setIsInvited((typeof window !== 'undefined' && localStorage.getItem('dissekt_tier')) === 'invited');"
new = '''    if (typeof window !== 'undefined') {
      const invited = localStorage.getItem('dissekt_tier') === 'invited';
      const admin = localStorage.getItem('dissekt_admin') === 'true';
      setIsInvited(invited || admin);
    }'''

if old in content:
    content = content.replace(old, new)
    open('src/components/SiteFooter.tsx', 'w').write(content)
    print('✅ Footer shows community links for invited users OR admins')
else:
    print('⚠️ footer setter not matched — paste SiteFooter lines 4-10')
PYEOF

echo ""
echo "Verify admin flag wiring:"
grep -n "dissekt_admin" src/app/admin/page.tsx src/components/SiteFooter.tsx

echo ""
echo "Run: rm -rf .next && npm run build"
