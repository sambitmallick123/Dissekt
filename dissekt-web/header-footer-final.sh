#!/bin/bash
# Dissekt — Header D + Footer A across all pages
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. SiteHeader — D warm off-white
# ============================================

cat > src/components/SiteHeader.tsx << 'HEADEOF'
'use client';
import { useEffect, useState } from 'react';

export default function SiteHeader({ active }: { active?: string }) {
  const [tier, setTier] = useState('free');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      setTier(localStorage.getItem('dissekt_tier') || 'free');
      const expiry = localStorage.getItem('dissekt_access_expires');
      if (expiry) {
        const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
        if (days > 0) setExpiryText(`${days}d`);
        else {
          setExpiryText('');
          localStorage.removeItem('dissekt_tier');
          localStorage.removeItem('dissekt_access_expires');
          setTier('free');
        }
      }
    }
  }, []);

  const signOut = () => {
    ['dissekt_tier','dissekt_invite_code','dissekt_invite_name','dissekt_access_expires','dissekt_token','dissekt_email','dissekt_name','dissekt_usage'].forEach(k => localStorage.removeItem(k));
    window.location.href = '/';
  };

  const links = [
    { href: '/analyze', label: 'Analyze' },
    { href: '/observatory', label: 'Observatory' },
    { href: '/compare', label: 'Compare' },
    { href: '/help', label: 'Help' },
    { href: '/feedback', label: 'Feedback' },
  ];

  if (!mounted) return <nav style={{ height: 46 }} />;

  return (
    <nav style={{ position: 'sticky', top: 0, zIndex: 30 }}>
      <div style={{ height: 2, background: '#0d9488' }} />
      <div style={{ background: '#fafaf8', borderBottom: '0.5px solid #e8e5de' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 8, textDecoration: 'none', color: '#2c2c2a' }}>
              <div style={{ width: 22, height: 22, background: '#0d9488', borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              </div>
              <span style={{ fontWeight: 600, fontSize: 14 }}>Dissekt</span>
            </a>
            <div style={{ width: 1, height: 14, background: '#d3d1c7' }} />
            <div style={{ display: 'flex', gap: 12 }}>
              {links.map(l => (
                <a key={l.href} href={l.href}
                  style={{ fontSize: 12, color: active === l.label ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
                  {l.label}
                </a>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {tier === 'invited' ? (
              <>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '3px 8px', background: '#e1f5ee', borderRadius: 4, fontSize: 9, fontWeight: 600, color: '#085041' }}>
                  <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#0d9488' }} />
                  Invited
                </div>
                {expiryText && (
                  <div style={{ padding: '3px 8px', background: '#ccfbf1', borderRadius: 4, fontSize: 9, fontWeight: 600, color: '#04342c' }}>
                    {expiryText}
                  </div>
                )}
                <button onClick={signOut} aria-label="Sign out"
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 3, color: '#b4b2a9', fontSize: 14, lineHeight: 1 }}>
                  ✕
                </button>
              </>
            ) : (
              <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '4px 12px', fontWeight: 600, background: '#0d9488' }}>
                Get access
              </a>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
HEADEOF

echo "✅ SiteHeader: D warm off-white"

# ============================================
# 2. SiteFooter — A teal mist
# ============================================

cat > src/components/SiteFooter.tsx << 'FOOTEOF'
'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#f0fdfa', borderTop: '0.5px solid #ccfbf1', marginTop: 40 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: '#5f8a84' }}>
          <div style={{ width: 16, height: 16, background: '#0d9488', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span>© 2026 Dissekt · Munich · Beta</span>
        </div>
        <div style={{ display: 'flex', gap: 14, fontSize: 11 }}>
          <a href="/help" style={{ color: '#5f8a84', textDecoration: 'none' }}>Help</a>
          <a href="/feedback" style={{ color: '#5f8a84', textDecoration: 'none' }}>Feedback</a>
          <a href="/contact" style={{ color: '#5f8a84', textDecoration: 'none' }}>Contact</a>
          <a href="/docs" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>
          <a href="/privacy" style={{ color: '#5f8a84', textDecoration: 'none' }}>Privacy</a>
          <a href="/terms" style={{ color: '#5f8a84', textDecoration: 'none' }}>Terms</a>
          <a href="/disclaimer" style={{ color: '#5f8a84', textDecoration: 'none' }}>Disclaimer</a>
        </div>
      </div>
    </footer>
  );
}
FOOTEOF

echo "✅ SiteFooter: A teal mist"

# ============================================
# 3. Verify ALL pages have SiteHeader + SiteFooter
# ============================================

python3 << 'PYEOF'
import os, glob

pages = glob.glob('src/app/*/page.tsx') + glob.glob('src/app/*/*/page.tsx')
# Also check components that render full pages
pages.append('src/components/LandingPage.tsx')

missing_header = []
missing_footer = []
missing_import_h = []
missing_import_f = []

for filepath in sorted(pages):
    if not os.path.exists(filepath):
        continue
    content = open(filepath).read()
    name = filepath.replace('src/app/', '').replace('/page.tsx', '') or '/'
    
    # Check imports
    has_header_import = "SiteHeader" in content
    has_footer_import = "SiteFooter" in content
    has_header_tag = "<SiteHeader" in content
    has_footer_tag = "<SiteFooter" in content
    
    if not has_header_tag:
        missing_header.append(name)
    if not has_footer_tag:
        missing_footer.append(name)
    if has_header_tag and not has_header_import:
        missing_import_h.append(name)
    if has_footer_tag and not has_footer_import:
        missing_import_f.append(name)

print(f'Pages scanned: {len(pages)}')
if missing_header:
    print(f'⚠️  Missing SiteHeader: {missing_header}')
else:
    print('✅ All pages have SiteHeader')
if missing_footer:
    print(f'⚠️  Missing SiteFooter: {missing_footer}')
else:
    print('✅ All pages have SiteFooter')
if missing_import_h:
    print(f'⚠️  Missing SiteHeader import: {missing_import_h}')
if missing_import_f:
    print(f'⚠️  Missing SiteFooter import: {missing_import_f}')
PYEOF

# ============================================
# 4. Fix any pages missing header/footer
# ============================================

python3 << 'PYEOF'
import os, glob

pages = glob.glob('src/app/*/page.tsx') + glob.glob('src/app/*/*/page.tsx')
fixed = 0

for filepath in pages:
    if not os.path.exists(filepath):
        continue
    content = open(filepath).read()
    changed = False
    
    # Skip the root page.tsx (it renders LandingPage which has its own header/footer)
    if filepath == 'src/app/page.tsx':
        continue
    
    # Add SiteHeader import
    if '<SiteHeader' in content and "import SiteHeader" not in content:
        if "'use client';" in content:
            content = content.replace("'use client';", "'use client';\nimport SiteHeader from '@/components/SiteHeader';")
        else:
            content = "import SiteHeader from '@/components/SiteHeader';\n" + content
        changed = True
    
    # Add SiteFooter import
    if '<SiteFooter' in content and "import SiteFooter" not in content:
        if "import SiteHeader" in content:
            content = content.replace("import SiteHeader from '@/components/SiteHeader';", "import SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';")
        elif "'use client';" in content:
            content = content.replace("'use client';", "'use client';\nimport SiteFooter from '@/components/SiteFooter';")
        changed = True
    
    # Add SiteHeader if missing (has <main but no SiteHeader)
    if '<main' in content and '<SiteHeader' not in content:
        if "import SiteHeader" not in content:
            if "'use client';" in content:
                content = content.replace("'use client';", "'use client';\nimport SiteHeader from '@/components/SiteHeader';")
            else:
                content = "import SiteHeader from '@/components/SiteHeader';\n" + content
        content = content.replace('<main', '<main', 1)
        # Find first > after <main and insert SiteHeader
        idx = content.find('<main')
        end = content.find('>', idx)
        content = content[:end+1] + '\n      <SiteHeader />' + content[end+1:]
        changed = True
    
    # Add SiteFooter if missing
    if '</main>' in content and '<SiteFooter' not in content:
        if "import SiteFooter" not in content:
            if "import SiteHeader" in content:
                content = content.replace("import SiteHeader from '@/components/SiteHeader';", "import SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';")
            elif "'use client';" in content:
                content = content.replace("'use client';", "'use client';\nimport SiteFooter from '@/components/SiteFooter';")
        content = content.replace('</main>', '<SiteFooter />\n    </main>')
        changed = True
    
    if changed:
        open(filepath, 'w').write(content)
        fixed += 1
        print(f'  Fixed: {filepath}')

print(f'✅ Fixed {fixed} pages')
PYEOF

# ============================================
# 5. Update LandingPage background to match
# ============================================

python3 -c "
content = open('src/components/LandingPage.tsx').read()
# Make sure landing page sections use matching backgrounds
content = content.replace(\"background: '#f5f5f4'\", \"background: '#fafaf8'\")
content = content.replace(\"background: '#f8fafa'\", \"background: '#fafaf8'\")
open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ LandingPage: background synced')
"

# ============================================
# 6. Update analyze page background
# ============================================

python3 -c "
content = open('src/app/analyze/page.tsx').read()
content = content.replace(\"background: '#f5f5f4'\", \"background: '#fafaf8'\")
content = content.replace(\"background: '#f8fafa'\", \"background: '#fafaf8'\")
open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze page: background synced')
"

# ============================================
# 7. Sync all page backgrounds
# ============================================

python3 << 'PYEOF'
import glob

count = 0
for filepath in glob.glob('src/app/*/page.tsx') + glob.glob('src/app/*/*/page.tsx'):
    try:
        content = open(filepath).read()
        original = content
        content = content.replace("background: '#f5f5f4'", "background: '#fafaf8'")
        content = content.replace("background: '#f8fafa'", "background: '#fafaf8'")
        if content != original:
            open(filepath, 'w').write(content)
            count += 1
    except: pass

print(f'✅ Synced background color on {count} pages')
PYEOF

echo ""
echo "✅ All done:"
echo "  Header: warm off-white (#fafaf8), teal stripe, warm border (#e8e5de)"
echo "  Footer: teal mist (#f0fdfa), teal border (#ccfbf1), teal text (#5f8a84)"
echo "  Background: #fafaf8 everywhere"
echo "  All pages verified for SiteHeader + SiteFooter"
echo ""
echo "npm run build"
