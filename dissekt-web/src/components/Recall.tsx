'use client';
import { useState } from 'react';

export default function Recall({ onAnalyze }: { onAnalyze: (text: string) => void }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);

  const handleSearch = async () => {
    if (query.length < 3) return;
    setLoading(true);
    setSearched(true);
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/memory?q=${encodeURIComponent(query)}&limit=8`);
      const data = await res.json();
      setResults(data.results || []);
    } catch { setResults([]); }
    finally { setLoading(false); }
  };

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>🧠</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Memory</span>
        <span style={{ fontSize: 12, color: '#888' }}>Search past analyses by topic</span>
      </div>

      <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
        <input
          type="text"
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSearch()}
          placeholder="e.g. vaccines, Modi, climate change..."
          style={{ flex: 1, padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, outline: 'none', background: '#f8f8f6' }}
        />
        <button onClick={handleSearch} disabled={loading || query.length < 3}
          style={{ padding: '8px 16px', background: query.length >= 3 ? '#0d9488' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 8, fontSize: 12, fontWeight: 600, cursor: query.length >= 3 ? 'pointer' : 'not-allowed' }}>
          {loading ? '...' : 'Search'}
        </button>
      </div>

      {searched && results.length === 0 && !loading && (
        <div style={{ textAlign: 'center', padding: '12px 0', color: '#888', fontSize: 12 }}>
          No past analyses found for "{query}". Analyze some content first to build your memory.
        </div>
      )}

      {results.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {results.map((r, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 10, padding: '8px 10px', border: '1px solid #e5e5e5', borderRadius: 8 }}>
              <div style={{ width: 32, height: 32, borderRadius: 6, background: '#f0fdfa', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: '#0d9488' }}>{Math.round((r.similarity || 0) * 100)}%</span>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>
                  {r.text_preview}
                </div>
                {r.techniques?.length > 0 && (
                  <div style={{ display: 'flex', gap: 4, marginTop: 4, flexWrap: 'wrap' }}>
                    {r.techniques.slice(0, 3).map((t: string, j: number) => (
                      <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.replace(/_/g, ' ')}</span>
                    ))}
                  </div>
                )}
              </div>
              <button onClick={() => onAnalyze(r.text_preview)}
                style={{ fontSize: 10, padding: '4px 8px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600, flexShrink: 0 }}>
                Rescan
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
