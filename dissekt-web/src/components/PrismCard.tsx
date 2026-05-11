'use client';
import { useState } from 'react';

const categoryColors: Record<string, string> = {
  framing: 'bg-purple-50 text-purple-800 border-purple-200',
  logical_fallacy: 'bg-blue-50 text-blue-800 border-blue-200',
  credibility: 'bg-amber-50 text-amber-800 border-amber-200',
  deflection: 'bg-rose-50 text-rose-800 border-rose-200',
};

const confidenceColor = (c: number) => {
  if (c >= 0.85) return { bar: 'bg-red-500', text: 'text-red-700' };
  if (c >= 0.7) return { bar: 'bg-orange-500', text: 'text-orange-700' };
  return { bar: 'bg-yellow-500', text: 'text-yellow-700' };
};

export default function PrismCard({ prism }: { prism: any }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-xs uppercase tracking-widest text-purple-700 font-semibold mb-0.5">
              Prism
            </div>
            <h2 className="font-serif text-xl font-semibold text-ink-900">
              Manipulation analysis
            </h2>
          </div>
          <div className="text-xs text-ink-500">
            {prism.techniques?.length || 0} {prism.techniques?.length === 1 ? 'technique' : 'techniques'}
          </div>
        </div>
      </div>

      {/* Body */}
      <div className="px-5 py-4">
        {prism.techniques.length === 0 ? (
          <div className="py-6 text-center">
            <div className="text-4xl mb-2">✓</div>
            <p className="text-ink-600 text-sm">No manipulation techniques detected.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {prism.techniques.map((t: any, i: number) => {
              const color = confidenceColor(t.confidence);
              const catClass = categoryColors[t.category] || categoryColors.framing;
              return (
                <div key={i} className="border border-ink-100 rounded-lg p-4 hover:border-ink-200 transition-colors">
                  <div className="flex items-start justify-between gap-3 mb-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <span className="font-serif text-[15px] font-semibold text-ink-900 capitalize">
                          {t.name.replace(/_/g, ' ')}
                        </span>
                        <span className={`text-[10px] font-medium px-2 py-0.5 rounded-full border ${catClass} capitalize`}>
                          {t.category?.replace(/_/g, ' ')}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className={`text-xs font-semibold ${color.text}`}>
                        {(t.confidence * 100).toFixed(0)}%
                      </span>
                    </div>
                  </div>
                  <div className="h-1 bg-ink-100 rounded-full mb-3 overflow-hidden">
                    <div
                      className={`h-full ${color.bar} rounded-full transition-all`}
                      style={{ width: `${t.confidence * 100}%` }}
                    />
                  </div>
                  <p className="text-sm text-ink-700 leading-relaxed">{t.explanation}</p>
                  {t.evidence && (
                    <blockquote className="mt-2 pl-3 border-l-2 border-orange-200 text-sm text-ink-600 italic">
                      "{t.evidence}"
                    </blockquote>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* Brief summary */}
        {prism.brief && (
          <div className="mt-4 p-4 bg-orange-50 border border-orange-100 rounded-lg">
            <div className="text-[10px] uppercase tracking-widest text-orange-700 font-semibold mb-1.5">
              Summary
            </div>
            <p className="text-sm text-ink-800 leading-relaxed font-serif">{prism.brief}</p>
          </div>
        )}

        {/* Detailed (collapsible) */}
        {prism.detailed && (
          <div className="mt-4 pt-4 border-t border-ink-100">
            <button
              onClick={() => setExpanded(!expanded)}
              className="flex items-center gap-2 text-sm text-ink-700 hover:text-ink-900 font-medium"
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className={`transition-transform ${expanded ? 'rotate-90' : ''}`}
              >
                <path d="M9 18l6-6-6-6" />
              </svg>
              {expanded ? 'Hide detailed analysis' : 'Show detailed analysis'}
            </button>
            {expanded && (
              <div className="mt-3 p-4 bg-ink-50 border border-ink-100 rounded-lg">
                <p className="text-sm text-ink-700 leading-relaxed whitespace-pre-wrap font-serif">
                  {prism.detailed}
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </section>
  );
}
