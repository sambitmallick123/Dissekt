'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';
import MetaCard from './MetaCard';
import SimilarClaims from './SimilarClaims';
import ExtractedClaims from './ExtractedClaims';

const LANG_NAMES: Record<string, string> = { en: 'English', hi: 'Hindi', de: 'German', es: 'Spanish', fr: 'French' };

export default function AnalysisResult({ data, onShare }: { data: any; onShare?: () => void }) {
  const lang = data.detected_language;
  const langName = LANG_NAMES[lang] || lang;

  return (
    <div>
      <div className="anim-fade" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {lang && lang !== 'en' && (
            <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: '#dbeafe', color: '#1e40af', fontWeight: 500 }}>
              Detected: {langName}
            </span>
          )}
          <a href="/help" style={{ fontSize: 11, color: '#888', textDecoration: 'none' }}>What do these mean?</a>
        </div>
        {onShare && (
          <button onClick={onShare} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 12, fontWeight: 500, cursor: 'pointer', color: '#7c3aed' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg>
            Share report
          </button>
        )}
      </div>

      <div className="anim-fade"><ThreatScore data={data} /></div>

      <div className="result-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        <div className="anim-fade anim-d1"><PrismCard prism={data.prism} /></div>
        <div className="anim-fade anim-d2"><TraceCard trace={data.trace} /></div>
        <div className="anim-fade anim-d3"><SignalCard signal={data.signal} /></div>
        <div className="anim-fade anim-d4"><MetaCard data={data} /></div>
      </div>

      {data.extracted_claims?.length > 0 && (
        <div className="anim-fade anim-d3"><ExtractedClaims claims={data.extracted_claims} /></div>
      )}

      {data.similar_claims?.length > 0 && (
        <div className="anim-fade anim-d4"><SimilarClaims claims={data.similar_claims} /></div>
      )}
    </div>
  );
}
