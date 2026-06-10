'use client';
import { useState, useRef } from 'react';

interface BulkItem {
  input: string;
  status: 'pending' | 'analyzing' | 'done' | 'error';
  result?: any;
  error?: string;
}

export default function BulkAnalysis() {
  const [items, setItems] = useState<BulkItem[]>([]);
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState(0);
  const fileRef = useRef<HTMLInputElement>(null);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      const lines = text.split('\n').map(l => l.trim()).filter(l => l.length >= 10);
      // Skip header if it looks like one
      const start = lines[0]?.toLowerCase().includes('url') || lines[0]?.toLowerCase().includes('content') ? 1 : 0;
      setItems(lines.slice(start, start + 50).map(l => ({
        input: l.replace(/^["']|["']$/g, '').split(',')[0].trim(),
        status: 'pending',
      })));
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const runBulk = async () => {
    setRunning(true);
    setProgress(0);
    const updated = [...items];

    for (let i = 0; i < updated.length; i++) {
      updated[i].status = 'analyzing';
      setItems([...updated]);

      try {
        const res = await fetch('/api/scan', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ content: updated[i].input, mode: 'brief' }),
        });
        if (res.ok) {
          updated[i].result = await res.json();
          updated[i].status = 'done';
        } else {
          const err = await res.json();
          updated[i].error = err.detail || 'Failed';
          updated[i].status = 'error';
        }
      } catch {
        updated[i].error = 'Connection failed';
        updated[i].status = 'error';
      }

      setProgress(i + 1);
      setItems([...updated]);
    }
    setRunning(false);
  };

  const downloadCSV = () => {
    const header = 'Input,Threat Score,Techniques,Technique Names,Fact Checks,Toxicity,Sentiment,Language\n';
    const rows = items.filter(i => i.result).map(i => {
      const r = i.result;
      const techs = r.prism?.techniques || [];
      const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
      const fcs = r.trace?.fact_checks?.length || 0;
      const tox = r.signal?.toxicity_score || 0;
      let score = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
      score = Math.min(score, 100);
      const names = techs.map((t: any) => t.name?.replace(/_/g, ' ')).join('; ');
      return `"${i.input.replace(/"/g, '""')}",${score},${techs.length},"${names}",${fcs},${(tox*100).toFixed(1)}%,${r.signal?.sentiment || ''},${r.detected_language || 'en'}`;
    });
    const blob = new Blob([header + rows.join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'dissekt-bulk-results.csv'; a.click();
  };

  const getScore = (r: any) => {
    if (!r) return 0;
    const techs = r.prism?.techniques || [];
    const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
    const fcs = r.trace?.fact_checks?.length || 0;
    const tox = r.signal?.toxicity_score || 0;
    let s = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
    return Math.min(s, 100);
  };

  const scoreColor = (s: number) => s >= 70 ? '#dc2626' : s >= 40 ? '#d97706' : '#16a34a';

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 600, color: '#404040' }}>📊 Bulk Analysis</div>
          <div style={{ fontSize: 12, color: '#888' }}>Upload a CSV with URLs or claims (max 50 items)</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {items.length > 0 && items.some(i => i.result) && (
            <button onClick={downloadCSV} style={{ fontSize: 12, padding: '6px 12px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 6, cursor: 'pointer', color: '#404040', fontWeight: 500 }}>Download CSV</button>
          )}
          <button onClick={() => fileRef.current?.click()} style={{ fontSize: 12, padding: '6px 12px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
            Upload CSV
          </button>
          <input ref={fileRef} type="file" accept=".csv,.txt" style={{ display: 'none' }} onChange={handleFile} />
        </div>
      </div>

      {items.length > 0 && (
        <>
          {/* Progress */}
          {running && (
            <div style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: '#888', marginBottom: 4 }}>
                <span>Analyzing {progress}/{items.length}...</span>
                <span>{Math.round(progress / items.length * 100)}%</span>
              </div>
              <div style={{ height: 4, background: '#f0f0ee', borderRadius: 2 }}>
                <div style={{ height: '100%', width: `${(progress / items.length) * 100}%`, background: '#0d9488', borderRadius: 2, transition: 'width 0.3s' }} />
              </div>
            </div>
          )}

          {/* Start button */}
          {!running && items.every(i => i.status === 'pending') && (
            <button onClick={runBulk} style={{ width: '100%', padding: '10px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer', marginBottom: 12 }}>
              Analyze {items.length} items
            </button>
          )}

          {/* Results table */}
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e5e5e5' }}>
                  <th style={{ textAlign: 'left', padding: '6px 8px', color: '#888', fontWeight: 600 }}>#</th>
                  <th style={{ textAlign: 'left', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Input</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Score</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Techniques</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Fact-checks</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, i) => {
                  const score = item.result ? getScore(item.result) : 0;
                  return (
                    <tr key={i} style={{ borderBottom: '1px solid #f0f0ee' }}>
                      <td style={{ padding: '6px 8px', color: '#aaa' }}>{i + 1}</td>
                      <td style={{ padding: '6px 8px', maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.input}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center', fontWeight: 700, color: item.result ? scoreColor(score) : '#ccc' }}>{item.result ? score : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>{item.result ? item.result.prism?.techniques?.length || 0 : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>{item.result ? item.result.trace?.fact_checks?.length || 0 : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>
                        {item.status === 'pending' && <span style={{ color: '#aaa' }}>⏳</span>}
                        {item.status === 'analyzing' && <span style={{ color: '#0d9488' }}>🔍</span>}
                        {item.status === 'done' && <span style={{ color: '#16a34a' }}>✅</span>}
                        {item.status === 'error' && <span title={item.error} style={{ color: '#dc2626' }}>❌</span>}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}

      {items.length === 0 && (
        <div style={{ textAlign: 'center', padding: '20px 0', color: '#888', fontSize: 13 }}>
          Upload a CSV file with one URL or claim per line. Max 50 items.
        </div>
      )}
    </div>
  );
}
