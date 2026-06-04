'use client';

const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '10px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 4 };

export default function ThreatScore({ data }: { data: any }) {
  const techs = data.prism?.techniques?.length || 0;
  const fcs = data.trace?.fact_checks?.length || 0;
  const srcs = data.trace?.spread_timeline?.length || 0;
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = data.prism?.techniques?.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0) || 0;

  let score = (techs > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);

  const color = score >= 70 ? '#dc2626' : score >= 40 ? '#d97706' : '#16a34a';
  const label = score >= 70 ? 'High risk' : score >= 40 ? 'Medium risk' : 'Low risk';
  const R = 42, C = 2 * Math.PI * R, off = C - (score / 100) * C;

  const metrics = [
    { l: 'Techniques', v: String(techs), c: techs > 0 ? '#7c3aed' : '#bbb' },
    { l: 'Fact-checks', v: String(fcs), c: fcs > 0 ? '#dc2626' : '#bbb' },
    { l: 'Sources', v: String(srcs), c: srcs > 0 ? '#2563eb' : '#bbb' },
    { l: 'Toxicity', v: `${(tox*100).toFixed(1)}%`, c: tox > 0.5 ? '#dc2626' : tox > 0.2 ? '#d97706' : '#16a34a' },
    { l: 'Sentiment', v: data.signal?.sentiment || '—', c: '#404040' },
    { l: 'Model', v: data.prism?.model_used || '—', c: '#888' },
  ];

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' }}>
      <div className="threat-strip" style={{ display: 'flex', alignItems: 'stretch' }}>
        <div className="threat-ring" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '24px 32px', borderRight: '1px solid #e5e5e5' }}>
          <div style={{ position: 'relative', width: 100, height: 100 }}>
            <svg width="100" height="100" viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="50" cy="50" r={R} fill="none" stroke="#f0f0ee" strokeWidth="7"/>
              <circle cx="50" cy="50" r={R} fill="none" stroke={color} strokeWidth="7" strokeDasharray={C} strokeDashoffset={off} strokeLinecap="round" className="ring-anim"/>
            </svg>
            <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ fontSize: 28, fontWeight: 700, color }}>{score}</span>
              <span style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#aaa' }}>{label}</span>
            </div>
          </div>
        </div>
        <div className="threat-metrics" style={{ flex: 1, padding: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, alignContent: 'center' }}>
          {metrics.map(m => (
            <div key={m.l} style={metricBox}>
              <div style={metricLabel}>{m.l}</div>
              <div style={{ fontSize: 15, fontWeight: 600, color: m.c, textTransform: 'capitalize' }}>{m.v}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
