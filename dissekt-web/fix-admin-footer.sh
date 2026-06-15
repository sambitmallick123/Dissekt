#!/bin/bash
# Run this from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ═══ 1. FOOTER: copy replacement ═══
cp SiteFooter.tsx src/components/SiteFooter.tsx
echo "✅ Footer replaced (marginTop: auto, no fixed number)"

# ═══ 2. LAYOUT: copy replacement ═══
cp layout.tsx src/app/layout.tsx
echo "✅ Layout replaced (body: flex column, minHeight 100vh)"

# ═══ 3. EVERY PAGE: remove minHeight from <main> ═══
find src/app -name "page.tsx" -exec sed -i "s/minHeight: '100vh', //g" {} \;
find src/app -name "page.tsx" -exec sed -i "s/minHeight: '100vh'//g" {} \;
echo "✅ Removed minHeight from all page <main> tags"

# ═══ 4. EVERY PAGE: ensure <main> has style flex:1 ═══
# This makes main fill remaining space so footer stays at bottom
find src/app -name "page.tsx" -exec sed -i "s/<main style={{ background:/<main style={{ flex: 1, background:/g" {} \;
echo "✅ Added flex:1 to all <main> tags"

# ═══ 5. ADMIN: Rewrite header + tabs section ═══
python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Fix Tab type
content = content.replace(
    "type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions' | 'settings';",
    "type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions' | 'settings' | 'sources';"
)

# Replace the entire authenticated return block header
old_header = """<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h1 style={{ fontSize: 22, fontWeight: 700 }}>Admin dashboard</h1>
          <button onClick={() => { setAuthenticated(false); setAdminKey(''); }} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#dc2626' }}>Sign out</button>
        </div>"""

new_header = """<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>Admin</span>
            <span style={{ fontSize: 9, padding: '2px 8px', background: '#f0fdfa', color: '#0d9488', borderRadius: 4, fontWeight: 600 }}>LIVE</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button onClick={() => window.location.reload()} style={{ fontSize: 10, padding: '5px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 4, cursor: 'pointer', color: '#888' }}>Refresh</button>
            <button onClick={() => { setAuthenticated(false); setAdminKey(''); }} style={{ fontSize: 10, padding: '5px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 4, cursor: 'pointer', color: '#dc2626' }}>Sign out</button>
          </div>
        </div>"""

content = content.replace(old_header, new_header)

# Add sources to tab labels
content = content.replace(
    "settings: '⚙️ Settings',\n  };",
    "settings: '⚙️ Settings', sources: '📡 Sources',\n  };"
)
content = content.replace(
    "settings: '⚙️ Settings',\r\n  };",
    "settings: '⚙️ Settings', sources: '📡 Sources',\r\n  };"
)
# Also handle single-line
if "sources: " not in content:
    content = content.replace(
        "settings: '⚙️ Settings'",
        "settings: '⚙️ Settings', sources: '📡 Sources'"
    )

# Replace tab button styling — from pills to underlined
old_tab_style = "padding: '7px 16px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === t ? '#0d9488' : '#fff', color: tab === t ? '#fff' : '#555', boxShadow: tab !== t ? '0 0 0 0.5px #e5eaea' : 'none', whiteSpace: 'nowrap'"

new_tab_style = "padding: '8px 14px', borderRadius: 0, fontSize: 12, fontWeight: tab === t ? 600 : 400, border: 'none', cursor: 'pointer', background: 'transparent', color: tab === t ? '#0d9488' : '#888', borderBottom: tab === t ? '2px solid #0d9488' : '2px solid transparent', whiteSpace: 'nowrap' as any"

content = content.replace(old_tab_style, new_tab_style)

# Remove paddingBottom from tab container
content = content.replace("paddingBottom: 4", "paddingBottom: 0")

# Add sources tab render if missing
if "tab === 'sources'" not in content:
    content = content.replace(
        "{tab === 'settings'",
        "{tab === 'sources' && <SourcesTab />}\n        {tab === 'settings'"
    )

# Ensure main has flex:1
content = content.replace(
    "<main style={{ background: '#fafaf8' }}>",
    "<main style={{ flex: 1, background: '#fafaf8' }}>"
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin: option 2 dense view applied')
PYEOF

# ═══ 6. Verify ═══
echo ""
echo "Checking changes..."
grep -c "Admin.*LIVE\|LIVE" src/app/admin/page.tsx && echo "  ✓ Admin header updated" || echo "  ✗ Admin header NOT updated"
grep -c "borderBottom.*2px solid.*0d9488" src/app/admin/page.tsx && echo "  ✓ Underlined tabs" || echo "  ✗ Tabs NOT updated"
grep -c "sources" src/app/admin/page.tsx && echo "  ✓ Sources tab present" || echo "  ✗ Sources tab missing"
grep -c "marginTop: 'auto'" src/components/SiteFooter.tsx && echo "  ✓ Footer marginTop auto" || echo "  ✗ Footer NOT fixed"
grep -c "minHeight: '100vh'" src/app/layout.tsx && echo "  ✓ Layout has flex" || echo "  ✗ Layout NOT fixed"
echo ""
echo "Now run: npm run build"
