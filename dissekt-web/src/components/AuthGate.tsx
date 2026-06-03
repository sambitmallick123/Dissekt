'use client';
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';

export default function AuthGate({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => { setUser(user); setLoading(false); });
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => { setUser(session?.user ?? null); });
    return () => subscription.unsubscribe();
  }, []);

  const handleSubmit = async () => {
    setError(''); setSuccess('');
    try {
      if (isSignUp) {
        const { data, error: err } = await supabase.auth.signUp({ email, password });
        if (err) throw err;
        if (data.user && !data.session) setSuccess('Check your email to confirm your account.');
      } else {
        const { error: err } = await supabase.auth.signInWithPassword({ email, password });
        if (err) throw err;
      }
    } catch (e: any) { setError(e.message || 'Authentication failed'); }
  };

  if (loading) return <div style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888' }}>Loading...</div>;

  if (!user) return (
    <div style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 32, width: 380, maxWidth: '90vw' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24, justifyContent: 'center' }}>
          <div style={{ width: 32, height: 32, background: '#7c3aed', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span style={{ fontWeight: 700, fontSize: 18 }}>Dissekt</span>
        </div>
        <div style={{ fontSize: 13, color: '#888', textAlign: 'center', marginBottom: 20 }}>{isSignUp ? 'Create your free account' : 'Sign in to continue'}</div>
        {error && <div style={{ fontSize: 12, color: '#dc2626', marginBottom: 10, padding: '8px 12px', background: '#fef2f2', borderRadius: 6, border: '1px solid #fecaca' }}>{error}</div>}
        {success && <div style={{ fontSize: 12, color: '#059669', marginBottom: 10, padding: '8px 12px', background: '#f0fdf4', borderRadius: 6, border: '1px solid #bbf7d0' }}>{success}</div>}
        <input type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === 'Enter' && handleSubmit()}
          style={{ width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, marginBottom: 12, outline: 'none', background: '#f8f8f6' }} />
        <input type="password" placeholder="Password (min 6 characters)" value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && handleSubmit()}
          style={{ width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, marginBottom: 12, outline: 'none', background: '#f8f8f6' }} />
        <button onClick={handleSubmit} style={{ width: '100%', padding: '10px 0', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer', marginBottom: 8 }}>
          {isSignUp ? 'Create account' : 'Sign in'}
        </button>
        <button onClick={() => { setIsSignUp(!isSignUp); setError(''); setSuccess(''); }}
          style={{ fontSize: 13, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', textAlign: 'center', width: '100%', marginTop: 8 }}>
          {isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up free"}
        </button>
      </div>
    </div>
  );

  return <>{children}</>;
}
