#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# 1. Remove Compare from top nav (keep it as action tab)
# 2. Gate Bulk CSV + Compare for logged-in users only
set -e

# ─── 1. Remove Compare from header nav ───
python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()
# Remove the Compare nav entry
content = content.replace("    { href: '/compare', label: 'Compare' },\n", "")
open('src/components/SiteHeader.tsx', 'w').write(content)
print('✅ Removed Compare from top nav')
PYEOF

# ─── 2. Gate Bulk + Compare in the Analyze action area ───
python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Determine login state — the page already computes tier via getTier(); ensure we have it
# Add an isInvited check near the top of the component if not present
if 'const isInvited' not in content:
    content = content.replace(
        "const { lockedFeature, checkFeature, closePopup } = useFeatureGate();",
        "const { lockedFeature, checkFeature, closePopup } = useFeatureGate();\n  const [isInvited, setIsInvited] = useState(false);"
    )
    # set it in the mount effect
    content = content.replace(
        "setMounted(true);",
        "setMounted(true);\n    setIsInvited((typeof window !== 'undefined' && localStorage.getItem('dissekt_tier')) === 'invited');"
    )

# Replace the Bulk CSV button — gate on login
old_bulk = '''              <button onClick={() => { if (checkFeature('Bulk CSV analysis', enabledFeatures)) setScanTab('bulk'); }}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'bulk' ? '#0d9488' : '#f0f0ee', color: scanTab === 'bulk' ? '#fff' : '#555' }}>
                📊 Bulk CSV {!enabledFeatures.includes('bulk') && '🔒'}
              </button>'''

new_bulk = '''              <button onClick={() => { if (!isInvited) { window.location.href = '/invite'; return; } if (checkFeature('Bulk CSV analysis', enabledFeatures)) setScanTab('bulk'); }}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'bulk' ? '#0d9488' : '#f0f0ee', color: scanTab === 'bulk' ? '#fff' : '#555', opacity: isInvited ? 1 : 0.6 }}>
                📊 Bulk CSV {!isInvited && '🔒'}
              </button>'''

content = content.replace(old_bulk, new_bulk)

# Replace the Compare link — gate on login
old_compare = '''              <a href="/compare" style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 500, background: '#f0f0ee', color: '#555', textDecoration: 'none', display: 'flex', alignItems: 'center' }}>⚖️ Compare</a>'''

new_compare = '''              <button onClick={() => { window.location.href = isInvited ? '/compare' : '/invite'; }}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: '#f0f0ee', color: '#555', display: 'flex', alignItems: 'center', gap: 4, opacity: isInvited ? 1 : 0.6 }}>
                ⚖️ Compare {!isInvited && '🔒'}
              </button>'''

content = content.replace(old_compare, new_compare)

open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Bulk CSV + Compare gated for invited users (🔒 + redirect to /invite)')
PYEOF

echo ""
echo "Run: rm -rf .next && npm run build"
