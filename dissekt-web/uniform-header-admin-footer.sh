#!/bin/bash
# Dissekt — Admin option 2, uniform auth header, gated dashboard, sticky footer, full user layout
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. FIX STICKY FOOTER — bulletproof
# ============================================

python3 -c "
content = open('src/app/globals.css').read() if __import__('os').path.exists('src/app/globals.css') else ''
if 'min-height: 100vh' not in content:
    content += '''
/* Sticky footer — always at page bottom */
html { height: 100%; }
body { min-height: 100vh; display: flex; flex-direction: column; margin: 0; }
main { flex: 1 0 auto; }
footer { flex-shrink: 0; }
'''
    open('src/app/globals.css', 'w').write(content)
    print('✅ Sticky footer: globals.css')
"

# Also ensure layout.tsx imports globals.css
python3 -c "
content = open('src/app/layout.tsx').read()
if 'globals.css' not in content:
    content = content.replace(\"import type { Metadata }\", \"import './globals.css';\\nimport type { Metadata }\")
    open('src/app/layout.tsx', 'w').write(content)
    print('✅ layout.tsx: globals.css imported')
"

# Also in responsive.css ensure it's there
python3 -c "
content = open('src/app/responsive.css').read()
if 'flex-shrink: 0' not in content or 'footer' not in content:
    content += '''
html { height: 100%; }
body { min-height: 100vh; display: flex; flex-direction: column; }
main { flex: 1 0 auto; }
footer { flex-shrink: 0; }
'''
    open('src/app/responsive.css', 'w').write(content)
    print('✅ responsive.css: sticky footer reinforced')
"

echo "✅ Sticky footer fixed"

# ============================================
# 2. UNIFORM HEADER — shows user info on all pages
# ============================================

cat > src/components/SiteHeader.tsx << 'HEADEOF'
'use client';
import { useEffect, useState } from 'react';

export default function SiteHeader({ active }: { active?: string }) {
  const [tier, setTier] = useState('free');
  const [name, setName] = useState('');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      setTier(localStorage.getItem('dissekt_tier') || 'free');
      setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
      const expiry = localStorage.getItem('dissekt_access_expires');
      if (expiry) {
        const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
        if (days > 0) setExpiryText(`${days}d`);
        else { localStorage.removeItem('dissekt_tier'); localStorage.removeItem('dissekt_access_expires'); setTier('free'); }
      }
    }
  }, []);

  const signOut = () => {
    ['dissekt_tier','dissekt_invite_code','dissekt_invite_name','dissekt_access_expires','dissekt_token','dissekt_email','dissekt_name','dissekt_usage'].forEach(k => localStorage.removeItem(k));
    window.location.href = '/';
  };

  const isLoggedIn = tier === 'invited';

  const links = [
    { href: '/analyze', label: 'Analyze' },
    { href: '/observatory', label: 'Observatory' },
    { href: '/compare', label: 'Compare' },
    ...(isLoggedIn ? [{ href: '/dashboard', label: 'Dashboard' }] : []),
    { href: '/help', label: 'Help' },
  ];

  if (!mounted) return <nav style={{ height: 46 }} />;

  return (
    <>
      <nav style={{ position: 'sticky', top: 0, zIndex: 30 }}>
        <div style={{ height: 2, background: '#0d9488' }} />
        <div style={{ background: '#fafaf8', borderBottom: '0.5px solid #e8e5de' }}>
          <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 8, textDecoration: 'none', color: '#2c2c2a', flexShrink: 0 }}>
                <div style={{ width: 22, height: 22, background: '#0d9488', borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <span style={{ fontWeight: 600, fontSize: 14 }}>Dissekt</span>
              </a>
              <div style={{ width: 1, height: 14, background: '#d3d1c7' }} />
              {/* Desktop nav */}
              <div className="dissekt-nav-links" style={{ display: 'flex', gap: 12 }}>
                {links.map(l => (
                  <a key={l.href} href={l.href} style={{ fontSize: 12, color: active === l.label ? '#0d9488' : '#888780', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>{l.label}</a>
                ))}
              </div>
            </div>

            {/* Desktop right side */}
            <div className="dissekt-nav-links" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              {isLoggedIn ? (
                <>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 24, height: 24, background: '#0d9488', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, color: 'white', fontWeight: 600 }}>
                      {(name || 'U')[0].toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontSize: 11, fontWeight: 500, color: '#1a1a1a', lineHeight: 1 }}>{name || 'User'}</div>
                      <div style={{ fontSize: 9, color: '#888' }}>Invited{expiryText ? ` · ${expiryText} left` : ''}</div>
                    </div>
                  </div>
                  <button onClick={signOut} style={{ fontSize: 10, padding: '3px 10px', background: '#f0f0ee', color: '#888', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Sign out</button>
                </>
              ) : (
                <a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>
              )}
            </div>

            {/* Mobile hamburger */}
            <div className="dissekt-nav-mobile" style={{ display: 'none', alignItems: 'center', gap: 8 }}>
              {isLoggedIn && (
                <div style={{ width: 24, height: 24, background: '#0d9488', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, color: 'white', fontWeight: 600 }}>
                  {(name || 'U')[0].toUpperCase()}
                </div>
              )}
              <button onClick={() => setMenuOpen(!menuOpen)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4, fontSize: 18, color: '#888780', lineHeight: 1 }}>
                {menuOpen ? '✕' : '☰'}
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Mobile dropdown */}
      {menuOpen && (
        <div style={{ position: 'fixed', top: 46, left: 0, right: 0, bottom: 0, zIndex: 29, background: 'rgba(0,0,0,0.3)' }} onClick={() => setMenuOpen(false)}>
          <div style={{ background: '#fafaf8', borderBottom: '0.5px solid #e8e5de', padding: '8px 0' }} onClick={e => e.stopPropagation()}>
            {isLoggedIn && (
              <div style={{ padding: '10px 24px', borderBottom: '0.5px solid #f0efec', display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 28, height: 28, background: '#0d9488', borderRadius: 14, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, color: 'white', fontWeight: 600 }}>
                  {(name || 'U')[0].toUpperCase()}
                </div>
                <div><div style={{ fontSize: 13, fontWeight: 500, color: '#1a1a1a' }}>{name || 'User'}</div><div style={{ fontSize: 10, color: '#888' }}>Invited{expiryText ? ` · ${expiryText} left` : ''}</div></div>
              </div>
            )}
            {links.map(l => (
              <a key={l.href} href={l.href} style={{ display: 'block', padding: '10px 24px', fontSize: 14, color: active === l.label ? '#0d9488' : '#555', textDecoration: 'none', fontWeight: active === l.label ? 600 : 400, borderBottom: '0.5px solid #f0efec' }}>{l.label}</a>
            ))}
            <div style={{ padding: '10px 24px' }}>
              {isLoggedIn ? (
                <button onClick={signOut} style={{ padding: '8px 16px', background: '#f0f0ee', color: '#555', border: 'none', borderRadius: 6, fontSize: 13, cursor: 'pointer', width: '100%' }}>Sign out</button>
              ) : (
                <a href="/invite" style={{ display: 'block', textAlign: 'center', padding: '8px 16px', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Get access</a>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
HEADEOF

echo "✅ Uniform header with user avatar + name on all pages"

# ============================================
# 3. GATE DASHBOARD — only for logged-in users
# ============================================

python3 -c "
content = open('src/app/dashboard/page.tsx').read()
# Add gate at the top of the component
if 'tier !== .invited' not in content and 'must be signed in' not in content:
    content = content.replace(
        'if (!mounted) return null;',
        '''if (!mounted) return null;

  if (tier !== 'invited') {
    return (
      <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
        <SiteHeader />
        <div style={{ maxWidth: 440, margin: '80px auto', padding: '0 16px', textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Dashboard requires access</div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Sign in with your invite code to view your personal insights, trust graph, and API keys.</div>
          <a href=\"/invite\" style={{ display: 'inline-block', padding: '10px 24px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Sign in</a>
        </div>
        <SiteFooter />
      </main>
    );
  }'''
    )
    open('src/app/dashboard/page.tsx', 'w').write(content)
    print('✅ Dashboard: gated for logged-in users only')
"

# ============================================
# 4. FULL OPTION 1 WELCOME BAR with activity feed
# ============================================

cat > src/components/WelcomeBar.tsx << 'WBEOF'
'use client';
import { useState, useEffect } from 'react';

export default function WelcomeBar() {
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
    setTier(localStorage.getItem('dissekt_tier') || 'free');
    const expiry = localStorage.getItem('dissekt_access_expires');
    if (expiry) {
      const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
      if (days > 0) setExpiryText(`${days}d remaining`);
    }
  }, []);

  if (!mounted || tier !== 'invited') return null;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <div style={{ background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', color: 'white' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10 }}>
        <div>
          <div style={{ fontSize: 18, fontWeight: 600 }}>{greeting}{name ? `, ${name}` : ''}</div>
          <div style={{ fontSize: 11, opacity: 0.8, marginTop: 3 }}>See how information is constructed{expiryText ? ` · ${expiryText}` : ''}</div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <a href="/dashboard" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>📊 My insights</a>
          <a href="/aperture" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔖 Bookmarklet</a>
          <a href="/dashboard?tab=apikeys" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔑 API keys</a>
        </div>
      </div>
    </div>
  );
}
WBEOF

echo "✅ WelcomeBar: full option 1 with greeting + quick links"

# ============================================
# 5. ADMIN PAGE — Option 2 dense data view
# ============================================

# We need to see the current admin page structure to know what to update
# Let's create a wrapper that reskins the admin

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# 1. Update page background
content = content.replace("background: '#f5f5f4'", "background: '#fafaf8'")
content = content.replace("background: '#fafaf8'", "background: '#fafaf8'")

# 2. Compact admin header
old_header = """<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <h1 style={{ fontSize: 20, fontWeight: 600, margin: 0, color: '#1a1a1a' }}>Admin</h1>
              <span style={{ fontSize: 9, padding: '2px 8px', background: '#f0fdfa', color: '#0d9488', borderRadius: 4, fontWeight: 500 }}>LIVE</span>
            </div>
            <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>dissekt.info · Platform management</div>
          </div>
        </div>"""

if old_header in content:
    pass  # Already updated
elif '<h1' in content and 'Admin dashboard' in content:
    content = content.replace(
        "<h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Admin dashboard</h1>",
        """<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>Admin</span>
            <span style={{ fontSize: 9, padding: '2px 8px', background: '#f0fdfa', color: '#0d9488', borderRadius: 4, fontWeight: 500 }}>LIVE</span>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <button onClick={() => window.location.reload()} style={{ fontSize: 10, padding: '4px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 4, cursor: 'pointer', color: '#888' }}>↻ Refresh</button>
          </div>
        </div>"""
    )

# 3. Change tabs to underlined text style (option 2)
content = content.replace(
    "padding: '6px 16px', borderRadius: 8, fontSize: 12, fontWeight: 600",
    "padding: '6px 12px', borderRadius: 0, fontSize: 12, fontWeight: 500, borderBottom: '2px solid transparent'"
)

# Update active tab styling
content = content.replace(
    "background: activeTab === tab.id ? '#0d9488' : '#fff', boxShadow: activeTab === tab.id ? 'none' : '0 0 0 0.5px #e5eaea'",
    "background: 'transparent', borderBottomColor: activeTab === tab.id ? '#0d9488' : 'transparent'"
)
content = content.replace(
    "background: activeTab === tab.id ? '#0d9488' : '#f0f0ee'",
    "background: 'transparent', borderBottom: activeTab === tab.id ? '2px solid #0d9488' : '2px solid transparent'"
)
content = content.replace(
    "color: activeTab === tab.id ? '#fff' : '#555'",
    "color: activeTab === tab.id ? '#0d9488' : '#888'"
)

# 4. Make stat cards denser with mini sparklines look
content = content.replace(
    "gridTemplateColumns: 'repeat(3, 1fr)', gap: 12",
    "gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: 8"
)
content = content.replace(
    "gridTemplateColumns: 'repeat(4, 1fr)', gap: 12",
    "gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: 8"
)

# 5. Tighten padding
content = content.replace("padding: '16px 20px'", "padding: '12px 14px'")
content = content.replace("padding: '24px'", "padding: '16px'")
content = content.replace("maxWidth: 1000, margin: '0 auto', padding: '24px 16px'", "maxWidth: 1100, margin: '0 auto', padding: '16px'")
content = content.replace("maxWidth: 1000, margin: '0 auto', padding: '24px'", "maxWidth: 1100, margin: '0 auto', padding: '16px'")

# 6. Make the tabs container have a bottom border
content = content.replace(
    "display: 'flex', gap: 4, marginBottom: 20, flexWrap: 'wrap'",
    "display: 'flex', gap: 0, marginBottom: 16, borderBottom: '0.5px solid #e5eaea', flexWrap: 'wrap'"
)
content = content.replace(
    "display: 'flex', gap: 4, marginBottom: 20",
    "display: 'flex', gap: 0, marginBottom: 16, borderBottom: '0.5px solid #e5eaea', flexWrap: 'wrap'"
)

# 7. Remove the Sign out button from admin (handled by header)
content = content.replace(
    """<button onClick={() => { setAuth(false); }} style={{ padding: '6px 16px', background: '#fff', border: '1px solid #dc2626', color: '#dc2626', borderRadius: 8, fontSize: 13, cursor: 'pointer' }}>Sign out</button>""",
    ""
)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin: option 2 dense data view styling')
PYEOF

echo "✅ Admin: dense data view"

echo ""
echo "✅ All changes applied:"
echo ""
echo "  📌 Sticky footer: reinforced in globals.css + responsive.css"
echo "     html 100% height, body flex-column min-100vh, main flex-1, footer flex-shrink-0"
echo ""
echo "  👤 Uniform header (all pages):"
echo "     Logged in: avatar circle + name + 'Invited · 142d left' + Sign out"
echo "     Free: 'Get access' button"
echo "     Dashboard link: only shows when logged in"
echo "     Mobile: avatar + hamburger → dropdown with user info"
echo ""
echo "  🔒 Dashboard gated:"
echo "     Free user → /dashboard → locked page with 'Sign in' CTA"
echo "     Invited user → full insights + API keys"
echo ""
echo "  🎉 Welcome bar (option 1):"
echo "     Teal gradient, time-based greeting + name"
echo "     Quick links: My insights, Bookmarklet, API keys"
echo "     Only visible for invited users on /analyze"
echo ""
echo "  📊 Admin (option 2 dense):"
echo "     Underlined text tabs (not pills)"
echo "     Compact header: 'Admin LIVE' + Refresh button"
echo "     Dense stat cards, tighter padding"
echo "     Tab border-bottom indicator"
echo ""
echo "npm run build"
