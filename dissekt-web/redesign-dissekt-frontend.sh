#!/bin/bash
# Dissekt Frontend — Light Theme Redesign
# Run from inside dissekt-web/ directory
# Usage: bash redesign-dissekt-frontend.sh

set -e

echo "Redesigning Dissekt frontend with light theme..."

mkdir -p src/app/api/scan
mkdir -p src/components
mkdir -p src/lib

# ============================================
# .env.local (keep backend URL)
# ============================================
if [ ! -f .env.local ]; then
cat > .env.local << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
fi

# ============================================
# tailwind.config.ts (add custom colors)
# ============================================
cat > tailwind.config.ts << 'EOF'
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
        serif: ['Charter', 'Georgia', 'Cambria', 'Times New Roman', 'Times', 'serif'],
        sans: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Helvetica Neue', 'sans-serif'],
        mono: ['SF Mono', 'Monaco', 'Inconsolata', 'Roboto Mono', 'monospace'],
      },
      colors: {
        ink: {
          900: '#0a0a0a',
          800: '#1a1a1a',
          700: '#404040',
          600: '#525252',
          500: '#737373',
          400: '#a3a3a3',
          300: '#d4d4d4',
          200: '#e5e5e5',
          100: '#f5f5f5',
          50:  '#fafaf9',
        },
      },
    },
  },
  plugins: [],
};
export default config;
EOF

# ============================================
# API proxy route
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

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { detail: 'Analysis service unavailable. Please try again.' },
      { status: 503 }
    );
  }
}
EOF

# ============================================
# Root layout
# ============================================
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Dissekt — Explanation, not verdicts',
  description: 'Dissect manipulative content. Trace claims to their source. Export the evidence.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
EOF

# ============================================
# globals.css — light editorial theme
# ============================================
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --bg: #fafaf9;
  --bg-elevated: #ffffff;
  --border: #e7e5e4;
  --border-subtle: #f0efed;
  --ink: #1a1a1a;
  --ink-soft: #404040;
  --ink-muted: #737373;
  --ink-light: #a3a3a3;
  --accent: #c2410c;
  --accent-soft: #fed7aa;
}

html, body {
  background: var(--bg);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-feature-settings: "kern", "liga", "calt";
}

* {
  box-sizing: border-box;
}

::selection {
  background: #fde68a;
  color: #1a1a1a;
}

/* Serif for editorial feel */
.font-serif {
  font-family: Charter, "Iowan Old Style", "Apple Garamond", Baskerville, "Times New Roman", Georgia, serif;
}

::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #d4d4d4; border-radius: 5px; }
::-webkit-scrollbar-thumb:hover { background: #a3a3a3; }

/* Subtle grid pattern for hero */
.dissekt-grid {
  background-image:
    linear-gradient(to right, rgba(0,0,0,0.03) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(0,0,0,0.03) 1px, transparent 1px);
  background-size: 32px 32px;
}

/* Smooth fade-in animation */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in-up {
  animation: fadeInUp 0.4s ease-out forwards;
}

.fade-in-up-delay-1 { animation-delay: 0.05s; opacity: 0; }
.fade-in-up-delay-2 { animation-delay: 0.1s; opacity: 0; }
.fade-in-up-delay-3 { animation-delay: 0.15s; opacity: 0; }

/* Loading shimmer */
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.shimmer {
  background: linear-gradient(90deg, #f5f5f5 25%, #ebebeb 50%, #f5f5f5 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
EOF

# ============================================
# Homepage
# ============================================
cat > src/app/page.tsx << 'EOF'
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
    <main className="min-h-screen bg-[#fafaf9]">
      {/* Nav */}
      <nav className="border-b border-ink-200 bg-white/70 backdrop-blur-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-7 h-7 bg-ink-900 rounded flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 3l18 18M21 3L3 21" />
              </svg>
            </div>
            <span className="font-serif text-lg font-semibold tracking-tight text-ink-900">Dissekt</span>
          </div>
          <div className="flex items-center gap-6 text-sm">
            <a href="/radar" className="text-ink-600 hover:text-ink-900 transition-colors">Radar</a>
            <a href="#" className="text-ink-600 hover:text-ink-900 transition-colors hidden sm:inline">About</a>
            <a href="#" className="text-ink-600 hover:text-ink-900 transition-colors hidden sm:inline">API</a>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="border-b border-ink-200 dissekt-grid">
        <div className="max-w-3xl mx-auto px-6 py-16 md:py-20">
          <div className="mb-2 text-xs uppercase tracking-widest text-orange-700 font-semibold">
            An investigation tool
          </div>
          <h1 className="font-serif text-4xl md:text-5xl font-bold tracking-tight text-ink-900 mb-4 leading-tight">
            Explanation,<br />not verdicts.
          </h1>
          <p className="text-lg text-ink-600 leading-relaxed max-w-xl">
            Paste any URL or text. Dissekt identifies manipulation techniques, traces claims to their source, and exports blockchain-verified evidence.
          </p>
        </div>
      </section>

      {/* Scan interface */}
      <section className="max-w-3xl mx-auto px-6 py-10">
        <ScanInput onScan={handleScan} loading={loading} />

        {error && (
          <div className="mt-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-800 text-sm">
            <strong className="font-medium">Error: </strong>{error}
          </div>
        )}

        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
      </section>

      {/* Footer */}
      <footer className="border-t border-ink-200 mt-20">
        <div className="max-w-4xl mx-auto px-6 py-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-ink-500">
          <div>
            <span className="font-serif text-sm font-semibold text-ink-700">Dissekt</span>
            <span className="mx-2">·</span>
            <span>Built for journalists</span>
          </div>
          <div className="flex gap-4">
            <a href="#" className="hover:text-ink-800">Privacy</a>
            <a href="#" className="hover:text-ink-800">Terms</a>
            <a href="#" className="hover:text-ink-800">Contact</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
EOF

# ============================================
# ScanInput
# ============================================
cat > src/components/ScanInput.tsx << 'EOF'
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
    <div className="bg-white border border-ink-200 rounded-xl shadow-sm overflow-hidden">
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Paste a URL, article text, or social media post…"
        className="w-full h-36 p-5 text-[15px] leading-relaxed text-ink-900 placeholder-ink-400 focus:outline-none resize-none font-sans"
        onKeyDown={(e) => {
          if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
            handleSubmit();
          }
        }}
      />

      <div className="border-t border-ink-100 px-4 py-3 flex items-center justify-between gap-3 bg-ink-50/50">
        <div className="flex items-center gap-2">
          {/* Mode selector */}
          <div className="inline-flex bg-white border border-ink-200 rounded-md p-0.5">
            {(['brief', 'detailed'] as const).map((m) => (
              <button
                key={m}
                onClick={() => setMode(m)}
                className={`px-3 py-1 rounded text-xs font-medium capitalize transition-all ${
                  mode === m
                    ? 'bg-ink-900 text-white shadow-sm'
                    : 'text-ink-500 hover:text-ink-800'
                }`}
              >
                {m}
              </button>
            ))}
          </div>
          {/* Status indicator */}
          <span className="text-xs text-ink-500 hidden sm:inline">
            {isUrl ? (
              <span className="inline-flex items-center gap-1">
                <span className="w-1.5 h-1.5 bg-orange-500 rounded-full"></span>
                URL detected
              </span>
            ) : content.length > 0 ? (
              `${content.trim().split(/\s+/).length} words`
            ) : (
              ''
            )}
          </span>
        </div>

        <button
          onClick={handleSubmit}
          disabled={!canSubmit}
          className="inline-flex items-center gap-2 px-4 py-1.5 bg-ink-900 text-white rounded-md text-sm font-medium hover:bg-ink-800 disabled:bg-ink-300 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? (
            <>
              <svg className="animate-spin h-3.5 w-3.5" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"/>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
              </svg>
              Analyzing
            </>
          ) : (
            <>
              Analyze
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
            </>
          )}
        </button>
      </div>
    </div>
  );
}
EOF

# ============================================
# AnalysisResult
# ============================================
cat > src/components/AnalysisResult.tsx << 'EOF'
'use client';

import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div className="mt-8 space-y-4">
      {/* Summary bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-ink-200">
        <div>
          <div className="text-xs uppercase tracking-widest text-ink-500 font-semibold mb-1">
            Analysis complete
          </div>
          <div className="flex items-center gap-3 text-xs text-ink-500">
            <span>{data.analysis_time_ms}ms</span>
            <span>·</span>
            <span>{data.prism?.model_used || 'unknown'}</span>
            <span>·</span>
            <span>{data.cached ? 'Cached' : 'Fresh'}</span>
            {data.prism?.heuristic_only && (
              <>
                <span>·</span>
                <span className="text-green-700">Heuristic only (€0)</span>
              </>
            )}
          </div>
        </div>
        <div className="text-xs text-ink-400 font-mono">
          {data.blockchain?.content_hash?.slice(0, 16)}…
        </div>
      </div>

      <div className="fade-in-up fade-in-up-delay-1">
        <PrismCard prism={data.prism} />
      </div>
      <div className="fade-in-up fade-in-up-delay-2">
        <SignalCard signal={data.signal} />
      </div>
      <div className="fade-in-up fade-in-up-delay-3">
        <TraceCard trace={data.trace} />
      </div>
    </div>
  );
}
EOF

# ============================================
# PrismCard
# ============================================
cat > src/components/PrismCard.tsx << 'EOF'
'use client';
import { useState } from 'react';

const categoryColors: Record<string, string> = {
  framing: 'bg-purple-50 text-purple-800 border-purple-200',
  logical_fallacy: 'bg-blue-50 text-blue-800 border-blue-200',
  credibility: 'bg-amber-50 text-amber-800 border-amber-200',
  deflection: 'bg-rose-50 text-rose-800 border-rose-200',
};

const confidenceColor = (c: number) => {
  if (c >= 0.85) return { bar: 'bg-red-500', text: 'text-red-700' };
  if (c >= 0.7) return { bar: 'bg-orange-500', text: 'text-orange-700' };
  return { bar: 'bg-yellow-500', text: 'text-yellow-700' };
};

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-xs uppercase tracking-widest text-purple-700 font-semibold mb-0.5">
              Prism
            </div>
            <h2 className="font-serif text-xl font-semibold text-ink-900">
              Manipulation analysis
            </h2>
          </div>
          <div className="text-xs text-ink-500">
            {prism.techniques?.length || 0} {prism.techniques?.length === 1 ? 'technique' : 'techniques'}
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="px-5 py-4">
        {prism.techniques.length === 0 ? (
          <div className="py-6 text-center">
            <div className="text-4xl mb-2">✓</div>
            <p className="text-ink-600 text-sm">No manipulation techniques detected.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {prism.techniques.map((t: any, i: number) => {
              const color = confidenceColor(t.confidence);
              const catClass = categoryColors[t.category] || categoryColors.framing;
              return (
                <div key={i} className="border border-ink-100 rounded-lg p-4 hover:border-ink-200 transition-colors">
                  <div className="flex items-start justify-between gap-3 mb-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <span className="font-serif text-[15px] font-semibold text-ink-900 capitalize">
                          {t.name.replace(/_/g, ' ')}
                        </span>
                        <span className={`text-[10px] font-medium px-2 py-0.5 rounded-full border ${catClass} capitalize`}>
                          {t.category?.replace(/_/g, ' ')}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className={`text-xs font-semibold ${color.text}`}>
                        {(t.confidence * 100).toFixed(0)}%
                      </span>
                    </div>
                  </div>
                  <div className="h-1 bg-ink-100 rounded-full mb-3 overflow-hidden">
                    <div
                      className={`h-full ${color.bar} rounded-full transition-all`}
                      style={{ width: `${t.confidence * 100}%` }}
                    />
                  </div>
                  <p className="text-sm text-ink-700 leading-relaxed">{t.explanation}</p>
                  {t.evidence && (
                    <blockquote className="mt-2 pl-3 border-l-2 border-orange-200 text-sm text-ink-600 italic">
                      "{t.evidence}"
                    </blockquote>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* Brief summary */}
        {prism.brief && (
          <div className="mt-4 p-4 bg-orange-50 border border-orange-100 rounded-lg">
            <div className="text-[10px] uppercase tracking-widest text-orange-700 font-semibold mb-1.5">
              Summary
            </div>
            <p className="text-sm text-ink-800 leading-relaxed font-serif">{prism.brief}</p>
          </div>
        )}

        {/* Detailed (collapsible) */}
        {prism.detailed && (
          <div className="mt-4 pt-4 border-t border-ink-100">
            <button
              onClick={() => setExpanded(!expanded)}
              className="flex items-center gap-2 text-sm text-ink-700 hover:text-ink-900 font-medium"
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className={`transition-transform ${expanded ? 'rotate-90' : ''}`}
              >
                <path d="M9 18l6-6-6-6" />
              </svg>
              {expanded ? 'Hide detailed analysis' : 'Show detailed analysis'}
            </button>
            {expanded && (
              <div className="mt-3 p-4 bg-ink-50 border border-ink-100 rounded-lg">
                <p className="text-sm text-ink-700 leading-relaxed whitespace-pre-wrap font-serif">
                  {prism.detailed}
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </section>
  );
}
EOF

# ============================================
# SignalCard
# ============================================
cat > src/components/SignalCard.tsx << 'EOF'
'use client';

const biasLabel = (bias: string | null) => {
  if (!bias) return { label: 'Unknown', dot: 'bg-ink-300', text: 'text-ink-500' };
  const map: Record<string, { label: string; dot: string; text: string }> = {
    'far-left': { label: 'Far left', dot: 'bg-blue-700', text: 'text-blue-700' },
    'left': { label: 'Left', dot: 'bg-blue-500', text: 'text-blue-600' },
    'left-center': { label: 'Left-center', dot: 'bg-blue-300', text: 'text-blue-500' },
    'center': { label: 'Center', dot: 'bg-green-500', text: 'text-green-700' },
    'right-center': { label: 'Right-center', dot: 'bg-red-300', text: 'text-red-500' },
    'right': { label: 'Right', dot: 'bg-red-500', text: 'text-red-600' },
    'far-right': { label: 'Far right', dot: 'bg-red-700', text: 'text-red-700' },
  };
  return map[bias] || { label: bias, dot: 'bg-ink-400', text: 'text-ink-600' };
};

const factualityLabel = (f: string | null) => {
  if (!f) return { label: 'Unknown', color: 'text-ink-500' };
  const map: Record<string, { label: string; color: string }> = {
    'very-high': { label: 'Very high', color: 'text-green-700' },
    'high': { label: 'High', color: 'text-green-600' },
    'mixed': { label: 'Mixed', color: 'text-amber-600' },
    'low': { label: 'Low', color: 'text-orange-600' },
    'very-low': { label: 'Very low', color: 'text-red-700' },
  };
  return map[f] || { label: f, color: 'text-ink-600' };
};

export default function SignalCard({ signal }: { signal: any }) {
  const bias = biasLabel(signal.source_bias);
  const fact = factualityLabel(signal.source_factuality);
  const toxPercent = (signal.toxicity_score * 100).toFixed(1);
  const toxLevel =
    signal.toxicity_score > 0.5 ? 'High' : signal.toxicity_score > 0.2 ? 'Moderate' : 'Low';
  const toxColor =
    signal.toxicity_score > 0.5 ? 'text-red-700' : signal.toxicity_score > 0.2 ? 'text-amber-600' : 'text-green-700';

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="text-xs uppercase tracking-widest text-amber-700 font-semibold mb-0.5">
          Signal
        </div>
        <h2 className="font-serif text-xl font-semibold text-ink-900">
          Source credibility & sentiment
        </h2>
      </div>

      <div className="px-5 py-4">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-px bg-ink-100 border border-ink-100 rounded-lg overflow-hidden">
          {/* Source bias */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Source bias
            </div>
            <div className="flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${bias.dot}`}></span>
              <span className={`font-semibold text-sm ${bias.text}`}>{bias.label}</span>
            </div>
          </div>
          {/* Factuality */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Factuality
            </div>
            <span className={`font-semibold text-sm ${fact.color}`}>{fact.label}</span>
          </div>
          {/* Sentiment */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Sentiment
            </div>
            <div>
              <span className="font-semibold text-sm text-ink-800 capitalize">{signal.sentiment}</span>
              <span className="text-xs text-ink-500 ml-1">
                ({signal.sentiment_score?.toFixed(2)})
              </span>
            </div>
          </div>
          {/* Toxicity */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Toxicity
            </div>
            <div>
              <span className={`font-semibold text-sm ${toxColor}`}>{toxLevel}</span>
              <span className="text-xs text-ink-500 ml-1">({toxPercent}%)</span>
            </div>
          </div>
        </div>

        {/* Toxicity breakdown */}
        {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && signal.toxicity_score > 0.05 && (
          <div className="mt-4 pt-4 border-t border-ink-100">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Toxicity breakdown
            </div>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
                <div key={k}>
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-ink-600 capitalize">{k.replace(/_/g, ' ')}</span>
                    <span className="text-ink-800 font-medium">{(v * 100).toFixed(1)}%</span>
                  </div>
                  <div className="h-1 bg-ink-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${
                        v > 0.5 ? 'bg-red-400' : v > 0.2 ? 'bg-amber-400' : 'bg-ink-300'
                      }`}
                      style={{ width: `${Math.max(v * 100, 1)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
EOF

# ============================================
# TraceCard
# ============================================
cat > src/components/TraceCard.tsx << 'EOF'
'use client';
import { useState } from 'react';

const platformInfo = (platform: string) => {
  const p = (platform || '').toLowerCase();
  if (p.includes('twitter') || p === 'x/twitter')
    return { icon: '𝕏', name: 'X / Twitter', color: 'text-ink-900 bg-ink-100' };
  if (p.includes('reddit')) return { icon: 'R', name: 'Reddit', color: 'text-orange-700 bg-orange-50' };
  if (p.includes('facebook')) return { icon: 'f', name: 'Facebook', color: 'text-blue-700 bg-blue-50' };
  if (p.includes('youtube')) return { icon: '▶', name: 'YouTube', color: 'text-red-700 bg-red-50' };
  if (p.includes('instagram')) return { icon: '◉', name: 'Instagram', color: 'text-pink-700 bg-pink-50' };
  if (p.includes('telegram')) return { icon: '✈', name: 'Telegram', color: 'text-sky-700 bg-sky-50' };
  if (p.includes('whatsapp')) return { icon: '✓', name: 'WhatsApp', color: 'text-green-700 bg-green-50' };
  return { icon: '○', name: 'Web', color: 'text-ink-600 bg-ink-100' };
};

const ratingColor = (rating: string) => {
  const r = (rating || '').toLowerCase();
  if (r.includes('false') || r.includes('pinocchio') || r.includes('wrong')) return 'text-red-700 bg-red-50 border-red-200';
  if (r.includes('true')) return 'text-green-700 bg-green-50 border-green-200';
  if (r.includes('misleading') || r.includes('mixed') || r.includes('context'))
    return 'text-amber-700 bg-amber-50 border-amber-200';
  return 'text-ink-700 bg-ink-100 border-ink-200';
};

export default function TraceCard({ trace }: { trace: any }) {
  const [showAll, setShowAll] = useState(false);
  const timeline = showAll ? trace.spread_timeline : trace.spread_timeline?.slice(0, 5);
  const hasFactChecks = trace.fact_checks && trace.fact_checks.length > 0;
  const hasTimeline = trace.spread_timeline && trace.spread_timeline.length > 0;

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-xs uppercase tracking-widest text-blue-700 font-semibold mb-0.5">
              Trace
            </div>
            <h2 className="font-serif text-xl font-semibold text-ink-900">
              Source origins
            </h2>
          </div>
          {(hasFactChecks || hasTimeline) && (
            <div className="text-xs text-ink-500">
              {hasFactChecks && <span>{trace.fact_checks.length} fact-checks</span>}
              {hasFactChecks && hasTimeline && <span className="mx-1">·</span>}
              {hasTimeline && <span>{trace.spread_timeline.length} sources</span>}
            </div>
          )}
        </div>
      </div>

      <div className="px-5 py-4">
        {/* Fact checks */}
        {hasFactChecks && (
          <div className="mb-5">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Existing fact-checks
            </div>
            <div className="space-y-2">
              {trace.fact_checks.slice(0, 5).map((fc: any, i: number) => (
                <a
                  key={i}
                  href={fc.url}
                  target="_blank"
                  rel="noopener"
                  className="block p-3 border border-ink-100 rounded-lg hover:border-ink-300 hover:bg-ink-50/50 transition-all group"
                >
                  <div className="flex items-start justify-between gap-3 mb-1">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-sm text-ink-900">{fc.publisher}</span>
                        {fc.date && (
                          <span className="text-xs text-ink-500">· {fc.date.slice(0, 10)}</span>
                        )}
                      </div>
                    </div>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded border shrink-0 ${ratingColor(fc.rating)}`}>
                      {fc.rating}
                    </span>
                  </div>
                  <div className="text-sm text-ink-700 line-clamp-2 group-hover:text-ink-900 transition-colors">
                    {fc.title}
                  </div>
                </a>
              ))}
            </div>
          </div>
        )}

        {/* Spread timeline */}
        {hasTimeline && (
          <div>
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Spread timeline
            </div>
            <div className="relative space-y-1">
              {/* Vertical line */}
              <div className="absolute left-[9px] top-2 bottom-2 w-px bg-ink-200" aria-hidden="true" />
              {timeline.map((s: any, i: number) => {
                const p = platformInfo(s.platform);
                return (
                  <a
                    key={i}
                    href={s.url}
                    target="_blank"
                    rel="noopener"
                    className="relative flex items-start gap-3 p-2 pl-0 hover:bg-ink-50/70 rounded transition-colors group"
                  >
                    <div className={`relative z-[1] w-[19px] h-[19px] rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 ${p.color} border border-white`}>
                      {p.icon}
                    </div>
                    <div className="flex-1 min-w-0 pt-0">
                      <div className="text-sm text-ink-800 truncate group-hover:text-ink-900">
                        {s.title || '(untitled)'}
                      </div>
                      <div className="text-xs text-ink-500 flex items-center gap-2 mt-0.5">
                        <span>{p.name}</span>
                        {s.date && (
                          <>
                            <span>·</span>
                            <span>{s.date}</span>
                          </>
                        )}
                      </div>
                    </div>
                  </a>
                );
              })}
            </div>
            {trace.spread_timeline.length > 5 && (
              <button
                onClick={() => setShowAll(!showAll)}
                className="mt-3 text-sm text-blue-700 hover:text-blue-900 font-medium"
              >
                {showAll ? '− Show less' : `+ Show all ${trace.spread_timeline.length} sources`}
              </button>
            )}
          </div>
        )}

        {!hasFactChecks && !hasTimeline && (
          <div className="py-6 text-center">
            <p className="text-ink-500 text-sm">No existing sources found for this claim.</p>
          </div>
        )}
      </div>
    </section>
  );
}
EOF

# ============================================
# LoadingState
# ============================================
cat > src/components/LoadingState.tsx << 'EOF'
export default function LoadingState() {
  const sections = [
    { name: 'Prism', label: 'Manipulation analysis', color: 'text-purple-700' },
    { name: 'Signal', label: 'Source credibility', color: 'text-amber-700' },
    { name: 'Trace', label: 'Source origins', color: 'text-blue-700' },
  ];

  return (
    <div className="mt-8 space-y-4">
      <div className="flex items-center gap-2 pb-3 border-b border-ink-200">
        <svg className="animate-spin h-3.5 w-3.5 text-ink-500" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"/>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
        </svg>
        <span className="text-xs uppercase tracking-widest text-ink-500 font-semibold">Analyzing</span>
      </div>

      {sections.map((s, i) => (
        <div
          key={s.name}
          className="bg-white border border-ink-200 rounded-xl overflow-hidden"
          style={{ animationDelay: `${i * 0.1}s` }}
        >
          <div className="px-5 pt-5 pb-3 border-b border-ink-100">
            <div className={`text-xs uppercase tracking-widest font-semibold mb-0.5 ${s.color}`}>
              {s.name}
            </div>
            <div className="font-serif text-xl font-semibold text-ink-300">{s.label}</div>
          </div>
          <div className="px-5 py-5 space-y-3">
            <div className="h-3 shimmer rounded w-3/4" />
            <div className="h-3 shimmer rounded w-full" />
            <div className="h-3 shimmer rounded w-5/6" />
          </div>
        </div>
      ))}
    </div>
  );
}
EOF

echo ""
echo "✅ Redesign complete!"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Open http://localhost:3000"
echo ""
echo "Design features:"
echo "  • Light editorial theme (warm off-white background)"
echo "  • Charter/Georgia serif for headlines"
echo "  • Monochrome ink color palette + orange accent"
echo "  • Color-coded manipulation techniques by category"
echo "  • Visual spread timeline with platform icons"
echo "  • Collapsible detailed analysis"
echo "  • Smooth fade-in animations"
echo ""
