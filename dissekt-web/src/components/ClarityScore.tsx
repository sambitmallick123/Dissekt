'use client';
import { useState } from 'react';

const COLORS = { high: '#16a34a', moderate: '#d97706', low: '#dc2626' };
const DIM_COLORS = { construction: '#dc2626', verification: '#2563eb', intent: '#d97706' };

function sc(v: number) { return v >= 0.65 ? COLORS.high : v >= 0.35 ? COLORS.moderate : COLORS.low; }
function sl(v: number) { return v >= 0.65 ? 'High' : v >= 0.35 ? 'Moderate' : 'Low'; }
function pct(v: number) { return Math.round(v * 100); }

function MetricBar({ label, value, color, weight }: { label: string; value: number; color: string; weight?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
      <span style={{ fontSize: 11, width: 110, color: '#888', flexShrink: 0 }}>{label}</span>
      {weight && <span style={{ fontSize: 8, color: '#aaa', width: 28, flexShrink: 0 }}>{weight}</span>}
      <div style={{ flex: 1, height: 6, background: '#f0f0ee', borderRadius: 3 }}>
        <div style={{ height: '100%', width: `${pct(value)}%`, background: color, borderRadius: 3, transition: 'width 0.6s' }} />
      </div>
      <span style={{ fontSize: 11, fontWeight: 600, color: sc(value), width: 32, textAlign: 'right' }}>{value.toFixed(2)}</span>
    </div>
  );
}

function Legend() {
  return (
    <div style={{ display: 'flex', gap: 12, fontSize: 10, color: '#888', padding: '6px 0' }}>
      <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: COLORS.high, marginRight: 3 }} />0.65-1.0 High</span>
      <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: COLORS.moderate, marginRight: 3 }} />0.35-0.64 Moderate</span>
      <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: COLORS.low, marginRight: 3 }} />0.0-0.34 Low</span>
    </div>
  );
}

export default function ClarityScore({ data }: { data: any }) {
  const [expanded, setExpanded] = useState<string | null>(null);

  const s = data.scoring || {};
  const clarity = s.clarity_score ?? 0.5;
  const con = s.construction || {};
  const ver = s.verification || {};
  const int_ = s.intent || {};
  const band = s.confidence_band || 'n/a';
  const color = sc(clarity);
  const label = s.label || sl(clarity) + ' transparency';

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || data.lens?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const circumference = 2 * Math.PI * 50;
  const dashOffset = circumference - clarity * circumference;

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
        {/* Score circle */}
        <div style={{ position: 'relative', width: 110, height: 110, flexShrink: 0 }}>
          <svg width="110" height="110" viewBox="0 0 110 110">
            <circle cx="55" cy="55" r="50" fill="none" stroke="#f0f0ee" strokeWidth="5" />
            <circle cx="55" cy="55" r="50" fill="none" stroke={color} strokeWidth="5"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 55 55)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 24, fontWeight: 700, color, lineHeight: 1 }}>{clarity.toFixed(2)}</span>
            <span style={{ fontSize: 7, fontWeight: 600, color, textAlign: 'center', maxWidth: 70, marginTop: 2 }}>{label}</span>
          </div>
        </div>

        {/* 3 Dimensions */}
        <div style={{ flex: 1, minWidth: 220 }}>
          {[
            { key: 'construction', icon: '🏗️', label: 'Construction', value: con.score ?? 0.5, desc: 'How is it built?' },
            { key: 'verification', icon: '✅', label: 'Verification', value: ver.score ?? 0.5, desc: 'How verified is it?' },
            { key: 'intent', icon: '🎯', label: 'Intent', value: int_.score ?? 0.5, desc: 'What does it want?' },
          ].map(dim => (
            <div key={dim.key} style={{ marginBottom: 6, cursor: 'pointer' }} onClick={() => setExpanded(expanded === dim.key ? null : dim.key)}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontSize: 12 }}>{dim.icon}</span>
                <span style={{ fontSize: 11, width: 90, color: '#888' }}>{dim.label}</span>
                <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                  <div style={{ height: '100%', width: `${pct(dim.value)}%`, background: DIM_COLORS[dim.key as keyof typeof DIM_COLORS], borderRadius: 4, transition: 'width 0.6s' }} />
                </div>
                <span style={{ fontSize: 12, fontWeight: 600, color: sc(dim.value), width: 32, textAlign: 'right' }}>{dim.value.toFixed(2)}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Quick stats */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, minWidth: 130 }}>
          <div style={{ padding: '4px 8px', background: '#f8fafa', borderRadius: 4 }}>
            <div style={{ fontSize: 7, fontWeight: 600, textTransform: 'uppercase', color: '#888' }}>Techniques</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '4px 8px', background: '#f8fafa', borderRadius: 4 }}>
            <div style={{ fontSize: 7, fontWeight: 600, textTransform: 'uppercase', color: '#888' }}>Cross-refs</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '4px 8px', background: '#f8fafa', borderRadius: 4 }}>
            <div style={{ fontSize: 7, fontWeight: 600, textTransform: 'uppercase', color: '#888' }}>Toxicity</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(0)}%</div>
          </div>
          <div style={{ padding: '4px 8px', background: '#f8fafa', borderRadius: 4 }}>
            <div style={{ fontSize: 7, fontWeight: 600, textTransform: 'uppercase', color: '#888' }}>Confidence</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: band === 'high' ? '#dc2626' : band === 'medium' ? '#d97706' : '#16a34a', textTransform: 'capitalize' }}>{band}</div>
          </div>
        </div>
      </div>

      {/* Legend */}
      <Legend />

      {/* Expandable dimension breakdowns */}
      {expanded === 'construction' && (
        <div style={{ marginTop: 8, padding: '10px 14px', background: '#fef2f2', borderRadius: 10, borderLeft: '3px solid #dc2626' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#991b1b', marginBottom: 6 }}>🏗️ Construction — "How is it built?"</div>
          <MetricBar label="Rhetoric" value={con.rhetoric?.score ?? 0.5} color="#dc2626" weight="×0.40" />
          <MetricBar label="Argumentation" value={con.argumentation?.score ?? 0.5} color="#dc2626" weight="×0.35" />
          <MetricBar label="Completeness" value={con.completeness?.score ?? 0.5} color="#dc2626" weight="×0.25" />
          {con.rhetoric?.weighted?.slice(0, 3).map((t: any, i: number) => (
            <div key={i} style={{ fontSize: 10, color: '#888', marginLeft: 16 }}>↳ {t.name?.replace(/_/g, ' ')} — sev {t.severity} × conf {t.confidence} = −{t.penalty}</div>
          ))}
          <div style={{ fontSize: 10, color: '#888', marginTop: 4 }}>Completeness: who {con.completeness?.who?.toFixed(1)} · what {con.completeness?.what?.toFixed(1)} · when {con.completeness?.when?.toFixed(1)} · sources {con.completeness?.sources?.toFixed(1)} · counter {con.completeness?.counter_view?.toFixed(1)}</div>
        </div>
      )}

      {expanded === 'verification' && (
        <div style={{ marginTop: 8, padding: '10px 14px', background: '#eff6ff', borderRadius: 10, borderLeft: '3px solid #2563eb' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#1e40af', marginBottom: 6 }}>✅ Verification — "How verified is it?"</div>
          <MetricBar label="Evidence" value={ver.evidence?.score ?? 0.5} color="#2563eb" weight="×0.35" />
          <MetricBar label="Source" value={ver.source?.score ?? 0.5} color="#2563eb" weight="×0.25" />
          <MetricBar label="Src Diversity" value={ver.diversity?.score ?? 0.5} color="#2563eb" weight="×0.20" />
          <MetricBar label="Temporal" value={ver.temporal?.score ?? 0.5} color="#2563eb" weight="×0.20" />
          <div style={{ fontSize: 10, color: '#888', marginTop: 4 }}>
            Evidence: {ver.evidence?.checks || 0} fact-checks ({ver.evidence?.status || 'none'}) ·
            Source: {ver.source?.factuality || 'unknown'} ({ver.source?.bias || 'unknown'}) ·
            Diversity: {ver.diversity?.categories || 0} source categories
          </div>
        </div>
      )}

      {expanded === 'intent' && (
        <div style={{ marginTop: 8, padding: '10px 14px', background: '#fffbeb', borderRadius: 10, borderLeft: '3px solid #d97706' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#92400e', marginBottom: 6 }}>🎯 Intent — "What does it want me to do?"</div>
          <MetricBar label="Tone" value={int_.tone?.score ?? 0.5} color="#d97706" weight="×0.35" />
          <MetricBar label="Manipulation" value={int_.manipulation?.score ?? 0.5} color="#d97706" weight="×0.40" />
          <MetricBar label="Narrative Dir." value={int_.narrative?.score ?? 0.5} color="#d97706" weight="×0.25" />
          <div style={{ fontSize: 10, color: '#888', marginTop: 4 }}>
            Tone: genre {int_.tone?.genre || '?'}, quotes {pct(int_.tone?.quote_ratio || 0)}%, hostility {int_.tone?.hostility?.toFixed(2) || '?'} ·
            Direction: {int_.narrative?.direction || 'neutral'} ·
            {int_.manipulation?.cta ? ' CTA detected ·' : ''}
            Pressure: {int_.manipulation?.pressure?.toFixed(2) || '?'}
          </div>
        </div>
      )}

      {/* How is this calculated? */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 6 }}>
        <button onClick={() => setExpanded(expanded === 'formula' ? null : 'formula')}
          style={{ fontSize: 10, color: '#0d9488', background: 'none', border: 'none', cursor: 'pointer' }}>
          {expanded === 'formula' ? 'Hide formula' : 'How is this calculated?'}
        </button>
      </div>

      {expanded === 'formula' && (
        <div style={{ marginTop: 6, padding: '10px 14px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>Clarity = (Construction × Verification × Intent) ^ (1/3)</div>
          <div style={{ fontFamily: 'monospace', fontSize: 10, color: '#555' }}>
            = ({(con.score ?? 0.5).toFixed(2)} × {(ver.score ?? 0.5).toFixed(2)} × {(int_.score ?? 0.5).toFixed(2)}) ^ 0.333 = <strong style={{ color }}>{clarity.toFixed(2)}</strong>
          </div>
          <Legend />
          <div style={{ fontSize: 9, color: '#888', marginTop: 4 }}>
            Scale: 0.0 (opaque) → 1.0 (transparent). Geometric mean ensures one weak dimension cannot be hidden by strong ones.
            Based on: Da San Martino 2019, Baly 2018, Wachsmuth 2017, Card 2018, Pavlopoulos 2021, HDI methodology, IFCN, MBFC.
          </div>
        </div>
      )}
    </div>
  );
}
