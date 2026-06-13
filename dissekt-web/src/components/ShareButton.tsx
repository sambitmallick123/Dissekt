'use client';
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function ShareButton({ reportId, onCopied }: { reportId: string; onCopied?: () => void }) {
  const [showModal, setShowModal] = useState(false);
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const copyLink = () => {
    const url = `${window.location.origin}/report/${reportId}`;
    navigator.clipboard.writeText(url);
    onCopied?.();
  };

  const sendEmail = async () => {
    if (!email) return;
    setStatus('sending');
    try {
      const res = await fetch(`${API_URL}/api/share`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ to: email, report_id: reportId, from_name: name || 'Someone', message }),
      });
      const data = await res.json();
      setStatus(data.success ? 'sent' : 'error');
    } catch { setStatus('error'); }
  };

  return (
    <>
      <div style={{ display: 'flex', gap: 4 }}>
        <button onClick={copyLink}
          style={{ padding: '5px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
          🔗 Copy link
        </button>
        <button onClick={() => setShowModal(true)}
          style={{ padding: '5px 12px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
          📧 Email
        </button>
      </div>

      {showModal && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setShowModal(false)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 14, padding: 24, maxWidth: 400, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Share this analysis</div>
            {status === 'sent' ? (
              <div style={{ textAlign: 'center', padding: '16px 0' }}>
                <div style={{ fontSize: 24, marginBottom: 6 }}>✅</div>
                <div style={{ fontSize: 13, color: '#166534' }}>Email sent!</div>
              </div>
            ) : (
              <>
                <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
                <input type="email" placeholder="Recipient email *" value={email} onChange={e => setEmail(e.target.value)}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
                <textarea placeholder="Add a note (optional)" value={message} onChange={e => setMessage(e.target.value)} rows={2}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', resize: 'vertical', marginBottom: 8, boxSizing: 'border-box' as any, fontFamily: 'inherit' }} />
                <button onClick={sendEmail} disabled={!email || status === 'sending'}
                  style={{ width: '100%', padding: '8px 0', background: email ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                  {status === 'sending' ? 'Sending...' : 'Send'}
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
