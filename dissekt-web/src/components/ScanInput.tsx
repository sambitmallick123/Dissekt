'use client';
import { useState, useRef, useCallback, useEffect } from 'react';

interface Props {
  initialContent?: string;
  onScan: (content: string, mode: string, image?: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading, initialContent }: Props) {
  const [content, setContent] = useState(initialContent || '');
  useEffect(() => { if (initialContent) setContent(initialContent); }, [initialContent]);
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');
  const [image, setImage] = useState<string | null>(null);
  const [imageName, setImageName] = useState('');
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const cameraRef = useRef<HTMLInputElement>(null);

  const isUrl = content.trim().startsWith('http');
  const canSubmit = (content.trim().length >= 10 || image) && !loading;

  const processFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) return;
    if (file.size > 10 * 1024 * 1024) { alert('Image must be under 10MB'); return; }
    setImageName(file.name);
    const reader = new FileReader();
    reader.onload = (e) => setImage(e.target?.result as string);
    reader.readAsDataURL(file);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault(); setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) processFile(file);
  }, [processFile]);

  const handlePaste = useCallback((e: React.ClipboardEvent) => {
    const items = e.clipboardData?.items;
    if (!items) return;
    for (const item of Array.from(items)) {
      if (item.type.startsWith('image/')) { e.preventDefault(); const file = item.getAsFile(); if (file) processFile(file); return; }
    }
  }, [processFile]);

  const handleSubmit = () => { if (canSubmit) onScan(content.trim(), mode, image || undefined); };
  const removeImage = () => { setImage(null); setImageName(''); };

  return (
    <div>
      <div className="scan-row" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
          style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8, background: dragOver ? '#f3e8ff' : '#f5f5f4', borderRadius: 10, padding: '10px 12px', border: dragOver ? '2px dashed #7c3aed' : '1px solid #e5e5e5', transition: 'all 0.15s ease', minWidth: 0 }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="2" style={{ flexShrink: 0 }}><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" value={content} onChange={e => setContent(e.target.value)}
            placeholder={image ? "Add context..." : "Paste URL, text, or drop image..."}
            onKeyDown={e => { if (e.key === 'Enter') handleSubmit(); }} onPaste={handlePaste}
            style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: '#1a1a1a', minWidth: 0 }} />
          {isUrl && !image && <span style={{ fontSize: 10, fontWeight: 600, color: '#7c3aed', background: '#f3e8ff', padding: '2px 8px', borderRadius: 20, whiteSpace: 'nowrap', flexShrink: 0 }}>URL</span>}
          <button onClick={() => fileRef.current?.click()} title="Upload image" style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, display: 'flex', color: '#888', flexShrink: 0 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
          </button>
          <button onClick={() => cameraRef.current?.click()} title="Camera" style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, display: 'flex', color: '#888', flexShrink: 0 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/><circle cx="12" cy="13" r="4"/></svg>
          </button>
          <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
          <input ref={cameraRef} type="file" accept="image/*" capture="environment" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
        </div>

        <div className="scan-controls" style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
          <div style={{ display: 'flex', background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
            {(['brief', 'detailed'] as const).map(m => (
              <button key={m} onClick={() => setMode(m)} style={{ padding: '6px 10px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer', background: mode === m ? '#fff' : 'transparent', color: mode === m ? '#1a1a1a' : '#888', boxShadow: mode === m ? '0 1px 3px rgba(0,0,0,0.08)' : 'none', textTransform: 'capitalize', whiteSpace: 'nowrap' }}>{m}</button>
            ))}
          </div>
          <button onClick={handleSubmit} disabled={!canSubmit} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, padding: '8px 16px', background: canSubmit ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: canSubmit ? 'pointer' : 'not-allowed', whiteSpace: 'nowrap' }}>
            {loading ? (<><svg style={{ animation: 'spin 0.8s linear infinite' }} width="14" height="14" viewBox="0 0 24 24"><circle opacity="0.25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path opacity="0.75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>Scanning</>) : (<><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>Scan</>)}
          </button>
        </div>
      </div>

      {image && (
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'start', gap: 10, padding: 10, background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10 }}>
          <img src={image} alt="Preview" style={{ width: 60, height: 60, objectFit: 'cover', borderRadius: 8, border: '1px solid #e5e5e5', flexShrink: 0 }} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 500, color: '#404040', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{imageName || 'Captured image'}</div>
            <div style={{ fontSize: 11, color: '#888' }}>AI vision will extract text and detect manipulation.</div>
          </div>
          <button onClick={removeImage} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#888', fontSize: 16, flexShrink: 0 }}>✕</button>
        </div>
      )}

      {dragOver && (
        <div style={{ marginTop: 8, padding: 16, border: '2px dashed #7c3aed', borderRadius: 10, background: '#faf5ff', textAlign: 'center' }}>
          <div style={{ fontSize: 13, fontWeight: 500, color: '#7c3aed' }}>Drop image here</div>
          <div style={{ fontSize: 11, color: '#888' }}>PNG, JPG, WEBP up to 10MB</div>
        </div>
      )}
    </div>
  );
}
