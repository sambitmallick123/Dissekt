'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';
import ScanHistory, { addToHistory } from '@/components/ScanHistory';
import BulkAnalysis from '@/components/BulkAnalysis';
import Recall from '@/components/Recall';
import LedgerView from '@/components/Ledger';
import Reflect from '@/components/Reflect';
import TrustGraph from '@/components/TrustGraph';
import Scope from '@/components/Scope';
import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';
import { fetchConfig } from '@/lib/config';
import { FeatureLockedPopup, useFeatureGate } from '@/components/FeatureGate';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function ScanApp() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [inputContent, setInputContent] = useState('');
  const [scanTab, setScanTab] = useState<'single' | 'bulk'>('single');
  const [remaining, setRemaining] = useState<{ brief: number; detailed: number; tier: 'free' | 'invited' }>({ brief: 3, detailed: 1, tier: 'free' });
  const [resetIn, setResetIn] = useState('');
  const [shareToast, setShareToast] = useState('');
  const [mounted, setMounted] = useState(false);
  const [enabledFeatures, setEnabledFeatures] = useState<string[]>([]);
  const { lockedFeature, checkFeature, closePopup } = useFeatureGate();

  useEffect(() => {
    setMounted(true);
    fetchConfig().then(cfg => {
      const tier = getTier();
      const key = tier === 'invited' ? 'features_invited' : 'features_free';
      setEnabledFeatures(cfg[key] || ['single_scan', 'radar']);
    });
    setRemaining(getRemaining());
    setResetIn(getResetTime());
    const t = setInterval(() => setResetIn(getResetTime()), 60000);
    return () => clearInterval(t);
  }, []);

  const handleScan = async (content: string, modeArg: string) => {
    const mode = (modeArg === 'detailed' ? 'detailed' : 'brief') as 'brief' | 'detailed';
    if (!content || content.length < 10) { setError('Please enter at least 10 characters'); return; }

    // Gate detailed mode
    if (mode === 'detailed' && !enabledFeatures.includes('detailed_mode')) {
      checkFeature('Detailed mode', enabledFeatures);
      return;
    }

    if (!canScan(mode)) {
      const tier = getTier();
      if (tier === 'free') {
        setError(`Free tier limit reached for ${mode} scans (${LIMITS.free[mode]}/day). Resets in ${getResetTime()} at 00:00 GMT.`);
      } else {
        setError(`Daily limit reached for ${mode} scans. Resets in ${getResetTime()} at 00:00 GMT.`);
      }
      return;
    }

    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch(`${API_URL}/api/scan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });
      if (!res.ok) {
        const err = await res.json();
        setError(err.detail || 'Analysis failed'); return;
      }
      const data = await res.json();
      setResult(data);
      incrementUsage(mode);
      setRemaining(getRemaining());
      addToHistory({
        id: data.id,
        input: content.slice(0, 100),
        score: data.scoring?.clarity_score || data.clarity_score || 50,
        techniques: data.prism?.techniques?.length || 0,
        mode,
        time: new Date().toISOString(),
      });
    } catch {
      setError('Could not connect to the analysis service.');
    } finally {
      setLoading(false);
    }
  };

  const handleShare = async () => {
    if (!result?.id) return;
    const url = `${window.location.origin}/report/${result.id}`;
    await navigator.clipboard.writeText(url);
    setShareToast('Report link copied!');
    setTimeout(() => setShareToast(''), 2000);
  };

  if (!mounted) return null;

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader active="Analyze" />

      {lockedFeature && <FeatureLockedPopup feature={lockedFeature} onClose={closePopup} />}

      {shareToast && (
        <div style={{ position: 'fixed', top: 70, left: '50%', transform: 'translateX(-50%)', background: '#1a1a1a', color: '#fff', padding: '8px 16px', borderRadius: 8, fontSize: 13, zIndex: 100 }}>{shareToast}</div>
      )}

      {/* Scan input area */}
      <div style={{ background: '#fff', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, flexWrap: 'wrap', gap: 8 }}>
            <div style={{ display: 'flex', gap: 6 }}>
              <button onClick={() => setScanTab('single')}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'single' ? '#0d9488' : '#f0f0ee', color: scanTab === 'single' ? '#fff' : '#555' }}>
                Single scan
              </button>
              <button onClick={() => { if (checkFeature('Bulk CSV analysis', enabledFeatures)) setScanTab('bulk'); }}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'bulk' ? '#0d9488' : '#f0f0ee', color: scanTab === 'bulk' ? '#fff' : '#555' }}>
                📊 Bulk CSV {!enabledFeatures.includes('bulk') && '🔒'}
              </button>
              <a href="/compare" style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 500, background: '#f0f0ee', color: '#555', textDecoration: 'none', display: 'flex', alignItems: 'center' }}>⚖️ Compare</a>
            </div>
            <div style={{ fontSize: 11, color: '#888', textAlign: 'right' }}>
              <span style={{ fontWeight: 600, color: remaining.tier === 'invited' ? '#0d9488' : '#888' }}>
                {remaining.tier === 'invited' ? '🎫 Invited' : '🆓 Free'}
              </span>
              {' · '}{remaining.brief} brief, {remaining.detailed} detailed left
              <div style={{ fontSize: 10, color: '#aaa' }}>Resets in {resetIn} (00:00 GMT)</div>
            </div>
          </div>

          {scanTab === 'single' && <ScanInput onScan={handleScan} loading={loading} initialContent={inputContent} />}
          {scanTab === 'bulk' && <BulkAnalysis />}
        </div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 16px' }}>
        {error && (
          <div style={{ marginBottom: 16, padding: 12, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>
        )}

        {loading && <LoadingState />}

        {result && !loading && <AnalysisResult data={result} onShare={handleShare} />}

        {!result && !loading && (
          <>
            <TrustGraph />
            <Reflect />
            <LedgerView />
            <Recall onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
            <ScanHistory onReanalyze={(input: string) => handleScan(input, 'brief')} />
            <Scope onAnalyze={(text: string) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
          </>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
