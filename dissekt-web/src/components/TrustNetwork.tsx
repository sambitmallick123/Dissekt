'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function TrustNetwork({ reportId }: { reportId: string }) {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (reportId) {
      fetch(`${API_URL}/api/trust-network/${reportId}`)
        .then(r => r.json())
        .then(setData)
        .catch(() => {});
    }
  }, [reportId]);

  if (!data || data.total_votes === 0) return null;

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 16, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{ fontSize: 14 }}>🌐</span>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>Community signal</span>
        <span style={{ fontSize: 11, color: '#888' }}>{data.total_votes} user{data.total_votes !== 1 ? 's' : ''} evaluated this</span>
      </div>

      <div style={{ display: 'flex', height: 20, borderRadius: 6, overflow: 'hidden', marginBottom: 8 }}>
        {data.trust_pct > 0 && <div style={{ width: `${data.trust_pct}%`, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff', fontWeight: 600 }}>{data.trust_pct}%</span></div>}
        {data.unsure_pct > 0 && <div style={{ width: `${data.unsure_pct}%`, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff', fontWeight: 600 }}>{data.unsure_pct}%</span></div>}
        {data.reject_pct > 0 && <div style={{ width: `${data.reject_pct}%`, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff', fontWeight: 600 }}>{data.reject_pct}%</span></div>}
      </div>

      <div style={{ display: 'flex', gap: 12, fontSize: 11 }}>
        <span style={{ color: '#16a34a' }}>✅ Trust {data.trust}</span>
        <span style={{ color: '#d97706' }}>🤔 Unsure {data.unsure}</span>
        <span style={{ color: '#dc2626' }}>❌ Reject {data.reject}</span>
      </div>

      {data.notes?.length > 0 && (
        <div style={{ marginTop: 8, padding: '6px 10px', background: '#f8fafa', borderRadius: 6 }}>
          <div style={{ fontSize: 10, fontWeight: 600, color: '#888', marginBottom: 3 }}>Common concerns:</div>
          {data.notes.map((n: string, i: number) => (
            <div key={i} style={{ fontSize: 11, color: '#555', lineHeight: 1.5 }}>• {n}</div>
          ))}
        </div>
      )}
    </div>
  );
}
