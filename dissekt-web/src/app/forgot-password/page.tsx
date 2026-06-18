'use client';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleReset = async () => {
    setError('');
    if (!email) { setError('Please enter your email.'); return; }
    setLoading(true);
    try {
      const redirectTo = `${window.location.origin}/auth/reset-password`;
      const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo });
      if (error) { setError(error.message); setLoading(false); return; }
      setSent(true);
    } catch (e: any) {
      setError(e.message || 'Something went wrong.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 380, margin: '0 auto', padding: '48px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Reset password</h1>
        {sent ? (
          <div style={{ padding: 16, background: '#f0fdf4', border: '0.5px solid #bbf7d0', borderRadius: 10, fontSize: 13, color: '#16a34a', lineHeight: 1.6 }}>
            ✓ If an account exists for {email}, a password reset link has been sent. Check your inbox (and spam folder).
          </div>
        ) : (
          <>
            <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Enter your email and we&apos;ll send you a link to set a new password.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <input type="email" placeholder="you@example.com" value={email}
                onChange={e => setEmail(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') handleReset(); }}
                style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
              {error && <div style={{ fontSize: 12, color: '#dc2626', padding: '6px 0' }}>{error}</div>}
              <button onClick={handleReset} disabled={loading}
                style={{ padding: '11px 0', borderRadius: 8, border: 'none', background: '#0d9488', color: '#fff', fontSize: 14, fontWeight: 600, cursor: loading ? 'default' : 'pointer', opacity: loading ? 0.7 : 1 }}>
                {loading ? 'Sending…' : 'Send reset link'}
              </button>
            </div>
          </>
        )}
        <div style={{ marginTop: 18, fontSize: 13, color: '#888', textAlign: 'center' }}>
          <a href="/login" style={{ color: '#0d9488', textDecoration: 'none' }}>Back to sign in</a>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
