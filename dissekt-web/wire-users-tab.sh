#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Wire UsersTab into admin page, replacing Invitations in the People group.
set -e

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# 1. Import UsersTab (near other tab imports)
if 'import UsersTab' not in content:
    # add after the InvitationsTab import
    import re
    m = re.search(r"import InvitationsTab.*\n", content)
    if m:
        content = content[:m.end()] + "import UsersTab from '@/components/UsersTab';\n" + content[m.end():]
        print('✅ Imported UsersTab')
    else:
        # fallback: add after first import
        m2 = re.search(r"^import .*\n", content, flags=re.MULTILINE)
        content = content[:m2.end()] + "import UsersTab from '@/components/UsersTab';\n" + content[m2.end():]
        print('✅ Imported UsersTab (fallback position)')

# 2. Add 'users' to the Tab type
content = content.replace(
    "type Tab =",
    "type Tab = 'users' |", 1
) if "type Tab = 'users'" not in content else content

# 3. Add to tabLabels
content = content.replace(
    "overview: '📊 Overview', invitations: '🎟️ Invitations',",
    "overview: '📊 Overview', users: '👤 Users', invitations: '🎟️ Invitations',"
)

# 4. Add to People group (replace invitations with users, keep others)
content = content.replace(
    "{ id: 'people',  label: '👥 People',  tabs: ['invitations', 'feedback', 'contacts', 'corrections'] },",
    "{ id: 'people',  label: '👥 People',  tabs: ['users', 'feedback', 'contacts', 'corrections'] },"
)

# 5. Add the render line
content = content.replace(
    "{tab === 'invitations' && <InvitationsTab adminKey={adminKey} />}",
    "{tab === 'users' && <UsersTab adminKey={adminKey} />}\n        {tab === 'invitations' && <InvitationsTab adminKey={adminKey} />}"
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Wired UsersTab into admin (People group, replaces Invitations)')
PYEOF

echo ""
echo "Verify:"
grep -n "UsersTab\|'users'\|users:" src/app/admin/page.tsx | head

echo ""
echo "Run: rm -rf .next && npm run build"
