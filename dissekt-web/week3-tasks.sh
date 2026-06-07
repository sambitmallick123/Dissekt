#!/bin/bash
# Dissekt — Week 3 Tasks: Reports, History, Radar Badges, Auth
# Run from inside dissekt-web/
set -e

# ============================================
# Task 1: Shareable Report URLs
# ============================================

# 1a. API route to save + fetch reports
mkdir -p src/app/api/report

cat > src/app/api/report/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

// POST: Save a report
export async function POST(req: NextRequest) {
  try {
    const { id, analysis, input_content, mode } = await req.json();
    const { error } = await supabase.from('reports').upsert({
      id,
      analysis,
      input_content: (input_content || '').slice(0, 500),
      mode,
    });
    if (error) throw error;
    return NextResponse.json({ success: true, url: `/report/${id}` });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}

// GET: Fetch a report
export async function GET(req: NextRequest) {
  const id = req.nextUrl.searchParams.get('id');
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 });

  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('id', id)
      .single();
    if (error || !data) return NextResponse.json({ error: 'Report not found' }, { status: 404 });
    return NextResponse.json(data);
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
EOF

# 1b. Report view page
mkdir -p "src/app/report/[id]"

cat > "src/app/report/[id]/page.tsx" << 'REPORTEOF'
'use client';
import { useState, useEffect, use } from 'react';
import AnalysisResult from '@/components/AnalysisResult';

export default function ReportPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetch(`/api/report?id=${id}`)
      .then(r => r.json())
      .then(d => {
        if (d.error) { setError(d.error); }
        else { setData(d); }
        setLoading(false);
      })
      .catch(() => { setError('Failed to load report'); setLoading(false); });
  }, [id]);

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </a>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 12, color: '#888', background: '#f0f0ee', padding: '4px 10px', borderRadius: 6 }}>Shared report</span>
            <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>Scan your own →</a>
          </div>
        </div>
      </nav>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 24px' }}>
        {data?.input_content && (
          <div style={{ marginBottom: 14, padding: '10px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, fontSize: 13, color: '#555' }}>
            <span style={{ fontSize: 11, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Analyzed: </span>
            {data.input_content.length > 150 ? data.input_content.slice(0, 150) + '...' : data.input_content}
          </div>
        )}

        {loading && (
          <div style={{ textAlign: 'center', padding: 60, color: '#888' }}>Loading report...</div>
        )}

        {error && (
          <div style={{ textAlign: 'center', padding: 60 }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>🔍</div>
            <div style={{ fontSize: 16, fontWeight: 600, color: '#404040', marginBottom: 4 }}>Report not found</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>This report may have expired or the link is invalid.</div>
            <a href="/" style={{ color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>Run your own scan →</a>
          </div>
        )}

        {data?.analysis && <AnalysisResult data={data.analysis} />}

        {data && (
          <div style={{ textAlign: 'center', marginTop: 24, padding: '16px 0', borderTop: '1px solid #e5e5e5', fontSize: 12, color: '#aaa' }}>
            Scanned {new Date(data.created_at).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })} · {data.mode} mode
            <span style={{ margin: '0 6px' }}>·</span>
            <a href="/" style={{ color: '#7c3aed', textDecoration: 'none' }}>dissekt.info</a>
          </div>
        )}
      </div>
    </main>
  );
}
REPORTEOF

# 1c. Updated AnalysisResult with Share button
cat > src/components/AnalysisResult.tsx << 'AREOF'
'use client';
import { useState } from 'react';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';
import MetaCard from './MetaCard';

export default function AnalysisResult({ data, onShare }: { data: any; onShare?: () => void }) {
  return (
    <div>
      {/* Share button */}
      {onShare && (
        <div className="anim-fade" style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
          <button onClick={onShare} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 12, fontWeight: 500, cursor: 'pointer', color: '#7c3aed' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg>
            Share report
          </button>
        </div>
      )}

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

echo "✅ Task 1: Shareable report URLs — API + page + share button"

# ============================================
# Task 2: Scan History
# ============================================

cat > src/components/ScanHistory.tsx << 'HISTEOF'
'use client';
import { useState, useEffect } from 'react';

interface HistoryItem {
  id: string;
  input: string;
  score: number;
  techniques: number;
  mode: string;
  time: string;
}

function getHistory(): HistoryItem[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(localStorage.getItem('dissekt_history') || '[]');
  } catch { return []; }
}

export function addToHistory(item: HistoryItem) {
  if (typeof window === 'undefined') return;
  const history = getHistory();
  // Dedupe by id
  const filtered = history.filter(h => h.id !== item.id);
  filtered.unshift(item);
  // Keep last 50
  localStorage.setItem('dissekt_history', JSON.stringify(filtered.slice(0, 50)));
}

export default function ScanHistory({ onReanalyze }: { onReanalyze: (input: string) => void }) {
  const [items, setItems] = useState<HistoryItem[]>([]);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => { setItems(getHistory()); }, []);

  if (items.length === 0) return null;

  const visible = expanded ? items : items.slice(0, 5);
  const scoreColor = (s: number) => s >= 70 ? '#dc2626' : s >= 40 ? '#d97706' : '#16a34a';

  return (
    <div style={{ marginBottom: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>🕐 Recent scans</div>
          <div style={{ fontSize: 11, color: '#888' }}>{items.length} scans saved locally</div>
        </div>
        {items.length > 5 && (
          <button onClick={() => setExpanded(!expanded)} style={{ fontSize: 11, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
            {expanded ? 'Show less' : `Show all ${items.length}`}
          </button>
        )}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {visible.map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 8 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: '#f8f8f6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, color: scoreColor(item.score), flexShrink: 0 }}>
              {item.score}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.input}</div>
              <div style={{ fontSize: 10, color: '#aaa' }}>
                {item.techniques} techniques · {item.mode} · {new Date(item.time).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
              <a href={`/report/${item.id}`} style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', padding: '3px 8px', background: '#eff6ff', borderRadius: 4, fontWeight: 500 }}>View</a>
              <button onClick={() => onReanalyze(item.input)} style={{ fontSize: 10, color: '#7c3aed', background: '#f3e8ff', border: 'none', borderRadius: 4, padding: '3px 8px', cursor: 'pointer', fontWeight: 500 }}>Rescan</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
HISTEOF

echo "✅ Task 2: Scan history component"

# ============================================
# Task 3: Radar Auto-Risk Badges
# ============================================

# Backend: Add heuristic scoring to radar items
cd /mnt/d/Startup\ Ideas/Dissekt

python3 << 'PYEOF'
content = open('app/radar/__init__.py').read()

# Add risk scoring function
risk_fn = '''
def _quick_risk_score(title: str, summary: str) -> str:
    """Quick heuristic risk badge based on title/summary keywords."""
    text = (title + " " + summary).lower()
    high_risk = ["breaking", "shocking", "exposed", "conspiracy", "hoax", "fake",
                 "they don't want you to know", "secret", "banned", "cover-up",
                 "exposed", "urgent", "you won't believe", "mainstream media"]
    medium_risk = ["claim", "alleged", "reportedly", "sources say", "unverified",
                   "controversial", "debunk", "misleading", "false", "rumor",
                   "fact-check", "disputed"]

    high_count = sum(1 for w in high_risk if w in text)
    med_count = sum(1 for w in medium_risk if w in text)

    if high_count >= 2:
        return "high"
    elif high_count >= 1 or med_count >= 2:
        return "medium"
    elif med_count >= 1:
        return "low"
    return "none"

'''

# Insert before the get_radar_feed function
content = content.replace(
    'async def get_radar_feed',
    risk_fn + 'async def get_radar_feed'
)

# Add risk field to each item
content = content.replace(
    '"market": feed_market,',
    '"market": feed_market,\n                        "risk": _quick_risk_score(entry.get("title", ""), (entry.get("summary", "") or "")[:200]),'
)

open('app/radar/__init__.py', 'w').write(content)
print('✅ Task 3: Radar risk badges — backend')
PYEOF

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

echo "✅ Task 3: Radar risk scoring added to backend"

# ============================================
# Task 4: Update page.tsx with all integrations
# ============================================

cat > src/app/page.tsx << 'MAINEOF'
'use client';
import { useState, useEffect } from 'react';
import LandingPage from '@/components/LandingPage';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';
import ScanHistory, { addToHistory } from '@/components/ScanHistory';

const DAILY_LIMIT = 10;
const MARKETS = ['all', 'india', 'germany', 'us', 'uk'];
const FLAGS: Record<string, string> = { india: '🇮🇳', germany: '🇩🇪', us: '🇺🇸', uk: '🇬🇧', all: '🌐' };
const RISK_BADGE: Record<string, { emoji: string; color: string; bg: string }> = {
  high: { emoji: '🔴', color: '#b91c1c', bg: '#fef2f2' },
  medium: { emoji: '🟡', color: '#92400e', bg: '#fffbeb' },
  low: { emoji: '🟢', color: '#065f46', bg: '#f0fdf4' },
  none: { emoji: '', color: '#888', bg: 'transparent' },
};

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

function Toast({ message, onClose, type }: { message: string; onClose: () => void; type?: 'info' | 'success' }) {
  useEffect(() => { const t = setTimeout(onClose, 4000); return () => clearTimeout(t); }, [onClose]);
  const bg = type === 'success' ? '#065f46' : '#1a1a1a';
  const icon = type === 'success' ? '✅' : '🚧';
  return (
    <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 100, background: bg, color: '#fff', padding: '12px 24px', borderRadius: 10, fontSize: 14, boxShadow: '0 4px 20px rgba(0,0,0,0.15)', display: 'flex', alignItems: 'center', gap: 10, maxWidth: '90vw' }}>
      <span style={{ fontSize: 18 }}>{icon}</span>
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
  const handleFormat = async () => { if (!feedback.trim()) return; setStep('processing'); try { const res = await fetch('/api/feedback', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'format', name, email, feedback }) }); const data = await res.json(); setFormatted(data.formatted || feedback); setStep('preview'); } catch { setFormatted(feedback); setStep('preview'); } };
  const handleSend = async () => { setStep('sending'); try { const res = await fetch('/api/feedback', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'send', name, email, feedback, formatted }) }); const data = await res.json(); if (data.success) { setStep('sent'); setTimeout(onClose, 2500); } else { setStep('error'); } } catch { setStep('error'); } };
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{ background: '#fff', borderRadius: 14, padding: 28, width: 460, maxWidth: '90vw', boxShadow: '0 8px 30px rgba(0,0,0,0.12)', maxHeight: '85vh', overflowY: 'auto' }}>
        {step === 'sent' && <div style={{ textAlign: 'center', padding: '24px 0' }}><div style={{ fontSize: 32, marginBottom: 8 }}>✅</div><div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Feedback sent!</div><div style={{ fontSize: 13, color: '#888' }}>Thank you for helping improve Dissekt.</div></div>}
        {step === 'error' && <div style={{ textAlign: 'center', padding: '24px 0' }}><div style={{ fontSize: 32, marginBottom: 8 }}>⚠️</div><div style={{ fontSize: 16, fontWeight: 600 }}>Something went wrong</div><div style={{ fontSize: 13, color: '#888', marginTop: 4 }}>Feedback was saved but email failed.</div><button onClick={onClose} style={{ ...btnSecondary, width: 'auto', padding: '8px 20px', display: 'inline-block', marginTop: 12 }}>Close</button></div>}
        {step === 'write' && <><div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}><div><div style={{ fontSize: 16, fontWeight: 600 }}>Send feedback</div><div style={{ fontSize: 12, color: '#888' }}>Help us improve Dissekt</div></div><button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 18, color: '#888', cursor: 'pointer' }}>✕</button></div><input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)} style={inputStyle} /><input type="email" placeholder="Your email (optional)" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} /><textarea placeholder="Bug reports, feature requests, or general thoughts..." value={feedback} onChange={e => setFeedback(e.target.value)} rows={5} style={{ ...inputStyle, resize: 'vertical', marginBottom: 12 }} /><button onClick={handleFormat} disabled={!feedback.trim()} style={feedback.trim() ? btnPrimary : btnDisabled}>Preview & format with AI ✨</button></>}
        {step === 'processing' && <div style={{ textAlign: 'center', padding: '32px 0' }}><div style={{ width: 40, height: 40, border: '3px solid #f0f0ee', borderTopColor: '#7c3aed', borderRadius: 20, margin: '0 auto 12px', animation: 'spin 0.8s linear infinite' }} /><div style={{ fontSize: 14, fontWeight: 500 }}>Formatting...</div></div>}
        {step === 'preview' && <><div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}><div><div style={{ fontSize: 16, fontWeight: 600 }}>Review before sending</div><div style={{ fontSize: 12, color: '#888' }}>Formatted by AI · edit if needed</div></div><button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 18, color: '#888', cursor: 'pointer' }}>✕</button></div><div style={{ background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 10, padding: 14, marginBottom: 12 }}><textarea value={formatted} onChange={e => setFormatted(e.target.value)} rows={10} style={{ width: '100%', border: 'none', background: 'transparent', fontSize: 13, lineHeight: 1.7, outline: 'none', resize: 'vertical', fontFamily: 'inherit', color: '#333', boxSizing: 'border-box' }} /></div><button onClick={handleSend} style={btnPrimary}>Send feedback →</button><button onClick={() => { setStep('write'); setFormatted(''); }} style={btnSecondary}>← Back to edit</button></>}
        {step === 'sending' && <div style={{ textAlign: 'center', padding: '32px 0' }}><div style={{ width: 40, height: 40, border: '3px solid #f0f0ee', borderTopColor: '#7c3aed', borderRadius: 20, margin: '0 auto 12px', animation: 'spin 0.8s linear infinite' }} /><div style={{ fontSize: 14, fontWeight: 500 }}>Sending...</div></div>}
      </div>
    </div>
  );
}

function RadarFeed({ onAnalyze }: { onAnalyze: (url: string) => void }) {
  const [market, setMarket] = useState('all');
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastRefreshed, setLastRefreshed] = useState<string | null>(null);
  const [cached, setCached] = useState(false);

  const fetchRadar = (forceRefresh = false) => {
    setLoading(true);
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const refreshParam = forceRefresh ? '&refresh=true' : '';
    fetch(`${apiUrl}/api/radar?market=${market}&limit=15${refreshParam}`)
      .then(r => r.json())
      .then(d => {
        const sorted = (d.items || []).sort((a: any, b: any) => new Date(b.published || 0).getTime() - new Date(a.published || 0).getTime());
        setItems(sorted);
        setLastRefreshed(d.last_refreshed || null);
        setCached(d.cached || false);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  useEffect(() => { fetchRadar(); }, [market]);

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14, flexWrap: 'wrap', gap: 8 }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 600, color: '#404040' }}>📡 Radar</div>
          <div style={{ fontSize: 12, color: '#888' }}>Latest from news sources. Click Analyze to scan.</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {lastRefreshed && (
            <span style={{ fontSize: 11, color: '#aaa' }}>
              Updated {new Date(lastRefreshed).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', timeZoneName: 'short' })}
              {cached && ' (cached)'}
            </span>
          )}
          <button onClick={() => fetchRadar(true)} disabled={loading}
            style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 10px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 6, fontSize: 11, fontWeight: 500, color: '#7c3aed', cursor: loading ? 'not-allowed' : 'pointer' }}>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }}><path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/></svg>
            Refresh
          </button>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 5, marginBottom: 14, flexWrap: 'wrap' }}>
        {MARKETS.map(m => (
          <button key={m} onClick={() => setMarket(m)}
            style={{ padding: '5px 12px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: market === m ? '#7c3aed' : '#fff', color: market === m ? '#fff' : '#555', boxShadow: market === m ? 'none' : '0 0 0 1px #e5e5e5' }}>
            {FLAGS[m]} {m.charAt(0).toUpperCase() + m.slice(1)}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: 14, height: 56 }}>
              <div style={{ height: 11, width: '55%', background: '#f0f0ee', borderRadius: 4, marginBottom: 6 }} />
              <div style={{ height: 9, width: '35%', background: '#f0f0ee', borderRadius: 4 }} />
            </div>
          ))}
        </div>
      ) : items.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13 }}>No items found.</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {items.map((item, i) => {
            const risk = RISK_BADGE[item.risk] || RISK_BADGE.none;
            return (
              <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '10px 14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', gap: 10 }}>
                  <a href={item.url} target="_blank" rel="noopener" style={{ flex: 1, minWidth: 0, textDecoration: 'none', color: 'inherit' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                      {risk.emoji && <span style={{ fontSize: 10 }}>{risk.emoji}</span>}
                      <span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a', lineHeight: 1.3 }}>{item.title}</span>
                    </div>
                    <div style={{ fontSize: 11, color: '#888' }}>
                      <span style={{ fontWeight: 500, color: '#7c3aed' }}>{item.source}</span>
                      <span style={{ margin: '0 4px', color: '#ddd' }}>·</span>
                      {FLAGS[item.market] || '🌐'} {item.published ? new Date(item.published).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', timeZoneName: 'short' }) : ''}
                    </div>
                  </a>
                  <button onClick={() => onAnalyze(item.url)}
                    style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '5px 10px', background: '#f3e8ff', color: '#7c3aed', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0 }}>
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                    Analyze
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function ScanPage({ onShowToast, onShowFeedback, onBack }: { onShowToast: () => void; onShowFeedback: () => void; onBack: () => void }) {
  const [result, setResult] = useState<any>(null);
  const [inputContent, setInputContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [usage, setUsage] = useState(0);
  const [shareToast, setShareToast] = useState('');

  useEffect(() => {
    setUsage(getAnonUsage());
    const autoUrl = localStorage.getItem('dissekt_analyze');
    if (autoUrl) {
      localStorage.removeItem('dissekt_analyze');
      setInputContent(autoUrl);
      handleScan(autoUrl, 'brief');
    }
  }, []);

  const handleScan = async (content: string, mode: string, image?: string) => {
    const currentUsage = getAnonUsage();
    if (currentUsage >= DAILY_LIMIT) { onShowToast(); return; }
    setLoading(true); setError(''); setResult(null); setInputContent(content);
    try {
      const res = await fetch('/api/scan', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ content, mode, image }) });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Analysis failed'); return; }
      const data = await res.json();
      setResult(data);
      const newUsage = currentUsage + 1;
      setAnonUsage(newUsage);
      setUsage(newUsage);

      // Save report to Supabase
      const reportId = data.id || data.blockchain?.content_hash?.slice(0, 12) || Date.now().toString(36);
      try {
        await fetch('/api/report', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: reportId, analysis: data, input_content: content, mode }),
        });
      } catch {}

      // Save to local history
      const techs = data.prism?.techniques?.length || 0;
      const maxConf = data.prism?.techniques?.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0) || 0;
      const fcs = data.trace?.fact_checks?.length || 0;
      const tox = data.signal?.toxicity_score || 0;
      let score = (techs > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
      score = Math.min(score, 100);
      addToHistory({ id: reportId, input: content.slice(0, 120), score, techniques: techs, mode, time: new Date().toISOString() });
    } catch (e) { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  const handleShare = async () => {
    if (!result) return;
    const reportId = result.id || result.blockchain?.content_hash?.slice(0, 12);
    const url = `${window.location.origin}/report/${reportId}`;
    await navigator.clipboard.writeText(url);
    setShareToast(url);
  };

  const handleRadarAnalyze = (url: string) => {
    setInputContent(url);
    handleScan(url, 'brief');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const remaining = Math.max(0, DAILY_LIMIT - usage);

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      {shareToast && <Toast message={`Link copied: ${shareToast}`} onClose={() => setShareToast('')} type="success" />}

      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }} onClick={onBack}>
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
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px 24px' }}>
          <ScanInput onScan={handleScan} loading={loading} initialContent={inputContent} />
        </div>
      </div>

      {remaining <= 3 && remaining > 0 && (
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '8px 24px' }}>
          <div style={{ padding: '10px 16px', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 10, fontSize: 13, color: '#92400e', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>{remaining} free {remaining === 1 ? 'scan' : 'scans'} remaining today.</span>
          </div>
        </div>
      )}

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 24px' }}>
        {error && <div style={{ marginBottom: 16, padding: 14, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>}
        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} onShare={handleShare} />}

        {!result && !loading && !error && (
          <div>
            <div style={{ textAlign: 'center', padding: '24px 0 20px' }}>
              <div style={{ fontSize: 15, fontWeight: 500, color: '#404040', marginBottom: 4 }}>Paste anything — URL, text, screenshot, or claim</div>
              <div style={{ fontSize: 13, color: '#aaa' }}>Or pick something from Radar below and see the playbook.</div>
            </div>

            <ScanHistory onReanalyze={(input) => handleScan(input, 'brief')} />

            <div style={{ borderTop: '1px solid #e5e5e5', paddingTop: 20 }}>
              <RadarFeed onAnalyze={handleRadarAnalyze} />
            </div>
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

  useEffect(() => {
    if (typeof window !== 'undefined' && localStorage.getItem('dissekt_analyze')) {
      setView('scan');
    }
  }, []);

  const handleShowToast = () => {
    setToast('Sign in / Sign up is under development. Currently enjoy the free tier — 10 scans per day!');
  };

  return (
    <>
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
      {showFeedback && <FeedbackModal onClose={() => setShowFeedback(false)} />}
      {view === 'scan' ? (
        <ScanPage onShowToast={handleShowToast} onShowFeedback={() => setShowFeedback(true)} onBack={() => setView('landing')} />
      ) : (
        <LandingPage onSignIn={handleShowToast} onTryFree={() => setView('scan')} onShowFeedback={() => setShowFeedback(true)} />
      )}
    </>
  );
}
MAINEOF

echo "✅ Task 4: page.tsx updated with reports, history, radar badges, share"
echo ""
echo "All 4 tasks complete:"
echo "  1. Shareable reports: /report/[id] page + API + share button"
echo "  2. Scan history: localStorage, shown above Radar, View + Rescan buttons"
echo "  3. Radar badges: 🔴🟡🟢 based on headline keywords"
echo "  4. Auth: kept as toast (ready to enable later)"
echo ""
echo "Don't forget to create the 'reports' table in Supabase SQL Editor!"
echo "Run: npm run dev"
