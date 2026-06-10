'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import { useState } from 'react';
import ThreatScore from '@/components/ThreatScore';
import PrismCard from '@/components/PrismCard';
import TraceCard from '@/components/TraceCard';

export default function ComparePage() {
  const [contentA, setContentA] = useState('');
  const [contentB, setContentB] = useState('');
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleCompare = async () => {
    if (contentA.length < 10 || contentB.length < 10) { setError('Both inputs must be at least 10 characters'); return; }
    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch('/api/compare', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content_a: contentA, content_b: contentB, mode: 'brief' }),
      });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Comparison failed'); return; }
      setResult(await res.json());
    } catch { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 12px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, outline: 'none', background: '#f8f8f6', fontFamily: 'inherit', resize: 'vertical' };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader />

      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '24px 24px' }}>
        <h1 style={{ fontSize: 20, fontWeight: 600, marginBottom: 4 }}>⚖️ Comparative Analysis</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Compare how two sources cover the same story. Paste URLs or text for both.</p>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>Source A</div>
            <textarea placeholder="Paste URL or text..." value={contentA} onChange={e => setContentA(e.target.value)} rows={4} style={inputStyle} />
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#2563eb', marginBottom: 6 }}>Source B</div>
            <textarea placeholder="Paste URL or text..." value={contentB} onChange={e => setContentB(e.target.value)} rows={4} style={inputStyle} />
          </div>
        </div>

        {error && <div style={{ marginBottom: 16, padding: 12, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>}

        <button onClick={handleCompare} disabled={loading || contentA.length < 10 || contentB.length < 10}
          style={{ width: '100%', padding: '12px 0', background: (contentA.length >= 10 && contentB.length >= 10 && !loading) ? '#0d9488' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 14, fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', marginBottom: 20 }}>
          {loading ? '🔍 Comparing... (this takes 10-20 seconds)' : '⚖️ Compare both sources'}
        </button>

        {result && (
          <>
            {/* Comparison summary */}
            <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>📝 Comparison Summary</div>
              <p style={{ fontSize: 13, color: '#404040', lineHeight: 1.6 }}>{result.comparison?.summary}</p>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, marginTop: 12 }}>
                <div style={{ padding: '8px 10px', background: '#f0fdfa', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#0d9488', fontWeight: 600 }}>SHARED TECHNIQUES</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.shared_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.shared_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
                <div style={{ padding: '8px 10px', background: '#f0fdfa', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#0d9488', fontWeight: 600 }}>ONLY IN A</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.only_a_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.only_a_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
                <div style={{ padding: '8px 10px', background: '#eff6ff', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#2563eb', fontWeight: 600 }}>ONLY IN B</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.only_b_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.only_b_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
              </div>
            </div>

            {/* Side by side results */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 8, padding: '6px 12px', background: '#f0fdfa', borderRadius: 8, textAlign: 'center' }}>Source A</div>
                <ThreatScore data={result.result_a} />
                <div style={{ marginTop: 12 }}><PrismCard prism={result.result_a?.prism} /></div>
                <div style={{ marginTop: 12 }}><TraceCard trace={result.result_a?.trace} /></div>
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#2563eb', marginBottom: 8, padding: '6px 12px', background: '#eff6ff', borderRadius: 8, textAlign: 'center' }}>Source B</div>
                <ThreatScore data={result.result_b} />
                <div style={{ marginTop: 12 }}><PrismCard prism={result.result_b?.prism} /></div>
                <div style={{ marginTop: 12 }}><TraceCard trace={result.result_b?.trace} /></div>
              </div>
            </div>
          </>
        )}
      </div>
    <SiteFooter />
    </main>
  );
}
