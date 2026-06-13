'use client';

const shimmer: React.CSSProperties = {
  background: 'linear-gradient(90deg, #f0f0ee 25%, #e8e6e3 50%, #f0f0ee 75%)',
  backgroundSize: '200% 100%',
  animation: 'shimmer 1.5s infinite',
  borderRadius: 6,
};

export default function LoadingState() {
  return (
    <div>
      <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 24, display: 'flex', alignItems: 'center', gap: 24 }}>
        <div style={{ width: 110, height: 110, borderRadius: 55, ...shimmer, flexShrink: 0 }}/>
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10 }}>
          {Array.from({length: 6}).map((_, i) => (
            <div key={i} style={{ background: '#f8f8f6', borderRadius: 10, padding: 14 }}>
              <div style={{ height: 8, width: 50, ...shimmer, marginBottom: 8 }}/>
              <div style={{ height: 14, width: 30, ...shimmer }}/>
            </div>
          ))}
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        {['Prism', 'Trace', 'Signal', 'Meta'].map(n => (
          <div key={n} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14 }}>
            <div style={{ padding: '14px 18px', borderBottom: '1px solid #e5e5e5', display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, ...shimmer }}/>
              <div style={{ height: 10, width: 100, ...shimmer }}/>
            </div>
            <div style={{ padding: 18 }}>
              <div style={{ height: 8, width: '100%', ...shimmer, marginBottom: 10 }}/>
              <div style={{ height: 8, width: '80%', ...shimmer, marginBottom: 10 }}/>
              <div style={{ height: 8, width: '60%', ...shimmer }}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
