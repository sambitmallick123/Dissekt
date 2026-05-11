#!/bin/bash
# Dissekt Frontend Scaffold
# Run from inside dissekt-web/ directory AFTER create-next-app completes
# Usage: bash setup-dissekt-frontend.sh

set -e  # Exit on error

echo "Creating Dissekt frontend files..."

# ============================================
# 1. Create directory structure
# ============================================
mkdir -p src/app/api/scan
mkdir -p src/app/radar
mkdir -p src/components
mkdir -p src/lib

# ============================================
# 2. .env.local
# ============================================
cat > .env.local << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000
# When deployed, change to:
# NEXT_PUBLIC_API_URL=https://dissekt-api.up.railway.app
EOF

# ============================================
# 3. src/app/api/scan/route.ts (API proxy)
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
# 4. src/app/page.tsx (homepage - REPLACE default)
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
    <main className="min-h-screen bg-[#04060a] text-gray-100">
      <div className="max-w-3xl mx-auto px-4 py-12">
        <div className="mb-8">
          <h1 className="text-3xl font-bold tracking-tight mb-1">DISSEKT</h1>
          <p className="text-gray-500 text-sm">
            Dissect manipulative content. Trace claims to their source. Export the evidence.
          </p>
        </div>

        <ScanInput onScan={handleScan} loading={loading} />

        {error && (
          <div className="mt-4 p-3 bg-red-900/20 border border-red-800/30 rounded-lg text-red-300 text-sm">
            {error}
          </div>
        )}

        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
      </div>
    </main>
  );
}
EOF

# ============================================
# 5. src/app/layout.tsx (REPLACE default)
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
    <html lang="en" className="dark">
      <body className="antialiased">{children}</body>
    </html>
  );
}
EOF

# ============================================
# 6. src/app/globals.css (REPLACE default)
# ============================================
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  background: #04060a;
  color: #e6eaf2;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: #111620; }
::-webkit-scrollbar-thumb { background: #2a3142; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #3a4253; }
EOF

# ============================================
# 7. src/components/ScanInput.tsx
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

  return (
    <div className="space-y-3">
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Paste any URL or text to analyze..."
        className="w-full h-32 bg-[#111620] border border-gray-800 rounded-lg p-3 text-sm text-gray-200 placeholder-gray-600 focus:border-teal-500/50 focus:outline-none resize-none"
      />
      <div className="flex items-center gap-3">
        <button
          onClick={handleSubmit}
          disabled={loading || content.trim().length < 10}
          className="px-5 py-2 bg-teal-600/20 border border-teal-600/30 rounded-lg text-teal-400 text-sm font-medium hover:bg-teal-600/30 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {loading ? 'Analyzing...' : 'Analyze'}
        </button>
        <div className="flex gap-1">
          {(['brief', 'detailed'] as const).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`px-3 py-1.5 rounded text-xs capitalize ${
                mode === m
                  ? 'bg-gray-700/50 text-gray-200'
                  : 'text-gray-500 hover:text-gray-300'
              }`}
            >
              {m}
            </button>
          ))}
        </div>
        <span className="text-xs text-gray-600 ml-auto">
          {content.trim().startsWith('http')
            ? 'URL detected'
            : content.length > 0
            ? `${content.length} chars`
            : ''}
        </span>
      </div>
    </div>
  );
}
EOF

# ============================================
# 8. src/components/AnalysisResult.tsx
# ============================================
cat > src/components/AnalysisResult.tsx << 'EOF'
'use client';

import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div className="mt-6 space-y-4">
      <PrismCard prism={data.prism} />
      <SignalCard signal={data.signal} />
      <TraceCard trace={data.trace} />

      {/* Metadata footer */}
      <div className="flex flex-wrap gap-4 text-xs text-gray-600 pt-2">
        <span>Time: {data.analysis_time_ms}ms</span>
        <span>Hash: {data.blockchain?.content_hash?.slice(0, 12)}...</span>
        <span>{data.cached ? 'Cached' : 'Fresh analysis'}</span>
        {data.prism?.model_used && <span>Model: {data.prism.model_used}</span>}
      </div>
    </div>
  );
}
EOF

# ============================================
# 9. src/components/PrismCard.tsx
# ============================================
cat > src/components/PrismCard.tsx << 'EOF'
'use client';
import { useState } from 'react';

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
      <h2 className="text-sm font-semibold text-purple-400 uppercase tracking-wider mb-3">
        Prism — Manipulation Analysis
      </h2>

      {prism.techniques.length === 0 ? (
        <p className="text-gray-500 text-sm">No manipulation techniques detected.</p>
      ) : (
        <div className="space-y-3">
          {prism.techniques.map((t: any, i: number) => (
            <div key={i} className="bg-[#0a0e14] rounded-lg p-3">
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-medium capitalize">
                  {t.name.replace(/_/g, ' ')}
                </span>
                <span className="text-xs text-gray-500">
                  {(t.confidence * 100).toFixed(0)}%
                </span>
              </div>
              <div className="h-1 bg-gray-800 rounded-full mb-2">
                <div
                  className={`h-full rounded-full ${
                    t.confidence > 0.8
                      ? 'bg-red-500'
                      : t.confidence > 0.6
                      ? 'bg-amber-500'
                      : 'bg-yellow-600'
                  }`}
                  style={{ width: `${t.confidence * 100}%` }}
                />
              </div>
              <p className="text-xs text-gray-400">{t.explanation}</p>
              {t.evidence && (
                <p className="text-xs text-gray-500 mt-1 italic">"{t.evidence}"</p>
              )}
            </div>
          ))}
        </div>
      )}

      <p className="text-xs text-gray-400 mt-3 leading-relaxed">{prism.brief}</p>

      {prism.detailed && (
        <div className="mt-2">
          <button
            onClick={() => setExpanded(!expanded)}
            className="text-xs text-teal-400 hover:text-teal-300"
          >
            {expanded ? '− Hide detailed analysis' : '+ Show detailed analysis'}
          </button>
          {expanded && (
            <p className="text-xs text-gray-400 mt-2 leading-relaxed whitespace-pre-wrap">
              {prism.detailed}
            </p>
          )}
        </div>
      )}
    </section>
  );
}
EOF

# ============================================
# 10. src/components/SignalCard.tsx
# ============================================
cat > src/components/SignalCard.tsx << 'EOF'
'use client';

const biasColor = (bias: string | null) => {
  if (!bias) return 'text-gray-500';
  if (bias.includes('far-left') || bias.includes('far-right')) return 'text-red-400';
  if (bias === 'left' || bias === 'right') return 'text-orange-400';
  if (bias.includes('center')) return 'text-teal-400';
  return 'text-gray-400';
};

const factualityColor = (f: string | null) => {
  if (!f) return 'text-gray-500';
  if (f === 'very-high') return 'text-green-400';
  if (f === 'high') return 'text-teal-400';
  if (f === 'mixed') return 'text-amber-400';
  if (f === 'low') return 'text-orange-400';
  if (f === 'very-low') return 'text-red-400';
  return 'text-gray-400';
};

export default function SignalCard({ signal }: { signal: any }) {
  return (
    <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
      <h2 className="text-sm font-semibold text-amber-400 uppercase tracking-wider mb-3">
        Signal — Source Credibility
      </h2>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div className="bg-[#0a0e14] rounded p-2 text-center">
          <div className={`text-base font-semibold capitalize ${biasColor(signal.source_bias)}`}>
            {signal.source_bias || '—'}
          </div>
          <div className="text-xs text-gray-500 mt-1">Bias</div>
        </div>
        <div className="bg-[#0a0e14] rounded p-2 text-center">
          <div className={`text-base font-semibold capitalize ${factualityColor(signal.source_factuality)}`}>
            {signal.source_factuality || '—'}
          </div>
          <div className="text-xs text-gray-500 mt-1">Factuality</div>
        </div>
        <div className="bg-[#0a0e14] rounded p-2 text-center">
          <div className="text-base font-semibold capitalize">{signal.sentiment}</div>
          <div className="text-xs text-gray-500 mt-1">
            Sentiment ({signal.sentiment_score?.toFixed(2)})
          </div>
        </div>
        <div className="bg-[#0a0e14] rounded p-2 text-center">
          <div
            className={`text-base font-semibold ${
              signal.toxicity_score > 0.5
                ? 'text-red-400'
                : signal.toxicity_score > 0.2
                ? 'text-amber-400'
                : 'text-gray-300'
            }`}
          >
            {(signal.toxicity_score * 100).toFixed(1)}%
          </div>
          <div className="text-xs text-gray-500 mt-1">Toxicity</div>
        </div>
      </div>

      {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && (
        <div className="mt-3 pt-3 border-t border-gray-800/50">
          <div className="text-xs text-gray-500 mb-1">Toxicity breakdown:</div>
          <div className="grid grid-cols-3 md:grid-cols-6 gap-2 text-xs">
            {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
              <div key={k} className="text-gray-400">
                <span className="capitalize">{k.replace(/_/g, ' ')}: </span>
                <span className="text-gray-300">{(v * 100).toFixed(1)}%</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}
EOF

# ============================================
# 11. src/components/TraceCard.tsx
# ============================================
cat > src/components/TraceCard.tsx << 'EOF'
'use client';
import { useState } from 'react';

const platformIcon = (platform: string) => {
  const p = platform?.toLowerCase() || '';
  if (p.includes('twitter') || p === 'x/twitter') return '𝕏';
  if (p.includes('reddit')) return '🔶';
  if (p.includes('facebook')) return '📘';
  if (p.includes('youtube')) return '▶️';
  if (p.includes('instagram')) return '📷';
  if (p.includes('telegram')) return '✈️';
  if (p.includes('whatsapp')) return '💬';
  return '🌐';
};

export default function TraceCard({ trace }: { trace: any }) {
  const [showAll, setShowAll] = useState(false);
  const timeline = showAll ? trace.spread_timeline : trace.spread_timeline?.slice(0, 5);

  return (
    <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
      <h2 className="text-sm font-semibold text-blue-400 uppercase tracking-wider mb-3">
        Trace — Source Origins
      </h2>

      {trace.fact_checks && trace.fact_checks.length > 0 && (
        <div className="mb-4">
          <h3 className="text-xs text-gray-500 mb-2">
            Existing fact-checks ({trace.fact_checks.length}):
          </h3>
          <div className="space-y-1">
            {trace.fact_checks.slice(0, 5).map((fc: any, i: number) => (
              <a
                key={i}
                href={fc.url}
                target="_blank"
                rel="noopener"
                className="block p-2 bg-[#0a0e14] rounded hover:bg-[#0d1117] transition-colors"
              >
                <div className="flex justify-between items-start gap-3 text-sm">
                  <span className="text-gray-300">{fc.publisher}</span>
                  <span className="text-red-400 font-medium text-xs whitespace-nowrap">
                    {fc.rating}
                  </span>
                </div>
                <div className="text-xs text-gray-500 truncate">{fc.title}</div>
              </a>
            ))}
          </div>
        </div>
      )}

      {timeline && timeline.length > 0 && (
        <div>
          <h3 className="text-xs text-gray-500 mb-2">
            Spread timeline ({trace.spread_timeline.length} sources):
          </h3>
          <div className="space-y-1">
            {timeline.map((s: any, i: number) => (
              <a
                key={i}
                href={s.url}
                target="_blank"
                rel="noopener"
                className="block py-2 px-2 hover:bg-[#0a0e14] rounded transition-colors"
              >
                <div className="flex items-start gap-2 text-xs">
                  <span className="text-base leading-none">{platformIcon(s.platform)}</span>
                  <div className="flex-1 min-w-0">
                    <div className="text-gray-400 truncate">{s.title}</div>
                    <div className="text-gray-600 flex gap-2 mt-0.5">
                      <span>{s.platform}</span>
                      {s.date && <span>· {s.date}</span>}
                    </div>
                  </div>
                </div>
              </a>
            ))}
          </div>
          {trace.spread_timeline.length > 5 && (
            <button
              onClick={() => setShowAll(!showAll)}
              className="text-xs text-teal-400 hover:text-teal-300 mt-2"
            >
              {showAll ? '− Show less' : `+ Show all ${trace.spread_timeline.length} sources`}
            </button>
          )}
        </div>
      )}

      {(!trace.fact_checks || trace.fact_checks.length === 0) &&
        (!trace.spread_timeline || trace.spread_timeline.length === 0) && (
          <p className="text-gray-500 text-sm">No existing sources found.</p>
        )}
    </section>
  );
}
EOF

# ============================================
# 12. src/components/LoadingState.tsx
# ============================================
cat > src/components/LoadingState.tsx << 'EOF'
export default function LoadingState() {
  return (
    <div className="mt-6 space-y-4">
      {['Prism', 'Signal', 'Trace'].map((name) => (
        <div
          key={name}
          className="bg-[#111620] border border-gray-800 rounded-lg p-4 animate-pulse"
        >
          <div className="h-3 w-24 bg-gray-800 rounded mb-3" />
          <div className="space-y-2">
            <div className="h-3 w-full bg-gray-800 rounded" />
            <div className="h-3 w-3/4 bg-gray-800 rounded" />
            <div className="h-3 w-1/2 bg-gray-800 rounded" />
          </div>
        </div>
      ))}
    </div>
  );
}
EOF

# ============================================
# 13. src/lib/api.ts (optional helper)
# ============================================
cat > src/lib/api.ts << 'EOF'
export async function scanContent(content: string, mode: 'brief' | 'detailed') {
  const res = await fetch('/api/scan', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ content, mode }),
  });

  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.detail || 'Analysis failed');
  }

  return res.json();
}
EOF

echo ""
echo "✅ All files created successfully!"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Open http://localhost:3000"
echo "  3. Make sure backend is running at http://localhost:8000"
echo ""
echo "Files created:"
find src -type f -name "*.ts" -o -name "*.tsx" -o -name "*.css" | sort
echo ""
ls -la .env.local
