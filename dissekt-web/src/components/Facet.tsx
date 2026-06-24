'use client';

const COLORS = { high: '#16a34a', moderate: '#d97706', low: '#dc2626' };
function sc(v: number) { return v >= 0.65 ? COLORS.high : v >= 0.35 ? COLORS.moderate : COLORS.low; }
function sl(v: number) { return v >= 0.65 ? 'High' : v >= 0.35 ? 'Moderate' : 'Low'; }

const KIND_LABEL: Record<string, string> = { url: 'URL', image: 'Image', video: 'Video', text: 'Text' };

// Infer content kind defensively if the backend didn't tag it.
function inferKind(data: any): string {
  const f = data.facet || {};
  if (f.kind && KIND_LABEL[f.kind]) return f.kind;
  const raw = (data.url || data.input_content || '').toString().trim();
  if (/^https?:\/\//i.test(raw)) return 'url';
  return 'text';
}

// Format an ISO/date string, or null if unparseable. Never fabricate.
function fmtDate(d?: string | null): string | null {
  if (!d) return null;
  const t = Date.parse(d);
  if (Number.isNaN(t)) return null;
  return new Date(t).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

export default function Facet({ data }: { data: any }) {
  const f = data.facet || {};
  const s = data.scoring || {};
  const techs = data.prism?.techniques || [];

  const kind = inferKind(data);
  const kindLabel = KIND_LABEL[kind] || 'Text';
  const title: string | null = f.title || data.title || null;
  const source: string | null = f.source_name || data.source_name || null;
  const published = fmtDate(f.published_at);
  const synopsis: string | null = f.synopsis || null;

  // Synopsis fallback — never fabricate; explain why it's absent.
  const heuristicOnly = (data.mode && /heur/i.test(data.mode)) || data.engine === 'heuristic';
  const synopsisFallback = heuristicOnly
    ? 'Synopsis isn’t generated in heuristic-only scans. Run a Brief or Detailed scan for a written summary.'
    : 'Synopsis unavailable for this scan.';

  // ── Findings: assembled ONLY from data.scoring so it can never disagree
  //    with the panels below. ───────────────────────────────────────────
  const clarity = s.clarity_score;
  const hasScore = typeof clarity === 'number';
  const dims = [
    { key: 'Construction', v: s.construction?.score },
    { key: 'Verification', v: s.verification?.score },
    { key: 'Intent', v: s.intent?.score },
  ].filter(d => typeof d.v === 'number') as { key: string; v: number }[];
  const driver = dims.length ? dims.reduce((a, b) => (b.v < a.v ? b : a)) : null;
  const topTech = s.construction?.rhetoric?.weighted?.[0]
    || [...techs].sort((a: any, b: any) => (b.confidence ?? 0) - (a.confidence ?? 0))[0]
    || null;
  const techName = topTech?.name ? String(topTech.name).replace(/_/g, ' ') : null;
  const coverage = s.coverage || {};
  const thinCoverage = coverage.level === 'low';

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 14 }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{ fontSize: 14, color: '#0d9488' }}>❖</span>
        <span style={{ fontSize: 13, fontWeight: 700, color: '#404040', letterSpacing: 0.2 }}>Facet</span>
        <span style={{ fontSize: 11, color: '#aaa' }}>— what is this?</span>
        <span style={{ marginLeft: 'auto', fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.4, color: '#0d9488', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 99, padding: '3px 10px' }}>{kindLabel}</span>
      </div>

      {/* title + meta */}
      {title && <div style={{ fontSize: 15, fontWeight: 600, color: '#1f2937', lineHeight: 1.35, marginBottom: 4 }}>{title}</div>}
      {(published || source) && (
        <div style={{ fontSize: 11, color: '#9ca3af', marginBottom: 10 }}>
          {published && <span>Published {published}</span>}
          {published && source && <span> · </span>}
          {source && <span>{source}</span>}
        </div>
      )}

      {/* synopsis */}
      <div style={{ fontSize: 13, lineHeight: 1.6, color: synopsis ? '#374151' : '#9ca3af', fontStyle: synopsis ? 'normal' : 'italic' }}>
        {synopsis || synopsisFallback}
      </div>

      {/* findings — derived from scoring, locked to the report */}
      {hasScore && (
        <div style={{ marginTop: 12, paddingTop: 10, borderTop: '0.5px solid #f0f0ee' }}>
          <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5, color: '#9ca3af', marginBottom: 5 }}>Findings</div>
          {data.prism?.brief && <div style={{ fontSize: 12.5, lineHeight: 1.6, color: '#374151', marginBottom: 6 }}>{data.prism.brief}</div>}
          <div style={{ fontSize: 12.5, lineHeight: 1.65, color: '#374151' }}>
            Reads as <strong style={{ color: sc(clarity) }}>{sl(clarity).toLowerCase()} transparency</strong>{' '}
            (<span style={{ fontWeight: 600, color: sc(clarity) }}>{clarity.toFixed(2)}</span>).
            {driver && <>
              {' '}Weakest on <strong style={{ color: sc(driver.v) }}>{driver.key}</strong>{' '}
              (<span style={{ fontWeight: 600, color: sc(driver.v) }}>{driver.v.toFixed(2)}</span>)
              {techName && <>, with <em style={{ color: '#6b7280' }}>{techName}</em> the most-weighted technique</>}.
            </>}
            {thinCoverage && <span style={{ color: '#9ca3af' }}> Limited evidence coverage — treat the verdict as provisional.</span>}
          </div>
        </div>
      )}
    </div>
  );
}
