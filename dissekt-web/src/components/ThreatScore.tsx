'use client';
import { useState } from 'react';

export default function ThreatScore({ data }: { data: any }) {
  const [showFormula, setShowFormula] = useState(false);

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  const techScore = techs.length > 0 ? Math.round(maxConf * 40) : 0;
  const fcScore = Math.min(fcs.length * 4, 30);
  const toxScore = Math.round(tox * 20);
  const bonusScore = fcs.length >= 3 ? 10 : 0;
  const score = Math.min(techScore + fcScore + toxScore + bonusScore, 100);

  const scoreColor = score >= 70 ? '#dc2626' : score >= 40 ? '#d97706' : '#16a34a';
  const scoreLabel = score >= 70 ? 'HIGH RISK' : score >= 40 ? 'MEDIUM' : 'LOW RISK';

  // Confidence band based on technique confidences
  const avgConf = techs.length > 0
    ? techs.reduce((sum: number, t: any) => sum + (t.confidence || 0), 0) / techs.length
    : 0;
  const confLabel = avgConf >= 0.8 ? 'High' : avgConf >= 0.5 ? 'Medium' : techs.length > 0 ? 'Low' : 'N/A';
  const confColor = avgConf >= 0.8 ? '#dc2626' : avgConf >= 0.5 ? '#d97706' : '#16a34a';

  const circumference = 2 * Math.PI * 54;
  const dashOffset = circumference - (score / 100) * circumference;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        {/* Score ring */}
        <div style={{ position: 'relative', width: 120, height: 120, flexShrink: 0 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="54" fill="none" stroke="#f0f0ee" strokeWidth="6" />
            <circle cx="60" cy="60" r="54" fill="none" stroke={scoreColor} strokeWidth="6"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 60 60)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: scoreColor, lineHeight: 1 }}>{score}</span>
            <span style={{ fontSize: 10, fontWeight: 600, color: scoreColor }}>{scoreLabel}</span>
          </div>
        </div>

        {/* Metrics grid */}
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Techniques</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Fact-checks</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Sources</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{data.signal?.source_bias ? 1 : 0}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Toxicity</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(1)}%</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Sentiment</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{data.signal?.sentiment || 'Neutral'}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Model</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{(data.prism?.model_used || 'gpt-4o-mini').replace(/-/g, ' ').replace('gpt 4o mini', 'GPT-4o Mini')}</div>
          </div>
        </div>
      </div>

      {/* Confidence band + formula toggle */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12, paddingTop: 10, borderTop: '1px solid #f0f0ee' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 11, color: '#888' }}>Confidence:</span>
          <span style={{ fontSize: 11, fontWeight: 600, color: confColor, padding: '2px 8px', borderRadius: 4, background: confLabel === 'High' ? '#fef2f2' : confLabel === 'Medium' ? '#fffbeb' : '#f0fdf4' }}>
            {confLabel}
          </span>
          {confLabel === 'Low' && <span style={{ fontSize: 10, color: '#aaa' }}>— signals detected but not definitive</span>}
          {confLabel === 'Medium' && <span style={{ fontSize: 10, color: '#aaa' }}>— moderate manipulation signals</span>}
          {confLabel === 'High' && <span style={{ fontSize: 10, color: '#aaa' }}>— strong manipulation signals detected</span>}
        </div>
        <button onClick={() => setShowFormula(!showFormula)}
          style={{ fontSize: 10, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
          {showFormula ? 'Hide formula' : 'How is this calculated?'}
        </button>
      </div>

      {/* Formula breakdown */}
      {showFormula && (
        <div style={{ marginTop: 8, padding: '10px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, marginBottom: 4, color: '#7c3aed' }}>Score breakdown:</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: '2px 10px', alignItems: 'center' }}>
            <span style={{ color: '#888' }}>Technique confidence</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(techScore / 40 * 100, 100)}%`, background: '#7c3aed', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{techScore}/40</span>

            <span style={{ color: '#888' }}>Fact-check matches</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(fcScore / 30 * 100, 100)}%`, background: '#2563eb', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{fcScore}/30</span>

            <span style={{ color: '#888' }}>Toxicity level</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(toxScore / 20 * 100, 100)}%`, background: '#d97706', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{toxScore}/20</span>

            <span style={{ color: '#888' }}>Cross-reference bonus</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${bonusScore > 0 ? 100 : 0}%`, background: '#16a34a', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{bonusScore}/10</span>
          </div>
          <div style={{ marginTop: 6, fontSize: 10, color: '#888' }}>
            Total: {techScore} + {fcScore} + {toxScore} + {bonusScore} = <strong style={{ color: scoreColor }}>{score}/100</strong>
          </div>
        </div>
      )}
    </div>
  );
}
