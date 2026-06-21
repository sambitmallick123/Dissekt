'use client';
import { useState } from 'react';
import { getUserEmail } from '@/lib/tier';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const toxColor = (t: number) => (t >= 0.65 ? '#dc2626' : t >= 0.4 ? '#d97706' : '#16a34a');
const clarColor = (c: number) => (c >= 0.65 ? '#16a34a' : c >= 0.35 ? '#d97706' : '#dc2626');

export default function KeywordAnalysis() {
  const [keyword, setKeyword] = useState('');
  const [chips, setChips] = useState<string[]>([]);          // selected keywords
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');
  const [loadingSug, setLoadingSug] = useState(false);
  const [loadingReport, setLoadingReport] = useState(false);
  const [report, setReport] = useState<any>(null);
  const [error, setError] = useState('');

  const suggest = async () => {
    const kw = keyword.trim();
    if (kw.length < 2) return;
    setLoadingSug(true); setError('');
    // add the typed keyword as the first chip if not present
    setChips(prev => prev.includes(kw) ? prev : [...prev, kw]);
    setKeyword('');
    try {
      const res = await fetch(`${API_URL}/api/keyword/recommend`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ keyword: kw }),
      });
      const d = await res.json();
      setSuggestions((d.suggestions || []).filter((s: string) => !chips.includes(s)));
    } catch { setSuggestions([]); }
    finally { setLoadingSug(false); }
  };

  const addChip = (s: string) => {
    if (!chips.includes(s)) setChips([...chips, s]);
    setSuggestions(suggestions.filter(x => x !== s));
  };
  const removeChip = (s: string) => setChips(chips.filter(x => x !== s));

  const analyze = async () => {
    if (chips.length === 0) { setError('Add at least one keyword.'); return; }
    setLoadingReport(true); setError(''); setReport(null);
    try {
      const res = await fetch(`${API_URL}/api/keyword/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-User-Email': getUserEmail() || '' },
        body: JSON.stringify({ keywords: chips, mode }),
      });
      if (!res.ok) { const e = await res.json().catch(() => ({})); throw new Error(e.detail || 'Analysis failed'); }
      setReport(await res.json());
    } catch (err: any) { setError(err.message || 'Something went wrong'); }
    finally { setLoadingReport(false); }
  };

  const s = report?.summary;

  return (
    <div style={{ padding: '4px 0' }}>
      {/* INPUT ROW */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <input type="text" value={keyword} onChange={e => setKeyword(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && suggest()}
          placeholder="Enter a topic: 5G health risks, election fraud, climate…"
          style={{ flex: 1, padding: '11px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff' }} />
        <button onClick={suggest} disabled={loadingSug || keyword.trim().length < 2}
          style={{ padding: '11px 18px', background: keyword.trim().length >= 2 ? '#f0f0ee' : '#f7f7f5', color: '#555', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: keyword.trim().length >= 2 ? 'pointer' : 'default' }}>
          {loadingSug ? '…' : '+ Suggest related'}
        </button>
      </div>

      {/* SELECTED CHIPS */}
      {chips.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 10 }}>
          {chips.map(ch => (
            <span key={ch} style={{ fontSize: 12, padding: '4px 10px', borderRadius: 20, background: '#f0fdfa', color: '#0d9488', border: '1px solid #cce9e3', display: 'flex', alignItems: 'center', gap: 5 }}>
              {ch}
              <span onClick={() => removeChip(ch)} style={{ cursor: 'pointer', fontWeight: 700 }}>×</span>
            </span>
          ))}
        </div>
      )}

      {/* SUGGESTIONS */}
      {suggestions.length > 0 && (
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, color: '#888', marginBottom: 6 }}>Add related keywords to sharpen the search:</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {suggestions.map(sg => (
              <span key={sg} onClick={() => addChip(sg)}
                style={{ fontSize: 12, padding: '4px 10px', borderRadius: 20, background: '#f0f0ee', color: '#555', cursor: 'pointer' }}>
                + {sg}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* DEPTH + ANALYZE */}
      {chips.length > 0 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 4, background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
            <button onClick={() => setMode('brief')}
              style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'brief' ? '#fff' : 'transparent', color: mode === 'brief' ? '#0d9488' : '#888' }}>
              Brief · more articles
            </button>
            <button onClick={() => setMode('detailed')}
              style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'detailed' ? '#fff' : 'transparent', color: mode === 'detailed' ? '#0d9488' : '#888' }}>
              Detailed · deeper
            </button>
          </div>
          <button onClick={analyze} disabled={loadingReport}
            style={{ padding: '10px 22px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer', marginLeft: 'auto' }}>
            {loadingReport ? 'Analyzing coverage…' : 'Analyze topic'}
          </button>
        </div>
      )}

      {error && (
        <div style={{ marginBottom: 16, padding: 12, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>
      )}

      {loadingReport && (
        <div style={{ textAlign: 'center', padding: 40, color: '#888', fontSize: 13 }}>
          Fetching and analyzing recent coverage… this can take up to a minute.
        </div>
      )}

      {/* REPORT */}
      {report && !loadingReport && (
        <div>
          <div style={{ fontSize: 17, fontWeight: 600, marginBottom: 4 }}>"{report.topic}" — coverage analysis</div>
          <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>
            {s?.count || 0} of {s?.attempted || 0} articles analyzed{report.cached ? ' · cached' : ''}
          </div>

          {s?.count > 0 ? (
            <>
              {/* SUMMARY CARDS */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px,1fr))', gap: 12, marginBottom: 20 }}>
                <div style={{ background: '#fafaf8', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 11, color: '#888' }}>Avg clarity</div>
                  <div style={{ fontSize: 22, fontWeight: 700, color: s.avg_clarity != null ? clarColor(s.avg_clarity) : '#888' }}>
                    {s.avg_clarity != null ? s.avg_clarity.toFixed(2) : '—'}
                  </div>
                </div>
                <div style={{ background: '#fafaf8', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 11, color: '#888' }}>Articles</div>
                  <div style={{ fontSize: 22, fontWeight: 700 }}>{s.count}</div>
                </div>
                <div style={{ background: '#fafaf8', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: 11, color: '#888' }}>Avg toxicity</div>
                  <div style={{ fontSize: 22, fontWeight: 700, color: s.avg_toxicity != null ? toxColor(s.avg_toxicity) : '#888' }}>
                    {s.avg_toxicity != null ? `${Math.round(s.avg_toxicity * 100)}%` : '—'}
                  </div>
                </div>
              </div>

              {/* DOMINANT TECHNIQUES */}
              {s.dominant_techniques?.length > 0 && (
                <div style={{ marginBottom: 20 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>Dominant manipulation techniques</div>
                  {s.dominant_techniques.map((t: any) => (
                    <div key={t.name} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 7 }}>
                      <span style={{ fontSize: 12, width: 150, flexShrink: 0 }}>{t.name.replace(/_/g, ' ')}</span>
                      <div style={{ flex: 1, height: 7, background: '#f0f0ee', borderRadius: 4, overflow: 'hidden' }}>
                        <div style={{ width: `${Math.min((t.count / s.count) * 100, 100)}%`, height: '100%', background: '#0d9488' }} />
                      </div>
                      <span style={{ fontSize: 11, color: '#888', width: 36, textAlign: 'right' }}>{t.count}/{s.count}</span>
                    </div>
                  ))}
                </div>
              )}

              {/* SOURCES */}
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>Sources analyzed</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {report.articles.map((a: any, i: number) => (
                  <a key={i} href={a.analysis_id ? `/report/${a.analysis_id}` : a.url} target={a.analysis_id ? '_self' : '_blank'}
                    style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10, padding: '10px 12px', background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 8, textDecoration: 'none' }}>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.title || a.source || a.url}</div>
                      <div style={{ fontSize: 11, color: '#888' }}>
                        {a.source} · {(a.techniques || []).slice(0, 2).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'analyzed'}
                      </div>
                    </div>
                    <span style={{ fontSize: 13, fontWeight: 600, color: a.clarity != null ? clarColor(a.clarity) : '#888', flexShrink: 0 }}>
                      {a.clarity != null ? a.clarity.toFixed(2) : '—'}
                    </span>
                  </a>
                ))}
              </div>
            </>
          ) : (
            <div style={{ textAlign: 'center', padding: 40, color: '#888', fontSize: 13 }}>
              {report.message || 'No analyzable coverage found. Try different or broader keywords.'}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
