'use client';

export default function Arc({ analyses, topic }: { analyses: any[]; topic: string }) {
  if (!analyses || analyses.length < 2) return null;

  // Group by week
  const weeks: Record<string, { count: number; techniques: Record<string, number>; avgSimilarity: number }> = {};
  
  for (const a of analyses) {
    const ts = a.timestamp ? new Date(parseFloat(a.timestamp) * 1000) : new Date();
    const weekKey = `${ts.getFullYear()}-W${Math.ceil((ts.getDate()) / 7)}`;
    
    if (!weeks[weekKey]) weeks[weekKey] = { count: 0, techniques: {}, avgSimilarity: 0 };
    weeks[weekKey].count++;
    weeks[weekKey].avgSimilarity += a.similarity || 0;
    
    for (const t of (a.techniques || [])) {
      weeks[weekKey].techniques[t] = (weeks[weekKey].techniques[t] || 0) + 1;
    }
  }

  const weekKeys = Object.keys(weeks).sort();
  const maxCount = Math.max(...weekKeys.map(k => weeks[k].count));

  // Find dominant technique across all analyses
  const allTechs: Record<string, number> = {};
  for (const a of analyses) {
    for (const t of (a.techniques || [])) {
      allTechs[t] = (allTechs[t] || 0) + 1;
    }
  }
  const topTechs = Object.entries(allTechs).sort((a, b) => b[1] - a[1]).slice(0, 5);

  const barColors = ['#0d9488', '#2563eb', '#d97706', '#dc2626', '#7c3aed'];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>📈</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Arc</span>
        <span style={{ fontSize: 12, color: '#888' }}>How "{topic}" coverage evolved</span>
      </div>

      {/* Volume timeline */}
      <div style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Analysis volume over time</div>
        <div style={{ display: 'flex', alignItems: 'end', gap: 4, height: 60 }}>
          {weekKeys.map((k, i) => {
            const h = (weeks[k].count / maxCount) * 100;
            return (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                <span style={{ fontSize: 9, color: '#888' }}>{weeks[k].count}</span>
                <div style={{ width: '100%', height: `${h}%`, background: '#0d9488', borderRadius: '3px 3px 0 0', minHeight: 4 }} />
                <span style={{ fontSize: 8, color: '#aaa' }}>{k.split('-W')[1] ? `W${k.split('-W')[1]}` : k}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Technique distribution */}
      {topTechs.length > 0 && (
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Most used techniques</div>
          {topTechs.map(([name, count], i) => (
            <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <span style={{ fontSize: 11, width: 120, color: '#555' }}>{name.replace(/_/g, ' ')}</span>
              <div style={{ flex: 1, height: 8, background: '#f0f0ee', borderRadius: 4 }}>
                <div style={{ height: '100%', width: `${(count / analyses.length) * 100}%`, background: barColors[i % barColors.length], borderRadius: 4 }} />
              </div>
              <span style={{ fontSize: 10, fontWeight: 600, color: '#555', width: 24 }}>{count}</span>
            </div>
          ))}
        </div>
      )}

      {/* Summary */}
      <div style={{ marginTop: 14, padding: '10px 12px', background: '#f8fafa', borderRadius: 8, fontSize: 12, color: '#555', lineHeight: 1.6 }}>
        <strong>{analyses.length}</strong> analyses found for "{topic}" across <strong>{weekKeys.length}</strong> time period{weekKeys.length !== 1 ? 's' : ''}.
        {topTechs[0] && <> Most common technique: <strong>{topTechs[0][0].replace(/_/g, ' ')}</strong> ({topTechs[0][1]} occurrences).</>}
      </div>
    </div>
  );
}
