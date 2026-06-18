'use client';
import { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';

// Pages where the banner should NOT appear
const EXCLUDED = ['/', '/admin', '/invite', '/signup', '/login', '/forgot-password', '/auth/reset-password'];

export default function WelcomeBar() {
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
    setTier(localStorage.getItem('dissekt_tier') || 'free');
    const expiry = localStorage.getItem('dissekt_access_expires');
    if (expiry) {
      const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
      if (days > 0) setExpiryText(`${days}d remaining`);
    }
    // One-time cache migration
    try {
      if (localStorage.getItem('dissekt_scan_schema') !== 'v2') {
        localStorage.removeItem('dissekt_scans');
        localStorage.removeItem('dissekt_history');
        localStorage.removeItem('dissekt_recent');
        localStorage.setItem('dissekt_scan_schema', 'v2');
      }
    } catch {}
  }, []);

  if (!mounted || tier !== 'member') return null;
  if (EXCLUDED.includes(pathname)) return null;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <div style={{ background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', color: 'white' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10 }}>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>{greeting}{name ? `, ${name}` : ''}</div>
          <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>See how information is constructed{expiryText ? ` · ${expiryText}` : ''}</div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <a href="/dashboard" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>📊 My insights</a>
          <a href="/dashboard" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔑 API keys</a>
        </div>
      </div>
    </div>
  );
}
