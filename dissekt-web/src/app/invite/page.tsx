'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function InvitePage() {
  const [tab, setTab] = useState<'request' | 'signin'>('request');
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [org, setOrg] = useState('');
  const [reason, setReason] = useState('');
  const [code, setCode] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const handleRequest = async () => {
    if (!email) return;
    setStatus('loading');
    try {
      const res = await fetch('/api/invite', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'request', email, name, reason, organization: org }) });
      const data = await res.json();
      if (data.success) { setStatus('success'); setMessage(data.message); }
      else { setStatus('error'); setMessage(data.error || 'Something went wrong'); }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const handleSignIn = async () => {
    if (!email || !code) return;
    setStatus('loading');
    try {
      const res = await fetch('/api/invite', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'redeem', code }) });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('dissekt_tier', 'invited');
        localStorage.setItem('dissekt_invite_code', code.toUpperCase());
        localStorage.setItem('dissekt_invite_name', data.name || name || '');
        localStorage.setItem('dissekt_email', email);
        if (data.access_expires_at) localStorage.setItem('dissekt_access_expires', data.access_expires_at);
        setStatus('success');
        setMessage('Welcome! Redirecting...');
        setTimeout(() => window.location.href = '/analyze', 1500);
      } else { setStatus('error'); setMessage(data.error || 'Invalid code'); }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const inp: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8fafa', fontFamily: 'inherit', boxSizing: 'border-box' as any, marginBottom: 10 };

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 440, margin: '40px auto', padding: '0 24px' }}>
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 28 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
            <button onClick={() => { setTab('request'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'request' ? '#0d9488' : '#f0f0ee', color: tab === 'request' ? '#fff' : '#555' }}>
              Request access
            </button>
            <button onClick={() => { setTab('signin'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'signin' ? '#0d9488' : '#f0f0ee', color: tab === 'signin' ? '#fff' : '#555' }}>
              Sign in
            </button>
          </div>

          {status === 'success' && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{message}</div>
            </div>
          )}

          {status === 'error' && (
            <div style={{ padding: '10px 14px', background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 13, marginBottom: 12 }}>{message}</div>
          )}

          {tab === 'request' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Request early access</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Full access: 25 brief + 10 detailed scans/day, all features. Valid 6 months.</div>
              <input type="email" placeholder="Your email *" value={email} onChange={e => setEmail(e.target.value)} style={inp} />
              <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)} style={inp} />
              <input type="text" placeholder="Organization (optional)" value={org} onChange={e => setOrg(e.target.value)} style={inp} />
              <textarea placeholder="Why do you want access?" value={reason} onChange={e => setReason(e.target.value)} rows={3} style={{ ...inp, resize: 'vertical' }} />
              <button onClick={handleRequest} disabled={!email || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: email ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Submitting...' : 'Request access'}
              </button>
            </>
          )}

          {tab === 'signin' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Sign in</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Enter your email and the invite code from your approval email.</div>
              <input type="email" placeholder="Your email" value={email} onChange={e => setEmail(e.target.value)} style={inp} />
              <input type="text" placeholder="DSK-XXXXXXXX" value={code} onChange={e => setCode(e.target.value.toUpperCase())}
                style={{ ...inp, textAlign: 'center', fontSize: 18, fontWeight: 600, letterSpacing: '0.08em' }} />
              <button onClick={handleSignIn} disabled={!email || !code || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: email && code ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email && code ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Verifying...' : 'Sign in'}
              </button>
            </>
          )}
        </div>

        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>
          <p>Free tier: 3 brief + 1 detailed scan/day (resets 00:00 GMT)</p>
          <p style={{ fontSize: 11, color: '#aaa', marginTop: 4 }}>Invite codes expire in 7 days · Access valid for 6 months</p>
          <a href="/analyze" style={{ color: '#0d9488', textDecoration: 'none', fontWeight: 500, display: 'inline-block', marginTop: 6 }}>Continue with free tier →</a>
        </div>
        <div style={{ textAlign: 'center', marginTop: 12, padding: '10px 14px', background: '#f8f8f6', borderRadius: 8, fontSize: 11, color: '#888' }}>
          🚧 Account signup with password is under development. For now, access is invitation-based.
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
