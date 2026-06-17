#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Show relative time ("4h ago", "3d ago") so freshness is clear at a glance
set -e

python3 << 'PYEOF'
content = open('src/components/Scope.tsx').read()

# Add a relative-time helper near the top of the component file (after imports).
if 'function timeAgo' not in content:
    helper = '''
function timeAgo(iso: string): string {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  if (isNaN(then)) return '';
  const mins = Math.floor((Date.now() - then) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(iso).toLocaleDateString();
}
'''
    # insert after the last import line
    import re
    m = list(re.finditer(r'^import .*$', content, flags=re.MULTILINE))
    if m:
        pos = m[-1].end()
        content = content[:pos] + '\n' + helper + content[pos:]
        print('✅ Added timeAgo() helper')

# Replace the plain toLocaleDateString with relative time
content = content.replace(
    "{item.published && <span>· {new Date(item.published).toLocaleDateString()}</span>}",
    "{item.published && <span>· {timeAgo(item.published)}</span>}"
)
print('✅ Timestamps now show relative time (fresh vs backfilled is obvious)')

open('src/components/Scope.tsx', 'w').write(content)
PYEOF

echo ""
echo "Verify:"
grep -n "timeAgo\|published" src/components/Scope.tsx | head

echo ""
echo "Run: rm -rf .next && npm run build"
