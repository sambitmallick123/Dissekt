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
        const d = new Date(expiry);
        const now = new Date();
        const days = Math.round((d.getTime() - now.getTime()) / 86400000);
        if (days > 0) {
          setExpiryText(`${days}d left`);
        } else {
          setExpiryText('Expired');
          localStorage.removeItem('dissekt_tier');
          localStorage.removeItem('dissekt_access_expires');
          setTier('free');
        }
      }
    }
  }, []);

  const signOut = () => {
    localStorage.removeItem('dissekt_tier');
    localStorage.removeItem('dissekt_invite_code');
    localStorage.removeItem('dissekt_invite_name');
    localStorage.removeItem('dissekt_access_expires');
    localStorage.removeItem('dissekt_token');
    localStorage.removeItem('dissekt_email');
    localStorage.removeItem('dissekt_name');
    localStorage.removeItem('dissekt_usage');
    window.location.href = '/';
  };

  const links = [
    { href: '/analyze', label: 'Analyze' },
    { href: '/observatory', label: 'Observatory' },
    { href: '/compare', label: 'Compare' },
    { href: '/help', label: 'Help' },
    { href: '/feedback', label: 'Feedback' },
  ];

  if (!mounted) return null;

  return (
    <nav style={{ position: 'sticky', top: 0, zIndex: 30 }}>
      <div style={{ height: 3, background: '#0d9488' }} />
      <div style={{ background: '#fff', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#0d9488', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 16, color: '#1a1a1a' }}>Dissekt</span>
            <span style={{ fontSize: 9, fontWeight: 700, color: '#0d9488', background: '#f0fdfa', padding: '2px 6px', borderRadius: 4, letterSpacing: '0.05em' }}>BETA</span>
          </a>

          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            {links.map(l => (
              <a key={l.href} href={l.href}
                style={{ fontSize: 13, color: active === l.label ? '#0d9488' : '#777', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
                {l.label}
              </a>
            ))}

            {tier === 'invited' ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                  <span style={{ fontSize: 11, color: '#0d9488', fontWeight: 600 }}>🎫 Invited</span>
                  {expiryText && (
                    <span style={{ fontSize: 9, color: expiryText === 'Expired' ? '#dc2626' : '#888' }}>
                      {expiryText === 'Expired' ? '⚠️ Access expired' : `Access ends in ${expiryText}`}
                    </span>
                  )}
                </div>
                <button onClick={signOut}
                  style={{ fontSize: 11, padding: '4px 10px', background: '#f8fafa', color: '#888', border: '0.5px solid #e5eaea', borderRadius: 5, cursor: 'pointer', fontWeight: 500 }}>
                  Sign out
                </button>
              </div>
            ) : (
              <a href="/invite" style={{ fontSize: 13, color: '#fff', textDecoration: 'none', borderRadius: 8, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>
                Get access
              </a>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
