#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ═══ FIX 1: Claims link to source article (not Google search) ═══
python3 << 'PYEOF'
content = open('src/components/FacetCard.tsx').read()

# Accept a sourceUrl prop
content = content.replace(
    "export default function FacetCard({ claims }: { claims: any[] }) {",
    "export default function FacetCard({ claims, sourceUrl }: { claims: any[]; sourceUrl?: string }) {"
)

# Remove the google searchUrl helper
import re
content = re.sub(
    r"  const searchUrl = \(claim: string\) =>\n    `https://www\.google\.com/search\?q=\$\{encodeURIComponent\(claim \+ ' fact check'\)\}`;\n",
    "",
    content
)

# Replace the 4 search links with a single source-article link (when sourceUrl exists)
old_links = '''                <a href={searchUrl(c.claim)} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', fontWeight: 500 }}>🔍 Google fact-check</a>
                <a href={`https://www.snopes.com/?s=${encodeURIComponent(c.claim)}`} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', fontWeight: 500 }}>Snopes</a>
                <a href={`https://www.politifact.com/search/?q=${encodeURIComponent(c.claim)}`} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', fontWeight: 500 }}>PolitiFact</a>
                <a href={`https://www.altnews.in/?s=${encodeURIComponent(c.claim)}`} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', fontWeight: 500 }}>Alt News</a>'''

new_links = '''                {sourceUrl && sourceUrl.startsWith('http') ? (
                  <a href={sourceUrl} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', fontWeight: 500, display: 'flex', alignItems: 'center', gap: 3 }}>
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><path d="M15 3h6v6M10 14L21 3"/></svg>
                    View in source article
                  </a>
                ) : (
                  <span style={{ fontSize: 10, color: '#aaa' }}>From analyzed text</span>
                )}'''

content = content.replace(old_links, new_links)
open('src/components/FacetCard.tsx', 'w').write(content)
print('✅ FIX 1: Claims link to source article (no more Google search)')
PYEOF

# Pass sourceUrl from AnalysisResult to FacetCard
python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()
if '<FacetCard' in content and 'sourceUrl' not in content:
    import re
    content = re.sub(
        r'<FacetCard claims=\{([^}]+)\}\s*/>',
        r'<FacetCard claims={\1} sourceUrl={data.input_type === "url" ? data.input_content : (data.source_url || "")} />',
        content
    )
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ FIX 1b: AnalysisResult passes sourceUrl to FacetCard')
elif 'sourceUrl' in content:
    print('  sourceUrl already passed')
else:
    print('⚠️ FacetCard not found in AnalysisResult — check render')
PYEOF

# ═══ FIX 2: Scope feed titles clickable → new tab ═══
python3 << 'PYEOF'
content = open('src/components/Scope.tsx').read()

# Find the title div and wrap it in a link. The title renders item.title.
# Looking for: <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5, ... }}>{item.title}</div>
import re
m = re.search(r"<div style=\{\{ fontSize: 12, color: '#404040'[^}]*\}\}[^>]*>\{item\.title\}</div>", content)
if m:
    old_title = m.group(0)
    # Wrap title in an anchor to item.url (new tab)
    new_title = '''<a href={item.url || item.link || '#'} target="_blank" rel="noopener" style={{ textDecoration: 'none' }}>''' + old_title.replace("color: '#404040'", "color: '#1a4d8f'") + '''</a>'''
    content = content.replace(old_title, new_title)
    open('src/components/Scope.tsx', 'w').write(content)
    print('✅ FIX 2: Scope titles now link to article (new tab)')
else:
    print('⚠️ FIX 2: title div pattern not matched — paste Scope item render')
PYEOF

# ═══ FIX 3: Move Help next to Get access (right side) ═══
python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

# Remove Help from the nav links array
content = content.replace("    { href: '/help', label: 'Help' },\n", "")

# Add a Help link just before the Get access button (desktop)
old_getaccess = '''                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>'''
new_getaccess = '''                <a href="/help" style={{ fontSize: 12, color: active === 'Help' ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === 'Help' ? 600 : 500 }}>Help</a>
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>'''
content = content.replace(old_getaccess, new_getaccess, 1)

open('src/components/SiteHeader.tsx', 'w').write(content)
print('✅ FIX 3: Help moved next to Get access (desktop). Mobile menu still lists it via links.')
PYEOF

# Re-add Help to mobile menu links (since we removed from shared array)
python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()
# Mobile menu maps over `links` too (line ~112). Help was removed from links,
# so add a standalone Help entry in the mobile menu before Get access.
old_mobile = '''                <a href="/invite" style={{ display: 'block', textAlign: 'center', padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>'''
new_mobile = '''                <a href="/help" style={{ display: 'block', padding: '10px 24px', fontSize: 14, color: active === 'Help' ? '#0d9488' : '#555', textDecoration: 'none', fontWeight: active === 'Help' ? 600 : 400, borderBottom: '0.5px solid #f0efec' }}>Help</a>
                <a href="/invite" style={{ display: 'block', textAlign: 'center', padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>'''
content = content.replace(old_mobile, new_mobile, 1)
open('src/components/SiteHeader.tsx', 'w').write(content)
print('✅ FIX 3b: Help added to mobile menu near Get access')
PYEOF

echo ""
echo "Run: rm -rf .next && npm run build"
