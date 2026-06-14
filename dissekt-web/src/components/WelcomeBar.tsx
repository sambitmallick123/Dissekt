'use client';
import { useState, useEffect } from 'react';

export default function WelcomeBar() {
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
    setTier(localStorage.getItem('dissekt_tier') || 'free');
  }, []);

  if (!mounted || tier !== 'invited') return null;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <div style={{ background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', padding: '14px 24px', color: 'white' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{greeting}{name ? `, ${name}` : ''}</div>
          <div style={{ fontSize: 11, opacity: 0.8, marginTop: 2 }}>See how information is constructed</div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <a href="/dashboard" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>📊 My insights</a>
          <a href="/aperture" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔖 Aperture</a>
          <a href="/dashboard" style={{ padding: '5px 12px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 10, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔑 API keys</a>
        </div>
      </div>
    </div>
  );
}
