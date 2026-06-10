'use client';
import { useState } from 'react';

export default function InvitePage() {
  const [tab, setTab] = useState<'request' | 'redeem'>('request');
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
      const res = await fetch('/api/invite', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'request', email, name, reason, organization: org }),
      });
      const data = await res.json();
      if (data.success) { setStatus('success'); setMessage(data.message); }
      else { setStatus('error'); setMessage(data.error || 'Something went wrong'); }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const handleRedeem = async () => {
    if (!code) return;
    setStatus('loading');
    try {
      const res = await fetch('/api/invite', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'redeem', code }),
      });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('dissekt_tier', 'invited');
        localStorage.setItem('dissekt_invite_code', code.toUpperCase());
        localStorage.setItem('dissekt_invite_name', data.name || '');
        setStatus('success');
        setMessage('Access granted! Redirecting...');
        setTimeout(() => window.location.href = '/', 1500);
      } else {
        setStatus('error'); setMessage(data.error || 'Invalid code');
      }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8f8f6', fontFamily: 'inherit', boxSizing: 'border-box', marginBottom: 10 };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: 440, maxWidth: '90vw' }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <a href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 32, height: 32, background: '#7c3aed', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 18 }}>Dissekt</span>
          </a>
        </div>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 28 }}>
          {/* Tabs */}
          <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
            <button onClick={() => { setTab('request'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'request' ? '#7c3aed' : '#f0f0ee', color: tab === 'request' ? '#fff' : '#555' }}>
              Request access
            </button>
            <button onClick={() => { setTab('redeem'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'redeem' ? '#7c3aed' : '#f0f0ee', color: tab === 'redeem' ? '#fff' : '#555' }}>
              I have a code
            </button>
          </div>

          {status === 'success' && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{message}</div>
            </div>
          )}

          {status === 'error' && (
            <div style={{ padding: '10px 14px', background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 13, marginBottom: 12 }}>{message}</div>
          )}

          {/* Request form */}
          {tab === 'request' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Request early access</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Full access includes: 25 scans/day, Detailed mode, Bulk analysis, Compare, Topics, and all future features.</div>
              <input type="email" placeholder="Your email *" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} />
              <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)} style={inputStyle} />
              <input type="text" placeholder="Organization (optional)" value={org} onChange={e => setOrg(e.target.value)} style={inputStyle} />
              <textarea placeholder="Why do you want access? What will you use Dissekt for?" value={reason} onChange={e => setReason(e.target.value)} rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
              <button onClick={handleRequest} disabled={!email || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: email ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Submitting...' : 'Request access'}
              </button>
            </>
          )}

          {/* Redeem code */}
          {tab === 'redeem' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Enter your invite code</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Paste the code from your invitation email.</div>
              <input type="text" placeholder="DSK-XXXXXXXX" value={code} onChange={e => setCode(e.target.value.toUpperCase())} style={{ ...inputStyle, textAlign: 'center', fontSize: 18, fontWeight: 600, letterSpacing: '0.1em' }} />
              <button onClick={handleRedeem} disabled={!code || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: code ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: code ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Verifying...' : 'Unlock access'}
              </button>
            </>
          )}
        </div>

        {/* Free tier info */}
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>
          <p>Free tier: 3 scans/day · Brief mode only</p>
          <a href="/" style={{ color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>Continue with free tier →</a>
        </div>
      </div>
    </main>
  );
}
