'use client';

const card: React.CSSProperties = { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden', height: '100%', display: 'flex', flexDirection: 'column' };
const header: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 10, padding: '14px 18px', borderBottom: '1px solid #e5e5e5' };
const metricBox: React.CSSProperties = { background: '#f8f8f6', borderRadius: 10, padding: '12px 14px' };
const metricLabel: React.CSSProperties = { fontSize: 10, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#aaa', marginBottom: 6 };

const biasInfo = (b: string|null) => {
  if (!b) return { label: 'Unknown', dot: '#d4d4d4', color: '#aaa' };
  const m: Record<string,{label:string;dot:string;color:string}> = {
    'far-left':{label:'Far left',dot:'#1d4ed8',color:'#1d4ed8'},
    'left':{label:'Left',dot:'#3b82f6',color:'#2563eb'},
    'left-center':{label:'Left-center',dot:'#60a5fa',color:'#3b82f6'},
    'center':{label:'Center',dot:'#16a34a',color:'#16a34a'},
    'right-center':{label:'Right-center',dot:'#f87171',color:'#dc2626'},
    'right':{label:'Right',dot:'#dc2626',color:'#dc2626'},
    'far-right':{label:'Far right',dot:'#991b1b',color:'#991b1b'},
  };
  return m[b] || { label: b, dot: '#aaa', color: '#888' };
};

const factInfo = (f: string|null) => {
  if (!f) return { label: 'Unknown', color: '#aaa' };
  const m: Record<string,{label:string;color:string}> = {
    'very-high':{label:'Very high',color:'#16a34a'}, 'high':{label:'High',color:'#22c55e'},
    'mixed':{label:'Mixed',color:'#d97706'}, 'low':{label:'Low',color:'#ea580c'},
    'very-low':{label:'Very low',color:'#dc2626'},
  };
  return m[f] || { label: f, color: '#888' };
};

export default function SignalCard({ signal }: { signal: any }) {
  const bias = biasInfo(signal.source_bias);
  const fact = factInfo(signal.source_factuality);
  const tox = signal.toxicity_score || 0;
  const toxLabel = tox > 0.5 ? 'High' : tox > 0.2 ? 'Moderate' : 'Low';
  const toxColor = tox > 0.5 ? '#dc2626' : tox > 0.2 ? '#d97706' : '#16a34a';

  return (
    <div style={card}>
      <div style={header}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" strokeWidth="2" strokeLinecap="round"><path d="M2 20h.01M7 20v-4M12 20v-8M17 20V8M22 4v16"/></svg>
        </div>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Signal — evidence</span>
      </div>
      <div style={{ padding: 18, flex: 1 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div style={metricBox}>
            <div style={metricLabel}>Source bias</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 8, height: 8, borderRadius: 4, background: bias.dot, display: 'inline-block' }}/>
              <span style={{ fontSize: 14, fontWeight: 600, color: bias.color }}>{bias.label}</span>
            </div>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Factuality</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: fact.color }}>{fact.label}</span>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Sentiment</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{signal.sentiment}</span>
            <span style={{ fontSize: 11, color: '#aaa', marginLeft: 4 }}>({signal.sentiment_score?.toFixed(2)})</span>
          </div>
          <div style={metricBox}>
            <div style={metricLabel}>Toxicity</div>
            <span style={{ fontSize: 14, fontWeight: 600, color: toxColor }}>{toxLabel}</span>
            <span style={{ fontSize: 11, color: '#aaa', marginLeft: 4 }}>({(tox*100).toFixed(1)}%)</span>
          </div>
        </div>

        {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && tox > 0.05 && (
          <div style={{ marginTop: 16, paddingTop: 14, borderTop: '1px solid #e5e5e5' }}>
            <div style={metricLabel}>Toxicity breakdown</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 16px', marginTop: 8 }}>
              {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
                <div key={k} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 11 }}>
                  <span style={{ color: '#888', textTransform: 'capitalize' }}>{k.replace(/_/g, ' ')}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div style={{ width: 50, height: 3, background: '#f0f0ee', borderRadius: 2, overflow: 'hidden' }}>
                      <div style={{ height: '100%', borderRadius: 2, width: `${Math.max(v*100, 2)}%`, background: v > 0.5 ? '#dc2626' : v > 0.2 ? '#d97706' : '#d4d4d4' }}/>
                    </div>
                    <span style={{ fontWeight: 500, color: '#555', width: 36, textAlign: 'right' }}>{(v*100).toFixed(1)}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
