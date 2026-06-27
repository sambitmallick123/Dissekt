'use client';
import { useState, useEffect } from 'react';

export default function Reflect() {
  const [decisions, setDecisions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [open, setOpen] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/decisions');
      const data = await res.json();
      setDecisions(data.decisions || []);
    } catch {}
    finally { setLoading(false); setLoaded(true); }
  };

  if (!loaded) {
    return (
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 16 }}>🪞</span>
            <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Your Reflect</span>
            <span style={{ fontSize: 12, color: '#888' }}>Based on your decisions</span>
          </div>
          <button onClick={load} disabled={loading} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>
            {loading ? 'Loading...' : 'Reveal'}
          </button>
        </div>
      </div>
    );
  }

  if (decisions.length < 3) {
    return (
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16, textAlign: 'center' }}>
        <span style={{ fontSize: 16 }}>🪞</span>
        <div style={{ fontSize: 13, color: '#888', marginTop: 6 }}>Need at least 3 decisions to build your profile. Keep analyzing and marking Trust/Unsure/Reject.</div>
      </div>
    );
  }

  // Analyze patterns
  const total = decisions.length;
  const trustCount = decisions.filter(d => d.decision === 'trust').length;
  const unsureCount = decisions.filter(d => d.decision === 'unsure').length;
  const rejectCount = decisions.filter(d => d.decision === 'reject').length;

  const trustPct = Math.round((trustCount / total) * 100);
  const unsurePct = Math.round((unsureCount / total) * 100);
  const rejectPct = Math.round((rejectCount / total) * 100);

  // Find patterns in what they trust vs reject
  const trustWords: Record<string, number> = {};
  const rejectWords: Record<string, number> = {};
  
  for (const d of decisions) {
    const words = (d.input_preview || '').toLowerCase().split(/\s+/).filter((w: string) => w.length > 4);
    const target = d.decision === 'trust' ? trustWords : d.decision === 'reject' ? rejectWords : {};
    for (const w of words) {
      target[w] = (target[w] || 0) + 1;
    }
  }

  const topTrustTopics = Object.entries(trustWords).sort((a, b) => b[1] - a[1]).slice(0, 3);
  const topRejectTopics = Object.entries(rejectWords).sort((a, b) => b[1] - a[1]).slice(0, 3);

  // Determine profile type
  let profileType = '';
  let profileDesc = '';
  if (trustPct > 60) { profileType = 'Trusting reader'; profileDesc = 'You tend to accept most content at face value. Consider applying more scrutiny to claims that align with your existing beliefs.'; }
  else if (rejectPct > 60) { profileType = 'Skeptical reader'; profileDesc = 'You reject most content you analyze. This is healthy skepticism, but be careful not to dismiss credible information along with the misleading.'; }
  else if (unsurePct > 40) { profileType = 'Careful evaluator'; profileDesc = 'You frequently mark content as "Unsure" — a sign of thoughtful evaluation. You prefer to gather more evidence before deciding.'; }
  else { profileType = 'Balanced reader'; profileDesc = 'Your decisions are spread across Trust, Unsure, and Reject. You evaluate each piece of content on its own merits.'; }

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginBottom: 16 }}>
      <div onClick={() => setOpen(o => !o)} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: open ? 14 : 0, cursor: 'pointer' }}>
        <span style={{ fontSize: 16 }}>🪞</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Your Reflect</span>
        <span style={{ fontSize: 12, color: '#888' }}>Based on {total} decisions</span>
        <span style={{ marginLeft: 'auto', fontSize: 12, color: '#888' }}>{open ? '▾' : '▸'}</span>
      </div>

      {open && <>
      {/* Profile type */}
      <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10, marginBottom: 14 }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>{profileType}</div>
        <div style={{ fontSize: 12, color: '#555', lineHeight: 1.6 }}>{profileDesc}</div>
      </div>

      {/* Decision distribution */}
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Decision distribution</div>
        <div style={{ display: 'flex', height: 24, borderRadius: 6, overflow: 'hidden', marginBottom: 6 }}>
          {trustPct > 0 && <div style={{ width: `${trustPct}%`, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{trustPct}%</span></div>}
          {unsurePct > 0 && <div style={{ width: `${unsurePct}%`, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{unsurePct}%</span></div>}
          {rejectPct > 0 && <div style={{ width: `${rejectPct}%`, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{rejectPct}%</span></div>}
        </div>
        <div style={{ display: 'flex', gap: 12, fontSize: 11 }}>
          <span style={{ color: '#16a34a' }}>✅ Trust: {trustCount}</span>
          <span style={{ color: '#d97706' }}>🤔 Unsure: {unsureCount}</span>
          <span style={{ color: '#dc2626' }}>❌ Reject: {rejectCount}</span>
        </div>
      </div>

      {/* Topic patterns */}
      {(topTrustTopics.length > 0 || topRejectTopics.length > 0) && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {topTrustTopics.length > 0 && (
            <div style={{ padding: '8px 10px', background: '#f0fdf4', borderRadius: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#166534', marginBottom: 4 }}>Topics you trust</div>
              {topTrustTopics.map(([word, count], i) => (
                <div key={i} style={{ fontSize: 11, color: '#555' }}>{word} ({count}x)</div>
              ))}
            </div>
          )}
          {topRejectTopics.length > 0 && (
            <div style={{ padding: '8px 10px', background: '#fef2f2', borderRadius: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#b91c1c', marginBottom: 4 }}>Topics you reject</div>
              {topRejectTopics.map(([word, count], i) => (
                <div key={i} style={{ fontSize: 11, color: '#555' }}>{word} ({count}x)</div>
              ))}
            </div>
          )}
        </div>
      )}
      </>}
    </div>
  );
}
