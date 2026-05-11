'use client';
import { useState } from 'react';

interface Props {
  onScan: (content: string, mode: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading }: Props) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');

  const handleSubmit = () => {
    if (content.trim().length < 10) return;
    onScan(content.trim(), mode);
  };

  const isUrl = content.trim().startsWith('http');
  const canSubmit = content.trim().length >= 10 && !loading;

  return (
    <div className="bg-white border border-ink-200 rounded-xl shadow-sm overflow-hidden">
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Paste a URL, article text, or social media post…"
        className="w-full h-36 p-5 text-[15px] leading-relaxed text-ink-900 placeholder-ink-400 focus:outline-none resize-none font-sans"
        onKeyDown={(e) => {
          if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
            handleSubmit();
          }
        }}
      />

      <div className="border-t border-ink-100 px-4 py-3 flex items-center justify-between gap-3 bg-ink-50/50">
        <div className="flex items-center gap-2">
          {/* Mode selector */}
          <div className="inline-flex bg-white border border-ink-200 rounded-md p-0.5">
            {(['brief', 'detailed'] as const).map((m) => (
              <button
                key={m}
                onClick={() => setMode(m)}
                className={`px-3 py-1 rounded text-xs font-medium capitalize transition-all ${
                  mode === m
                    ? 'bg-ink-900 text-white shadow-sm'
                    : 'text-ink-500 hover:text-ink-800'
                }`}
              >
                {m}
              </button>
            ))}
          </div>
          {/* Status indicator */}
          <span className="text-xs text-ink-500 hidden sm:inline">
            {isUrl ? (
              <span className="inline-flex items-center gap-1">
                <span className="w-1.5 h-1.5 bg-orange-500 rounded-full"></span>
                URL detected
              </span>
            ) : content.length > 0 ? (
              `${content.trim().split(/\s+/).length} words`
            ) : (
              ''
            )}
          </span>
        </div>

        <button
          onClick={handleSubmit}
          disabled={!canSubmit}
          className="inline-flex items-center gap-2 px-4 py-1.5 bg-ink-900 text-white rounded-md text-sm font-medium hover:bg-ink-800 disabled:bg-ink-300 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? (
            <>
              <svg className="animate-spin h-3.5 w-3.5" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"/>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
              </svg>
              Analyzing
            </>
          ) : (
            <>
              Analyze
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
            </>
          )}
        </button>
      </div>
    </div>
  );
}
