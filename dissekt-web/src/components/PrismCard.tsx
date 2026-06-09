'use client';
import { useState } from 'react';

const CATEGORY_COLORS: Record<string, { bg: string; color: string }> = {
  framing: { bg: '#fff7ed', color: '#c2410c' },
  logical_fallacy: { bg: '#fef2f2', color: '#b91c1c' },
  credibility: { bg: '#f0fdf4', color: '#166534' },
  deflection: { bg: '#eff6ff', color: '#1e40af' },
};

function TechniqueVote({ analysisId, technique }: { analysisId: string; technique: any }) {
  const [voted, setVoted] = useState<'agree' | 'disagree' | null>(null);
  const [showComment, setShowComment] = useState(false);
  const [comment, setComment] = useState('');
  const [sent, setSent] = useState(false);

  const handleVote = async (vote: 'agree' | 'disagree') => {
    setVoted(vote);
    if (vote === 'disagree') {
      setShowComment(true);
      return;
    }
    try {
      await fetch('/api/corrections', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, technique_name: technique.name, vote, comment: '' }),
      });
      setSent(true);
    } catch {}
  };

  const submitDisagree = async () => {
    try {
      await fetch('/api/corrections', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, technique_name: technique.name, vote: 'disagree', comment }),
      });
      setSent(true);
      setShowComment(false);
    } catch {}
  };

  if (sent) {
    return (
      <div style={{ fontSize: 10, color: '#16a34a', marginTop: 6 }}>
        ✓ Thanks for your feedback
      </div>
    );
  }

  return (
    <div style={{ marginTop: 6 }}>
      {!showComment && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 10, color: '#aaa' }}>Accurate?</span>
          <button onClick={() => handleVote('agree')}
            style={{ padding: '2px 8px', fontSize: 10, borderRadius: 4, border: '1px solid #e5e5e5', background: voted === 'agree' ? '#f0fdf4' : '#fff', color: voted === 'agree' ? '#16a34a' : '#888', cursor: 'pointer', fontWeight: 500 }}>
            👍
          </button>
          <button onClick={() => handleVote('disagree')}
            style={{ padding: '2px 8px', fontSize: 10, borderRadius: 4, border: '1px solid #e5e5e5', background: voted === 'disagree' ? '#fef2f2' : '#fff', color: voted === 'disagree' ? '#b91c1c' : '#888', cursor: 'pointer', fontWeight: 500 }}>
            👎
          </button>
        </div>
      )}
      {showComment && (
        <div style={{ display: 'flex', gap: 4, marginTop: 4 }}>
          <input
            type="text"
            placeholder="What's wrong? (optional)"
            value={comment}
            onChange={e => setComment(e.target.value)}
            style={{ flex: 1, fontSize: 10, padding: '4px 8px', border: '1px solid #e5e5e5', borderRadius: 4, outline: 'none' }}
          />
          <button onClick={submitDisagree}
            style={{ fontSize: 10, padding: '4px 10px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>
            Send
          </button>
        </div>
      )}
    </div>
  );
}

export default function PrismCard({ prism, analysisId }: { prism: any; analysisId?: string }) {
  if (!prism) return null;

  const techniques = prism.techniques || [];
  const brief = prism.brief || '';

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 24, height: 24, borderRadius: 6, background: '#f3e8ff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>
          </div>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Prism — techniques</span>
        </div>
        <span style={{ fontSize: 12, color: '#888' }}>{techniques.length} found</span>
      </div>

      {techniques.length === 0 ? (
        <div style={{ padding: '12px 0', textAlign: 'center', color: '#16a34a', fontSize: 13 }}>✓ No manipulation techniques detected</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {techniques.map((t: any, i: number) => {
            const conf = Math.round((t.confidence || 0) * 100);
            const barColor = conf >= 85 ? '#dc2626' : conf >= 70 ? '#d97706' : '#eab308';
            const cat = CATEGORY_COLORS[t.category] || { bg: '#f0f0ee', color: '#555' };
            const name = (t.name || '').replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase());

            return (
              <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{name}</span>
                    <span style={{ fontSize: 9, padding: '1px 6px', borderRadius: 4, background: cat.bg, color: cat.color, fontWeight: 600 }}>
                      {(t.category || 'framing').replace(/_/g, ' ')}
                    </span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: barColor }}>{conf}%</span>
                </div>
                <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2, marginBottom: 6 }}>
                  <div style={{ height: '100%', width: `${conf}%`, background: barColor, borderRadius: 2 }} />
                </div>
                {t.explanation && <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5, marginBottom: 2 }}>{t.explanation}</div>}
                {t.evidence && <div style={{ fontSize: 11, color: '#888', fontStyle: 'italic', borderLeft: '2px solid #e5e5e5', paddingLeft: 8, marginTop: 4 }}>"{t.evidence}"</div>}
                {analysisId && <TechniqueVote analysisId={analysisId} technique={t} />}
              </div>
            );
          })}
        </div>
      )}

      {brief && (
        <div style={{ marginTop: 12, padding: '10px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, fontSize: 12, color: '#404040', lineHeight: 1.6 }}>
          {brief}
        </div>
      )}
    </div>
  );
}
