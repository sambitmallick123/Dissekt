'use client';
import { useState } from 'react';

const DECISIONS = [
  { key: 'trust', emoji: '✅', label: 'Trust', color: '#16a34a', bg: '#f0fdf4' },
  { key: 'unsure', emoji: '🤔', label: 'Unsure', color: '#d97706', bg: '#fffbeb' },
  { key: 'reject', emoji: '❌', label: 'Reject', color: '#dc2626', bg: '#fef2f2' },
];

export function DecisionButtons({ analysisId, inputPreview }: { analysisId: string; inputPreview: string }) {
  const [selected, setSelected] = useState<string | null>(null);
  const [note, setNote] = useState('');
  const [saved, setSaved] = useState(false);

  const handleDecision = async (decision: string) => {
    setSelected(decision);
    if (decision === 'unsure') return; // show note input
    
    try {
      await fetch('/api/decisions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, input_preview: inputPreview?.slice(0, 200), decision, note: '' }),
      });
      setSaved(true);
    } catch {}
  };

  const saveWithNote = async () => {
    try {
      await fetch('/api/decisions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, input_preview: inputPreview?.slice(0, 200), decision: selected, note }),
      });
      setSaved(true);
    } catch {}
  };

  if (saved) {
    const d = DECISIONS.find(d => d.key === selected);
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 12px', background: d?.bg || '#f0f0ee', borderRadius: 8, fontSize: 12 }}>
        <span>{d?.emoji}</span>
        <span style={{ fontWeight: 600, color: d?.color }}>Saved as: {d?.label}</span>
        <span style={{ color: '#888', marginLeft: 4 }}>— revisit in your journal</span>
      </div>
    );
  }

  return (
    <div style={{ padding: '10px 0' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: selected === 'unsure' ? 8 : 0 }}>
        <span style={{ fontSize: 11, color: '#888' }}>Your verdict:</span>
        {DECISIONS.map(d => (
          <button key={d.key} onClick={() => handleDecision(d.key)}
            style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '5px 12px', borderRadius: 6, fontSize: 11, fontWeight: 600, border: '1px solid #e5e5e5', cursor: 'pointer', background: selected === d.key ? d.bg : '#fff', color: selected === d.key ? d.color : '#888' }}>
            <span>{d.emoji}</span> {d.label}
          </button>
        ))}
      </div>
      {selected === 'unsure' && !saved && (
        <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
          <input type="text" value={note} onChange={e => setNote(e.target.value)} placeholder="Why are you unsure? (optional)"
            style={{ flex: 1, padding: '6px 10px', border: '1px solid #e5e5e5', borderRadius: 6, fontSize: 11, outline: 'none' }} />
          <button onClick={saveWithNote} style={{ padding: '6px 12px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>Save</button>
        </div>
      )}
    </div>
  );
}

export default function DecisionJournalView() {
  const [decisions, setDecisions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);

  const loadJournal = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/decisions');
      const data = await res.json();
      setDecisions(data.decisions || []);
    } catch {}
    finally { setLoading(false); setLoaded(true); }
  };

  const dMap: Record<string, { emoji: string; color: string; bg: string }> = {
    trust: { emoji: '✅', color: '#16a34a', bg: '#f0fdf4' },
    unsure: { emoji: '🤔', color: '#d97706', bg: '#fffbeb' },
    reject: { emoji: '❌', color: '#dc2626', bg: '#fef2f2' },
  };

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>📓</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Decision Journal</span>
          <span style={{ fontSize: 12, color: '#888' }}>Your past verdicts</span>
        </div>
        {!loaded && (
          <button onClick={loadJournal} style={{ fontSize: 11, padding: '4px 12px', background: '#f3e8ff', color: '#7c3aed', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
            {loading ? 'Loading...' : 'Load journal'}
          </button>
        )}
      </div>

      {loaded && decisions.length === 0 && (
        <div style={{ textAlign: 'center', padding: '12px 0', color: '#888', fontSize: 12 }}>
          No decisions yet. Analyze content and mark it as Trust, Unsure, or Reject.
        </div>
      )}

      {decisions.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {decisions.map((d, i) => {
            const style = dMap[d.decision] || dMap.unsure;
            return (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', background: style.bg, borderRadius: 6 }}>
                <span style={{ fontSize: 12 }}>{style.emoji}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 11, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{d.input_preview}</div>
                  {d.note && <div style={{ fontSize: 10, color: '#888', marginTop: 1 }}>Note: {d.note}</div>}
                </div>
                <span style={{ fontSize: 9, color: '#aaa', flexShrink: 0 }}>{new Date(d.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}</span>
                <a href={`/report/${d.analysis_id}`} style={{ fontSize: 9, color: '#2563eb', textDecoration: 'none', flexShrink: 0 }}>view ↗</a>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
