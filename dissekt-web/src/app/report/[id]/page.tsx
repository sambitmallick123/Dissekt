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
            <div style={{ width: 28, height: 28, background: '#0d9488', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </a>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 12, color: '#888', background: '#f0f0ee', padding: '4px 10px', borderRadius: 6 }}>Shared report</span>
            <a href="/" style={{ fontSize: 13, color: '#0d9488', textDecoration: 'none', fontWeight: 500 }}>Scan your own →</a>
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
            <a href="/" style={{ color: '#0d9488', textDecoration: 'none', fontWeight: 500 }}>Run your own scan →</a>
          </div>
        )}

        {data?.analysis && <AnalysisResult data={data.analysis} />}

        {data && (
          <div style={{ textAlign: 'center', marginTop: 24, padding: '16px 0', borderTop: '1px solid #e5e5e5', fontSize: 12, color: '#aaa' }}>
            Scanned {new Date(data.created_at).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })} · {data.mode} mode
            <span style={{ margin: '0 6px' }}>·</span>
            <a href="/" style={{ color: '#0d9488', textDecoration: 'none' }}>dissekt.info</a>
          </div>
        )}
      </div>
    </main>
  );
}
