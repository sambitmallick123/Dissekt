'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const COST_COLOR: Record<string, string> = { '$': '#16a34a', '$$': '#d97706', '$$$': '#dc2626', '$$$$': '#991b1b', '?': '#888' };

export default function ModelsTab({ adminKey }: { adminKey: string }) {
  const [roles, setRoles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState('');
  const [advanced, setAdvanced] = useState<Record<string, string>>({});

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/admin/models?adminKey=${encodeURIComponent(adminKey)}`);
      const d = await res.json();
      setRoles(d.roles || []);
    } catch { setRoles([]); }
    finally { setLoading(false); }
  };

  useEffect(() => { if (adminKey) load(); }, [adminKey]);

  const setModel = async (role: string, model: string | null) => {
    setSaving(role);
    try {
      await fetch(`${API_URL}/api/admin/models`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ adminKey, role, model }),
      });
      await load();
    } finally { setSaving(''); }
  };

  if (loading) return <div style={{ padding: 20, color: '#888', fontSize: 13 }}>Loading model config…</div>;

  return (
    <div>
      <div style={{ fontSize: 12, color: '#888', marginBottom: 14, lineHeight: 1.6 }}>
        Assign a model to each pipeline role. Changes take effect on the next scan. Cost badges: <span style={{ color: '#16a34a' }}>$ cheap</span> → <span style={{ color: '#991b1b' }}>$$$$ premium</span>.
      </div>

      {roles.map(r => (
        <div key={r.role} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, marginBottom: 10 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <div>
              <span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{r.label}</span>
              <span style={{ fontSize: 10, color: '#aaa', marginLeft: 8, fontFamily: 'monospace' }}>{r.role}</span>
              <span style={{ fontSize: 9, color: '#888', marginLeft: 6, padding: '1px 6px', background: '#f0f0ee', borderRadius: 3 }}>{r.capability}</span>
            </div>
            {r.is_override
              ? <span style={{ fontSize: 9, fontWeight: 600, color: '#0d9488', padding: '2px 8px', background: '#f0fdfa', borderRadius: 10 }}>OVERRIDE</span>
              : <span style={{ fontSize: 9, color: '#aaa', padding: '2px 8px', background: '#fafaf8', borderRadius: 10 }}>default</span>}
          </div>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 8 }}>
            {r.options.map((o: any) => {
              const active = o.id === r.current;
              return (
                <button key={o.id} onClick={() => setModel(r.role, o.id)} disabled={saving === r.role}
                  style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '5px 10px', borderRadius: 6, fontSize: 11, fontWeight: active ? 600 : 500, cursor: 'pointer',
                    border: active ? '2px solid #0d9488' : '0.5px solid #e5eaea', background: active ? '#f0fdfa' : '#fff', color: active ? '#0d9488' : '#555' }}>
                  {o.label}
                  <span style={{ fontSize: 9, fontWeight: 700, color: COST_COLOR[o.cost] || '#888' }}>{o.cost}</span>
                  <span style={{ fontSize: 8, color: '#bbb' }}>{o.provider === 'anthropic' ? 'A' : 'O'}</span>
                </button>
              );
            })}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {r.is_override && (
              <button onClick={() => setModel(r.role, null)} disabled={saving === r.role}
                style={{ fontSize: 10, padding: '3px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 4, cursor: 'pointer' }}>
                Reset to default ({r.default})
              </button>
            )}
            {/* Advanced free-text escape hatch */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginLeft: 'auto' }}>
              <input
                placeholder="custom model id…"
                value={advanced[r.role] || ''}
                onChange={e => setAdvanced({ ...advanced, [r.role]: e.target.value })}
                style={{ fontSize: 10, padding: '3px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, width: 150, outline: 'none' }}
              />
              <button onClick={() => { if (advanced[r.role]?.trim()) setModel(r.role, advanced[r.role].trim()); }}
                disabled={!advanced[r.role]?.trim() || saving === r.role}
                style={{ fontSize: 10, padding: '3px 10px', background: '#1a1a1a', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
                Set
              </button>
            </div>
          </div>
        </div>
      ))}

      <div style={{ fontSize: 10, color: '#aaa', marginTop: 8, lineHeight: 1.5 }}>
        <strong>O</strong> = OpenAI · <strong>A</strong> = Anthropic. The custom field accepts any model id (advanced — make sure you have API access to it, or scans for that role will fail).
      </div>
    </div>
  );
}
