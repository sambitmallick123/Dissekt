'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function Annotations({ reportId }: { reportId: string }) {
  const [annotations, setAnnotations] = useState<any[]>([]);
  const [newText, setNewText] = useState('');
  const [author, setAuthor] = useState('');
  const [sending, setSending] = useState(false);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (reportId) {
      fetch(`${API_URL}/api/annotations/${reportId}`)
        .then(r => r.json())
        .then(d => { setAnnotations(d.annotations || []); setLoaded(true); })
        .catch(() => setLoaded(true));
    }
  }, [reportId]);

  const submit = async () => {
    if (!newText.trim()) return;
    setSending(true);
    try {
      const res = await fetch(`${API_URL}/api/annotations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ report_id: reportId, text: newText, author: author || 'Anonymous' }),
      });
      const data = await res.json();
      if (data.success && data.annotation) {
        setAnnotations(prev => [...prev, data.annotation]);
        setNewText('');
      }
    } catch {}
    finally { setSending(false); }
  };

  if (!reportId) return null;

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>💬</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Community notes</span>
        <span style={{ fontSize: 12, color: '#888' }}>{annotations.length} annotation{annotations.length !== 1 ? 's' : ''}</span>
      </div>

      {/* Existing annotations */}
      {annotations.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
          {annotations.map((a, i) => (
            <div key={i} style={{ padding: '8px 12px', background: '#f8fafa', borderRadius: 8, borderLeft: '3px solid #0d9488' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                <span style={{ fontSize: 11, fontWeight: 600, color: '#0d9488' }}>{a.author || 'Anonymous'}</span>
                <span style={{ fontSize: 10, color: '#aaa' }}>{a.created_at ? new Date(a.created_at).toLocaleDateString() : ''}</span>
              </div>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{a.text}</div>
            </div>
          ))}
        </div>
      )}

      {/* Add annotation */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <input type="text" placeholder="Your name (optional)" value={author} onChange={e => setAuthor(e.target.value)}
            style={{ width: 160, padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, outline: 'none' }} />
          <input type="text" placeholder="Add a note — what did you verify or find?" value={newText} onChange={e => setNewText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && submit()}
            style={{ flex: 1, padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, outline: 'none' }} />
          <button onClick={submit} disabled={!newText.trim() || sending}
            style={{ padding: '6px 14px', background: newText.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: newText.trim() ? 'pointer' : 'not-allowed' }}>
            {sending ? '...' : 'Post'}
          </button>
        </div>
        <div style={{ fontSize: 10, color: '#aaa' }}>Notes are visible to all users. Share what you independently verified or found.</div>
      </div>
    </div>
  );
}
