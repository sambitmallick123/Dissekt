'use client';
import { useState } from 'react';

const AXIS_COLORS = {
  rhetoric: { bar: '#dc2626', bg: '#fef2f2', text: '#991b1b' },
  evidence: { bar: '#2563eb', bg: '#eff6ff', text: '#1e40af' },
  source:   { bar: '#0d9488', bg: '#f0fdfa', text: '#065f53' },
  tone:     { bar: '#d97706', bg: '#fffbeb', text: '#92400e' },
};

export default function ClarityScore({ data }: { data: any }) {
  const [showBreakdown, setShowBreakdown] = useState(false);

  const scoring = data.scoring || {};
  const axes = scoring.axes || {};
  const rhetoric = axes.rhetoric ?? 100;
  const evidence = axes.evidence ?? 50;
  const source = axes.source ?? 50;
  const tone = axes.tone ?? 100;
  const clarity = scoring.clarity_score ?? data.clarity_score ?? 50;
  const label = scoring.label || (clarity >= 70 ? 'HIGH TRANSPARENCY' : clarity >= 45 ? 'MODERATE' : 'LOW TRANSPARENCY');
  const scoreColor = clarity >= 70 ? '#16a34a' : clarity >= 45 ? '#d97706' : '#dc2626';
  const band = scoring.confidence_band || 'n/a';

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || data.lens?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const circumference = 2 * Math.PI * 54;
  const dashOffset = circumference - (clarity / 100) * circumference;

  const rhetoricDetail = scoring.rhetoric || {};
  const evidenceDetail = scoring.evidence || {};
  const toneDetail = scoring.tone || {};
  const sourceDetail = scoring.source || {};

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, flexWrap: 'wrap' }}>
        {/* Score circle */}
        <div style={{ position: 'relative', width: 120, height: 120, flexShrink: 0 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="54" fill="none" stroke="#f0f0ee" strokeWidth="6" />
            <circle cx="60" cy="60" r="54" fill="none" stroke={scoreColor} strokeWidth="6"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 60 60)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: scoreColor, lineHeight: 1 }}>{clarity}</span>
            <span style={{ fontSize: 8, fontWeight: 600, color: scoreColor, textAlign: 'center', maxWidth: 80 }}>{label}</span>
          </div>
        </div>

        {/* 4 Axes */}
        <div style={{ flex: 1, minWidth: 240 }}>
          {[
            { key: 'rhetoric', label: 'Rhetoric', value: rhetoric, desc: 'How manipulative are the techniques used?' },
            { key: 'evidence', label: 'Evidence', value: evidence, desc: 'What do fact-checkers say?' },
            { key: 'source', label: 'Source', value: source, desc: 'How credible is the source?' },
            { key: 'tone', label: 'Tone', value: tone, desc: 'How hostile or provocative is the framing?' },
          ].map(ax => {
            const c = AXIS_COLORS[ax.key as keyof typeof AXIS_COLORS];
            const axColor = ax.value >= 70 ? '#16a34a' : ax.value >= 45 ? '#d97706' : '#dc2626';
            return (
              <div key={ax.key} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                <span style={{ fontSize: 11, width: 60, color: '#888', flexShrink: 0 }}>{ax.label}</span>
                <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                  <div style={{ height: '100%', width: `${ax.value}%`, background: c.bar, borderRadius: 4, transition: 'width 0.6s ease' }} />
                </div>
                <span style={{ fontSize: 12, fontWeight: 600, color: axColor, width: 28, textAlign: 'right' }}>{ax.value}</span>
              </div>
            );
          })}
        </div>

        {/* Quick stats */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6, minWidth: 160 }}>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Techniques</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Cross-refs</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Toxicity</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(0)}%</div>
          </div>
          <div style={{ padding: '6px 8px', background: '#f8fafa', borderRadius: 6 }}>
            <div style={{ fontSize: 8, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Confidence</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: band === 'high' ? '#dc2626' : band === 'medium' ? '#d97706' : '#16a34a', textTransform: 'capitalize' }}>{band}</div>
          </div>
        </div>
      </div>

      {/* Expand breakdown */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 10 }}>
        <button onClick={() => setShowBreakdown(!showBreakdown)}
          style={{ fontSize: 10, color: '#0d9488', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
          {showBreakdown ? 'Hide calculation' : 'How is this calculated?'}
        </button>
      </div>

      {showBreakdown && (
        <div style={{ marginTop: 8, padding: '12px 14px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>Clarity = (Rhetoric × Evidence × Source × Tone) ^ 0.25</div>

          {/* Rhetoric breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #dc2626' }}>
            <div style={{ fontWeight: 600, color: '#991b1b' }}>Rhetoric: {rhetoric}/100</div>
            <div style={{ color: '#888' }}>100 − severity-weighted technique penalties (capped at 90)</div>
            {rhetoricDetail.weighted_techniques?.slice(0, 4).map((t: any, i: number) => (
              <div key={i} style={{ color: '#555' }}>
                {t.name?.replace(/_/g, ' ')} — severity {t.severity} × confidence {t.confidence} = −{t.penalty}
              </div>
            ))}
          </div>

          {/* Evidence breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #2563eb' }}>
            <div style={{ fontWeight: 600, color: '#1e40af' }}>Evidence: {evidence}/100</div>
            <div style={{ color: '#888' }}>
              {evidenceDetail.check_count || 0} fact-check{(evidenceDetail.check_count || 0) !== 1 ? 's' : ''} found.
              {evidenceDetail.status === 'confirmed' && ' Mostly confirmed.'}
              {evidenceDetail.status === 'disputed' && ' Mostly disputed.'}
              {evidenceDetail.status === 'mixed' && ' Mixed verdicts.'}
              {evidenceDetail.status === 'no_checks' && ' No existing fact-checks. Neutral score (50).'}
              {' '}Weighted by fact-checker tier (A=1.0, B=0.7, C=0.4).
            </div>
          </div>

          {/* Source breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #0d9488' }}>
            <div style={{ fontWeight: 600, color: '#065f53' }}>Source: {source}/100</div>
            <div style={{ color: '#888' }}>
              MBFC factuality: {sourceDetail.factuality || 'unknown'} · Bias: {sourceDetail.bias || 'unknown'}
            </div>
          </div>

          {/* Tone breakdown */}
          <div style={{ padding: '6px 8px', background: '#fff', borderRadius: 6, marginBottom: 6, borderLeft: '3px solid #d97706' }}>
            <div style={{ fontWeight: 600, color: '#92400e' }}>Tone: {tone}/100</div>
            <div style={{ color: '#888' }}>
              Genre: {toneDetail.genre || 'unknown'} · Quote ratio: {((toneDetail.quote_ratio || 0) * 100).toFixed(0)}%
            </div>
            <div style={{ color: '#555' }}>
              Toxicity (editorial, adjusted): −{toneDetail.breakdown?.toxicity_penalty || 0} ·
              Rhetorical hostility: −{toneDetail.breakdown?.hostility_penalty || 0} ·
              Sentiment extremity: −{toneDetail.breakdown?.sentiment_penalty || 0}
            </div>
          </div>

          {/* Final calculation */}
          <div style={{ fontFamily: 'monospace', fontSize: 10, color: '#555', marginTop: 4 }}>
            ({rhetoric} × {evidence} × {source} × {tone})^0.25 = <strong style={{ color: scoreColor }}>{clarity}/100</strong>
          </div>

          <div style={{ marginTop: 6, fontSize: 10, color: '#888' }}>
            Based on: Da San Martino et al. 2019 (severity), Baly et al. 2018 (multi-axis), HDI geometric mean, Pavlopoulos et al. 2021 (context-aware toxicity).
          </div>
        </div>
      )}
    </div>
  );
}
