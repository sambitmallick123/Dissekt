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
