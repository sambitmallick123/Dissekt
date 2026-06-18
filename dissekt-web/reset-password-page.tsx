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

  useEffect(() => {
    // Supabase sets a recovery session from the email link (detectSessionInUrl)
    supabase.auth.getSession().then(({ data }) => {
      setReady(!!data.session);
      if (!data.session) setError('This reset link is invalid or has expired. Request a new one.');
    });
  }, []);

  const handleUpdate = async () => {
    setError('');
    if (password.length < 8) { setError('Password must be at least 8 characters.'); return; }
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
              <input type="password" placeholder="New password (min 8 characters)" value={password}
                onChange={e => setPassword(e.target.value)} disabled={!ready}
                onKeyDown={e => { if (e.key === 'Enter') handleUpdate(); }}
                style={{ padding: '10px 12px', borderRadius: 8, border: '0.5px solid #d5dada', fontSize: 14, outline: 'none' }} />
              {error && <div style={{ fontSize: 12, color: '#dc2626', padding: '6px 0' }}>{error}</div>}
              <button onClick={handleUpdate} disabled={loading || !ready}
                style={{ padding: '11px 0', borderRadius: 8, border: 'none', background: '#0d9488', color: '#fff', fontSize: 14, fontWeight: 600, cursor: (loading || !ready) ? 'default' : 'pointer', opacity: (loading || !ready) ? 0.7 : 1 }}>
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
