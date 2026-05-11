export default function LoadingState() {
  const sections = [
    { name: 'Prism', label: 'Manipulation analysis', color: 'text-purple-700' },
    { name: 'Signal', label: 'Source credibility', color: 'text-amber-700' },
    { name: 'Trace', label: 'Source origins', color: 'text-blue-700' },
  ];

  return (
    <div className="mt-8 space-y-4">
      <div className="flex items-center gap-2 pb-3 border-b border-ink-200">
        <svg className="animate-spin h-3.5 w-3.5 text-ink-500" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"/>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
        </svg>
        <span className="text-xs uppercase tracking-widest text-ink-500 font-semibold">Analyzing</span>
      </div>

      {sections.map((s, i) => (
        <div
          key={s.name}
          className="bg-white border border-ink-200 rounded-xl overflow-hidden"
          style={{ animationDelay: `${i * 0.1}s` }}
        >
          <div className="px-5 pt-5 pb-3 border-b border-ink-100">
            <div className={`text-xs uppercase tracking-widest font-semibold mb-0.5 ${s.color}`}>
              {s.name}
            </div>
            <div className="font-serif text-xl font-semibold text-ink-300">{s.label}</div>
          </div>
          <div className="px-5 py-5 space-y-3">
            <div className="h-3 shimmer rounded w-3/4" />
            <div className="h-3 shimmer rounded w-full" />
            <div className="h-3 shimmer rounded w-5/6" />
          </div>
        </div>
      ))}
    </div>
  );
}
