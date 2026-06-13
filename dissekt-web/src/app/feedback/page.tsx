'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const COMPONENTS = [
  { key: 'general', label: 'General feedback' },
  { key: 'clarity_score', label: 'Clarity Score' },
  { key: 'prism', label: 'Prism — techniques detection' },
  { key: 'trace', label: 'Lens — cross-references' },
  { key: 'signal', label: 'Spectrum — evidence/credibility' },
  { key: 'compass', label: 'Meridian — political context' },
  { key: 'pulse', label: 'Flare — coordination detection' },
  { key: 'counterfactual', label: 'Mirror — alternative framings' },
  { key: 'claims', label: 'Facet extraction' },
  { key: 'radar', label: 'Scope — news feed' },
  { key: 'bulk', label: 'Bulk CSV analysis' },
  { key: 'compare', label: 'Comparative analysis' },
  { key: 'topics', label: 'Topic tracking' },
  { key: 'telegram', label: 'Telegram bot' },
  { key: 'extension', label: 'Chrome extension' },
  { key: 'ui', label: 'UI/UX design' },
  { key: 'performance', label: 'Performance/speed' },
  { key: 'bug', label: 'Bug report' },
  { key: 'feature', label: 'Feature request' },
];

const TYPES = [
  { key: 'feedback', label: 'Feedback', icon: '💬' },
  { key: 'bug', label: 'Bug report', icon: '🐛' },
  { key: 'feature', label: 'Feature request', icon: '💡' },
  { key: 'question', label: 'Question', icon: '❓' },
];

export default function FeedbackPage() {
  const [type, setType] = useState('feedback');
  const [component, setComponent] = useState('general');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async () => {
    if (!message.trim()) return;
    setStatus('sending');
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name, email, message,
          type,
          component,
          source: 'feedback_page',
        }),
      });
      if (res.ok) { setStatus('sent'); setMessage(''); }
      else setStatus('error');
    } catch { setStatus('error'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fafaf8', fontFamily: 'inherit', boxSizing: 'border-box' as const };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>Feedback</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Help us improve Dissekt. Your feedback shapes the product.</p>

        {status === 'sent' ? (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 32, textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Thanks for your feedback!</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>We read every submission and use it to improve.</div>
            <button onClick={() => setStatus('idle')} style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Send another</button>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            {/* Type selector */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>Type</label>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                {TYPES.map(t => (
                  <button key={t.key} onClick={() => setType(t.key)}
                    style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, border: 'none', cursor: 'pointer', fontWeight: 500, background: type === t.key ? '#0d9488' : '#f0fdfa', color: type === t.key ? '#fff' : '#0d9488' }}>
                    {t.icon} {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Component selector */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>About which component?</label>
              <select value={component} onChange={e => setComponent(e.target.value)}
                style={{ ...inputStyle, cursor: 'pointer' }}>
                {COMPONENTS.map(c => (
                  <option key={c.key} value={c.key}>{c.label}</option>
                ))}
              </select>
            </div>

            {/* Name + Email */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Name (optional)</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="Your name" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Email (optional)</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="For follow-up" style={inputStyle} />
              </div>
            </div>

            {/* Message */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Message *</label>
              <textarea value={message} onChange={e => setMessage(e.target.value)} rows={5} placeholder="What did you notice? What would you improve?" style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            {status === 'error' && (
              <div style={{ marginBottom: 12, padding: 10, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12 }}>Failed to send. Please try again.</div>
            )}

            <button onClick={handleSubmit} disabled={!message.trim() || status === 'sending'}
              style={{ width: '100%', padding: '11px 0', background: message.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: message.trim() ? 'pointer' : 'not-allowed' }}>
              {status === 'sending' ? 'Sending...' : 'Send feedback'}
            </button>
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
