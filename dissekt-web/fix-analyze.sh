#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Fix analyze page: tier comparison + isInvited→member via session + warm refreshAuth
set -e

python3 << 'PYEOF'
c = open('src/app/analyze/page.tsx').read()

# Ensure refreshAuth + isMember are imported from tier
import re
# Find the tier import line and add refreshAuth, isMember if missing
m = re.search(r"import \{([^}]*)\} from ['\"]@/lib/tier['\"]", c)
if m:
    names = m.group(1)
    additions = []
    for fn in ['refreshAuth', 'isMember']:
        if fn not in names:
            additions.append(fn)
    if additions:
        new_names = names.rstrip() + ', ' + ', '.join(additions) + ' '
        c = c[:m.start(1)] + new_names + c[m.end(1):]
        print(f"✅ Imported {', '.join(additions)} from tier")

# Replace the localStorage isInvited line + the tier comparison block with session-based logic
old_block = '''    setMounted(true);
    setIsInvited((typeof window !== 'undefined' && localStorage.getItem('dissekt_tier')) === 'invited');
    fetchConfig().then(cfg => {
      const tier = getTier();
      const key = tier === 'invited' ? 'features_invited' : 'features_free';
      setEnabledFeatures(cfg[key] || ['single_scan', 'radar']);
    });
    fetchLiveLimits().then(() => setRemaining(getRemaining()));'''

new_block = '''    setMounted(true);
    // Warm the auth state from the Supabase session, then load tier-dependent data
    refreshAuth().then(() => {
      setIsInvited(isMember());
      fetchConfig().then(cfg => {
        const key = isMember() ? 'features_member' : 'features_free';
        setEnabledFeatures(cfg[key] || cfg['features_invited'] || ['single_scan', 'radar']);
      });
      fetchLiveLimits().then(() => setRemaining(getRemaining()));
      setRemaining(getRemaining());
    });'''

if old_block in c:
    c = c.replace(old_block, new_block)
    print("✅ analyze: session-based auth warming + member feature key")
else:
    print("⚠️ analyze block not matched exactly — trying line-level fixes")
    c = c.replace(
        "setIsInvited((typeof window !== 'undefined' && localStorage.getItem('dissekt_tier')) === 'invited');",
        "setIsInvited(isMember());"
    )
    c = c.replace(
        "const key = tier === 'invited' ? 'features_invited' : 'features_free';",
        "const key = isMember() ? 'features_member' : 'features_free';"
    )

open('src/app/analyze/page.tsx', 'w').write(c)
PYEOF

echo ""
echo "Verify analyze no longer compares to 'invited':"
grep -n "=== 'invited'\|features_invited\|refreshAuth\|isMember" src/app/analyze/page.tsx | head

echo ""
echo "Run the broad fix for other files, then build:"
echo "  bash /mnt/user-data/outputs/migrate/fix-tier-comparisons.sh"
echo "  rm -rf .next && npm run build"
