'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function SignupPage() {
  const [mode, setMode] = useState<'signup' | 'login'>('signup');
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const handleSubmit = async () => {
    if (!email || !password) return;
    setStatus('loading');
    try {
      const res = await fetch(`${API_URL}/api/auth/${mode}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, name, password }),
      });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('dissekt_token', data.token);
        localStorage.setItem('dissekt_tier', data.user.tier);
        localStorage.setItem('dissekt_email', data.user.email);
        localStorage.setItem('dissekt_name', data.user.name || '');
        setStatus('success');
        setMessage(mode === 'signup' ? 'Account created!' : 'Welcome back!');
        setTimeout(() => window.location.href = '/analyze', 1500);
      } else {
        setStatus('error');
        setMessage(data.detail || data.error || 'Something went wrong');
      }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const inp: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fafaf8', marginBottom: 10, boxSizing: 'border-box' as any };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 400, margin: '60px auto', padding: '0 24px' }}>
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 28 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
            <button onClick={() => { setMode('signup'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'signup' ? '#0d9488' : '#f0f0ee', color: mode === 'signup' ? '#fff' : '#555' }}>
              Sign up
            </button>
            <button onClick={() => { setMode('login'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'login' ? '#0d9488' : '#f0f0ee', color: mode === 'login' ? '#fff' : '#555' }}>
              Log in
            </button>
          </div>

          {status === 'success' && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{message}</div>
              <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>Redirecting...</div>
            </div>
          )}

          {status === 'error' && (
            <div style={{ padding: '8px 12px', background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12, marginBottom: 12 }}>{message}</div>
          )}

          {status !== 'success' && (
            <>
              {mode === 'signup' && <input type="text" placeholder="Name" value={name} onChange={e => setName(e.target.value)} style={inp} />}
              <input type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} style={inp} />
              <input type="password" placeholder="Password (8+ characters)" value={password} onChange={e => setPassword(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleSubmit()} style={inp} />
              <button onClick={handleSubmit} disabled={!email || !password || password.length < 8 || status === 'loading'}
                style={{ width: '100%', padding: '10px 0', background: email && password.length >= 8 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email && password.length >= 8 ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Please wait...' : mode === 'signup' ? 'Create account' : 'Log in'}
              </button>
              <div style={{ textAlign: 'center', marginTop: 12, fontSize: 12, color: '#888' }}>
                {mode === 'signup' ? (
                  <>Already have an invite code? <a href="/invite" style={{ color: '#0d9488' }}>Redeem here</a></>
                ) : (
                  <>No account? <a href="/invite" style={{ color: '#0d9488' }}>Request access</a></>
                )}
              </div>
            </>
          )}
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
