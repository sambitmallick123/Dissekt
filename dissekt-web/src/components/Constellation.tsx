'use client';
import { useState, useEffect, useRef, useCallback } from 'react';
import { getUserEmail } from '@/lib/tier';

type Node = {
  id: string; name: string; type: string; freq: number;
  toxicity: number; clarity: number | null;
  top_techniques: string[];
  scans: { analysis_id: string; clarity: number | null; top_technique: string | null; toxicity: number; created_at: string }[];
  x: number; y: number; vx: number; vy: number;
};
type Edge = { source: string; target: string; type: 'co' | 'tech'; weight: number };

const TYPE_COLORS: Record<string, string> = {
  person: '#7F77DD', org: '#378ADD', place: '#1D9E75', theme: '#D85A30', topic: '#D4537E',
};
const toxColor = (t: number) => (t >= 0.65 ? '#E24B4A' : t >= 0.4 ? '#EF9F27' : '#1D9E75');
const clarColor = (c: number) => (c >= 0.65 ? '#1D9E75' : c >= 0.35 ? '#BA7517' : '#A32D2D');

export default function Constellation() {
  const [state, setState] = useState<'loading' | 'locked' | 'ready' | 'error'>('loading');
  const [count, setCount] = useState(0);
  const [needed, setNeeded] = useState(10);
  const [nodes, setNodes] = useState<Node[]>([]);
  const [edges, setEdges] = useState<Edge[]>([]);
  const [selected, setSelected] = useState<Node | null>(null);
  const [colorMode, setColorMode] = useState<'tox' | 'type'>('tox');
  // Report state
  const [nClusters, setNClusters] = useState(0);
  const [reportCluster, setReportCluster] = useState(-1);
  const [reportLoading, setReportLoading] = useState(false);
  const [report, setReport] = useState<any>(null);
  const [reportErr, setReportErr] = useState('');

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const nodesRef = useRef<Node[]>([]);
  const edgesRef = useRef<Edge[]>([]);
  const dragRef = useRef<Node | null>(null);
  const movedRef = useRef(false);
  const offRef = useRef({ x: 0, y: 0 });
  const selRef = useRef<Node | null>(null);
  const colorRef = useRef<'tox' | 'type'>('tox');
  const clusterRef = useRef<number>(-1);
  const [zoom, setZoom] = useState(1);
  const zoomRef = useRef(1);
  useEffect(() => { zoomRef.current = zoom; }, [zoom]);
  const rafRef = useRef<number>(0);

  const W = 600, H = 420;

  useEffect(() => { colorRef.current = colorMode; }, [colorMode]);
  useEffect(() => { selRef.current = selected; }, [selected]);
  useEffect(() => { clusterRef.current = reportCluster; }, [reportCluster]);

  useEffect(() => {
    const email = getUserEmail();
    if (!email) { setState('locked'); setCount(0); return; }
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    fetch(`${apiUrl}/api/constellation?email=${encodeURIComponent(email)}`)
      .then(r => r.json())
      .then(d => {
        if (!d.ready) { setState('locked'); setCount(d.count || 0); setNeeded(d.needed || 10); return; }
        const W2 = 600, H2 = 420;
        const ns: Node[] = (d.nodes || []).map((n: any) => ({
          ...n, x: W2 / 2 + (Math.random() - 0.5) * 200, y: H2 / 2 + (Math.random() - 0.5) * 200, vx: 0, vy: 0,
        }));
        nodesRef.current = ns; edgesRef.current = d.edges || [];
        setNodes(ns); setEdges(d.edges || []);
        setNClusters(d.n_clusters || (ns.length ? Math.max(...ns.map((n: any) => n.cluster ?? 0)) + 1 : 0));
        setState('ready');
      })
      .catch(() => setState('error'));
  }, []);

  const radius = (n: Node) => 9 + n.freq * 2;
  const nodeColor = useCallback((n: Node) => (colorRef.current === 'tox' ? toxColor(n.toxicity) : (TYPE_COLORS[n.type] || '#888780')), []);

  useEffect(() => {
    if (state !== 'ready') return;
    const canvas = canvasRef.current; if (!canvas) return;
    const ctx = canvas.getContext('2d'); if (!ctx) return;
    const byId: Record<string, Node> = Object.fromEntries(nodesRef.current.map(n => [n.id, n]));

    const tick = () => {
      const ns = nodesRef.current, es = edgesRef.current;
      for (let i = 0; i < ns.length; i++) for (let j = i + 1; j < ns.length; j++) {
        const a = ns[i], b = ns[j]; let dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy) || 1;
        const rep = 2400 / (d * d); a.vx -= dx / d * rep; a.vy -= dy / d * rep; b.vx += dx / d * rep; b.vy += dy / d * rep;
      }
      es.forEach(e => {
        const a = byId[e.source], b = byId[e.target]; if (!a || !b) return;
        let dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy) || 1; const f = (d - 110) * 0.01;
        a.vx += dx / d * f; a.vy += dy / d * f; b.vx -= dx / d * f; b.vy -= dy / d * f;
      });
      // gentle centering
      ns.forEach(n => { n.vx += (W / 2 - n.x) * 0.0008; n.vy += (H / 2 - n.y) * 0.0008; });
      ns.forEach(n => {
        if (n === dragRef.current) return;
        n.x += n.vx * 0.5; n.y += n.vy * 0.5; n.vx *= 0.85; n.vy *= 0.85;
        n.x = Math.max(30, Math.min(W - 30, n.x)); n.y = Math.max(30, Math.min(H - 30, n.y));
      });
    };
    const draw = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      // ensure backing store matches DPR for crisp rendering
      if (canvas.width !== Math.round(W * dpr)) { canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr); }
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, W, H);
      // center zoom: scale around canvas center
      const z = zoomRef.current;
      ctx.translate(W / 2, H / 2); ctx.scale(z, z); ctx.translate(-W / 2, -H / 2);
      const ns = nodesRef.current, es = edgesRef.current;
      es.forEach(e => {
        const a = byId[e.source], b = byId[e.target]; if (!a || !b) return;
        const cl = clusterRef.current;
        const edgeIn = (a as any).cluster === cl && (b as any).cluster === cl;
        const eDim = cl < 0 ? 1 : (edgeIn ? 1 : 0.08);
        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y);
        if (e.type === 'tech') { ctx.strokeStyle = '#7F77DD'; ctx.setLineDash([4, 3]); ctx.lineWidth = 1.5; ctx.globalAlpha = 0.55 * eDim; }
        else { ctx.strokeStyle = '#888780'; ctx.setLineDash([]); ctx.lineWidth = 1.5; ctx.globalAlpha = 0.3 * eDim; }
        ctx.stroke(); ctx.globalAlpha = 1; ctx.setLineDash([]);
      });
      ns.forEach(n => {
        const cl2 = clusterRef.current;
        const inCl = (n as any).cluster === cl2;
        const isFocus = cl2 >= 0 && inCl;     // a cluster is selected AND this node is in it
        const isOther = cl2 >= 0 && !inCl;    // a cluster is selected and this node is NOT in it
        // Focused nodes get a size boost; others shrink slightly and recede
        const baseR = radius(n);
        const r = isFocus ? baseR * 1.25 : baseR;
        // Soft glow behind focused nodes so they clearly pop
        if (isFocus) {
          ctx.globalAlpha = 1; ctx.beginPath(); ctx.arc(n.x, n.y, r + 6, 0, 7);
          ctx.fillStyle = 'rgba(13,148,136,0.18)'; ctx.fill();
        }
        ctx.beginPath(); ctx.arc(n.x, n.y, r, 0, 7);
        if (isOther) { ctx.fillStyle = '#d8d8d4'; } else { ctx.fillStyle = nodeColor(n); }
        ctx.globalAlpha = isOther ? 0.28 : 0.95; ctx.fill();
        // crisp white edge on focused nodes (separates them from the glow)
        if (isFocus) { ctx.globalAlpha = 1; ctx.lineWidth = 2; ctx.strokeStyle = '#fff'; ctx.stroke(); }
        if (n === selRef.current) { ctx.globalAlpha = 1; ctx.lineWidth = 2.5; ctx.strokeStyle = '#2C2C2A'; ctx.stroke(); }
        // label: readable size, halo for contrast, dim if outside selected cluster
        ctx.globalAlpha = (cl2 >= 0 && !inCl) ? 0.35 : 1;
        const fs = 11;
        ctx.font = `600 ${fs}px sans-serif`;
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(255,255,255,0.9)';
        const labelR = (cl2 >= 0 && (n as any).cluster === cl2) ? radius(n) * 1.25 : radius(n);
        ctx.strokeText(n.name, n.x, n.y - labelR - 8);
        ctx.fillStyle = '#2C2C2A';
        ctx.fillText(n.name, n.x, n.y - labelR - 8);
        ctx.globalAlpha = 1;
      });
    };
    const loop = () => { tick(); draw(); rafRef.current = requestAnimationFrame(loop); };
    loop();
    return () => cancelAnimationFrame(rafRef.current);
  }, [state, nodeColor]);

  const getPos = (ev: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current!; const r = canvas.getBoundingClientRect();
    const sx = W / r.width, sy = H / r.height;
    const cx = 'touches' in ev ? ev.touches[0].clientX : ev.clientX;
    const cy = 'touches' in ev ? ev.touches[0].clientY : ev.clientY;
    // canvas-space point
    const px = (cx - r.left) * sx, py = (cy - r.top) * sy;
    // undo center zoom
    const z = zoomRef.current;
    return { x: (px - W / 2) / z + W / 2, y: (py - H / 2) / z + H / 2 };
  };
  const hit = (p: { x: number; y: number }) => nodesRef.current.find(n => Math.hypot(n.x - p.x, n.y - p.y) <= radius(n) + 2) || null;

  const onDown = (e: React.MouseEvent) => {
    const p = getPos(e); const n = hit(p);
    if (n) { dragRef.current = n; movedRef.current = false; offRef.current = { x: p.x - n.x, y: p.y - n.y }; }
  };
  const onMove = (e: React.MouseEvent) => {
    if (!dragRef.current) return;
    const p = getPos(e); dragRef.current.x = p.x - offRef.current.x; dragRef.current.y = p.y - offRef.current.y; dragRef.current.vx = 0; dragRef.current.vy = 0; movedRef.current = true;
  };
  const onUp = () => { if (dragRef.current && !movedRef.current) setSelected(dragRef.current); dragRef.current = null; };

  if (state === 'loading') return <div style={{ textAlign: 'center', padding: 60, color: '#888' }}>Loading your Constellation…</div>;
  if (state === 'error') return <div style={{ textAlign: 'center', padding: 60, color: '#888' }}>Couldn't load the Constellation. Try again later.</div>;

  if (state === 'locked') {
    const pct = Math.min((count / needed) * 100, 100);
    return (
      <div style={{ textAlign: 'center', padding: '48px 16px', maxWidth: 440, margin: '0 auto' }}>
        <div style={{ fontSize: 30, marginBottom: 12 }}>✦</div>
        <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Your Constellation is forming</div>
        <div style={{ fontSize: 13, color: '#888', lineHeight: 1.6, marginBottom: 20 }}>
          As you analyze content, Dissekt maps the people, places, and topics you investigate — and how they're manipulated. Analyze at least {needed} pieces to reveal your Constellation.
        </div>
        <div style={{ background: '#f0f0ee', borderRadius: 8, height: 10, overflow: 'hidden', marginBottom: 8 }}>
          <div style={{ width: `${pct}%`, height: '100%', background: '#0d9488', transition: 'width 0.4s' }} />
        </div>
        <div style={{ fontSize: 12, color: '#888' }}>{count} / {needed} analyses</div>
      </div>
    );
  }

  const generateReport = async () => {
    setReportLoading(true); setReportErr(''); setReport(null);
    try {
      const email = getUserEmail();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/constellation/report?email=${encodeURIComponent(email || '')}&cluster=${reportCluster}`);
      if (!res.ok) { const e = await res.json().catch(() => ({})); throw new Error(e.detail || 'Report failed'); }
      setReport(await res.json());
    } catch (err: any) { setReportErr(err.message || 'Something went wrong'); }
    finally { setReportLoading(false); }
  };

  const reportPlainText = () => {
    if (!report) return '';
    let t = `Constellation Report — Cluster ${report.cluster}\n\n${report.report}\n\n`;
    if (report.references?.length) {
      t += 'References:\n';
      report.references.forEach((r: any, i: number) => {
        const d = r.created_at ? new Date(r.created_at).toLocaleDateString() : '';
        t += `[${i + 1}] ${d} · ${(r.top_technique || 'analysis').replace(/_/g, ' ')} · clarity ${r.clarity != null ? r.clarity.toFixed(2) : '—'} · /report/${r.analysis_id}\n`;
      });
    }
    return t;
  };

  const copyReport = () => navigator.clipboard?.writeText(reportPlainText());
  const downloadTxt = () => {
    const blob = new Blob([reportPlainText()], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `constellation-report-cluster-${report.cluster}.txt`; a.click();
    URL.revokeObjectURL(url);
  };
  const printReport = () => {
    const w = window.open('', '_blank');
    if (!w) return;
    const refs = (report.references || []).map((r: any, i: number) => {
      const d = r.created_at ? new Date(r.created_at).toLocaleDateString() : '';
      return `<li>${d} · ${(r.top_technique || 'analysis').replace(/_/g, ' ')} · clarity ${r.clarity != null ? r.clarity.toFixed(2) : '—'} · <a href="${location.origin}/report/${r.analysis_id}">/report/${r.analysis_id}</a></li>`;
    }).join('');
    w.document.write(`<html><head><title>Constellation Report</title><style>body{font-family:Georgia,serif;max-width:680px;margin:40px auto;padding:0 20px;line-height:1.6;color:#222}h1{font-size:20px}p{white-space:pre-wrap}ul{font-size:13px;color:#444}</style></head><body><h1>Constellation Report — Cluster ${report.cluster}</h1><p>${report.report.replace(/\n/g, '<br>')}</p><h3>References</h3><ul>${refs}</ul></body></html>`);
    w.document.close(); w.focus(); w.print();
  };

  const zoomIn = () => setZoom(z => Math.min(z * 1.25, 4));
  const zoomOut = () => setZoom(z => Math.max(z / 1.25, 0.5));
  const zoomReset = () => setZoom(1);

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{ fontSize: 12, color: '#888', marginRight: 'auto' }}>Drag nodes · zoom with +/− · click a node for details</span>
        <div style={{ display: 'flex', gap: 3, marginRight: 6 }}>
          <button onClick={zoomOut} title="Zoom out" style={{ fontSize: 13, width: 26, height: 26, border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555', lineHeight: 1 }}>−</button>
          <button onClick={zoomReset} title="Reset view" style={{ fontSize: 10, padding: '0 8px', height: 26, border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>{Math.round(zoom * 100)}%</button>
          <button onClick={zoomIn} title="Zoom in" style={{ fontSize: 13, width: 26, height: 26, border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555', lineHeight: 1 }}>+</button>
        </div>
        <button onClick={() => setColorMode(m => m === 'tox' ? 'type' : 'tox')}
          style={{ fontSize: 11, padding: '5px 12px', border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>
          Color: {colorMode === 'tox' ? 'manipulation' : 'entity type'}
        </button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 220px', gap: 12 }}>
        <canvas ref={canvasRef} width={W} height={H}
          onMouseDown={onDown} onMouseMove={onMove} onMouseUp={onUp} onMouseLeave={onUp}
          style={{ width: '100%', height: 'auto', display: 'block', borderRadius: 10, cursor: 'grab',
            backgroundColor: '#fff', backgroundImage: 'radial-gradient(circle, #e5e5e2 1px, transparent 1px)', backgroundSize: '20px 20px',
            border: '1px solid #e5e5e5' }} />
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: 14, minHeight: H, boxSizing: 'border-box' }}>
          {!selected ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', minHeight: 360, textAlign: 'center', color: '#bbb', fontSize: 12 }}>
              <div>Click a node to see<br />its details and scans</div>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 2 }}>{selected.name}</div>
              <div style={{ fontSize: 11, color: '#aaa', marginBottom: 12, textTransform: 'capitalize' }}>{selected.type}</div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
                <div style={{ flex: 1, background: '#fafaf8', borderRadius: 6, padding: '6px 8px' }}>
                  <div style={{ fontSize: 10, color: '#888' }}>scans</div>
                  <div style={{ fontSize: 16, fontWeight: 600 }}>{selected.freq}</div>
                </div>
                <div style={{ flex: 1, background: '#fafaf8', borderRadius: 6, padding: '6px 8px' }}>
                  <div style={{ fontSize: 10, color: '#888' }}>toxicity</div>
                  <div style={{ fontSize: 16, fontWeight: 600, color: toxColor(selected.toxicity) }}>{Math.round(selected.toxicity * 100)}%</div>
                </div>
              </div>
              {selected.clarity != null && (
                <div style={{ fontSize: 11, color: '#888', marginBottom: 10 }}>
                  Avg clarity <b style={{ color: clarColor(selected.clarity) }}>{selected.clarity.toFixed(2)}</b>
                </div>
              )}
              {selected.top_techniques?.length > 0 && (
                <div style={{ marginBottom: 10 }}>
                  <div style={{ fontSize: 10, color: '#888', marginBottom: 4 }}>Top techniques</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                    {selected.top_techniques.map((t, i) => (
                      <span key={i} style={{ fontSize: 10, padding: '2px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.replace(/_/g, ' ')}</span>
                    ))}
                  </div>
                </div>
              )}
              <div style={{ fontSize: 11, fontWeight: 600, margin: '10px 0 6px', borderTop: '1px solid #f0f0ee', paddingTop: 10 }}>
                Related scans {selected.scans?.length ? `(${selected.scans.length})` : ''}
              </div>
              {selected.scans?.length > 0 ? (
                selected.scans.map((s, i) => (
                  <a key={i} href={`/report/${s.analysis_id}`}
                    style={{ display: 'block', marginBottom: 7, textDecoration: 'none', cursor: 'pointer' }}>
                    <div style={{ fontSize: 11, color: '#404040', lineHeight: 1.35 }}>
                      {s.created_at ? new Date(s.created_at).toLocaleDateString() : 'Scan'} · {s.top_technique ? s.top_technique.replace(/_/g, ' ') : 'analysis'}
                    </div>
                    <div style={{ fontSize: 10, color: '#aaa' }}>
                      {s.clarity != null ? `clarity ${s.clarity.toFixed(2)}` : ''} · view report →
                    </div>
                  </a>
                ))
              ) : (
                <div style={{ fontSize: 11, color: '#bbb' }}>No linked reports yet.</div>
              )}
            </div>
          )}
        </div>
      </div>
      <div style={{ fontSize: 11, color: '#888', padding: '10px 4px 2px', lineHeight: 1.5 }}>
        {colorMode === 'tox'
          ? 'Color = manipulation level · size = how often analyzed · solid line = appeared together · dashed purple = manipulated the same way'
          : 'Color = entity type (person/org/place/theme/topic) · size = how often analyzed · dashed purple = manipulated the same way'}
      </div>

      {/* CLUSTER REPORT */}
      {nClusters > 0 && (
        <div style={{ marginTop: 16, borderTop: '1px solid #ececec', paddingTop: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Cluster report</div>
          <div style={{ fontSize: 12, color: '#888', marginBottom: 10 }}>Generate an analysis of how the topics in a cluster are covered, based on your scans.</div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap', marginBottom: 12 }}>
            <select value={reportCluster} onChange={e => setReportCluster(Number(e.target.value))}
              style={{ padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, background: '#fff' }}>
              <option value={-1}>Select a cluster to highlight…</option>
              {Array.from({ length: nClusters }, (_, i) => {
                const cnt = nodes.filter(n => (n as any).cluster === i).length;
                return <option key={i} value={i}>Cluster {i} ({cnt} {cnt === 1 ? 'entity' : 'entities'})</option>;
              })}
            </select>
            <button onClick={generateReport} disabled={reportLoading || reportCluster < 0}
              style={{ padding: '8px 18px', background: reportCluster < 0 ? '#b8b8b4' : '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: reportCluster < 0 ? 'default' : 'pointer' }}>
              {reportLoading ? 'Generating…' : 'Generate report'}
            </button>
            {reportCluster >= 0 && (
              <span style={{ fontSize: 12, color: '#0d9488', fontWeight: 600 }}>
                ● Highlighting Cluster {reportCluster}
              </span>
            )}
          </div>

          {reportErr && <div style={{ fontSize: 12, color: '#b91c1c', marginBottom: 10 }}>{reportErr}</div>}

          {report && (
            <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: 18 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 12 }}>
                <span style={{ fontSize: 13, fontWeight: 600, marginRight: 'auto' }}>Cluster {report.cluster} report</span>
                <button onClick={printReport} style={{ fontSize: 11, padding: '4px 10px', border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>Print</button>
                <button onClick={copyReport} style={{ fontSize: 11, padding: '4px 10px', border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>Copy</button>
                <button onClick={downloadTxt} style={{ fontSize: 11, padding: '4px 10px', border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>.txt</button>
                <button onClick={printReport} style={{ fontSize: 11, padding: '4px 10px', border: '1px solid #e5e5e5', borderRadius: 6, background: '#fff', cursor: 'pointer', color: '#555' }}>.pdf</button>
              </div>
              <div style={{ fontFamily: 'Charter, Georgia, serif', fontSize: 14, lineHeight: 1.65, color: '#222', whiteSpace: 'pre-wrap' }}>{report.report}</div>
              {report.references?.length > 0 && (
                <div style={{ marginTop: 14, borderTop: '1px solid #f0f0ee', paddingTop: 12 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 8 }}>References ({report.references.length})</div>
                  {report.references.map((r: any, i: number) => (
                    <a key={i} href={`/report/${r.analysis_id}`} style={{ display: 'block', marginBottom: 6, textDecoration: 'none' }}>
                      <span style={{ fontSize: 11, color: '#404040' }}>
                        [{i + 1}] {r.created_at ? new Date(r.created_at).toLocaleDateString() : ''} · {(r.top_technique || 'analysis').replace(/_/g, ' ')} · clarity {r.clarity != null ? r.clarity.toFixed(2) : '—'} <span style={{ color: '#0d9488' }}>→</span>
                      </span>
                    </a>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
