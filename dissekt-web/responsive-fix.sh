#!/bin/bash
# Dissekt — Mobile responsive fixes
# Run from inside dissekt-web/
set -e

# ============================================
# Add responsive CSS to globals.css
# ============================================
cat >> src/app/globals.css << 'CSSEOF'

/* ========== RESPONSIVE ========== */
@media (max-width: 768px) {
  /* Scan input stacks vertically */
  .scan-row { flex-direction: column !important; gap: 8px !important; }
  .scan-row > * { width: 100% !important; }
  .scan-controls { display: flex !important; gap: 8px !important; }
  .scan-controls > * { flex: 1 !important; }

  /* Result grid: single column */
  .result-grid { grid-template-columns: 1fr !important; }

  /* Threat score: stack vertically */
  .threat-strip { flex-direction: column !important; }
  .threat-ring { border-right: none !important; border-bottom: 1px solid #e5e5e5 !important; padding: 16px !important; }
  .threat-metrics { grid-template-columns: repeat(3, 1fr) !important; padding: 12px !important; gap: 8px !important; }

  /* Nav: tighten */
  .nav-inner { padding: 8px 12px !important; }
  .nav-links { gap: 6px !important; font-size: 11px !important; }

  /* Landing page */
  .hero-title { font-size: 24px !important; }
  .hero-sub { font-size: 13px !important; }
  .hero-buttons { flex-direction: column !important; gap: 8px !important; }
  .hero-buttons > * { margin-left: 0 !important; width: 100% !important; text-align: center !important; justify-content: center !important; }
  .landing-grid-3 { grid-template-columns: 1fr !important; }
  .landing-grid-4 { grid-template-columns: 1fr 1fr !important; }
  .demo-grid { grid-template-columns: 1fr !important; }
  .demo-panel { border-right: none !important; border-bottom: 1px solid #e5e5e5 !important; }
  .how-steps { padding: 0 !important; }
  .trust-grid { grid-template-columns: 1fr !important; }
  .stats-grid { grid-template-columns: 1fr 1fr !important; }
  .cta-section { margin: 20px 0 !important; padding: 24px 16px !important; border-radius: 10px !important; }
  .section-title { font-size: 18px !important; }
  .section { padding: 24px 14px !important; }

  /* Signal grid */
  .signal-grid { grid-template-columns: 1fr 1fr !important; }

  /* Meta grid */
  .meta-grid { grid-template-columns: 1fr 1fr !important; }
}

@media (max-width: 480px) {
  .threat-metrics { grid-template-columns: repeat(2, 1fr) !important; }
  .landing-grid-4 { grid-template-columns: 1fr !important; }
  .stats-grid { grid-template-columns: 1fr 1fr !important; }
}
CSSEOF

echo "✅ Responsive CSS added to globals.css"

# ============================================
# Updated ScanInput — responsive
# ============================================
cat > src/components/ScanInput.tsx << 'SCANEOF'
'use client';
import { useState, useRef, useCallback } from 'react';

interface Props {
  onScan: (content: string, mode: string, image?: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading }: Props) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');
  const [image, setImage] = useState<string | null>(null);
  const [imageName, setImageName] = useState('');
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const cameraRef = useRef<HTMLInputElement>(null);

  const isUrl = content.trim().startsWith('http');
  const canSubmit = (content.trim().length >= 10 || image) && !loading;

  const processFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) return;
    if (file.size > 10 * 1024 * 1024) { alert('Image must be under 10MB'); return; }
    setImageName(file.name);
    const reader = new FileReader();
    reader.onload = (e) => setImage(e.target?.result as string);
    reader.readAsDataURL(file);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault(); setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) processFile(file);
  }, [processFile]);

  const handlePaste = useCallback((e: React.ClipboardEvent) => {
    const items = e.clipboardData?.items;
    if (!items) return;
    for (const item of Array.from(items)) {
      if (item.type.startsWith('image/')) { e.preventDefault(); const file = item.getAsFile(); if (file) processFile(file); return; }
    }
  }, [processFile]);

  const handleSubmit = () => { if (canSubmit) onScan(content.trim(), mode, image || undefined); };
  const removeImage = () => { setImage(null); setImageName(''); };

  return (
    <div>
      <div className="scan-row" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
          style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8, background: dragOver ? '#f3e8ff' : '#f5f5f4', borderRadius: 10, padding: '10px 12px', border: dragOver ? '2px dashed #7c3aed' : '1px solid #e5e5e5', transition: 'all 0.15s ease', minWidth: 0 }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="2" style={{ flexShrink: 0 }}><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" value={content} onChange={e => setContent(e.target.value)}
            placeholder={image ? "Add context..." : "Paste URL, text, or drop image..."}
            onKeyDown={e => { if (e.key === 'Enter') handleSubmit(); }} onPaste={handlePaste}
            style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: '#1a1a1a', minWidth: 0 }} />
          {isUrl && !image && <span style={{ fontSize: 10, fontWeight: 600, color: '#7c3aed', background: '#f3e8ff', padding: '2px 8px', borderRadius: 20, whiteSpace: 'nowrap', flexShrink: 0 }}>URL</span>}
          <button onClick={() => fileRef.current?.click()} title="Upload image" style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, display: 'flex', color: '#888', flexShrink: 0 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
          </button>
          <button onClick={() => cameraRef.current?.click()} title="Camera" style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, display: 'flex', color: '#888', flexShrink: 0 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/><circle cx="12" cy="13" r="4"/></svg>
          </button>
          <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
          <input ref={cameraRef} type="file" accept="image/*" capture="environment" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
        </div>

        <div className="scan-controls" style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
          <div style={{ display: 'flex', background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
            {(['brief', 'detailed'] as const).map(m => (
              <button key={m} onClick={() => setMode(m)} style={{ padding: '6px 10px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: mode === m ? '#fff' : 'transparent', color: mode === m ? '#1a1a1a' : '#888', boxShadow: mode === m ? '0 1px 3px rgba(0,0,0,0.08)' : 'none', textTransform: 'capitalize', whiteSpace: 'nowrap' }}>{m}</button>
            ))}
          </div>
          <button onClick={handleSubmit} disabled={!canSubmit} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, padding: '8px 16px', background: canSubmit ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: canSubmit ? 'pointer' : 'not-allowed', whiteSpace: 'nowrap' }}>
            {loading ? (<><svg style={{ animation: 'spin 0.8s linear infinite' }} width="14" height="14" viewBox="0 0 24 24"><circle opacity="0.25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path opacity="0.75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>Scanning</>) : (<><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>Scan</>)}
          </button>
        </div>
      </div>

      {image && (
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'start', gap: 10, padding: 10, background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10 }}>
          <img src={image} alt="Preview" style={{ width: 60, height: 60, objectFit: 'cover', borderRadius: 8, border: '1px solid #e5e5e5', flexShrink: 0 }} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 500, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{imageName || 'Captured image'}</div>
            <div style={{ fontSize: 11, color: '#888' }}>AI vision will extract text and detect manipulation.</div>
          </div>
          <button onClick={removeImage} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#888', fontSize: 16, flexShrink: 0 }}>✕</button>
        </div>
      )}

      {dragOver && (
        <div style={{ marginTop: 8, padding: 16, border: '2px dashed #7c3aed', borderRadius: 10, background: '#faf5ff', textAlign: 'center' }}>
          <div style={{ fontSize: 13, fontWeight: 500, color: '#7c3aed' }}>Drop image here</div>
          <div style={{ fontSize: 11, color: '#888' }}>PNG, JPG, WEBP up to 10MB</div>
        </div>
      )}
    </div>
  );
}
SCANEOF

echo "✅ ScanInput updated (responsive)"

# ============================================
# Updated ThreatScore — responsive classes
# ============================================
cat > src/components/ThreatScore.tsx << 'TSEOF'
'use client';

const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '10px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 4 };

export default function ThreatScore({ data }: { data: any }) {
  const techs = data.prism?.techniques?.length || 0;
  const fcs = data.trace?.fact_checks?.length || 0;
  const srcs = data.trace?.spread_timeline?.length || 0;
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = data.prism?.techniques?.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0) || 0;

  let score = (techs > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);

  const color = score >= 70 ? '#dc2626' : score >= 40 ? '#d97706' : '#16a34a';
  const label = score >= 70 ? 'High risk' : score >= 40 ? 'Medium risk' : 'Low risk';
  const R = 42, C = 2 * Math.PI * R, off = C - (score / 100) * C;

  const metrics = [
    { l: 'Techniques', v: String(techs), c: techs > 0 ? '#7c3aed' : '#bbb' },
    { l: 'Fact-checks', v: String(fcs), c: fcs > 0 ? '#dc2626' : '#bbb' },
    { l: 'Sources', v: String(srcs), c: srcs > 0 ? '#2563eb' : '#bbb' },
    { l: 'Toxicity', v: `${(tox*100).toFixed(1)}%`, c: tox > 0.5 ? '#dc2626' : tox > 0.2 ? '#d97706' : '#16a34a' },
    { l: 'Sentiment', v: data.signal?.sentiment || '—', c: '#404040' },
    { l: 'Model', v: data.prism?.model_used || '—', c: '#888' },
  ];

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' }}>
      <div className="threat-strip" style={{ display: 'flex', alignItems: 'stretch' }}>
        <div className="threat-ring" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '24px 32px', borderRight: '1px solid #e5e5e5' }}>
          <div style={{ position: 'relative', width: 100, height: 100 }}>
            <svg width="100" height="100" viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="50" cy="50" r={R} fill="none" stroke="#f0f0ee" strokeWidth="7"/>
              <circle cx="50" cy="50" r={R} fill="none" stroke={color} strokeWidth="7" strokeDasharray={C} strokeDashoffset={off} strokeLinecap="round" className="ring-anim"/>
            </svg>
            <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ fontSize: 28, fontWeight: 700, color }}>{score}</span>
              <span style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#aaa' }}>{label}</span>
            </div>
          </div>
        </div>
        <div className="threat-metrics" style={{ flex: 1, padding: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, alignContent: 'center' }}>
          {metrics.map(m => (
            <div key={m.l} style={metricBox}>
              <div style={metricLabel}>{m.l}</div>
              <div style={{ fontSize: 15, fontWeight: 600, color: m.c, textTransform: 'capitalize' }}>{m.v}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
TSEOF

echo "✅ ThreatScore updated (responsive)"

# ============================================
# Updated AnalysisResult — responsive grid class
# ============================================
cat > src/components/AnalysisResult.tsx << 'AREOF'
'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';
import MetaCard from './MetaCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div>
      <div className="anim-fade"><ThreatScore data={data} /></div>
      <div className="result-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        <div className="anim-fade anim-d1"><PrismCard prism={data.prism} /></div>
        <div className="anim-fade anim-d2"><TraceCard trace={data.trace} /></div>
        <div className="anim-fade anim-d3"><SignalCard signal={data.signal} /></div>
        <div className="anim-fade anim-d4"><MetaCard data={data} /></div>
      </div>
    </div>
  );
}
AREOF

echo "✅ AnalysisResult updated (responsive grid)"

# ============================================
# Updated LandingPage — responsive classes
# ============================================
# We need to add CSS classes to the LandingPage. Replace key inline grids with class-based ones.

cat > src/components/LandingPage.tsx << 'LANDEOF'
'use client';

export default function LandingPage({ onSignIn, onTryFree, onShowFeedback }: { onSignIn: () => void; onTryFree: () => void; onShowFeedback?: () => void }) {
  return (
    <div style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      {/* Nav */}
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div className="nav-inner" style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </div>
          <div className="nav-links" style={{ display: 'flex', gap: 14, fontSize: 13, color: '#737373', alignItems: 'center' }}>
            <a href="#features" style={{ color: '#737373', textDecoration: 'none' }}>Features</a>
            <a href="#how" style={{ color: '#737373', textDecoration: 'none' }}>How it works</a>
            {onShowFeedback && <button onClick={onShowFeedback} style={{ color: '#737373', background: 'none', border: 'none', cursor: 'pointer', fontSize: 13 }}>Feedback</button>}
            <button onClick={onSignIn} style={{ padding: '5px 14px', background: 'transparent', color: '#7c3aed', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Sign in</button>
            <button onClick={onTryFree} style={{ padding: '5px 14px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Try free</button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <div style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', textAlign: 'center', padding: '40px 20px 36px' }}>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 10, maxWidth: 500, margin: '0 auto 10px' }}>Journalists spend 30-90 minutes per claim verifying manually.</p>
        <h1 className="hero-title" style={{ fontSize: 34, fontWeight: 700, lineHeight: 1.2, letterSpacing: '-0.02em', maxWidth: 600, margin: '0 auto 12px' }}>Dissekt explains how content manipulates — in seconds.</h1>
        <p className="hero-sub" style={{ fontSize: 15, color: '#555', lineHeight: 1.6, maxWidth: 520, margin: '0 auto 20px' }}>
          Paste any URL, text, or image. Get manipulation techniques, fact-checks from 100+ organizations, and source credibility scores.
        </p>
        <div className="hero-buttons" style={{ display: 'flex', justifyContent: 'center', gap: 10, flexWrap: 'wrap' }}>
          <button onClick={onTryFree} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 24px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Try it free — no signup
          </button>
          <button onClick={onSignIn} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 24px', background: '#fff', color: '#7c3aed', border: '1px solid #e5e5e5', borderRadius: 10, fontSize: 15, fontWeight: 500, cursor: 'pointer' }}>Sign in</button>
        </div>
        <p style={{ fontSize: 12, color: '#aaa', marginTop: 10 }}>10 free scans per day · No credit card · No signup required</p>
      </div>

      {/* Live demo */}
      <div id="demo" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#888', textAlign: 'center', marginBottom: 4 }}>Live analysis example</div>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 4 }}>What Dissekt finds in 3 seconds</div>
        <p style={{ fontSize: 13, color: '#888', textAlign: 'center', marginBottom: 20 }}>Real analysis of: "COVID-19 vaccines contain microchips for tracking people"</p>
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' }}>
          <div style={{ padding: '10px 14px', borderBottom: '1px solid #e5e5e5', fontSize: 12, color: '#888', display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 4 }}>
            <span>Threat score: <strong style={{ color: '#dc2626' }}>76/100 High risk</strong></span>
            <span>3.1s · GPT-4o mini</span>
          </div>
          <div className="demo-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <div className="demo-panel" style={{ padding: 14, borderRight: '1px solid #e5e5e5' }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#7c3aed', marginBottom: 8 }}>👁 Prism</div>
              <div style={{ border: '1px solid #e5e5e5', borderRadius: 8, padding: 8, marginBottom: 6 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, marginBottom: 3 }}><span style={{ fontWeight: 600 }}>Loaded language</span><span style={{ fontWeight: 700, color: '#dc2626' }}>90%</span></div>
                <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: '90%', background: '#dc2626', borderRadius: 2 }}></div></div>
              </div>
              <p style={{ fontSize: 10, color: '#555', lineHeight: 1.5, margin: 0 }}>Uses "microchips" to provoke fear about surveillance without evidence.</p>
            </div>
            <div className="demo-panel" style={{ padding: 14, borderRight: '1px solid #e5e5e5' }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#2563eb', marginBottom: 8 }}>🌐 Trace · 10 checks</div>
              {['FactCheck.org', 'Full Fact', 'AP News'].map((p,i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 6px', border: '1px solid #e5e5e5', borderRadius: 6, marginBottom: 3, fontSize: 11 }}>
                  <span style={{ fontWeight: 600 }}>{p}</span>
                  <span style={{ fontSize: 9, fontWeight: 600, padding: '1px 5px', borderRadius: 4, background: '#fef2f2', color: '#b91c1c' }}>False</span>
                </div>
              ))}
            </div>
            <div className="demo-panel" style={{ padding: 14 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#d97706', marginBottom: 8 }}>📊 Signal</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4 }}>
                {[{l:'Toxicity',v:'0.1%',c:'#059669'},{l:'Sentiment',v:'Neutral',c:'#404040'},{l:'Bias',v:'N/A',c:'#888'},{l:'Factuality',v:'N/A',c:'#888'}].map((s,i) => (
                  <div key={i} style={{ background: '#f8f8f6', borderRadius: 6, padding: 6, fontSize: 10 }}>
                    <div style={{ color: '#888', textTransform: 'uppercase', fontSize: 8, marginBottom: 1 }}>{s.l}</div>
                    <div style={{ fontWeight: 600, color: s.c }}>{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button onClick={onTryFree} style={{ padding: '10px 20px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Try it yourself →</button>
        </div>
      </div>

      {/* How it works */}
      <div id="how" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#888', textAlign: 'center', marginBottom: 4 }}>How it works</div>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>Four steps to a complete investigation</div>
        <div className="how-steps" style={{ maxWidth: 560, margin: '0 auto' }}>
          {[
            { n: '1', t: 'Paste or upload', d: 'Drop any URL, text, WhatsApp forward, screenshot, or social media post.' },
            { n: '2', t: 'Prism analyzes', d: 'AI identifies manipulation techniques with confidence scores and evidence quotes.' },
            { n: '3', t: 'Trace verifies', d: 'Searches 100+ fact-checking organizations and traces the claim to its origin.' },
            { n: '4', t: 'Signal assesses', d: 'Scores source bias, toxicity, sentiment — all running locally, zero external data.' },
          ].map(s => (
            <div key={s.n} style={{ display: 'flex', alignItems: 'start', gap: 14, marginBottom: 16 }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: '#f3e8ff', color: '#7c3aed', fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{s.n}</div>
              <div><div style={{ fontSize: 14, fontWeight: 600, marginBottom: 2 }}>{s.t}</div><div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>{s.d}</div></div>
            </div>
          ))}
        </div>
      </div>

      {/* Features */}
      <div id="features" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>Built for journalists, not algorithms</div>
        <div className="landing-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          {[
            { icon: '👁', title: 'Prism', desc: '20 manipulation techniques across framing, logical fallacies, credibility, and deflection.' },
            { icon: '🌐', title: 'Trace', desc: '100+ fact-checker organizations. Spread timeline across platforms.' },
            { icon: '📊', title: 'Signal', desc: '231 rated sources. Detoxify toxicity. VADER sentiment. All local, zero API cost.' },
            { icon: '🔒', title: 'Anchor', desc: 'SHA-256 hash + OpenTimestamps blockchain proof for evidence integrity.' },
            { icon: '📡', title: 'Radar', desc: '16 RSS feeds across India, Germany, US, UK for emerging patterns.' },
            { icon: '📷', title: 'Image analysis', desc: 'Upload screenshots, WhatsApp forwards, or use camera. AI extracts text and detects visual manipulation.' },
          ].map((f, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
              <div style={{ fontSize: 22, marginBottom: 8 }}>{f.icon}</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{f.title}</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>{f.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px' }}>
        <div className="stats-grid landing-grid-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { num: '20', label: 'Manipulation techniques', color: '#7c3aed' },
            { num: '100+', label: 'Fact-checker organizations', color: '#2563eb' },
            { num: '231', label: 'Rated news sources', color: '#d97706' },
            { num: '~3s', label: 'Average analysis time', color: '#059669' },
          ].map((s, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '18px 14px', textAlign: 'center' }}>
              <div style={{ fontSize: 26, fontWeight: 700, color: s.color }}>{s.num}</div>
              <div style={{ fontSize: 12, color: '#888', marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Markets */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>Four markets, local fact-checkers</div>
        <div className="landing-grid-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { flag: '🇮🇳', name: 'India', checkers: 'Alt News, BOOM Live, Vishvas News' },
            { flag: '🇩🇪', name: 'Germany', checkers: 'Correctiv, dpa-Faktencheck' },
            { flag: '🇺🇸', name: 'US', checkers: 'PolitiFact, Snopes, FactCheck.org' },
            { flag: '🇬🇧', name: 'UK', checkers: 'Full Fact, BBC Reality Check' },
          ].map((m, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 16 }}>
              <div style={{ fontSize: 26, marginBottom: 4 }}>{m.flag}</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{m.name}</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{m.checkers}</div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '0 20px' }}>
        <div className="cta-section" style={{ background: '#7c3aed', borderRadius: 14, padding: '36px 20px', textAlign: 'center', margin: '36px auto', maxWidth: 800 }}>
          <div style={{ fontSize: 22, fontWeight: 700, color: '#fff', marginBottom: 6 }}>Start analyzing content now</div>
          <div style={{ fontSize: 13, color: '#d4bfff', marginBottom: 16 }}>No signup required · 10 free scans per day</div>
          <button onClick={onTryFree} style={{ padding: '12px 24px', background: '#fff', color: '#7c3aed', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>Start scanning →</button>
        </div>
      </div>

      {/* Footer */}
      <div style={{ borderTop: '1px solid #e5e5e5', padding: '16px 20px', textAlign: 'center', fontSize: 12, color: '#aaa' }}>
        <span style={{ fontWeight: 600, color: '#555' }}>Dissekt</span>
        <span style={{ margin: '0 6px' }}>·</span>Built for journalists
        <span style={{ margin: '0 6px' }}>·</span><a href="mailto:sambitmallick123@gmail.com" style={{ color: '#7c3aed', textDecoration: 'none' }}>sambitmallick123@gmail.com</a>
        <span style={{ margin: '0 6px' }}>·</span>Munich, Germany · 2026
      </div>
    </div>
  );
}
LANDEOF

echo "✅ LandingPage updated (responsive + image analysis mentioned)"
echo ""
echo "Run: npm run dev"
echo "Test on mobile or resize browser to ~375px width"
