'use client';
import { useState } from 'react';
import { getUserEmail, canScan, incrementUsage, getTier, getResetTime, LIMITS } from '@/lib/tier';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const toxColor = (t: number) => (t >= 0.65 ? '#dc2626' : t >= 0.4 ? '#d97706' : '#16a34a');
const clarColor = (c: number) => (c >= 0.65 ? '#16a34a' : c >= 0.35 ? '#d97706' : '#dc2626');
const clarLabel = (c: number) => (c >= 0.65 ? 'high' : c >= 0.35 ? 'moderate' : 'low');

export default function KeywordAnalysis() {
  const [keyword, setKeyword] = useState('');
  const [chips, setChips] = useState<string[]>([]);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [loadingSug, setLoadingSug] = useState(false);
  const [loadingReport, setLoadingReport] = useState(false);
  const [report, setReport] = useState<any>(null);
  const [error, setError] = useState('');

  // split on commas so "a, b, c" becomes individual chips
  const addKeywords = (raw: string) => {
    const parts = raw.split(',').map(p => p.trim()).filter(Boolean);
    if (report) { setReport(null); setSuggestions([]); }  // starting a fresh search
    setChips(prev => {
      const base = report ? [] : prev;  // don't append onto a finished search
      const next = [...base];
      parts.forEach(p => { if (!next.some(x => x.toLowerCase() === p.toLowerCase())) next.push(p); });
      return next;
    });
  };

  const suggest = async () => {
    const kw = keyword.trim();
    if (kw.length < 2) return;
    setLoadingSug(true); setError('');
    addKeywords(kw);
    const firstWord = kw.split(',')[0].trim();
    setKeyword('');
    try {
      const res = await fetch(`${API_URL}/api/keyword/recommend`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ keyword: firstWord }),
      });
      const d = await res.json();
      setSuggestions((d.suggestions || []));
    } catch { setSuggestions([]); }
    finally { setLoadingSug(false); }
  };

  const addChip = (s: string) => {
    setChips(prev => prev.some(x => x.toLowerCase() === s.toLowerCase()) ? prev : [...prev, s]);
    setSuggestions(prev => prev.filter(x => x !== s));
  };
  const removeChip = (s: string) => setChips(prev => prev.filter(x => x !== s));

  const analyze = async () => {
    if (chips.length === 0) { setError('Add at least one keyword.'); return; }
    // Keyword analysis counts as one scan against the brief/detailed quota
    if (!canScan('brief')) {
      const tier = getTier();
      setError(tier === 'free'
        ? `Free tier limit reached for brief scans (${LIMITS.free.brief}/day). Resets in ${getResetTime()} at 00:00 GMT.`
        : `Daily limit reached for brief scans. Resets in ${getResetTime()} at 00:00 GMT.`);
      return;
    }
    setLoadingReport(true); setError(''); setReport(null);
    try {
      const res = await fetch(`${API_URL}/api/keyword/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-User-Email': getUserEmail() || '' },
        body: JSON.stringify({ keywords: chips, mode: 'brief' }),
      });
      if (!res.ok) { const e = await res.json().catch(() => ({})); throw new Error(e.detail || 'Analysis failed'); }
      const data = await res.json();
      setReport(data);
      incrementUsage('brief');  // count it only on success
    } catch (err: any) { setError(err.message || 'Something went wrong'); }
    finally { setLoadingReport(false); }
  };

  const s = report?.summary;
  const sortedArticles = report?.articles ? [...report.articles].sort((a: any, b: any) => (a.clarity ?? 1) - (b.clarity ?? 1)) : [];
  const topTech = s?.dominant_techniques?.[0];
  const clarVals = sortedArticles.map((a: any) => a.clarity).filter((x: any) => x != null);
  const clarLo = clarVals.length ? Math.min(...clarVals) : null;
  const clarHi = clarVals.length ? Math.max(...clarVals) : null;
  const uniqueSources = report ? new Set((report.articles || []).map((a: any) => a.source).filter(Boolean)).size : 0;
  const unfetched = s ? Math.max((s.attempted || 0) - (s.count || 0), 0) : 0;

  return (
    <div style={{ padding: '4px 0' }}>
      {/* INPUT */}
      <div style={{ display: 'flex', gap: 8, marginBottom: chips.length ? 14 : 0 }}>
        <input type="text" value={keyword} onChange={e => setKeyword(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter' && keyword.trim()) { addKeywords(keyword); setKeyword(''); } }}
          placeholder="Type a keyword and press Enter, or use Suggest…"
          style={{ flex: 1, padding: '11px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff' }} />
        <button onClick={suggest} disabled={loadingSug || keyword.trim().length < 2}
          style={{ padding: '11px 18px', background: '#f0f0ee', color: '#555', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: keyword.trim().length >= 2 ? 'pointer' : 'default', whiteSpace: 'nowrap' }}>
          {loadingSug ? '…' : '✦ Suggest'}
        </button>
      </div>

      {/* REFINEMENT PANEL (only when there are chips) */}
      {chips.length > 0 && (
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: 14, marginBottom: 14 }}>
          <div style={{ fontSize: 11, color: '#aaa', marginBottom: 8 }}>Searching for</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: suggestions.length ? 12 : 0 }}>
            {chips.map(ch => (
              <span key={ch} style={{ fontSize: 12, padding: '4px 10px', borderRadius: 20, background: '#f0fdfa', color: '#0d9488', border: '1px solid #cce9e3', display: 'flex', alignItems: 'center', gap: 5 }}>
                {ch}
                <span onClick={() => removeChip(ch)} style={{ cursor: 'pointer', fontWeight: 700 }}>×</span>
              </span>
            ))}
          </div>
          {suggestions.length > 0 && (
            <>
              <div style={{ fontSize: 11, color: '#aaa', marginBottom: 6, borderTop: '0.5px solid #f0efec', paddingTop: 10 }}>Suggested — tap to add</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                {suggestions.map(sg => (
                  <span key={sg} onClick={() => addChip(sg)}
                    style={{ fontSize: 12, padding: '4px 10px', borderRadius: 20, background: '#f0f0ee', color: '#555', cursor: 'pointer' }}>
                    + {sg}
                  </span>
                ))}
              </div>
            </>
          )}
        </div>
      )}

      {/* ACTION ROW */}
      {chips.length > 0 && (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
          <div />
          <button onClick={analyze} disabled={loadingReport}
            style={{ padding: '10px 22px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
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

      {/* REPORT — Option A editorial */}
      {report && !loadingReport && (
        <div>
          {s?.count > 0 ? (
            <>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 6 }}>Coverage analysis · {report.topic}</div>
              {unfetched > 0 && (
                <div style={{ fontSize: 11, color: '#a16207', background: '#fef9e7', border: '0.5px solid #fde68a', borderRadius: 6, padding: '6px 10px', marginBottom: 10 }}>
                  ⓘ {unfetched} source{unfetched !== 1 ? 's' : ''} couldn't be fetched (paywalled or blocking automated access) and {unfetched !== 1 ? 'were' : 'was'} excluded.
                </div>
              )}
              <div style={{ fontFamily: 'Charter, Georgia, serif', fontSize: 19, lineHeight: 1.5, marginBottom: 16, color: '#1a1a1a' }}>
                Across {s.count} article{s.count !== 1 ? 's' : ''}, coverage shows{' '}
                <span style={{ color: s.avg_clarity != null ? clarColor(s.avg_clarity) : '#888' }}>
                  {s.avg_clarity != null ? `${clarLabel(s.avg_clarity)} clarity (${s.avg_clarity.toFixed(2)})` : 'unscored clarity'}
                </span>
                {topTech && <> — the dominant pattern is <span style={{ color: '#0d9488' }}>{topTech.name.replace(/_/g, ' ')}</span>, in {topTech.count} of {s.count} sources</>}.
              </div>

              {s.synopsis && (
                <div style={{ background: '#f0fdfa', border: '0.5px solid #cce9e3', borderRadius: 10, padding: '12px 16px', marginBottom: 16 }}>
                  <div style={{ fontSize: 14, lineHeight: 1.7, color: '#374151' }}>{s.synopsis}</div>
                  <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 8 }}>* Topic summary is inferred from article headlines and sources, not full text.</div>
                </div>
              )}

              {/* stat strip */}
              <div style={{ display: 'flex', gap: 20, padding: '12px 0', borderTop: '0.5px solid #ececec', borderBottom: '0.5px solid #ececec', marginBottom: 18, flexWrap: 'wrap' }}>
                <div><span style={{ fontSize: 20, fontWeight: 700, color: s.avg_clarity != null ? clarColor(s.avg_clarity) : '#888' }}>{s.avg_clarity != null ? s.avg_clarity.toFixed(2) : '—'}</span> <span style={{ fontSize: 12, color: '#888' }}>clarity</span></div>
                <div><span style={{ fontSize: 20, fontWeight: 700 }}>{s.count}</span> <span style={{ fontSize: 12, color: '#888' }}>articles</span></div>
                <div><span style={{ fontSize: 20, fontWeight: 700 }}>{uniqueSources}</span> <span style={{ fontSize: 12, color: '#888' }}>source{uniqueSources !== 1 ? 's' : ''}</span></div>
                <div><span style={{ fontSize: 20, fontWeight: 700 }}>{clarLo != null && clarHi != null ? `${clarLo.toFixed(2)}–${clarHi.toFixed(2)}` : '—'}</span> <span style={{ fontSize: 12, color: '#888' }}>clarity range</span></div>
              </div>

              {/* technique bars */}
              {s.dominant_techniques?.length > 0 && (
                <div style={{ marginBottom: 18 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 8 }}>How these articles are constructed</div>
                  {s.dominant_techniques.map((t: any) => (
                    <div key={t.name} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                      <span style={{ fontSize: 12, width: 140, flexShrink: 0 }}>{t.name.replace(/_/g, ' ')}</span>
                      <div style={{ flex: 1, height: 6, background: '#f0f0ee', borderRadius: 3, overflow: 'hidden' }}>
                        <div style={{ width: `${Math.min((t.count / s.count) * 100, 100)}%`, height: '100%', background: '#0d9488' }} />
                      </div>
                      <span style={{ fontSize: 11, color: '#888', width: 30, textAlign: 'right' }}>{t.count}/{s.count}</span>
                    </div>
                  ))}
                </div>
              )}

              {/* sources, least to most clear */}
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 8 }}>Sources, least to most clear</div>
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {sortedArticles.map((a: any, i: number) => (
                  <a key={i} href={a.url || undefined} target="_blank" rel="noopener"
                    style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: i < sortedArticles.length - 1 ? '0.5px solid #f0efec' : 'none', textDecoration: 'none' }}>
                    <span style={{ width: 4, height: 32, background: a.clarity != null ? clarColor(a.clarity) : '#ccc', flexShrink: 0 }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.title || a.source || a.url}</div>
                      <div style={{ fontSize: 11, color: '#aaa' }}>{a.source} · {(a.techniques || []).slice(0, 2).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'analyzed'}</div>
                    </div>
                    <span style={{ fontSize: 14, fontWeight: 600, color: a.clarity != null ? clarColor(a.clarity) : '#888', flexShrink: 0 }}>{a.clarity != null ? a.clarity.toFixed(2) : '—'}</span>
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
