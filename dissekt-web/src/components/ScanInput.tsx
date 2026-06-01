'use client';
import { useState } from 'react';

export default function ScanInput({ onScan, loading }: { onScan: (c: string, m: string) => void; loading: boolean }) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief'|'detailed'>('brief');
  const isUrl = content.trim().startsWith('http');
  const ok = content.trim().length >= 10 && !loading;

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 10, background: '#f5f5f4', borderRadius: 10, padding: '10px 14px', border: '1px solid #e5e5e5' }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input
          type="text" value={content} onChange={e => setContent(e.target.value)}
          placeholder="Paste a URL, article text, or claim to analyze..."
          onKeyDown={e => { if (e.key === 'Enter' && ok) onScan(content.trim(), mode); }}
          style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: '#1a1a1a' }}
        />
        {isUrl && (
          <span style={{ fontSize: 11, fontWeight: 600, color: '#7c3aed', background: '#f3e8ff', padding: '3px 10px', borderRadius: 20, whiteSpace: 'nowrap' }}>URL</span>
        )}
      </div>
      <div style={{ display: 'flex', background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
        {(['brief','detailed'] as const).map(m => (
          <button key={m} onClick={() => setMode(m)} style={{ padding: '6px 12px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: mode===m ? '#fff' : 'transparent', color: mode===m ? '#1a1a1a' : '#888', boxShadow: mode===m ? '0 1px 3px rgba(0,0,0,0.08)' : 'none', textTransform: 'capitalize' }}>{m}</button>
        ))}
      </div>
      <button onClick={() => ok && onScan(content.trim(), mode)} disabled={!ok}
        style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '10px 20px', background: ok ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: ok ? 'pointer' : 'not-allowed', whiteSpace: 'nowrap' }}>
        {loading ? (
          <><svg style={{ animation: 'spin 0.8s linear infinite' }} width="14" height="14" viewBox="0 0 24 24"><circle opacity="0.25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path opacity="0.75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg> Scanning</>
        ) : (
          <><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg> Scan</>
        )}
      </button>
    </div>
  );
}
