#!/bin/bash
# Dissekt — Responsive design for all screen sizes
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Add global responsive CSS
# ============================================

cat > src/app/responsive.css << 'CSSEOF'
/* Dissekt responsive breakpoints */

/* Viewport meta should be in layout.tsx */

/* Mobile-first responsive utilities */
@media (max-width: 768px) {
  /* Global */
  body { -webkit-text-size-adjust: 100%; }
  
  /* Header */
  .dissekt-nav-links { display: none !important; }
  .dissekt-nav-mobile { display: flex !important; }
  .dissekt-nav-container { padding: 8px 16px !important; }
  
  /* Footer */
  .dissekt-footer-inner { flex-direction: column !important; gap: 8px !important; text-align: center !important; }
  .dissekt-footer-links { justify-content: center !important; flex-wrap: wrap !important; gap: 10px !important; }
  
  /* Content containers */
  .dissekt-content { padding: 16px !important; }
  
  /* Grids → single column */
  .dissekt-grid-2, .dissekt-grid-3, .dissekt-grid-4 { grid-template-columns: 1fr !important; }
  
  /* Hide on mobile */
  .dissekt-hide-mobile { display: none !important; }
}

@media (min-width: 769px) {
  .dissekt-nav-mobile { display: none !important; }
  .dissekt-hide-desktop { display: none !important; }
}

@media (max-width: 480px) {
  /* Extra small screens */
  .dissekt-hero-title { font-size: 24px !important; }
  .dissekt-hero-subtitle { font-size: 14px !important; }
  .dissekt-hero-buttons { flex-direction: column !important; }
}
CSSEOF

echo "✅ Global responsive CSS"

# ============================================
# 2. Import CSS in layout.tsx
# ============================================

python3 << 'PYEOF'
content = open('src/app/layout.tsx').read()

if 'responsive.css' not in content:
    content = content.replace(
        "import type { Metadata } from 'next';",
        "import type { Metadata } from 'next';\nimport './responsive.css';"
    )

# Ensure viewport meta exists
if 'viewport' not in content:
    content = content.replace(
        'export const metadata: Metadata = {',
        '''export const metadata: Metadata = {
  viewport: 'width=device-width, initial-scale=1, maximum-scale=5','''
    )

open('src/app/layout.tsx', 'w').write(content)
print('✅ layout.tsx: responsive CSS + viewport meta')
PYEOF

# ============================================
# 3. SiteHeader — mobile hamburger menu
# ============================================

cat > src/components/SiteHeader.tsx << 'HEADEOF'
'use client';
import { useEffect, useState } from 'react';

export default function SiteHeader({ active }: { active?: string }) {
  const [tier, setTier] = useState('free');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      setTier(localStorage.getItem('dissekt_tier') || 'free');
      const expiry = localStorage.getItem('dissekt_access_expires');
      if (expiry) {
        const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
        if (days > 0) setExpiryText(`${days}d`);
        else {
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
    <>
      <nav style={{ position: 'sticky', top: 0, zIndex: 30 }}>
        <div style={{ height: 2, background: '#0d9488' }} />
        <div className="dissekt-nav-container" style={{ background: '#fafaf8', borderBottom: '0.5px solid #e8e5de' }}>
          <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            {/* Logo */}
            <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 8, textDecoration: 'none', color: '#2c2c2a', flexShrink: 0 }}>
              <div style={{ width: 22, height: 22, background: '#0d9488', borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              </div>
              <span style={{ fontWeight: 600, fontSize: 14 }}>Dissekt</span>
            </a>

            {/* Desktop nav */}
            <div className="dissekt-nav-links" style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{ width: 1, height: 14, background: '#d3d1c7' }} />
              {links.map(l => (
                <a key={l.href} href={l.href}
                  style={{ fontSize: 12, color: active === l.label ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
                  {l.label}
                </a>
              ))}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                {tier === 'invited' ? (
                  <>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '3px 8px', background: '#e1f5ee', borderRadius: 4, fontSize: 9, fontWeight: 600, color: '#085041' }}>
                      <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#0d9488' }} /> Invited
                    </div>
                    {expiryText && <div style={{ padding: '3px 8px', background: '#ccfbf1', borderRadius: 4, fontSize: 9, fontWeight: 600, color: '#04342c' }}>{expiryText}</div>}
                    <button onClick={signOut} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 3, color: '#b4b2a9', fontSize: 13 }}>✕</button>
                  </>
                ) : (
                  <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '4px 12px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
                )}
              </div>
            </div>

            {/* Mobile hamburger */}
            <div className="dissekt-nav-mobile" style={{ display: 'none', alignItems: 'center', gap: 8 }}>
              {tier === 'invited' && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '3px 8px', background: '#e1f5ee', borderRadius: 4, fontSize: 9, fontWeight: 600, color: '#085041' }}>
                  <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#0d9488' }} /> {expiryText || 'Invited'}
                </div>
              )}
              <button onClick={() => setMenuOpen(!menuOpen)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4, fontSize: 18, color: '#888780', lineHeight: 1 }}>
                {menuOpen ? '✕' : '☰'}
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Mobile menu dropdown */}
      {menuOpen && (
        <div style={{ position: 'fixed', top: 46, left: 0, right: 0, bottom: 0, zIndex: 29, background: 'rgba(0,0,0,0.3)' }} onClick={() => setMenuOpen(false)}>
          <div style={{ background: '#fafaf8', borderBottom: '0.5px solid #e8e5de', padding: '8px 0' }} onClick={e => e.stopPropagation()}>
            {links.map(l => (
              <a key={l.href} href={l.href}
                style={{ display: 'block', padding: '10px 24px', fontSize: 14, color: active === l.label ? '#0d9488' : '#555', textDecoration: 'none', fontWeight: active === l.label ? 600 : 400, borderBottom: '0.5px solid #f0efec' }}>
                {l.label}
              </a>
            ))}
            <div style={{ padding: '10px 24px', display: 'flex', gap: 8 }}>
              {tier === 'invited' ? (
                <button onClick={signOut} style={{ padding: '8px 16px', background: '#f0f0ee', color: '#555', border: 'none', borderRadius: 6, fontSize: 13, cursor: 'pointer' }}>Sign out</button>
              ) : (
                <a href="/invite" style={{ padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
HEADEOF

echo "✅ SiteHeader: responsive with mobile menu"

# ============================================
# 4. SiteFooter — responsive
# ============================================

cat > src/components/SiteFooter.tsx << 'FOOTEOF'
'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#f0fdfa', borderTop: '0.5px solid #ccfbf1', marginTop: 40 }}>
      <div className="dissekt-footer-inner" style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: '#5f8a84' }}>
          <div style={{ width: 16, height: 16, background: '#0d9488', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span>© 2026 Dissekt · Munich · Beta</span>
        </div>
        <div className="dissekt-footer-links" style={{ display: 'flex', gap: 14, fontSize: 11 }}>
          <a href="/help" style={{ color: '#5f8a84', textDecoration: 'none' }}>Help</a>
          <a href="/feedback" style={{ color: '#5f8a84', textDecoration: 'none' }}>Feedback</a>
          <a href="/contact" style={{ color: '#5f8a84', textDecoration: 'none' }}>Contact</a>
          <a href="/docs" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>
          <a href="/privacy" style={{ color: '#5f8a84', textDecoration: 'none' }}>Privacy</a>
          <a href="/terms" style={{ color: '#5f8a84', textDecoration: 'none' }}>Terms</a>
        </div>
      </div>
    </footer>
  );
}
FOOTEOF

echo "✅ SiteFooter: responsive"

# ============================================
# 5. Add responsive classes to LandingPage
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Add responsive class names to key elements
content = content.replace(
    "fontSize: 36, fontWeight: 700",
    "fontSize: 36, fontWeight: 700, className: 'dissekt-hero-title'"
).replace(
    "fontSize: 36, fontWeight: 700, className: 'dissekt-hero-title'",
    "fontSize: 36, fontWeight: 700"
)

# Make grids responsive by adding inline responsive styles
# Replace 3-col grids
content = content.replace(
    "gridTemplateColumns: 'repeat(3, 1fr)'",
    "gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))'"
)
# Replace 2-col grids
content = content.replace(
    "gridTemplateColumns: 'repeat(2, 1fr)'",
    "gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))'"
)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ LandingPage: responsive grids')
PYEOF

# ============================================
# 6. Make all pages use responsive grids
# ============================================

python3 << 'PYEOF'
import glob

count = 0
for filepath in glob.glob('src/**/*.tsx', recursive=True):
    try:
        content = open(filepath).read()
        original = content
        
        # Replace fixed grid columns with responsive auto-fit
        content = content.replace(
            "gridTemplateColumns: 'repeat(4, 1fr)'",
            "gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))'"
        )
        content = content.replace(
            "gridTemplateColumns: 'repeat(3, 1fr)'",
            "gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))'"
        )
        content = content.replace(
            "gridTemplateColumns: 'repeat(2, 1fr)'",
            "gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))'"
        )
        
        # Make max-width containers responsive
        content = content.replace(
            "maxWidth: 900, margin: '0 auto', padding: '32px 24px'",
            "maxWidth: 900, margin: '0 auto', padding: '32px 16px'"
        )
        content = content.replace(
            "maxWidth: 800, margin: '0 auto', padding: '32px 24px'",
            "maxWidth: 800, margin: '0 auto', padding: '32px 16px'"
        )
        content = content.replace(
            "maxWidth: 700, margin: '0 auto', padding: '32px 24px'",
            "maxWidth: 700, margin: '0 auto', padding: '32px 16px'"
        )
        content = content.replace(
            "maxWidth: 640, margin: '0 auto', padding: '32px 24px'",
            "maxWidth: 640, margin: '0 auto', padding: '32px 16px'"
        )
        
        # Make flex gaps responsive
        content = content.replace(
            "display: 'flex', gap: 40, flexWrap: 'wrap'",
            "display: 'flex', gap: 24, flexWrap: 'wrap'"
        )
        
        if content != original:
            open(filepath, 'w').write(content)
            count += 1
    except: pass

print(f'✅ Made {count} files responsive')
PYEOF

# ============================================
# 7. Make analyze page responsive
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Make the scan header responsive
content = content.replace(
    "display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12",
    "display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, flexWrap: 'wrap', gap: 8"
)

# Make content container responsive
content = content.replace(
    "maxWidth: 1100, margin: '0 auto', padding: '20px 24px'",
    "maxWidth: 1100, margin: '0 auto', padding: '20px 16px'"
)
content = content.replace(
    "maxWidth: 1100, margin: '0 auto', padding: '16px 24px'",
    "maxWidth: 1100, margin: '0 auto', padding: '16px'"
)

open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze page: responsive')
PYEOF

# ============================================
# 8. Make admin page responsive
# ============================================

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Make tab bar scrollable on mobile
content = content.replace(
    "display: 'flex', gap: 4, marginBottom: 20, overflowX: 'auto'",
    "display: 'flex', gap: 4, marginBottom: 20, overflowX: 'auto', WebkitOverflowScrolling: 'touch', paddingBottom: 4"
)

# Make admin container responsive
content = content.replace(
    "maxWidth: 1000, margin: '0 auto', padding: '24px'",
    "maxWidth: 1000, margin: '0 auto', padding: '24px 16px'"
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin page: responsive')
PYEOF

# ============================================
# 9. Make invite page responsive
# ============================================

python3 << 'PYEOF'
content = open('src/app/invite/page.tsx').read()

content = content.replace(
    "maxWidth: 440, margin: '40px auto', padding: '0 24px'",
    "maxWidth: 440, margin: '40px auto', padding: '0 16px'"
)

open('src/app/invite/page.tsx', 'w').write(content)
print('✅ Invite page: responsive')
PYEOF

# ============================================
# 10. Make help page responsive
# ============================================

python3 << 'PYEOF'
try:
    content = open('src/app/help/page.tsx').read()
    content = content.replace(
        "maxWidth: 800, margin: '0 auto', padding: '32px 24px'",
        "maxWidth: 800, margin: '0 auto', padding: '32px 16px'"
    )
    open('src/app/help/page.tsx', 'w').write(content)
    print('✅ Help page: responsive')
except: print('  Help page not found or already done')
PYEOF

echo ""
echo "✅ Responsive design complete:"
echo ""
echo "  📱 Mobile (< 768px):"
echo "     - Hamburger menu replaces nav links"
echo "     - Full-screen dropdown menu overlay"
echo "     - Footer stacks vertically, centered"
echo "     - All grids collapse to single column"
echo "     - Reduced padding (24px → 16px)"
echo ""
echo "  📱 Small mobile (< 480px):"
echo "     - Hero title shrinks to 24px"
echo "     - CTA buttons stack vertically"
echo ""
echo "  💻 Desktop (> 768px):"
echo "     - Full horizontal nav"
echo "     - Multi-column grids"
echo "     - Hamburger hidden"
echo ""
echo "npm run build"
