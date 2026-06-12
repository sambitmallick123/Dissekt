'use client';
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function Kaleidoscope() {
  const [claim, setClaim] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [analyzed, setAnalyzed] = useState(false);

  const analyze = async () => {
    if (!claim || claim.length < 10) return;
    setLoading(true); setAnalyzed(false);
    try {
      // Analyze the claim from multiple angles using the existing scan API
      const sources = [
        claim,
        `According to conservative media, ${claim}`,
        `According to liberal media, ${claim}`,
        `International perspective on: ${claim}`,
        `Fact-checkers say about: ${claim}`,
      ];

      const analyses = await Promise.all(
        sources.map(async (src, i) => {
          try {
            const res = await fetch(`${API_URL}/api/scan`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ content: src, mode: 'brief' }),
            });
            return await res.json();
          } catch { return null; }
        })
      );

      setResults(analyses.filter(Boolean));
      setAnalyzed(true);
    } catch {}
    finally { setLoading(false); }
  };

  const labels = ['Original claim', 'Conservative framing', 'Liberal framing', 'International view', 'Fact-checker view'];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>📊</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Kaleidoscope</span>
        <span style={{ fontSize: 12, color: '#888' }}>How would different outlets frame this?</span>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <input type="text" value={claim} onChange={e => setClaim(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && analyze()}
          placeholder="Enter a claim to compare across perspectives..."
          style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 13, outline: 'none', background: '#f8fafa' }} />
        <button onClick={analyze} disabled={loading || claim.length < 10}
          style={{ padding: '10px 20px', background: claim.length >= 10 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: claim.length >= 10 ? 'pointer' : 'not-allowed' }}>
          {loading ? 'Analyzing...' : 'Compare'}
        </button>
      </div>

      {loading && (
        <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13 }}>
          Analyzing across 5 perspectives... (this takes ~30 seconds)
        </div>
      )}

      {analyzed && results.length > 0 && (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 11 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #e5eaea' }}>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Perspective</th>
                <th style={{ padding: '8px 10px', textAlign: 'center', color: '#888', fontWeight: 600 }}>Score</th>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Top techniques</th>
                <th style={{ padding: '8px 10px', textAlign: 'left', color: '#888', fontWeight: 600 }}>Brief</th>
              </tr>
            </thead>
            <tbody>
              {results.map((r, i) => {
                const techs = r?.prism?.techniques || [];
                const techScore = techs.length > 0
                  ? 100 - Math.min(Math.round(Math.max(...techs.map((t: any) => t.confidence || 0)) * 40) + Math.min(techs.length * 10, 30), 100)
                  : 100;
                const scoreColor = techScore >= 70 ? '#16a34a' : techScore >= 40 ? '#d97706' : '#dc2626';
                return (
                  <tr key={i} style={{ borderBottom: '0.5px solid #f0f0ee' }}>
                    <td style={{ padding: '8px 10px', fontWeight: 600, color: '#404040' }}>{labels[i] || `Source ${i + 1}`}</td>
                    <td style={{ padding: '8px 10px', textAlign: 'center' }}>
                      <span style={{ fontWeight: 700, color: scoreColor }}>{techScore}</span>
                    </td>
                    <td style={{ padding: '8px 10px' }}>
                      <div style={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                        {techs.slice(0, 3).map((t: any, j: number) => (
                          <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.name?.replace(/_/g, ' ')}</span>
                        ))}
                        {techs.length === 0 && <span style={{ color: '#aaa' }}>None</span>}
                      </div>
                    </td>
                    <td style={{ padding: '8px 10px', color: '#888', maxWidth: 200 }}>
                      {(r?.prism?.brief || '').slice(0, 80)}{(r?.prism?.brief || '').length > 80 ? '...' : ''}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
