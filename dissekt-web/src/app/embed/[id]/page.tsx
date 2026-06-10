'use client';
import { useState, useEffect, use } from 'react';

export default function EmbedPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/report?id=${id}`)
      .then(r => r.json())
      .then(d => { if (!d.error) setData(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, [id]);

  if (loading) return <div style={{ padding: 20, textAlign: 'center', fontSize: 13, color: '#888' }}>Loading analysis...</div>;
  if (!data?.analysis) return <div style={{ padding: 20, textAlign: 'center', fontSize: 13, color: '#888' }}>Report not found</div>;

  const a = data.analysis;
  const techs = a.prism?.techniques || [];
  const fcs = a.trace?.fact_checks || [];
  const tox = a.signal?.toxicity_score || 0;
  const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  const raw = Math.min((techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs.length * 4, 30) + Math.round(tox * 20) + (fcs.length >= 3 ? 10 : 0), 100);
  const score = 100 - raw;
  const scoreColor = score <= 30 ? '#dc2626' : score <= 60 ? '#d97706' : '#16a34a';
  const label = score <= 30 ? 'Low transparency' : score <= 60 ? 'Moderate' : 'High transparency';

  return (
    <div style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', maxWidth: 400, margin: '0 auto', padding: 16 }}>
      {/* Score bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, marginBottom: 10 }}>
        <div style={{ width: 44, height: 44, borderRadius: 22, border: `3px solid ${scoreColor}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 16, fontWeight: 700, color: scoreColor }}>{score}</span>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: scoreColor }}>{label}</div>
          <div style={{ fontSize: 10, color: '#888' }}>{techs.length} techniques · {fcs.length} cross-refs · {(tox * 100).toFixed(1)}% toxicity</div>
        </div>
      </div>

      {/* Techniques */}
      {techs.length > 0 && (
        <div style={{ marginBottom: 10 }}>
          {techs.slice(0, 3).map((t: any, i: number) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', fontSize: 11, borderBottom: '1px solid #f0f0ee' }}>
              <span style={{ fontWeight: 500 }}>{(t.name || '').replace(/_/g, ' ')}</span>
              <span style={{ fontWeight: 700, color: t.confidence >= 0.8 ? '#dc2626' : '#d97706' }}>{Math.round(t.confidence * 100)}%</span>
            </div>
          ))}
        </div>
      )}

      {/* Brief */}
      {a.prism?.brief && (
        <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6, marginBottom: 10 }}>
          {a.prism.brief.slice(0, 200)}
        </div>
      )}

      {/* Footer */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 8, borderTop: '1px solid #e5e5e5' }}>
        <a href={`https://dissekt.info/report/${id}`} target="_blank" rel="noopener"
          style={{ fontSize: 11, color: '#0d9488', textDecoration: 'none', fontWeight: 600 }}>
          Full analysis →
        </a>
        <a href="https://dissekt.info" target="_blank" rel="noopener"
          style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: '#888', textDecoration: 'none' }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#0d9488" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          Powered by Dissekt
        </a>
      </div>
    </div>
  );
}
