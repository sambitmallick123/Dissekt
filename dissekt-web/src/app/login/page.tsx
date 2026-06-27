'use client';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    setError('');
    if (!email || !password) { setError('Enter your email and password.'); return; }
    setLoading(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) { setError(error.message); setLoading(false); return; }
      // success → go to analyze
      window.location.href = '/analyze';
    } catch (e: any) {
      setError(e.message || 'Something went wrong.');
      setLoading(false);
    }
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 380, margin: '0 auto', padding: '48px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Sign in</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Welcome back. Enter your details to continue.</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input
            type="email" placeholder="you@example.com" value={email}
            onChange={e => setEmail(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleLogin(); }}
            style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }}
          />
          <input
            type="password" placeholder="Password" value={password}
            onChange={e => setPassword(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleLogin(); }}
            style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }}
          />
          {error && <div style={{ fontSize: 12, color: '#dc2626', padding: '6px 0' }}>{error}</div>}
          <button onClick={handleLogin} disabled={loading}
            style={{ padding: '11px 0', borderRadius: 8, border: 'none', background: '#0d9488', color: '#fff', fontSize: 14, fontWeight: 600, cursor: loading ? 'default' : 'pointer', opacity: loading ? 0.7 : 1 }}>
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </div>

        <div style={{ marginTop: 18, fontSize: 13, color: '#888', textAlign: 'center', lineHeight: 2 }}>
          <a href="/forgot-password" style={{ color: '#0d9488', textDecoration: 'none' }}>Forgot password?</a>
          <br />
          New here? <a href="/signup" style={{ color: '#0d9488', textDecoration: 'none', fontWeight: 600 }}>Create an account</a>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
