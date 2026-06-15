'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function SuggestSourcePage() {
  const [url, setUrl] = useState('');
  const [name, setName] = useState('');
  const [reason, setReason] = useState('');
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const submit = async () => {
    if (!url) return;
    setStatus('loading');
    try {
      const res = await fetch(`${API_URL}/api/suggest-source`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ url, name, reason, email }) });
      const data = await res.json();
      setStatus(data.success ? 'success' : 'error');
    } catch { setStatus('error'); }
  };

  const inp: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff', fontFamily: 'inherit', boxSizing: 'border-box' as any, marginBottom: 10 };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 520, margin: '40px auto', padding: '0 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Suggest a source</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Know a reliable independent outlet or journalist? Suggest it for our Scope feeds. We review every submission.</p>
        {status === 'success' ? (
          <div style={{ background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 14, padding: 28, textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#166534' }}>Suggestion received</div>
            <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>We review all submissions and add quality sources.</div>
            <a href="/analyze" style={{ display: 'inline-block', marginTop: 16, padding: '8px 20px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Back to Analyze</a>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            <input type="url" placeholder="RSS feed or website URL *" value={url} onChange={e => setUrl(e.target.value)} style={inp} />
            <input type="text" placeholder="Source name (e.g., The Wire, Bellingcat)" value={name} onChange={e => setName(e.target.value)} style={inp} />
            <textarea placeholder="Why should we add this source?" value={reason} onChange={e => setReason(e.target.value)} rows={3} style={{ ...inp, resize: 'vertical' }} />
            <input type="email" placeholder="Your email (optional)" value={email} onChange={e => setEmail(e.target.value)} style={inp} />
            <button onClick={submit} disabled={!url || status === 'loading'} style={{ width: '100%', padding: '11px 0', background: url ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: url ? 'pointer' : 'not-allowed' }}>
              {status === 'loading' ? 'Submitting...' : 'Suggest source'}
            </button>
            <div style={{ marginTop: 14, padding: '10px 14px', background: '#f8fafa', borderRadius: 8, fontSize: 11, color: '#888', lineHeight: 1.7 }}>
              <strong>What we look for:</strong> Original reporting, clear editorial standards, RSS feed preferred. Independent newsrooms, investigative outlets, subject-matter experts.
            </div>
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
