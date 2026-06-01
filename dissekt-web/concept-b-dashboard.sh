#!/bin/bash
# Dissekt Frontend — Concept B: Threat Intelligence Dashboard
# Run from inside dissekt-web/ directory
# Usage: bash concept-b-dashboard.sh

set -e
echo "Applying Concept B — Threat Intelligence Dashboard..."

mkdir -p src/app/api/scan
mkdir -p src/app/radar
mkdir -p src/components
mkdir -p src/lib

# ============================================
# tailwind.config.ts
# ============================================
cat > tailwind.config.ts << 'TAILEOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'Monaco', 'monospace'],
      },
      colors: {
        panel: {
          bg: '#f8f8f7',
          surface: '#ffffff',
          border: '#e8e6e3',
          muted: '#f3f2f0',
        },
        accent: {
          purple: '#7c3aed',
          blue: '#2563eb',
          amber: '#d97706',
          red: '#dc2626',
          green: '#059669',
          teal: '#0d9488',
        },
      },
    },
  },
  plugins: [],
};
export default config;
TAILEOF

# ============================================
# globals.css
# ============================================
cat > src/app/globals.css << 'CSSEOF'
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --purple: #7c3aed;
  --blue: #2563eb;
  --amber: #d97706;
  --red: #dc2626;
  --green: #059669;
  --teal: #0d9488;
}

html, body {
  background: #f8f8f7;
  color: #1a1a1a;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  -webkit-font-smoothing: antialiased;
}

::selection {
  background: #ddd6fe;
  color: #1a1a1a;
}

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #d4d4d4; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #a3a3a3; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}
.fade-in { animation: fadeIn 0.3s ease-out forwards; }
.fade-in-d1 { animation-delay: 0.05s; opacity: 0; }
.fade-in-d2 { animation-delay: 0.1s; opacity: 0; }
.fade-in-d3 { animation-delay: 0.15s; opacity: 0; }
.fade-in-d4 { animation-delay: 0.2s; opacity: 0; }

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
.shimmer {
  background: linear-gradient(90deg, #f3f2f0 25%, #eae8e5 50%, #f3f2f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
.spinner { animation: spin 0.8s linear infinite; }

@keyframes ringDraw {
  from { stroke-dashoffset: 264; }
}
.ring-animate { animation: ringDraw 1s ease-out forwards; }
CSSEOF

# ============================================
# layout.tsx
# ============================================
cat > src/app/layout.tsx << 'LAYEOF'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Dissekt — Threat Intelligence for Content',
  description: 'Detect manipulation. Trace claims. Export evidence.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
LAYEOF

# ============================================
# API proxy route
# ============================================
cat > src/app/api/scan/route.ts << 'APIEOF'
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

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { detail: 'Analysis service unavailable. Please try again.' },
      { status: 503 }
    );
  }
}
APIEOF

# ============================================
# page.tsx — Main page
# ============================================
cat > src/app/page.tsx << 'PAGEEOF'
'use client';
import { useState } from 'react';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';

export default function Home() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleScan = async (content: string, mode: string) => {
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });

      if (!res.ok) {
        const err = await res.json();
        setError(err.detail || 'Analysis failed');
        return;
      }

      const data = await res.json();
      setResult(data);
    } catch (e) {
      setError('Could not connect to analysis service. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#f8f8f7]">
      {/* Nav */}
      <nav className="bg-white border-b border-[#e8e6e3] sticky top-0 z-20">
        <div className="max-w-5xl mx-auto px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-7 h-7 bg-[#7c3aed] rounded-md flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
              </svg>
            </div>
            <span className="font-semibold text-[15px] tracking-tight">Dissekt</span>
          </div>
          <div className="flex items-center gap-1">
            {['Scan', 'Radar', 'History'].map((tab, i) => (
              <button
                key={tab}
                className={`px-3.5 py-1.5 rounded-md text-[13px] font-medium transition-colors ${
                  i === 0
                    ? 'bg-[#f3f2f0] text-[#1a1a1a]'
                    : 'text-[#737373] hover:text-[#1a1a1a] hover:bg-[#f3f2f0]'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* Search */}
      <div className="bg-white border-b border-[#e8e6e3]">
        <div className="max-w-5xl mx-auto px-6 py-5">
          <ScanInput onScan={handleScan} loading={loading} />
        </div>
      </div>

      {/* Content */}
      <div className="max-w-5xl mx-auto px-6 py-6">
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-800 text-sm flex items-center gap-3">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/></svg>
            {error}
          </div>
        )}
        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}

        {!result && !loading && !error && (
          <div className="text-center py-16">
            <div className="w-14 h-14 mx-auto mb-4 bg-[#f3f2f0] rounded-xl flex items-center justify-center">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#a3a3a3" strokeWidth="1.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <h2 className="text-[15px] font-medium text-[#404040] mb-1">Paste a URL or text to begin</h2>
            <p className="text-[13px] text-[#a3a3a3] max-w-sm mx-auto">
              Dissekt detects manipulation techniques, finds existing fact-checks, and assesses source credibility — in seconds.
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
PAGEEOF

# ============================================
# ScanInput.tsx
# ============================================
cat > src/components/ScanInput.tsx << 'SCANEOF'
'use client';
import { useState } from 'react';

interface Props {
  onScan: (content: string, mode: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading }: Props) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');

  const handleSubmit = () => {
    if (content.trim().length < 10) return;
    onScan(content.trim(), mode);
  };

  const isUrl = content.trim().startsWith('http');
  const canSubmit = content.trim().length >= 10 && !loading;

  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 flex items-center gap-3 bg-[#f3f2f0] rounded-lg px-4 py-2.5 border border-transparent focus-within:border-[#7c3aed]/30 focus-within:bg-white transition-all">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#a3a3a3" strokeWidth="2" strokeLinecap="round">
          <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
        </svg>
        <input
          type="text"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Paste a URL, article text, or claim to analyze..."
          className="flex-1 bg-transparent text-[14px] text-[#1a1a1a] placeholder-[#a3a3a3] outline-none"
          onKeyDown={(e) => { if (e.key === 'Enter') handleSubmit(); }}
        />
        {isUrl && (
          <span className="flex items-center gap-1.5 text-[11px] font-medium text-[#7c3aed] bg-[#f3e8ff] px-2.5 py-0.5 rounded-full shrink-0">
            <span className="w-1.5 h-1.5 bg-[#7c3aed] rounded-full"></span>
            URL
          </span>
        )}
      </div>

      {/* Mode toggle */}
      <div className="flex bg-[#f3f2f0] rounded-md p-0.5 shrink-0">
        {(['brief', 'detailed'] as const).map((m) => (
          <button
            key={m}
            onClick={() => setMode(m)}
            className={`px-3 py-1.5 rounded text-[12px] font-medium capitalize transition-all ${
              mode === m
                ? 'bg-white text-[#1a1a1a] shadow-sm'
                : 'text-[#737373] hover:text-[#404040]'
            }`}
          >
            {m}
          </button>
        ))}
      </div>

      {/* Scan button */}
      <button
        onClick={handleSubmit}
        disabled={!canSubmit}
        className="flex items-center gap-2 px-5 py-2.5 bg-[#7c3aed] text-white rounded-lg text-[13px] font-semibold hover:bg-[#6d28d9] disabled:bg-[#d4d4d4] disabled:cursor-not-allowed transition-colors shrink-0"
      >
        {loading ? (
          <>
            <svg className="spinner w-4 h-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
            Scanning
          </>
        ) : (
          <>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Scan
          </>
        )}
      </button>
    </div>
  );
}
SCANEOF

# ============================================
# AnalysisResult.tsx
# ============================================
cat > src/components/AnalysisResult.tsx << 'AREOF'
'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div className="space-y-4">
      {/* Threat score strip */}
      <div className="fade-in">
        <ThreatScore data={data} />
      </div>

      {/* 2-column panel grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="fade-in fade-in-d1">
          <PrismCard prism={data.prism} />
        </div>
        <div className="fade-in fade-in-d2">
          <TraceCard trace={data.trace} />
        </div>
        <div className="fade-in fade-in-d3">
          <SignalCard signal={data.signal} />
        </div>
        <div className="fade-in fade-in-d4">
          {/* Metadata panel */}
          <div className="bg-white border border-[#e8e6e3] rounded-xl p-5 h-full">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-lg bg-[#f3f2f0] flex items-center justify-center">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#737373" strokeWidth="2" strokeLinecap="round"><path d="M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z"/><path d="M13 2v7h7"/></svg>
              </div>
              <span className="text-[13px] font-semibold text-[#404040]">Analysis metadata</span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {[
                { label: 'Time', value: `${(data.analysis_time_ms / 1000).toFixed(1)}s`, color: '' },
                { label: 'Model', value: data.prism?.model_used || '—', color: '' },
                { label: 'Cache', value: data.cached ? 'Hit' : 'Fresh', color: data.cached ? 'text-[#059669]' : '' },
                { label: 'Heuristic', value: data.prism?.heuristic_only ? 'Yes (€0)' : 'No', color: data.prism?.heuristic_only ? 'text-[#059669]' : '' },
              ].map((m) => (
                <div key={m.label} className="bg-[#f8f8f7] rounded-lg p-3">
                  <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-1">{m.label}</div>
                  <div className={`text-[13px] font-medium ${m.color || 'text-[#404040]'}`}>{m.value}</div>
                </div>
              ))}
            </div>
            <div className="mt-4 pt-3 border-t border-[#e8e6e3]">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-1">Content hash</div>
              <div className="text-[11px] font-mono text-[#737373] break-all">
                {data.blockchain?.content_hash || '—'}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
AREOF

# ============================================
# ThreatScore.tsx — Hero score strip
# ============================================
cat > src/components/ThreatScore.tsx << 'TSEOF'
'use client';

export default function ThreatScore({ data }: { data: any }) {
  const techniques = data.prism?.techniques?.length || 0;
  const factChecks = data.trace?.fact_checks?.length || 0;
  const sources = data.trace?.spread_timeline?.length || 0;
  const toxicity = data.signal?.toxicity_score || 0;

  // Calculate threat score (0-100)
  let score = 0;
  score += Math.min(techniques * 20, 40);          // Up to 40 from techniques
  score += Math.min(factChecks * 5, 30);            // Up to 30 from fact-checks
  score += Math.min(toxicity * 20, 20);             // Up to 20 from toxicity
  score += data.prism?.techniques?.some((t: any) => t.confidence > 0.85) ? 10 : 0;
  score = Math.min(Math.round(score), 100);

  const color = score >= 70 ? '#dc2626' : score >= 40 ? '#d97706' : '#059669';
  const label = score >= 70 ? 'High risk' : score >= 40 ? 'Medium risk' : 'Low risk';

  // SVG ring math
  const radius = 42;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (score / 100) * circumference;

  const metrics = [
    { label: 'Techniques', value: techniques.toString(), color: techniques > 0 ? '#7c3aed' : '#a3a3a3' },
    { label: 'Fact-checks', value: factChecks.toString(), color: factChecks > 0 ? '#dc2626' : '#a3a3a3' },
    { label: 'Sources', value: sources.toString(), color: sources > 0 ? '#2563eb' : '#a3a3a3' },
    { label: 'Toxicity', value: `${(toxicity * 100).toFixed(1)}%`, color: toxicity > 0.5 ? '#dc2626' : toxicity > 0.2 ? '#d97706' : '#059669' },
    { label: 'Sentiment', value: data.signal?.sentiment || 'neutral', color: '#404040' },
    { label: 'Model', value: data.prism?.model_used || '—', color: '#737373' },
  ];

  return (
    <div className="bg-white border border-[#e8e6e3] rounded-xl overflow-hidden">
      <div className="flex items-stretch">
        {/* Ring */}
        <div className="flex flex-col items-center justify-center px-8 py-6 border-r border-[#e8e6e3] shrink-0">
          <div className="relative w-[100px] h-[100px]">
            <svg width="100" height="100" viewBox="0 0 100 100" className="-rotate-90">
              <circle cx="50" cy="50" r={radius} fill="none" stroke="#f3f2f0" strokeWidth="6"/>
              <circle
                cx="50" cy="50" r={radius} fill="none"
                stroke={color} strokeWidth="6"
                strokeDasharray={circumference}
                strokeDashoffset={offset}
                strokeLinecap="round"
                className="ring-animate"
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-[28px] font-semibold" style={{ color }}>{score}</span>
              <span className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3]">{label}</span>
            </div>
          </div>
        </div>

        {/* Metrics grid */}
        <div className="flex-1 p-4">
          <div className="grid grid-cols-3 gap-3 h-full">
            {metrics.map((m) => (
              <div key={m.label} className="bg-[#f8f8f7] rounded-lg p-3 flex flex-col justify-center">
                <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-1">{m.label}</div>
                <div className="text-[15px] font-semibold capitalize" style={{ color: m.color }}>{m.value}</div>
              </div>
            ))}
          </div>
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

const categoryStyles: Record<string, { bg: string; text: string }> = {
  framing: { bg: 'bg-purple-50', text: 'text-purple-700' },
  logical_fallacy: { bg: 'bg-blue-50', text: 'text-blue-700' },
  credibility: { bg: 'bg-amber-50', text: 'text-amber-700' },
  deflection: { bg: 'bg-rose-50', text: 'text-rose-700' },
};

const confColor = (c: number) => c >= 0.85 ? '#dc2626' : c >= 0.7 ? '#d97706' : '#eab308';

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="bg-white border border-[#e8e6e3] rounded-xl h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[#e8e6e3]">
        <div className="w-7 h-7 rounded-lg bg-[#f3e8ff] flex items-center justify-center shrink-0">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2" strokeLinecap="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
        </div>
        <div className="flex-1">
          <div className="text-[13px] font-semibold text-[#404040]">Prism — techniques</div>
        </div>
        <span className="text-[12px] font-medium text-[#a3a3a3]">{prism.techniques?.length || 0} found</span>
      </div>

      {/* Body */}
      <div className="px-5 py-4 flex-1">
        {prism.techniques.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center mb-2">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#059669" strokeWidth="2.5" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>
            </div>
            <span className="text-[13px] text-[#737373]">No manipulation detected</span>
          </div>
        ) : (
          <div className="space-y-3">
            {prism.techniques.map((t: any, i: number) => {
              const cat = categoryStyles[t.category] || categoryStyles.framing;
              return (
                <div key={i} className="border border-[#e8e6e3] rounded-lg p-3.5">
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-2">
                      <span className="text-[13px] font-semibold text-[#1a1a1a] capitalize">
                        {t.name.replace(/_/g, ' ')}
                      </span>
                      <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${cat.bg} ${cat.text} capitalize`}>
                        {t.category?.replace(/_/g, ' ')}
                      </span>
                    </div>
                    <span className="text-[14px] font-bold" style={{ color: confColor(t.confidence) }}>
                      {(t.confidence * 100).toFixed(0)}%
                    </span>
                  </div>
                  <div className="h-1.5 bg-[#f3f2f0] rounded-full overflow-hidden mb-2.5">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{ width: `${t.confidence * 100}%`, background: confColor(t.confidence) }}
                    />
                  </div>
                  <p className="text-[12px] text-[#525252] leading-relaxed">{t.explanation}</p>
                  {t.evidence && (
                    <div className="mt-2 pl-3 border-l-2 border-orange-200">
                      <p className="text-[12px] text-[#737373] italic">"{t.evidence}"</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* Summary */}
        {prism.brief && (
          <div className="mt-4 p-3.5 bg-[#faf5ff] border border-[#ede9fe] rounded-lg">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#7c3aed] mb-1.5">Summary</div>
            <p className="text-[12px] text-[#404040] leading-relaxed">{prism.brief}</p>
          </div>
        )}

        {/* Detailed toggle */}
        {prism.detailed && (
          <div className="mt-3">
            <button
              onClick={() => setExpanded(!expanded)}
              className="flex items-center gap-1.5 text-[12px] font-medium text-[#7c3aed] hover:text-[#6d28d9]"
            >
              <svg
                width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"
                className={`transition-transform ${expanded ? 'rotate-90' : ''}`}
              >
                <path d="M9 18l6-6-6-6"/>
              </svg>
              {expanded ? 'Hide detailed analysis' : 'Show detailed analysis'}
            </button>
            {expanded && (
              <div className="mt-2 p-3.5 bg-[#f8f8f7] border border-[#e8e6e3] rounded-lg">
                <p className="text-[12px] text-[#525252] leading-relaxed whitespace-pre-wrap">{prism.detailed}</p>
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
# SignalCard.tsx
# ============================================
cat > src/components/SignalCard.tsx << 'SIGEOF'
'use client';

const biasInfo = (bias: string | null) => {
  if (!bias) return { label: 'Unknown', dot: 'bg-[#d4d4d4]', text: 'text-[#a3a3a3]' };
  const map: Record<string, { label: string; dot: string; text: string }> = {
    'far-left': { label: 'Far left', dot: 'bg-blue-700', text: 'text-blue-700' },
    'left': { label: 'Left', dot: 'bg-blue-500', text: 'text-blue-600' },
    'left-center': { label: 'Left-center', dot: 'bg-blue-400', text: 'text-blue-500' },
    'center': { label: 'Center', dot: 'bg-green-500', text: 'text-green-600' },
    'right-center': { label: 'Right-center', dot: 'bg-red-400', text: 'text-red-500' },
    'right': { label: 'Right', dot: 'bg-red-500', text: 'text-red-600' },
    'far-right': { label: 'Far right', dot: 'bg-red-700', text: 'text-red-700' },
  };
  return map[bias] || { label: bias, dot: 'bg-[#a3a3a3]', text: 'text-[#737373]' };
};

const factInfo = (f: string | null) => {
  if (!f) return { label: 'Unknown', color: 'text-[#a3a3a3]' };
  const map: Record<string, { label: string; color: string }> = {
    'very-high': { label: 'Very high', color: 'text-green-600' },
    'high': { label: 'High', color: 'text-green-500' },
    'mixed': { label: 'Mixed', color: 'text-amber-600' },
    'low': { label: 'Low', color: 'text-orange-600' },
    'very-low': { label: 'Very low', color: 'text-red-600' },
  };
  return map[f] || { label: f, color: 'text-[#737373]' };
};

export default function SignalCard({ signal }: { signal: any }) {
  const bias = biasInfo(signal.source_bias);
  const fact = factInfo(signal.source_factuality);
  const tox = signal.toxicity_score || 0;
  const toxLabel = tox > 0.5 ? 'High' : tox > 0.2 ? 'Moderate' : 'Low';
  const toxColor = tox > 0.5 ? 'text-red-600' : tox > 0.2 ? 'text-amber-600' : 'text-green-600';

  return (
    <div className="bg-white border border-[#e8e6e3] rounded-xl h-full flex flex-col">
      <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[#e8e6e3]">
        <div className="w-7 h-7 rounded-lg bg-amber-50 flex items-center justify-center shrink-0">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" strokeWidth="2" strokeLinecap="round"><path d="M2 20h.01M7 20v-4M12 20v-8M17 20V8M22 4v16"/></svg>
        </div>
        <span className="text-[13px] font-semibold text-[#404040]">Signal — credibility</span>
      </div>

      <div className="px-5 py-4 flex-1">
        <div className="grid grid-cols-2 gap-3">
          {/* Bias */}
          <div className="bg-[#f8f8f7] rounded-lg p-3.5">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2">Source bias</div>
            <div className="flex items-center gap-2">
              <span className={`w-2.5 h-2.5 rounded-full ${bias.dot}`}></span>
              <span className={`text-[14px] font-semibold ${bias.text}`}>{bias.label}</span>
            </div>
          </div>
          {/* Factuality */}
          <div className="bg-[#f8f8f7] rounded-lg p-3.5">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2">Factuality</div>
            <span className={`text-[14px] font-semibold ${fact.color}`}>{fact.label}</span>
          </div>
          {/* Sentiment */}
          <div className="bg-[#f8f8f7] rounded-lg p-3.5">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2">Sentiment</div>
            <span className="text-[14px] font-semibold text-[#404040] capitalize">{signal.sentiment}</span>
            <span className="text-[11px] text-[#a3a3a3] ml-1">({signal.sentiment_score?.toFixed(2)})</span>
          </div>
          {/* Toxicity */}
          <div className="bg-[#f8f8f7] rounded-lg p-3.5">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2">Toxicity</div>
            <span className={`text-[14px] font-semibold ${toxColor}`}>{toxLabel}</span>
            <span className="text-[11px] text-[#a3a3a3] ml-1">({(tox * 100).toFixed(1)}%)</span>
          </div>
        </div>

        {/* Toxicity breakdown */}
        {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && tox > 0.05 && (
          <div className="mt-4 pt-4 border-t border-[#e8e6e3]">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-3">Toxicity breakdown</div>
            <div className="grid grid-cols-2 gap-2">
              {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
                <div key={k} className="flex items-center justify-between text-[11px]">
                  <span className="text-[#737373] capitalize">{k.replace(/_/g, ' ')}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-16 h-1 bg-[#f3f2f0] rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${Math.max(v * 100, 2)}%`,
                          background: v > 0.5 ? '#dc2626' : v > 0.2 ? '#d97706' : '#d4d4d4',
                        }}
                      />
                    </div>
                    <span className="text-[#404040] font-medium w-10 text-right">{(v * 100).toFixed(1)}%</span>
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
# TraceCard.tsx
# ============================================
cat > src/components/TraceCard.tsx << 'TREOF'
'use client';
import { useState } from 'react';

const ratingStyle = (rating: string) => {
  const r = (rating || '').toLowerCase();
  if (r.includes('false') || r.includes('pinocchio') || r.includes('wrong'))
    return 'bg-red-50 text-red-700 border-red-200';
  if (r.includes('true'))
    return 'bg-green-50 text-green-700 border-green-200';
  if (r.includes('misleading') || r.includes('mixed') || r.includes('context'))
    return 'bg-amber-50 text-amber-700 border-amber-200';
  return 'bg-[#f3f2f0] text-[#525252] border-[#e8e6e3]';
};

const platformDot = (p: string) => {
  const pl = (p || '').toLowerCase();
  if (pl.includes('reddit')) return '#ef4444';
  if (pl.includes('facebook')) return '#3b82f6';
  if (pl.includes('youtube')) return '#dc2626';
  if (pl.includes('twitter') || pl === 'x/twitter') return '#1a1a1a';
  if (pl.includes('instagram')) return '#e879f9';
  if (pl.includes('whatsapp')) return '#22c55e';
  if (pl.includes('telegram')) return '#0ea5e9';
  return '#a3a3a3';
};

export default function TraceCard({ trace }: { trace: any }) {
  const [showAll, setShowAll] = useState(false);
  const hasFC = trace.fact_checks && trace.fact_checks.length > 0;
  const hasTL = trace.spread_timeline && trace.spread_timeline.length > 0;
  const timeline = showAll ? trace.spread_timeline : trace.spread_timeline?.slice(0, 4);

  return (
    <div className="bg-white border border-[#e8e6e3] rounded-xl h-full flex flex-col">
      <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[#e8e6e3]">
        <div className="w-7 h-7 rounded-lg bg-blue-50 flex items-center justify-center shrink-0">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
        </div>
        <div className="flex-1">
          <span className="text-[13px] font-semibold text-[#404040]">Trace — fact-checks</span>
        </div>
        <div className="flex gap-2 text-[11px] text-[#a3a3a3]">
          {hasFC && <span>{trace.fact_checks.length} checks</span>}
          {hasFC && hasTL && <span>·</span>}
          {hasTL && <span>{trace.spread_timeline.length} sources</span>}
        </div>
      </div>

      <div className="px-5 py-4 flex-1">
        {/* Fact checks */}
        {hasFC && (
          <div className="mb-4">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2.5">Existing fact-checks</div>
            <div className="space-y-2">
              {trace.fact_checks.slice(0, 4).map((fc: any, i: number) => (
                <a
                  key={i}
                  href={fc.url}
                  target="_blank"
                  rel="noopener"
                  className="flex items-center justify-between p-3 border border-[#e8e6e3] rounded-lg hover:border-[#d4d4d4] hover:bg-[#fafaf9] transition-all group"
                >
                  <div className="flex-1 min-w-0 mr-3">
                    <div className="text-[12px] font-semibold text-[#404040] group-hover:text-[#1a1a1a]">{fc.publisher}</div>
                    <div className="text-[11px] text-[#a3a3a3] truncate">{fc.title}</div>
                  </div>
                  <span className={`text-[10px] font-semibold px-2.5 py-1 rounded-md border shrink-0 ${ratingStyle(fc.rating)}`}>
                    {fc.rating}
                  </span>
                </a>
              ))}
            </div>
            {trace.fact_checks.length > 4 && (
              <div className="text-center mt-2">
                <span className="text-[12px] font-medium text-[#2563eb]">+ {trace.fact_checks.length - 4} more</span>
              </div>
            )}
          </div>
        )}

        {/* Spread timeline */}
        {hasTL && (
          <div>
            <div className="text-[10px] font-semibold uppercase tracking-wider text-[#a3a3a3] mb-2.5">Spread timeline</div>
            <div className="relative">
              <div className="absolute left-[5px] top-2 bottom-2 w-px bg-[#e8e6e3]"></div>
              <div className="space-y-1">
                {timeline.map((s: any, i: number) => (
                  <a
                    key={i}
                    href={s.url}
                    target="_blank"
                    rel="noopener"
                    className="relative flex items-start gap-3 py-1.5 pl-0 hover:bg-[#f8f8f7] rounded transition-colors group"
                  >
                    <div
                      className="relative z-10 w-[11px] h-[11px] rounded-full border-2 border-white shrink-0 mt-0.5"
                      style={{ background: platformDot(s.platform) }}
                    ></div>
                    <div className="flex-1 min-w-0">
                      <div className="text-[12px] text-[#525252] truncate group-hover:text-[#1a1a1a]">
                        {s.title || '(untitled)'}
                      </div>
                      <div className="text-[10px] text-[#a3a3a3] flex gap-1.5">
                        <span>{s.platform}</span>
                        {s.date && <span>· {s.date}</span>}
                      </div>
                    </div>
                  </a>
                ))}
              </div>
            </div>
            {trace.spread_timeline.length > 4 && (
              <button
                onClick={() => setShowAll(!showAll)}
                className="mt-2 text-[12px] font-medium text-[#2563eb] hover:text-[#1d4ed8]"
              >
                {showAll ? '− Show less' : `+ Show all ${trace.spread_timeline.length} sources`}
              </button>
            )}
          </div>
        )}

        {!hasFC && !hasTL && (
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <span className="text-[13px] text-[#a3a3a3]">No existing sources found</span>
          </div>
        )}
      </div>
    </div>
  );
}
TREOF

# ============================================
# LoadingState.tsx
# ============================================
cat > src/components/LoadingState.tsx << 'LOADEOF'
export default function LoadingState() {
  return (
    <div className="space-y-4">
      {/* Score strip skeleton */}
      <div className="bg-white border border-[#e8e6e3] rounded-xl p-6 flex items-center gap-6">
        <div className="w-[100px] h-[100px] rounded-full shimmer shrink-0"></div>
        <div className="flex-1 grid grid-cols-3 gap-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="bg-[#f8f8f7] rounded-lg p-3">
              <div className="h-2 w-14 shimmer rounded mb-2"></div>
              <div className="h-4 w-10 shimmer rounded"></div>
            </div>
          ))}
        </div>
      </div>

      {/* Panel skeletons */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {['Prism', 'Trace', 'Signal', 'Metadata'].map((name) => (
          <div key={name} className="bg-white border border-[#e8e6e3] rounded-xl">
            <div className="px-5 py-4 border-b border-[#e8e6e3] flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg shimmer"></div>
              <div className="h-3 w-28 shimmer rounded"></div>
            </div>
            <div className="px-5 py-5 space-y-3">
              <div className="h-3 shimmer rounded w-full"></div>
              <div className="h-3 shimmer rounded w-4/5"></div>
              <div className="h-3 shimmer rounded w-3/5"></div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
LOADEOF

echo ""
echo "✅ Concept B applied — Threat Intelligence Dashboard"
echo ""
echo "Run: npm run dev"
echo "Open: http://localhost:3000"
echo ""
echo "Features:"
echo "  • Threat score ring (0-100) with animated SVG"
echo "  • 6-metric summary strip"
echo "  • 2x2 panel grid (Prism, Trace, Signal, Metadata)"
echo "  • Purple accent + clean data-dense layout"
echo "  • Color-coded confidence bars and category badges"
echo "  • Fact-check rating badges (False/True/Misleading)"
echo "  • Spread timeline with platform-colored dots"
echo "  • Collapsible detailed analysis"
echo "  • Shimmer loading skeletons"
echo "  • Fade-in cascade animations"
echo ""
