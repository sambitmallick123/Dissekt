'use client';

const biasLabel = (bias: string | null) => {
  if (!bias) return { label: 'Unknown', dot: 'bg-ink-300', text: 'text-ink-500' };
  const map: Record<string, { label: string; dot: string; text: string }> = {
    'far-left': { label: 'Far left', dot: 'bg-blue-700', text: 'text-blue-700' },
    'left': { label: 'Left', dot: 'bg-blue-500', text: 'text-blue-600' },
    'left-center': { label: 'Left-center', dot: 'bg-blue-300', text: 'text-blue-500' },
    'center': { label: 'Center', dot: 'bg-green-500', text: 'text-green-700' },
    'right-center': { label: 'Right-center', dot: 'bg-red-300', text: 'text-red-500' },
    'right': { label: 'Right', dot: 'bg-red-500', text: 'text-red-600' },
    'far-right': { label: 'Far right', dot: 'bg-red-700', text: 'text-red-700' },
  };
  return map[bias] || { label: bias, dot: 'bg-ink-400', text: 'text-ink-600' };
};

const factualityLabel = (f: string | null) => {
  if (!f) return { label: 'Unknown', color: 'text-ink-500' };
  const map: Record<string, { label: string; color: string }> = {
    'very-high': { label: 'Very high', color: 'text-green-700' },
    'high': { label: 'High', color: 'text-green-600' },
    'mixed': { label: 'Mixed', color: 'text-amber-600' },
    'low': { label: 'Low', color: 'text-orange-600' },
    'very-low': { label: 'Very low', color: 'text-red-700' },
  };
  return map[f] || { label: f, color: 'text-ink-600' };
};

export default function SignalCard({ signal }: { signal: any }) {
  const bias = biasLabel(signal.source_bias);
  const fact = factualityLabel(signal.source_factuality);
  const toxPercent = (signal.toxicity_score * 100).toFixed(1);
  const toxLevel =
    signal.toxicity_score > 0.5 ? 'High' : signal.toxicity_score > 0.2 ? 'Moderate' : 'Low';
  const toxColor =
    signal.toxicity_score > 0.5 ? 'text-red-700' : signal.toxicity_score > 0.2 ? 'text-amber-600' : 'text-green-700';

  return (
    <section className="bg-white border border-ink-200 rounded-xl overflow-hidden">
      <div className="px-5 pt-5 pb-3 border-b border-ink-100">
        <div className="text-xs uppercase tracking-widest text-amber-700 font-semibold mb-0.5">
          Signal
        </div>
        <h2 className="font-serif text-xl font-semibold text-ink-900">
          Source credibility & sentiment
        </h2>
      </div>

      <div className="px-5 py-4">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-px bg-ink-100 border border-ink-100 rounded-lg overflow-hidden">
          {/* Source bias */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Source bias
            </div>
            <div className="flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${bias.dot}`}></span>
              <span className={`font-semibold text-sm ${bias.text}`}>{bias.label}</span>
            </div>
          </div>
          {/* Factuality */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Factuality
            </div>
            <span className={`font-semibold text-sm ${fact.color}`}>{fact.label}</span>
          </div>
          {/* Sentiment */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Sentiment
            </div>
            <div>
              <span className="font-semibold text-sm text-ink-800 capitalize">{signal.sentiment}</span>
              <span className="text-xs text-ink-500 ml-1">
                ({signal.sentiment_score?.toFixed(2)})
              </span>
            </div>
          </div>
          {/* Toxicity */}
          <div className="bg-white p-4">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-2">
              Toxicity
            </div>
            <div>
              <span className={`font-semibold text-sm ${toxColor}`}>{toxLevel}</span>
              <span className="text-xs text-ink-500 ml-1">({toxPercent}%)</span>
            </div>
          </div>
        </div>

        {/* Toxicity breakdown */}
        {signal.toxicity_labels && Object.keys(signal.toxicity_labels).length > 0 && signal.toxicity_score > 0.05 && (
          <div className="mt-4 pt-4 border-t border-ink-100">
            <div className="text-[10px] uppercase tracking-widest text-ink-500 font-semibold mb-3">
              Toxicity breakdown
            </div>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {Object.entries(signal.toxicity_labels).map(([k, v]: any) => (
                <div key={k}>
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-ink-600 capitalize">{k.replace(/_/g, ' ')}</span>
                    <span className="text-ink-800 font-medium">{(v * 100).toFixed(1)}%</span>
                  </div>
                  <div className="h-1 bg-ink-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${
                        v > 0.5 ? 'bg-red-400' : v > 0.2 ? 'bg-amber-400' : 'bg-ink-300'
                      }`}
                      style={{ width: `${Math.max(v * 100, 1)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
