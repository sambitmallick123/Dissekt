#!/bin/bash
# Dissekt Frontend — Concept B with INLINE STYLES (Tailwind-independent)
# Fixes the styling issue where Tailwind classes weren't being applied
# Run from inside dissekt-web/ directory
set -e
echo "Applying Concept B with inline styles..."

mkdir -p src/app/api/scan src/components src/lib

# ============================================
# Fix globals.css — remove @import before @tailwind
# ============================================
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  background: #f5f5f4;
  color: #1a1a1a;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  -webkit-font-smoothing: antialiased;
}

* { box-sizing: border-box; }

@keyframes ringDraw {
  from { stroke-dashoffset: 264; }
}
.ring-anim { animation: ringDraw 1s ease-out forwards; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
.anim-fade { animation: fadeUp 0.35s ease-out forwards; }
.anim-d1 { animation-delay: 0.06s; opacity: 0; }
.anim-d2 { animation-delay: 0.12s; opacity: 0; }
.anim-d3 { animation-delay: 0.18s; opacity: 0; }
.anim-d4 { animation-delay: 0.24s; opacity: 0; }

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

@keyframes spin { to { transform: rotate(360deg); } }
EOF

# ============================================
# layout.tsx
# ============================================
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Dissekt — Threat Intelligence for Content',
  description: 'Detect manipulation. Trace claims. Export evidence.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
      </head>
      <body style={{ fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
EOF

# ============================================
# API proxy (unchanged)
# ============================================
cat > src/app/api/scan/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const response = await fetch(`${apiUrl}/api/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }
    return NextResponse.json(await response.json());
  } catch (error) {
    return NextResponse.json({ detail: 'Analysis service unavailable.' }, { status: 503 });
  }
}
EOF

# ============================================
# page.tsx
# ============================================
cat > src/app/page.tsx << 'PAGEEOF'
'use client';
import { useState } from 'react';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';

const S = {
  page: { minHeight: '100vh', background: '#f5f5f4' } as React.CSSProperties,
  nav: { background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky' as const, top: 0, zIndex: 20 },
  navInner: { maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  logoWrap: { display: 'flex', alignItems: 'center', gap: 10 },
  logoIcon: { width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' },
  logoText: { fontWeight: 600, fontSize: 15, letterSpacing: '-0.01em' },
  tabs: { display: 'flex', gap: 2 },
  tab: (active: boolean) => ({ padding: '6px 14px', borderRadius: 7, fontSize: 13, fontWeight: 500, background: active ? '#f0f0ee' : 'transparent', color: active ? '#1a1a1a' : '#888', border: 'none', cursor: 'pointer' }),
  searchBar: { background: '#fff', borderBottom: '1px solid #e5e5e5' },
  searchInner: { maxWidth: 1100, margin: '0 auto', padding: '16px 24px' },
  content: { maxWidth: 1100, margin: '0 auto', padding: '20px 24px' },
  error: { marginBottom: 16, padding: 14, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 },
  empty: { textAlign: 'center' as const, padding: '60px 0' },
  emptyIcon: { width: 48, height: 48, margin: '0 auto 12px', background: '#f0f0ee', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' },
  emptyTitle: { fontSize: 15, fontWeight: 500, color: '#404040', marginBottom: 4 },
  emptySub: { fontSize: 13, color: '#aaa', maxWidth: 360, margin: '0 auto' },
};

export default function Home() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleScan = async (content: string, mode: string) => {
    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch('/api/scan', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ content, mode }) });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Analysis failed'); return; }
      setResult(await res.json());
    } catch (e) { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  return (
    <div style={S.page}>
      <nav style={S.nav}>
        <div style={S.navInner}>
          <div style={S.logoWrap}>
            <div style={S.logoIcon}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={S.logoText}>Dissekt</span>
          </div>
          <div style={S.tabs}>
            {['Scan', 'Radar', 'History'].map((t, i) => (
              <button key={t} style={S.tab(i === 0)}>{t}</button>
            ))}
          </div>
        </div>
      </nav>

      <div style={S.searchBar}><div style={S.searchInner}><ScanInput onScan={handleScan} loading={loading} /></div></div>

      <div style={S.content}>
        {error && <div style={S.error}>{error}</div>}
        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
        {!result && !loading && !error && (
          <div style={S.empty}>
            <div style={S.emptyIcon}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <div style={S.emptyTitle}>Paste a URL or text to begin</div>
            <div style={S.emptySub}>Dissekt detects manipulation techniques, finds existing fact-checks, and assesses source credibility — in seconds.</div>
          </div>
        )}
      </div>
    </div>
  );
}
PAGEEOF

# ============================================
# ScanInput.tsx
# ============================================
cat > src/components/ScanInput.tsx << 'EOF'
'use client';
import { useState } from 'react';

export default function ScanInput({ onScan, loading }: { onScan: (c: string, m: string) => void; loading: boolean }) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief'|'detailed'>('brief');
  const isUrl = content.trim().startsWith('http');
  const ok = content.trim().length >= 10 && !loading;

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 10, background: '#f5f5f4', borderRadius: 10, padding: '10px 14px', border: '1px solid #e5e5e5' }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input
          type="text" value={content} onChange={e => setContent(e.target.value)}
          placeholder="Paste a URL, article text, or claim to analyze..."
          onKeyDown={e => { if (e.key === 'Enter' && ok) onScan(content.trim(), mode); }}
          style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: '#1a1a1a' }}
        />
        {isUrl && (
          <span style={{ fontSize: 11, fontWeight: 600, color: '#7c3aed', background: '#f3e8ff', padding: '3px 10px', borderRadius: 20, whiteSpace: 'nowrap' }}>URL</span>
        )}
      </div>
      <div style={{ display: 'flex', background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
        {(['brief','detailed'] as const).map(m => (
          <button key={m} onClick={() => setMode(m)} style={{ padding: '6px 12px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: mode===m ? '#fff' : 'transparent', color: mode===m ? '#1a1a1a' : '#888', boxShadow: mode===m ? '0 1px 3px rgba(0,0,0,0.08)' : 'none', textTransform: 'capitalize' }}>{m}</button>
        ))}
      </div>
      <button onClick={() => ok && onScan(content.trim(), mode)} disabled={!ok}
        style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '10px 20px', background: ok ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: ok ? 'pointer' : 'not-allowed', whiteSpace: 'nowrap' }}>
        {loading ? (
          <><svg style={{ animation: 'spin 0.8s linear infinite' }} width="14" height="14" viewBox="0 0 24 24"><circle opacity="0.25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path opacity="0.75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg> Scanning</>
        ) : (
          <><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg> Scan</>
        )}
      </button>
    </div>
  );
}
EOF

# ============================================
# AnalysisResult.tsx
# ============================================
cat > src/components/AnalysisResult.tsx << 'EOF'
'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import TraceCard from './TraceCard';
import SignalCard from './SignalCard';
import MetaCard from './MetaCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div>
      <div className="anim-fade"><ThreatScore data={data} /></div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        <div className="anim-fade anim-d1"><PrismCard prism={data.prism} /></div>
        <div className="anim-fade anim-d2"><TraceCard trace={data.trace} /></div>
        <div className="anim-fade anim-d3"><SignalCard signal={data.signal} /></div>
        <div className="anim-fade anim-d4"><MetaCard data={data} /></div>
      </div>
    </div>
  );
}
EOF

# ============================================
# ThreatScore.tsx
# ============================================
cat > src/components/ThreatScore.tsx << 'TSEOF'
'use client';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' };
const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '10px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 4 };

export default function ThreatScore({ data }: { data: any }) {
  const techs = data.prism?.techniques?.length || 0;
  const fcs = data.trace?.fact_checks?.length || 0;
  const srcs = data.trace?.spread_timeline?.length || 0;
  const tox = data.signal?.toxicity_score || 0;

  let score = Math.min(techs * 20, 40) + Math.min(fcs * 5, 30) + Math.min(tox * 20, 20);
  if (data.prism?.techniques?.some((t: any) => t.confidence > 0.85)) score += 10;
  score = Math.min(Math.round(score), 100);

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
    <div style={card}>
      <div style={{ display: 'flex', alignItems: 'stretch' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '24px 32px', borderRight: '1px solid #e5e5e5' }}>
          <div style={{ position: 'relative', width: 110, height: 110 }}>
            <svg width="110" height="110" viewBox="0 0 110 110" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="55" cy="55" r={R} fill="none" stroke="#f0f0ee" strokeWidth="7"/>
              <circle cx="55" cy="55" r={R} fill="none" stroke={color} strokeWidth="7"
                strokeDasharray={C} strokeDashoffset={off} strokeLinecap="round" className="ring-anim"/>
            </svg>
            <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ fontSize: 32, fontWeight: 700, color }}>{score}</span>
              <span style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#aaa' }}>{label}</span>
            </div>
          </div>
        </div>
        <div style={{ flex: 1, padding: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, alignContent: 'center' }}>
          {metrics.map(m => (
            <div key={m.l} style={metricBox}>
              <div style={metricLabel}>{m.l}</div>
              <div style={{ fontSize: 16, fontWeight: 600, color: m.c, textTransform: 'capitalize' }}>{m.v}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
TSEOF

# ============================================
# PrismCard.tsx
# ============================================
cat > src/components/PrismCard.tsx << 'PREOF'
'use client';
import { useState } from 'react';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const iconBox = (bg: string): React.CSSProperties => ({ width: 30, height: 30, borderRadius: 8, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 });

const catColors: Record<string, { bg: string; text: string }> = {
  framing: { bg: '#f3e8ff', text: '#7c3aed' },
  logical_fallacy: { bg: '#dbeafe', text: '#2563eb' },
  credibility: { bg: '#fef3c7', text: '#b45309' },
  deflection: { bg: '#ffe4e6', text: '#be123c' },
};
const confColor = (c: number) => c >= 0.85 ? '#dc2626' : c >= 0.7 ? '#d97706' : '#eab308';

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);
  const cat = (c: string) => catColors[c] || catColors.framing;

  return (
    <div style={card}>
      <div style={header}>
        <div style={iconBox('#f3e8ff')}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2" strokeLinecap="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040', flex: 1 }}>Prism — techniques</span>
        <span style={{ fontSize: 12, color: '#aaa', fontWeight: 500 }}>{prism.techniques?.length || 0} found</span>
      </div>

      <div style={{ padding: 18, flex: 1 }}>
        {prism.techniques.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '30px 0' }}>
            <div style={{ width: 40, height: 40, borderRadius: 20, background: '#f0fdf4', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>
            </div>
            <span style={{ fontSize: 13, color: '#888' }}>No manipulation detected</span>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {prism.techniques.map((t: any, i: number) => {
              const cc = cat(t.category);
              return (
                <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 14 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 13, fontWeight: 600, textTransform: 'capitalize' }}>{t.name.replace(/_/g, ' ')}</span>
                      <span style={{ fontSize: 10, fontWeight: 600, padding: '2px 10px', borderRadius: 20, background: cc.bg, color: cc.text, textTransform: 'capitalize' }}>
                        {t.category?.replace(/_/g, ' ')}
                      </span>
                    </div>
                    <span style={{ fontSize: 16, fontWeight: 700, color: confColor(t.confidence) }}>{(t.confidence * 100).toFixed(0)}%</span>
                  </div>
                  <div style={{ height: 5, background: '#f0f0ee', borderRadius: 3, overflow: 'hidden', marginBottom: 10 }}>
                    <div style={{ height: '100%', borderRadius: 3, width: `${t.confidence * 100}%`, background: confColor(t.confidence), transition: 'width 0.7s ease' }}/>
                  </div>
                  <p style={{ fontSize: 12, color: '#555', lineHeight: 1.6, margin: 0 }}>{t.explanation}</p>
                  {t.evidence && (
                    <div style={{ marginTop: 8, paddingLeft: 12, borderLeft: '3px solid #fed7aa' }}>
                      <p style={{ fontSize: 12, color: '#888', fontStyle: 'italic', margin: 0 }}>"{t.evidence}"</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {prism.brief && (
          <div style={{ marginTop: 14, padding: 14, background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 10 }}>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#7c3aed', marginBottom: 6 }}>Summary</div>
            <p style={{ fontSize: 12, color: '#404040', lineHeight: 1.7, margin: 0 }}>{prism.brief}</p>
          </div>
        )}

        {prism.detailed && (
          <div style={{ marginTop: 10 }}>
            <button onClick={() => setExpanded(!expanded)}
              style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 500, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
              <span style={{ transform: expanded ? 'rotate(90deg)' : 'none', transition: 'transform 0.2s' }}>▸</span>
              {expanded ? 'Hide detailed analysis' : 'Show detailed analysis'}
            </button>
            {expanded && (
              <div style={{ marginTop: 8, padding: 14, background: '#f8f8f6', border: '1px solid #e5e5e5', borderRadius: 10 }}>
                <p style={{ fontSize: 12, color: '#555', lineHeight: 1.7, margin: 0, whiteSpace: 'pre-wrap' }}>{prism.detailed}</p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
PREOF

# ============================================
# TraceCard.tsx
# ============================================
cat > src/components/TraceCard.tsx << 'TREOF'
'use client';
import { useState } from 'react';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };

const ratingStyle = (r: string) => {
  const s = (r||'').toLowerCase();
  if (s.includes('false') || s.includes('pinocchio') || s.includes('wrong')) return { bg: '#fef2f2', color: '#b91c1c', border: '#fecaca' };
  if (s.includes('true')) return { bg: '#f0fdf4', color: '#166534', border: '#bbf7d0' };
  if (s.includes('context') || s.includes('mixed') || s.includes('misleading')) return { bg: '#fffbeb', color: '#92400e', border: '#fde68a' };
  return { bg: '#f5f5f4', color: '#555', border: '#e5e5e5' };
};

const dotColor = (p: string) => {
  const s = (p||'').toLowerCase();
  if (s.includes('reddit')) return '#ef4444'; if (s.includes('facebook')) return '#3b82f6';
  if (s.includes('youtube')) return '#dc2626'; if (s.includes('twitter')) return '#1a1a1a';
  if (s.includes('whatsapp')) return '#22c55e'; if (s.includes('instagram')) return '#e879f9';
  return '#aaa';
};

export default function TraceCard({ trace }: { trace: any }) {
  const [showAll, setShowAll] = useState(false);
  const hasFC = trace.fact_checks?.length > 0;
  const hasTL = trace.spread_timeline?.length > 0;
  const tl = showAll ? trace.spread_timeline : trace.spread_timeline?.slice(0, 4);

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040', flex: 1 }}>Trace — fact-checks</span>
        <span style={{ fontSize: 12, color: '#aaa' }}>
          {hasFC && `${trace.fact_checks.length} checks`}{hasFC && hasTL && ' · '}{hasTL && `${trace.spread_timeline.length} sources`}
        </span>
      </div>

      <div style={{ padding: 18, flex: 1 }}>
        {hasFC && (
          <div style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 10 }}>Existing fact-checks</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {trace.fact_checks.slice(0, 5).map((fc: any, i: number) => {
                const rs = ratingStyle(fc.rating);
                return (
                  <a key={i} href={fc.url} target="_blank" rel="noopener"
                    style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 10, textDecoration: 'none', color: 'inherit', gap: 10 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{fc.publisher}</div>
                      <div style={{ fontSize: 11, color: '#aaa', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{fc.title}</div>
                    </div>
                    <span style={{ fontSize: 10, fontWeight: 600, padding: '4px 10px', borderRadius: 6, background: rs.bg, color: rs.color, border: `1px solid ${rs.border}`, whiteSpace: 'nowrap' }}>
                      {fc.rating}
                    </span>
                  </a>
                );
              })}
              {trace.fact_checks.length > 5 && (
                <div style={{ textAlign: 'center', padding: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: 500, color: '#2563eb' }}>+ {trace.fact_checks.length - 5} more</span>
                </div>
              )}
            </div>
          </div>
        )}

        {hasTL && (
          <div>
            <div style={{ fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 10 }}>Spread timeline</div>
            <div style={{ position: 'relative', paddingLeft: 18 }}>
              <div style={{ position: 'absolute', left: 5, top: 6, bottom: 6, width: 1, background: '#e5e5e5' }}/>
              {tl.map((s: any, i: number) => (
                <a key={i} href={s.url} target="_blank" rel="noopener"
                  style={{ display: 'flex', alignItems: 'start', gap: 10, padding: '6px 0', textDecoration: 'none', color: 'inherit', position: 'relative' }}>
                  <div style={{ width: 10, height: 10, borderRadius: 5, background: dotColor(s.platform), border: '2px solid #fff', position: 'absolute', left: -17, top: 9, zIndex: 1 }}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{s.title || '(untitled)'}</div>
                    <div style={{ fontSize: 10, color: '#aaa' }}>{s.platform}{s.date ? ` · ${s.date}` : ''}</div>
                  </div>
                </a>
              ))}
            </div>
            {trace.spread_timeline.length > 4 && (
              <button onClick={() => setShowAll(!showAll)}
                style={{ fontSize: 12, fontWeight: 500, color: '#2563eb', background: 'none', border: 'none', cursor: 'pointer', marginTop: 8, padding: 0 }}>
                {showAll ? '− Show less' : `+ Show all ${trace.spread_timeline.length} sources`}
              </button>
            )}
          </div>
        )}

        {!hasFC && !hasTL && <div style={{ textAlign: 'center', padding: 30, fontSize: 13, color: '#aaa' }}>No sources found</div>}
      </div>
    </div>
  );
}
TREOF

# ============================================
# SignalCard.tsx
# ============================================
cat > src/components/SignalCard.tsx << 'SIGEOF'
'use client';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '12px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 6 };

const biasInfo = (b: string|null) => {
  if (!b) return { label: 'Unknown', dot: '#d4d4d4', color: '#aaa' };
  const m: Record<string,{label:string;dot:string;color:string}> = {
    'far-left':{label:'Far left',dot:'#1d4ed8',color:'#1d4ed8'},
    'left':{label:'Left',dot:'#3b82f6',color:'#2563eb'},
    'left-center':{label:'Left-center',dot:'#60a5fa',color:'#3b82f6'},
    'center':{label:'Center',dot:'#16a34a',color:'#16a34a'},
    'right-center':{label:'Right-center',dot:'#f87171',color:'#dc2626'},
    'right':{label:'Right',dot:'#dc2626',color:'#dc2626'},
    'far-right':{label:'Far right',dot:'#991b1b',color:'#991b1b'},
  };
  return m[b] || { label: b, dot: '#aaa', color: '#888' };
};

const factInfo = (f: string|null) => {
  if (!f) return { label: 'Unknown', color: '#aaa' };
  const m: Record<string,{label:string;color:string}> = {
    'very-high':{label:'Very high',color:'#16a34a'}, 'high':{label:'High',color:'#22c55e'},
    'mixed':{label:'Mixed',color:'#d97706'}, 'low':{label:'Low',color:'#ea580c'},
    'very-low':{label:'Very low',color:'#dc2626'},
  };
  return m[f] || { label: f, color: '#888' };
};

export default function SignalCard({ signal }: { signal: any }) {
  const bias = biasInfo(signal.source_bias);
  const fact = factInfo(signal.source_factuality);
  const tox = signal.toxicity_score || 0;
  const toxLabel = tox > 0.5 ? 'High' : tox > 0.2 ? 'Moderate' : 'Low';
  const toxColor = tox > 0.5 ? '#dc2626' : tox > 0.2 ? '#d97706' : '#16a34a';

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" strokeWidth="2" strokeLinecap="round"><path d="M2 20h.01M7 20v-4M12 20v-8M17 20V8M22 4v16"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Signal — credibility</span>
      </div>
      <div style={{ padding: 18, flex: 1 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div style={metricBox}>
            <div style={metricLabel}>Source bias</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 8, height: 8, borderRadius: 4, background: bias.dot, display: 'inline-block' }}/>
              <span style={{ fontSize: 14, fontWeight: 600, color: bias.color }}>{bias.label}</span>
            </div>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Factuality</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: fact.color }}>{fact.label}</span>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Sentiment</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{signal.sentiment}</span>
            <span style={{ fontSize: 11, color: '#aaa', marginLeft: 4 }}>({signal.sentiment_score?.toFixed(2)})</span>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Toxicity</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: toxColor }}>{toxLabel}</span>
            <span style={{ fontSize: 11, color: '#aaa', marginLeft: 4 }}>({(tox*100).toFixed(1)}%)</span>
          </div>
        </div>

        {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && tox > 0.05 && (
          <div style={{ marginTop: 16, paddingTop: 14, borderTop: '1px solid #e5e5e5' }}>
            <div style={metricLabel}>Toxicity breakdown</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 16px', marginTop: 8 }}>
              {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
                <div key={k} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 11 }}>
                  <span style={{ color: '#888', textTransform: 'capitalize' }}>{k.replace(/_/g, ' ')}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div style={{ width: 50, height: 3, background: '#f0f0ee', borderRadius: 2, overflow: 'hidden' }}>
                      <div style={{ height: '100%', borderRadius: 2, width: `${Math.max(v*100, 2)}%`, background: v > 0.5 ? '#dc2626' : v > 0.2 ? '#d97706' : '#d4d4d4' }}/>
                    </div>
                    <span style={{ fontWeight: 500, color: '#555', width: 36, textAlign: 'right' }}>{(v*100).toFixed(1)}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
SIGEOF

# ============================================
# MetaCard.tsx
# ============================================
cat > src/components/MetaCard.tsx << 'METEOF'
'use client';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '10px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 4 };

export default function MetaCard({ data }: { data: any }) {
  const items = [
    { l: 'Time', v: `${(data.analysis_time_ms / 1000).toFixed(1)}s` },
    { l: 'Model', v: data.prism?.model_used || '—' },
    { l: 'Cache', v: data.cached ? 'Hit' : 'Fresh', c: data.cached ? '#16a34a' : undefined },
    { l: 'Heuristic', v: data.prism?.heuristic_only ? 'Yes (€0)' : 'No', c: data.prism?.heuristic_only ? '#16a34a' : undefined },
  ];

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#f0f0ee', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#888" strokeWidth="2" strokeLinecap="round"><path d="M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z"/><path d="M13 2v7h7"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Analysis metadata</span>
      </div>
      <div style={{ padding: 18, flex: 1 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {items.map(m => (
            <div key={m.l} style={metricBox}>
              <div style={metricLabel}>{m.l}</div>
              <div style={{ fontSize: 13, fontWeight: 500, color: m.c || '#404040' }}>{m.v}</div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid #e5e5e5' }}>
          <div style={metricLabel}>Content hash (SHA-256)</div>
          <div style={{ fontSize: 11, fontFamily: 'monospace', color: '#888', wordBreak: 'break-all', lineHeight: 1.5 }}>
            {data.blockchain?.content_hash || '—'}
          </div>
          <div style={{ ...metricLabel, marginTop: 10 }}>Proof status</div>
          <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 6, background: '#f0f0ee', color: '#888' }}>
            {data.blockchain?.proof_status || 'pending'}
          </span>
        </div>
      </div>
    </div>
  );
}
METEOF

# ============================================
# LoadingState.tsx
# ============================================
cat > src/components/LoadingState.tsx << 'LOADEOF'
'use client';

const shimmer: React.CSSProperties = {
  background: 'linear-gradient(90deg, #f0f0ee 25%, #e8e6e3 50%, #f0f0ee 75%)',
  backgroundSize: '200% 100%',
  animation: 'shimmer 1.5s infinite',
  borderRadius: 6,
};

export default function LoadingState() {
  return (
    <div>
      <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 24, display: 'flex', alignItems: 'center', gap: 24 }}>
        <div style={{ width: 110, height: 110, borderRadius: 55, ...shimmer, flexShrink: 0 }}/>
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {Array.from({length: 6}).map((_, i) => (
            <div key={i} style={{ background: '#f8f8f6', borderRadius: 10, padding: 14 }}>
              <div style={{ height: 8, width: 50, ...shimmer, marginBottom: 8 }}/>
              <div style={{ height: 14, width: 30, ...shimmer }}/>
            </div>
          ))}
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        {['Prism', 'Trace', 'Signal', 'Meta'].map(n => (
          <div key={n} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14 }}>
            <div style={{ padding: '14px 18px', borderBottom: '1px solid #e5e5e5', display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, ...shimmer }}/>
              <div style={{ height: 10, width: 100, ...shimmer }}/>
            </div>
            <div style={{ padding: 18 }}>
              <div style={{ height: 8, width: '100%', ...shimmer, marginBottom: 10 }}/>
              <div style={{ height: 8, width: '80%', ...shimmer, marginBottom: 10 }}/>
              <div style={{ height: 8, width: '60%', ...shimmer }}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
LOADEOF

echo ""
echo "✅ Concept B applied with INLINE STYLES (no Tailwind dependency)"
echo ""
echo "Run: npm run dev"
echo "Open: http://localhost:3000"
echo ""
