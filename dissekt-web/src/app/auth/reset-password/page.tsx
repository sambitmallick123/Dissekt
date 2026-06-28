'use client';
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function ResetPasswordPage() {
  const [password, setPassword] = useState('');
  const [ready, setReady] = useState(false);
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showPw, setShowPw] = useState(false);
  const pwChecks = {
    length: password.length >= 8,
    upper: /[A-Z]/.test(password),
    lower: /[a-z]/.test(password),
    number: /[0-9]/.test(password),
    special: /[^A-Za-z0-9]/.test(password),
  };
  const pwValid = Object.values(pwChecks).every(Boolean);
  const suggestPassword = () => {
    const sets = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnpqrstuvwxyz', '23456789', '!@#$%^&*-_+='];
    const all = sets.join('');
    const r = (n: number) => crypto.getRandomValues(new Uint32Array(1))[0] % n;
    const pick = (s: string) => s[r(s.length)];
    const arr = sets.map(pick);
    while (arr.length < 16) arr.push(pick(all));
    for (let i = arr.length - 1; i > 0; i--) { const j = r(i + 1); [arr[i], arr[j]] = [arr[j], arr[i]]; }
    setPassword(arr.join('')); setShowPw(true);
  };

  useEffect(() => {
    // Supabase sets a recovery session from the email link (detectSessionInUrl)
    supabase.auth.getSession().then(({ data }) => {
      setReady(!!data.session);
      if (!data.session) setError('This reset link is invalid or has expired. Request a new one.');
    });
  }, []);

  const handleUpdate = async () => {
    setError('');
    if (!pwValid) { setError('Password must be 8+ chars with uppercase, lowercase, number, and special character.'); return; }
    setLoading(true);
    try {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) { setError(error.message); setLoading(false); return; }
      setDone(true);
      setTimeout(() => { window.location.href = '/dashboard'; }, 1500);
    } catch (e: any) {
      setError(e.message || 'Something went wrong.');
      setLoading(false);
    }
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 380, margin: '0 auto', padding: '48px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Set a new password</h1>
        {done ? (
          <div style={{ padding: 16, background: '#f0fdf4', border: '0.5px solid #bbf7d0', borderRadius: 10, fontSize: 13, color: '#16a34a' }}>
            ✓ Password updated. Redirecting…
          </div>
        ) : (
          <>
            <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Choose a new password for your account.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 11, color: '#888' }}>New password</span>
                <button type="button" onClick={suggestPassword} disabled={!ready} style={{ fontSize: 11, color: '#0d9488', background: 'none', border: 'none', cursor: 'pointer', padding: 0, fontWeight: 600 }}>Suggest strong password</button>
              </div>
              <div style={{ position: 'relative', display: 'flex' }}>
                <input type={showPw ? 'text' : 'password'} placeholder="New password" value={password}
                  onChange={e => setPassword(e.target.value)} disabled={!ready}
                  onKeyDown={e => { if (e.key === 'Enter') handleUpdate(); }}
                  style={{ padding: '10px 38px 10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none', width: '100%', boxSizing: 'border-box' as const }} />
                <button type="button" onClick={() => setShowPw(s => !s)} aria-label={showPw ? 'Hide password' : 'Show password'}
                  style={{ position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', padding: 4, display: 'flex', color: '#888' }}>
                  {showPw ? (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                  ) : (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                  )}
                </button>
              </div>
              {password.length > 0 && !pwValid && (
                <div style={{ fontSize: 11, display: 'flex', flexDirection: 'column', gap: 3, marginTop: 2 }}>
                  {([['length', 'At least 8 characters'], ['upper', 'One uppercase letter'], ['lower', 'One lowercase letter'], ['number', 'One number'], ['special', 'One special character']] as const).map(([k, label]) => (
                    <div key={k} style={{ color: (pwChecks as Record<string, boolean>)[k] ? '#16a34a' : '#aaa', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span>{(pwChecks as Record<string, boolean>)[k] ? '✓' : '○'}</span> {label}
                    </div>
                  ))}
                </div>
              )}
              {error && <div style={{ fontSize: 12, color: '#dc2626', padding: '6px 0' }}>{error}</div>}
              <button onClick={handleUpdate} disabled={loading || !ready || !pwValid}
                style={{ padding: '11px 0', borderRadius: 8, border: 'none', background: '#0d9488', color: '#fff', fontSize: 14, fontWeight: 600, cursor: (loading || !ready || !pwValid) ? 'default' : 'pointer', opacity: (loading || !ready || !pwValid) ? 0.7 : 1 }}>
                {loading ? 'Updating…' : 'Update password'}
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
