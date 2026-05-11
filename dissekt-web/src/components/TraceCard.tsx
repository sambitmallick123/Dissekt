'use client';
import { useState } from 'react';

const platformInfo = (platform: string) => {
  const p = (platform || '').toLowerCase();
  if (p.includes('twitter') || p === 'x/twitter')
    return { icon: '𝕏', name: 'X / Twitter', color: 'text-ink-900 bg-ink-100' };
  if (p.includes('reddit')) return { icon: 'R', name: 'Reddit', color: 'text-orange-700 bg-orange-50' };
  if (p.includes('facebook')) return { icon: 'f', name: 'Facebook', color: 'text-blue-700 bg-blue-50' };
  if (p.includes('youtube')) return { icon: '▶', name: 'YouTube', color: 'text-red-700 bg-red-50' };
  if (p.includes('instagram')) return { icon: '◉', name: 'Instagram', color: 'text-pink-700 bg-pink-50' };
  if (p.includes('telegram')) return { icon: '✈', name: 'Telegram', color: 'text-sky-700 bg-sky-50' };
  if (p.includes('whatsapp')) return { icon: '✓', name: 'WhatsApp', color: 'text-green-700 bg-green-50' };
  return { icon: '○', name: 'Web', color: 'text-ink-600 bg-ink-100' };
};

const ratingColor = (rating: string) => {
  const r = (rating || '').toLowerCase();
  if (r.includes('false') || r.includes('pinocchio') || r.includes('wrong')) return 'text-red-700 bg-red-50 border-red-200';
  if (r.includes('true')) return 'text-green-700 bg-green-50 border-green-200';
  if (r.includes('misleading') || r.includes('mixed') || r.includes('context'))
    return 'text-amber-700 bg-amber-50 border-amber-200';
  return 'text-ink-700 bg-ink-100 border-ink-200';
};

export default function TraceCard({ trace }: { trace: any }) {
  const [showAll, setShowAll] = useState(false);
  const timeline = showAll ? trace.spread_timeline : trace.spread_timeline?.slice(0, 5);
  const hasFactChecks = trace.fact_checks && trace.fact_checks.length > 0;
  const hasTimeline = trace.spread_timeline && trace.spread_timeline.length > 0;

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-xs uppercase tracking-widest text-blue-700 font-semibold mb-0.5">
              Trace
            </div>
            <h2 className="font-serif text-xl font-semibold text-ink-900">
              Source origins
            </h2>
          </div>
          {(hasFactChecks || hasTimeline) && (
            <div className="text-xs text-ink-500">
              {hasFactChecks && <span>{trace.fact_checks.length} fact-checks</span>}
              {hasFactChecks && hasTimeline && <span className="mx-1">·</span>}
              {hasTimeline && <span>{trace.spread_timeline.length} sources</span>}
            </div>
          )}
        </div>
      </div>

      <div className="px-5 py-4">
        {/* Fact checks */}
        {hasFactChecks && (
          <div className="mb-5">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Existing fact-checks
            </div>
            <div className="space-y-2">
              {trace.fact_checks.slice(0, 5).map((fc: any, i: number) => (
                <a
                  key={i}
                  href={fc.url}
                  target="_blank"
                  rel="noopener"
                  className="block p-3 border border-ink-100 rounded-lg hover:border-ink-300 hover:bg-ink-50/50 transition-all group"
                >
                  <div className="flex items-start justify-between gap-3 mb-1">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-sm text-ink-900">{fc.publisher}</span>
                        {fc.date && (
                          <span className="text-xs text-ink-500">· {fc.date.slice(0, 10)}</span>
                        )}
                      </div>
                    </div>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded border shrink-0 ${ratingColor(fc.rating)}`}>
                      {fc.rating}
                    </span>
                  </div>
                  <div className="text-sm text-ink-700 line-clamp-2 group-hover:text-ink-900 transition-colors">
                    {fc.title}
                  </div>
                </a>
              ))}
            </div>
          </div>
        )}

        {/* Spread timeline */}
        {hasTimeline && (
          <div>
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Spread timeline
            </div>
            <div className="relative space-y-1">
              {/* Vertical line */}
              <div className="absolute left-[9px] top-2 bottom-2 w-px bg-ink-200" aria-hidden="true" />
              {timeline.map((s: any, i: number) => {
                const p = platformInfo(s.platform);
                return (
                  <a
                    key={i}
                    href={s.url}
                    target="_blank"
                    rel="noopener"
                    className="relative flex items-start gap-3 p-2 pl-0 hover:bg-ink-50/70 rounded transition-colors group"
                  >
                    <div className={`relative z-[1] w-[19px] h-[19px] rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 ${p.color} border border-white`}>
                      {p.icon}
                    </div>
                    <div className="flex-1 min-w-0 pt-0">
                      <div className="text-sm text-ink-800 truncate group-hover:text-ink-900">
                        {s.title || '(untitled)'}
                      </div>
                      <div className="text-xs text-ink-500 flex items-center gap-2 mt-0.5">
                        <span>{p.name}</span>
                        {s.date && (
                          <>
                            <span>·</span>
                            <span>{s.date}</span>
                          </>
                        )}
                      </div>
                    </div>
                  </a>
                );
              })}
            </div>
            {trace.spread_timeline.length > 5 && (
              <button
                onClick={() => setShowAll(!showAll)}
                className="mt-3 text-sm text-blue-700 hover:text-blue-900 font-medium"
              >
                {showAll ? '− Show less' : `+ Show all ${trace.spread_timeline.length} sources`}
              </button>
            )}
          </div>
        )}

        {!hasFactChecks && !hasTimeline && (
          <div className="py-6 text-center">
            <p className="text-ink-500 text-sm">No existing sources found for this claim.</p>
          </div>
        )}
      </div>
    </section>
  );
}
