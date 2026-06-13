'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const SUBJECTS = [
  'General inquiry',
  'API access / integration',
  'Partnership / collaboration',
  'Press / media inquiry',
  'Bug report',
  'Feature request',
  'Data deletion request',
  'Other',
];

export default function ContactPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [subject, setSubject] = useState('General inquiry');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async () => {
    if (!message.trim()) return;
    setStatus('sending');
    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, subject, message }),
      });
      if (res.ok) { setStatus('sent'); setMessage(''); }
      else setStatus('error');
    } catch { setStatus('error'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fafaf8', fontFamily: 'inherit', boxSizing: 'border-box' as const };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>Contact us</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Questions, partnerships, or just want to say hi? We'll get back to you.</p>

        {status === 'sent' ? (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 32, textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Message sent!</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>We typically respond within 24 hours.</div>
            <button onClick={() => setStatus('idle')} style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Send another</button>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            {/* Subject */}
            <div style={{ marginBottom: 12 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Subject</label>
              <select value={subject} onChange={e => setSubject(e.target.value)} style={{ ...inputStyle, cursor: 'pointer' }}>
                {SUBJECTS.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>

            {/* Name + Email */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Name</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="Your name" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Email</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="For reply" style={inputStyle} />
              </div>
            </div>

            {/* Message */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Message *</label>
              <textarea value={message} onChange={e => setMessage(e.target.value)} rows={5} placeholder="How can we help?" style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            {status === 'error' && (
              <div style={{ marginBottom: 12, padding: 10, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12 }}>Failed to send. Try again or email sambitmallick123@gmail.com directly.</div>
            )}

            <button onClick={handleSubmit} disabled={!message.trim() || status === 'sending'}
              style={{ width: '100%', padding: '11px 0', background: message.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: message.trim() ? 'pointer' : 'not-allowed' }}>
              {status === 'sending' ? 'Sending...' : 'Send message'}
            </button>
          </div>
        )}

        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#aaa' }}>
          Or email directly: <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#0d9488', textDecoration: 'none' }}>sambitmallick123@gmail.com</a>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
