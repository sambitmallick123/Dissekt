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
