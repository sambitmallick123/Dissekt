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
  { key: 'claims', label: 'Facet extraction' },
  { key: 'radar', label: 'Scope — news feed' },
  { key: 'keyword', label: 'Keyword topic analysis' },
  { key: 'constellation', label: 'Constellation — knowledge graph' },
  { key: 'telegram', label: 'Telegram bot' },
  { key: 'extension', label: 'Chrome extension' },
  { key: 'ui', label: 'UI/UX design' },
  { key: 'performance', label: 'Performance/speed' },
  { key: 'bug', label: 'Bug report' },
  { key: 'feature', label: 'Feature request' },
];

const FEEDBACK_TYPES = [
  { key: 'feedback', label: 'Feedback', icon: '💬' },
  { key: 'bug', label: 'Bug report', icon: '🐛' },
  { key: 'feature', label: 'Feature request', icon: '💡' },
  { key: 'question', label: 'Question', icon: '❓' },
];

const CONTACT_SUBJECTS = [
  'General inquiry',
  'API access / integration',
  'Partnership / collaboration',
  'Press / media inquiry',
  'Data deletion request',
  'Other',
];

export default function ContactPage() {
  const [mode, setMode] = useState<'contact' | 'feedback'>('contact');
  // shared
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');
  // contact-specific
  const [subject, setSubject] = useState('General inquiry');
  // feedback-specific
  const [type, setType] = useState('feedback');
  const [component, setComponent] = useState('general');
  // AI formatting
  const [formatting, setFormatting] = useState(false);
  const [preFormat, setPreFormat] = useState<string | null>(null);

  const handleFormat = async () => {
    if (!message.trim() || formatting) return;
    setFormatting(true);
    const original = message;
    try {
      const res = await fetch('/api/format', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: message, kind: mode }),
      });
      const data = await res.json();
      if (res.ok && data.formatted && data.formatted !== original) {
        setPreFormat(original);
        setMessage(data.formatted);
      }
    } catch {
      // silent: keep original text on any failure
    } finally {
      setFormatting(false);
    }
  };

  const handleUndo = () => {
    if (preFormat !== null) {
      setMessage(preFormat);
      setPreFormat(null);
    }
  };

  const handleSubmit = async () => {
    if (!message.trim()) return;
    setStatus('sending');
    try {
      if (mode === 'feedback') {
        const res = await fetch('/api/feedback', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, email, message, type, component, source: 'contact_page' }),
        });
        if (res.ok) { setStatus('sent'); setMessage(''); setPreFormat(null); } else setStatus('error');
      } else {
        const res = await fetch('/api/contact', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, email, subject, message }),
        });
        if (res.ok) { setStatus('sent'); setMessage(''); setPreFormat(null); } else setStatus('error');
      }
    } catch { setStatus('error'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fafaf8', fontFamily: 'inherit', boxSizing: 'border-box' };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>Contact &amp; Feedback</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>
          Reach out with questions and partnerships, or share feedback on a specific feature. We read everything.
        </p>

        {/* Mode toggle */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 20 }}>
          <button onClick={() => { setMode('contact'); setStatus('idle'); }}
            style={{ padding: '8px 18px', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'contact' ? '#0d9488' : '#f0fdfa', color: mode === 'contact' ? '#fff' : '#0d9488' }}>
            Contact
          </button>
          <button onClick={() => { setMode('feedback'); setStatus('idle'); }}
            style={{ padding: '8px 18px', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'feedback' ? '#0d9488' : '#f0fdfa', color: mode === 'feedback' ? '#fff' : '#0d9488' }}>
            Feedback
          </button>
        </div>

        {status === 'sent' ? (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 32, textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>{mode === 'feedback' ? 'Thanks for your feedback!' : 'Message sent!'}</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>{mode === 'feedback' ? 'We read every submission and use it to improve.' : 'We typically respond within 24 hours.'}</div>
            <button onClick={() => setStatus('idle')} style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Send another</button>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            {mode === 'feedback' ? (
              <>
                <div style={{ marginBottom: 16 }}>
                  <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>Type</label>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    {FEEDBACK_TYPES.map(t => (
                      <button key={t.key} onClick={() => setType(t.key)}
                        style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, border: 'none', cursor: 'pointer', fontWeight: 500, background: type === t.key ? '#0d9488' : '#f0fdfa', color: type === t.key ? '#fff' : '#0d9488' }}>
                        {t.icon} {t.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div style={{ marginBottom: 16 }}>
                  <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>About which component?</label>
                  <select value={component} onChange={e => setComponent(e.target.value)} style={{ ...inputStyle, cursor: 'pointer' }}>
                    {COMPONENTS.map(c => <option key={c.key} value={c.key}>{c.label}</option>)}
                  </select>
                </div>
              </>
            ) : (
              <div style={{ marginBottom: 12 }}>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Subject</label>
                <select value={subject} onChange={e => setSubject(e.target.value)} style={{ ...inputStyle, cursor: 'pointer' }}>
                  {CONTACT_SUBJECTS.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Name{mode === 'feedback' ? ' (optional)' : ''}</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="Your name" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Email{mode === 'feedback' ? ' (optional)' : ''}</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder={mode === 'feedback' ? 'For follow-up' : 'For reply'} style={inputStyle} />
              </div>
            </div>

            <div style={{ marginBottom: 8 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Message *</label>
              <textarea value={message} onChange={e => { setMessage(e.target.value); if (preFormat !== null) setPreFormat(null); }} rows={5} placeholder={mode === 'feedback' ? 'What did you notice? What would you improve?' : 'How can we help?'} style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            {/* AI format toolbar */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
              <button onClick={handleFormat} disabled={!message.trim() || formatting}
                style={{ padding: '7px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600, border: '0.5px solid #0d9488', cursor: (!message.trim() || formatting) ? 'not-allowed' : 'pointer', background: '#f0fdfa', color: '#0d9488', opacity: (!message.trim() || formatting) ? 0.5 : 1 }}>
                {formatting ? 'Formatting…' : '✨ Format with AI'}
              </button>
              {preFormat !== null && (
                <button onClick={handleUndo}
                  style={{ padding: '7px 12px', borderRadius: 8, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: 'transparent', color: '#888', textDecoration: 'underline' }}>
                  Undo
                </button>
              )}
              <span style={{ fontSize: 11, color: '#aaa' }}>Polishes grammar &amp; clarity — you can still edit after.</span>
            </div>

            {status === 'error' && (
              <div style={{ marginBottom: 12, padding: 10, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12 }}>Failed to send. Try again or email sambitmallick123@gmail.com directly.</div>
            )}

            <button onClick={handleSubmit} disabled={!message.trim() || status === 'sending'}
              style={{ width: '100%', padding: '11px 0', background: message.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: message.trim() ? 'pointer' : 'not-allowed' }}>
              {status === 'sending' ? 'Sending...' : (mode === 'feedback' ? 'Send feedback' : 'Send message')}
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
