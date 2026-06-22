'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import { useState, useEffect } from 'react';
import { refreshAuth, isMember } from '@/lib/tier';
import Constellation from '@/components/Constellation';

export default function ObservatoryPage() {
  const [mounted, setMounted] = useState(false);
  const [member, setMember] = useState(false);

  useEffect(() => {
    refreshAuth().then(() => { setMember(isMember()); setMounted(true); });
  }, []);

  if (!mounted) return null;

  if (!member) {
    return (
      <main style={{ flex: 1, background: '#fafaf8' }}>
        <SiteHeader />
        <div style={{ maxWidth: 440, margin: '80px auto', padding: '0 16px', textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Observatory requires an account</div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Your personal knowledge graph of the entities you analyze. Sign up free to explore it.</div>
          <a href="/signup" style={{ display: 'inline-block', padding: '10px 24px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Sign up free</a>
          <div style={{ marginTop: 12, fontSize: 12, color: '#aaa' }}>Already have an account? <a href="/login" style={{ color: '#0d9488', textDecoration: 'none' }}>Sign in</a></div>
        </div>
        <SiteFooter />
      </main>
    );
  }

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Constellation</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Your personal knowledge graph — the entities you analyze and how they connect by manipulation pattern.</p>
        <Constellation />
      </div>
      <SiteFooter />
    </main>
  );
}
