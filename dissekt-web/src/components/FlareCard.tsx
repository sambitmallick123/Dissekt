'use client';

const SEVERITY_STYLE: Record<string, { bg: string; color: string; icon: string }> = {
  high: { bg: '#fef2f2', color: '#b91c1c', icon: '🔴' },
  medium: { bg: '#fffbeb', color: '#92400e', icon: '🟡' },
  low: { bg: '#f0fdf4', color: '#065f46', icon: '🟢' },
};

export default function FlareCard({ pulse }: { pulse: any }) {
  if (!pulse?.detected) return null;

  const riskStyle = SEVERITY_STYLE[pulse.risk_level] || SEVERITY_STYLE.low;
  const riskLabel = pulse.risk_level === 'high' ? 'HIGH COORDINATION RISK' : pulse.risk_level === 'medium' ? 'MODERATE COORDINATION SIGNALS' : 'LOW COORDINATION SIGNALS';

  return (
    <div style={{ background: '#fff', border: `1px solid ${riskStyle.color}33`, borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: riskStyle.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>📡</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Pulse — Coordination Detection</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', background: riskStyle.bg, borderRadius: 10, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>{riskStyle.icon}</span>
        <div>
          <div style={{ fontSize: 12, fontWeight: 700, color: riskStyle.color }}>{riskLabel}</div>
          <div style={{ fontSize: 11, color: '#888' }}>{pulse.similar_count} similar claims in knowledge base</div>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {pulse.signals.map((s: any, i: number) => {
          const ss = SEVERITY_STYLE[s.severity] || SEVERITY_STYLE.low;
          return (
            <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 8, padding: '8px 10px', border: '1px solid #e5e5e5', borderRadius: 8 }}>
              <span style={{ fontSize: 10, flexShrink: 0 }}>{ss.icon}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{s.type.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase())}</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.5 }}>{s.detail}</div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 10, padding: '8px 10px', background: '#f5f5f4', borderRadius: 6, fontSize: 11, color: '#888', lineHeight: 1.5 }}>
        ⚠️ Coordination signals suggest organized amplification, not necessarily falsehood. The same claim can be pushed coordinately and still be accurate.
      </div>
    </div>
  );
}
