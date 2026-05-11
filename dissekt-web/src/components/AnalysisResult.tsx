'use client';

import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div className="mt-8 space-y-4">
      {/* Summary bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-ink-200">
        <div>
          <div className="text-xs uppercase tracking-widest text-ink-500 font-semibold mb-1">
            Analysis complete
          </div>
          <div className="flex items-center gap-3 text-xs text-ink-500">
            <span>{data.analysis_time_ms}ms</span>
            <span>·</span>
            <span>{data.prism?.model_used || 'unknown'}</span>
            <span>·</span>
            <span>{data.cached ? 'Cached' : 'Fresh'}</span>
            {data.prism?.heuristic_only && (
              <>
                <span>·</span>
                <span className="text-green-700">Heuristic only (€0)</span>
              </>
            )}
          </div>
        </div>
        <div className="text-xs text-ink-400 font-mono">
          {data.blockchain?.content_hash?.slice(0, 16)}…
        </div>
      </div>

      <div className="fade-in-up fade-in-up-delay-1">
        <PrismCard prism={data.prism} />
      </div>
      <div className="fade-in-up fade-in-up-delay-2">
        <SignalCard signal={data.signal} />
      </div>
      <div className="fade-in-up fade-in-up-delay-3">
        <TraceCard trace={data.trace} />
      </div>
    </div>
  );
}
