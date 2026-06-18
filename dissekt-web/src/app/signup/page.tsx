'use client';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function SignupPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSignup = async () => {
    setError('');
    if (!name.trim()) { setError('Please enter your name.'); return; }
    if (!email) { setError('Please enter your email.'); return; }
    if (password.length < 8) { setError('Password must be at least 8 characters.'); return; }
    if (password !== confirmPassword) { setError('Passwords do not match.'); return; }
    setLoading(true);
    try {
      const redirectTo = `${window.location.origin}/auth/callback`;
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { name: name.trim() }, emailRedirectTo: redirectTo },
      });
      if (error) { setError(error.message); setLoading(false); return; }
      if (data.session) {
        // (confirmation off) instant session
        window.location.href = '/dashboard';
      } else {
        // confirmation on → email sent, show check-your-email message
        setSent(true);
        setLoading(false);
      }
    } catch (e: any) {
      setError(e.message || 'Something went wrong.');
      setLoading(false);
    }
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 380, margin: '0 auto', padding: '48px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Create your account</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Full access — 25 brief & 10 detailed scans a day, all features.</p>

        {sent ? (
          <div style={{ padding: 16, background: '#f0fdf4', border: '0.5px solid #bbf7d0', borderRadius: 10, fontSize: 13, color: '#16a34a', lineHeight: 1.6 }}>
            ✓ Almost there! We sent a confirmation link to <strong>{email}</strong>. Click it to activate your account, then you&apos;ll be signed in. (Check your spam folder if you don&apos;t see it.)
          </div>
        ) : (
        <>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <input type="text" placeholder="Your name" value={name}
            onChange={e => setName(e.target.value)}
            style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
          <input type="email" placeholder="you@example.com" value={email}
            onChange={e => setEmail(e.target.value)}
            style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
          <input type="password" placeholder="Password (min 8 characters)" value={password}
            onChange={e => setPassword(e.target.value)}
            style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
          <input type="password" placeholder="Confirm password" value={confirmPassword}
            onChange={e => setConfirmPassword(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleSignup(); }}
            style={{ padding: '10px 12px', borderRadius: 8, border: confirmPassword && password !== confirmPassword ? '0.5px solid #dc2626' : '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
          {confirmPassword && password !== confirmPassword && <div style={{ fontSize: 11, color: '#dc2626' }}>Passwords do not match</div>}
          {error && <div style={{ fontSize: 12, color: '#dc2626', padding: '6px 0' }}>{error}</div>}
          <button onClick={handleSignup} disabled={loading}
            style={{ padding: '11px 0', borderRadius: 8, border: 'none', background: '#0d9488', color: '#fff', fontSize: 14, fontWeight: 600, cursor: loading ? 'default' : 'pointer', opacity: loading ? 0.7 : 1 }}>
            {loading ? 'Creating account…' : 'Create account'}
          </button>
        </div>

        <div style={{ marginTop: 18, fontSize: 13, color: '#888', textAlign: 'center' }}>
          Already have an account? <a href="/login" style={{ color: '#0d9488', textDecoration: 'none', fontWeight: 600 }}>Sign in</a>
        </div>
        </>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
