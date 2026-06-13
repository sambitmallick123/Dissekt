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
