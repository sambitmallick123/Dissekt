'use client';
import { useState, useEffect } from 'react';
import LandingPage from '@/components/LandingPage';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';

const DAILY_LIMIT = 10;

function getAnonUsage(): number {
  if (typeof window === 'undefined') return 0;
  try {
    const stored = localStorage.getItem('dissekt_usage');
    if (!stored) return 0;
    const { count, date } = JSON.parse(stored);
    if (date !== new Date().toISOString().split('T')[0]) return 0;
    return count;
  } catch { return 0; }
}

function setAnonUsage(count: number) {
  if (typeof window === 'undefined') return;
  localStorage.setItem('dissekt_usage', JSON.stringify({ count, date: new Date().toISOString().split('T')[0] }));
}

function Toast({ message, onClose }: { message: string; onClose: () => void }) {
  useEffect(() => { const t = setTimeout(onClose, 4000); return () => clearTimeout(t); }, [onClose]);
  return (
    <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 100, background: '#1a1a1a', color: '#fff', padding: '12px 24px', borderRadius: 10, fontSize: 14, boxShadow: '0 4px 20px rgba(0,0,0,0.15)', display: 'flex', alignItems: 'center', gap: 10, maxWidth: '90vw' }}>
      <span style={{ fontSize: 18 }}>🚧</span>
      <span>{message}</span>
      <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#888', cursor: 'pointer', fontSize: 16, marginLeft: 8 }}>✕</button>
    </div>
  );
}

function FeedbackModal({ onClose }: { onClose: () => void }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [feedback, setFeedback] = useState('');
  const [formatted, setFormatted] = useState('');
  const [step, setStep] = useState<'write' | 'processing' | 'preview' | 'sending' | 'sent' | 'error'>('write');

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, marginBottom: 10, outline: 'none', background: '#f8f8f6', fontFamily: 'inherit', boxSizing: 'border-box' };
  const btnPrimary: React.CSSProperties = { width: '100%', padding: '10px 0', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' };
  const btnDisabled: React.CSSProperties = { ...btnPrimary, background: '#d4d4d4', cursor: 'not-allowed' };
  const btnSecondary: React.CSSProperties = { width: '100%', padding: '10px 0', background: '#fff', color: '#7c3aed', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, fontWeight: 500, cursor: 'pointer', marginTop: 8 };

  const handleFormat = async () => {
    if (!feedback.trim()) return;
    setStep('processing');
    try {
      const res = await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'format', name, email, feedback }),
      });
      const data = await res.json();
      setFormatted(data.formatted || feedback);
      setStep('preview');
    } catch {
      setFormatted(feedback);
      setStep('preview');
    }
  };

  const handleSend = async () => {
    setStep('sending');
    try {
      const res = await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'send', name, email, feedback, formatted }),
      });
      const data = await res.json();
      if (data.success) {
        setStep('sent');
        setTimeout(onClose, 2500);
      } else {
        setStep('error');
      }
    } catch {
      setStep('error');
    }
  };

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{ background: '#fff', borderRadius: 14, padding: 28, width: 460, maxWidth: '90vw', boxShadow: '0 8px 30px rgba(0,0,0,0.12)', maxHeight: '85vh', overflowY: 'auto' }}>

        {step === 'sent' && (
          <div style={{ textAlign: 'center', padding: '24px 0' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Feedback sent!</div>
            <div style={{ fontSize: 13, color: '#888' }}>Thank you for helping improve Dissekt.</div>
          </div>
        )}

        {step === 'error' && (
          <div style={{ textAlign: 'center', padding: '24px 0' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>⚠️</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Something went wrong</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>Your feedback was saved but email delivery failed.</div>
            <button onClick={onClose} style={{ ...btnSecondary, width: 'auto', padding: '8px 20px', display: 'inline-block' }}>Close</button>
          </div>
        )}

        {step === 'write' && (
          <>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div><div style={{ fontSize: 16, fontWeight: 600 }}>Send feedback</div><div style={{ fontSize: 12, color: '#888' }}>Help us improve Dissekt</div></div>
              <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 18, color: '#888', cursor: 'pointer' }}>✕</button>
            </div>
            <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)} style={inputStyle} />
            <input type="email" placeholder="Your email (optional)" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} />
            <textarea placeholder="What do you think? Bug reports, feature requests, or general thoughts..." value={feedback} onChange={e => setFeedback(e.target.value)} rows={5} style={{ ...inputStyle, resize: 'vertical', marginBottom: 12 }} />
            <button onClick={handleFormat} disabled={!feedback.trim()} style={feedback.trim() ? btnPrimary : btnDisabled}>Preview & format with AI ✨</button>
            <div style={{ fontSize: 11, color: '#aaa', textAlign: 'center', marginTop: 6 }}>Your feedback will be formatted by AI before sending</div>
          </>
        )}

        {step === 'processing' && (
          <div style={{ textAlign: 'center', padding: '32px 0' }}>
            <div style={{ width: 40, height: 40, border: '3px solid #f0f0ee', borderTopColor: '#7c3aed', borderRadius: 20, margin: '0 auto 12px', animation: 'spin 0.8s linear infinite' }} />
            <div style={{ fontSize: 14, fontWeight: 500, color: '#404040' }}>Formatting your feedback...</div>
            <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>AI is organizing your thoughts</div>
          </div>
        )}

        {step === 'preview' && (
          <>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div><div style={{ fontSize: 16, fontWeight: 600 }}>Review before sending</div><div style={{ fontSize: 12, color: '#888' }}>Formatted by AI · edit if needed</div></div>
              <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 18, color: '#888', cursor: 'pointer' }}>✕</button>
            </div>
            <div style={{ background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 10, padding: 14, marginBottom: 6 }}>
              <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#7c3aed', marginBottom: 6 }}>AI-formatted preview</div>
              <textarea value={formatted} onChange={e => setFormatted(e.target.value)} rows={10} style={{ width: '100%', border: 'none', background: 'transparent', fontSize: 13, lineHeight: 1.7, outline: 'none', resize: 'vertical', fontFamily: 'inherit', color: '#333', boxSizing: 'border-box' }} />
            </div>
            <div style={{ fontSize: 11, color: '#888', marginBottom: 12, textAlign: 'center' }}>You can edit the text above before sending</div>
            <button onClick={handleSend} style={btnPrimary}>Send feedback →</button>
            <button onClick={() => { setStep('write'); setFormatted(''); }} style={btnSecondary}>← Back to edit</button>
          </>
        )}

        {step === 'sending' && (
          <div style={{ textAlign: 'center', padding: '32px 0' }}>
            <div style={{ width: 40, height: 40, border: '3px solid #f0f0ee', borderTopColor: '#7c3aed', borderRadius: 20, margin: '0 auto 12px', animation: 'spin 0.8s linear infinite' }} />
            <div style={{ fontSize: 14, fontWeight: 500, color: '#404040' }}>Sending your feedback...</div>
          </div>
        )}
      </div>
    </div>
  );
}

function ScanPage({ onShowToast, onShowFeedback }: { onShowToast: () => void; onShowFeedback: () => void }) {
  const [result, setResult] = useState<any>(null);
  const [inputContent, setInputContent] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [usage, setUsage] = useState(0);

  useEffect(() => { setUsage(getAnonUsage()); }, []);

  const handleScan = async (content: string, mode: string) => {
    const currentUsage = getAnonUsage();
    if (currentUsage >= DAILY_LIMIT) { onShowToast(); return; }
    setLoading(true); setError(""); setResult(null); setInputContent(content);
    try {
      const res = await fetch('/api/scan', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ content, mode }) });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Analysis failed'); return; }
      const data = await res.json();
      setResult(data);
      const newUsage = currentUsage + 1;
      setAnonUsage(newUsage);
      setUsage(newUsage);
    } catch (e) { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  const remaining = Math.max(0, DAILY_LIMIT - usage);

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }} onClick={() => window.location.reload()}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 12, padding: '4px 10px', borderRadius: 6, background: remaining <= 3 ? '#fef2f2' : '#f0f0ee', color: remaining <= 3 ? '#b91c1c' : '#888' }}>{remaining} scans left today</span>
            <button onClick={onShowFeedback} style={{ fontSize: 12, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>Feedback</button>
            <button onClick={onShowToast} style={{ fontSize: 12, color: '#888', background: 'none', border: '1px solid #e5e5e5', borderRadius: 6, padding: '4px 12px', cursor: 'pointer', fontWeight: 500 }}>Sign in</button>
          </div>
        </div>
      </nav>
      <div style={{ background: '#fff', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px 24px' }}><ScanInput onScan={handleScan} loading={loading} /></div>
      </div>
      {remaining <= 3 && remaining > 0 && (
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '8px 24px' }}>
          <div style={{ padding: '10px 16px', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 10, fontSize: 13, color: '#92400e', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>{remaining} free {remaining === 1 ? 'scan' : 'scans'} remaining today.</span>
            <button onClick={onShowFeedback} style={{ fontSize: 12, fontWeight: 600, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer' }}>Send feedback →</button>
          </div>
        </div>
      )}
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 24px' }}>
        {error && <div style={{ marginBottom: 16, padding: 14, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>}
        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} inputContent={inputContent} />}
        {!result && !loading && !error && (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div style={{ width: 48, height: 48, margin: '0 auto 12px', background: '#f0f0ee', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <div style={{ fontSize: 15, fontWeight: 500, color: '#404040', marginBottom: 4 }}>Paste a URL or text to begin</div>
            <div style={{ fontSize: 13, color: '#aaa', maxWidth: 360, margin: '0 auto' }}>Dissekt detects manipulation techniques, finds existing fact-checks, and assesses source credibility — in seconds.</div>
          </div>
        )}
      </div>
    </main>
  );
}

export default function Home() {
  const [view, setView] = useState<'landing' | 'scan'>('landing');
  const [toast, setToast] = useState('');
  const [showFeedback, setShowFeedback] = useState(false);

  const handleShowToast = () => {
    setToast('Sign in / Sign up is under development. Currently enjoy the free tier — 10 scans per day!');
  };

  return (
    <>
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
      {showFeedback && <FeedbackModal onClose={() => setShowFeedback(false)} />}
      {view === 'scan' ? (
        <ScanPage onShowToast={handleShowToast} onShowFeedback={() => setShowFeedback(true)} />
      ) : (
        <LandingPage onSignIn={handleShowToast} onTryFree={() => setView('scan')} onShowFeedback={() => setShowFeedback(true)} />
      )}
    </>
  );
}
