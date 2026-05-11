'use client';
import { useState } from 'react';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';

export default function Home() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleScan = async (content: string, mode: string) => {
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });

      if (!res.ok) {
        const err = await res.json();
        setError(err.detail || 'Analysis failed');
        return;
      }

      const data = await res.json();
      setResult(data);
    } catch (e) {
      setError('Could not connect to analysis service. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#fafaf9]">
      {/* Nav */}
      <nav className="border-b border-ink-200 bg-white/70 backdrop-blur-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-7 h-7 bg-ink-900 rounded flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 3l18 18M21 3L3 21" />
              </svg>
            </div>
            <span className="font-serif text-lg font-semibold tracking-tight text-ink-900">Dissekt</span>
          </div>
          <div className="flex items-center gap-6 text-sm">
            <a href="/radar" className="text-ink-600 hover:text-ink-900 transition-colors">Radar</a>
            <a href="#" className="text-ink-600 hover:text-ink-900 transition-colors hidden sm:inline">About</a>
            <a href="#" className="text-ink-600 hover:text-ink-900 transition-colors hidden sm:inline">API</a>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="border-b border-ink-200 dissekt-grid">
        <div className="max-w-3xl mx-auto px-6 py-16 md:py-20">
          <div className="mb-2 text-xs uppercase tracking-widest text-orange-700 font-semibold">
            An investigation tool
          </div>
          <h1 className="font-serif text-4xl md:text-5xl font-bold tracking-tight text-ink-900 mb-4 leading-tight">
            Explanation,<br />not verdicts.
          </h1>
          <p className="text-lg text-ink-600 leading-relaxed max-w-xl">
            Paste any URL or text. Dissekt identifies manipulation techniques, traces claims to their source, and exports blockchain-verified evidence.
          </p>
        </div>
      </section>

      {/* Scan interface */}
      <section className="max-w-3xl mx-auto px-6 py-10">
        <ScanInput onScan={handleScan} loading={loading} />

        {error && (
          <div className="mt-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-800 text-sm">
            <strong className="font-medium">Error: </strong>{error}
          </div>
        )}

        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
      </section>

      {/* Footer */}
      <footer className="border-t border-ink-200 mt-20">
        <div className="max-w-4xl mx-auto px-6 py-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-ink-500">
          <div>
            <span className="font-serif text-sm font-semibold text-ink-700">Dissekt</span>
            <span className="mx-2">·</span>
            <span>Built for journalists</span>
          </div>
          <div className="flex gap-4">
            <a href="#" className="hover:text-ink-800">Privacy</a>
            <a href="#" className="hover:text-ink-800">Terms</a>
            <a href="#" className="hover:text-ink-800">Contact</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
