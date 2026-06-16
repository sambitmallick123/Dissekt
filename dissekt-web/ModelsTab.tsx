'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const COST_COLOR: Record<string, string> = { '$': '#16a34a', '$$': '#d97706', '$$$': '#dc2626', '$$$$': '#991b1b', '?': '#888' };

export default function ModelsTab({ adminKey }: { adminKey: string }) {
  const [roles, setRoles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState('');
  const [advanced, setAdvanced] = useState<Record<string, string>>({});
  const [msg, setMsg] = useState('');
  const [showKeyInfo, setShowKeyInfo] = useState(false);

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
    setMsg('');
    try {
      const res = await fetch(`${API_URL}/api/admin/models`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ adminKey, role, model }),
      });
      const d = await res.json();
      if (d.success) {
        setMsg(`✓ ${role} → ${model || 'default'}`);
        await load();
      } else {
        setMsg(`✗ Failed: ${d.detail || d.error || 'unknown error'}`);
      }
    } catch (e: any) {
      setMsg(`✗ Error: ${e.message}`);
    } finally {
      setSaving('');
      setTimeout(() => setMsg(''), 4000);
    }
  };

  if (loading) return <div style={{ padding: 20, color: '#888', fontSize: 13 }}>Loading model config…</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14, gap: 16, flexWrap: 'wrap' }}>
        <div style={{ fontSize: 12, color: '#888', lineHeight: 1.6, flex: 1, minWidth: 240 }}>
          Assign a model to each pipeline role. Changes take effect on the next scan.
          Cost: <span style={{ color: '#16a34a', fontWeight: 600 }}>$</span> cheap → <span style={{ color: '#991b1b', fontWeight: 600 }}>$$$$</span> premium.
        </div>
        <button onClick={() => setShowKeyInfo(!showKeyInfo)}
          style={{ fontSize: 11, padding: '5px 12px', background: '#f0fdfa', color: '#0d9488', border: '0.5px solid #ccfbf1', borderRadius: 6, cursor: 'pointer', fontWeight: 600, whiteSpace: 'nowrap' }}>
          🔑 API key setup
        </button>
      </div>

      {/* API key info panel */}
      {showKeyInfo && (
        <div style={{ background: '#f8fafc', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 14, fontSize: 12.5, color: '#444', lineHeight: 1.7 }}>
          <div style={{ fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>How to set up provider API keys</div>
          <div style={{ marginBottom: 10 }}>
            <strong style={{ color: '#0d9488' }}>OpenAI</strong> (GPT models):
            <div style={{ marginLeft: 12, color: '#666' }}>
              1. Get a key at <a href="https://platform.openai.com/api-keys" target="_blank" rel="noopener" style={{ color: '#0d9488' }}>platform.openai.com/api-keys</a> → "Create new secret key"<br />
              2. Copy it (starts with <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>sk-proj-…</code>) — shown once only<br />
              3. Add to your env as <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>OPENAI_API_KEY</code> in Railway → Variables (and local <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>.env</code>)
            </div>
          </div>
          <div style={{ marginBottom: 10 }}>
            <strong style={{ color: '#0d9488' }}>Anthropic</strong> (Claude models):
            <div style={{ marginLeft: 12, color: '#666' }}>
              1. Get a key at <a href="https://console.anthropic.com/settings/keys" target="_blank" rel="noopener" style={{ color: '#0d9488' }}>console.anthropic.com/settings/keys</a> → "Create Key"<br />
              2. Copy it (starts with <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>sk-ant-…</code>)<br />
              3. Add as <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>ANTHROPIC_API_KEY</code> in Railway → Variables (and local <code style={{ background: '#eee', padding: '1px 4px', borderRadius: 3 }}>.env</code>)
            </div>
          </div>
          <div style={{ fontSize: 11, color: '#888', borderTop: '0.5px solid #e5eaea', paddingTop: 8 }}>
            After adding a key, redeploy the backend (Railway auto-redeploys on env change). If a role's model uses a provider whose key isn't set, scans for that role will fail.
          </div>
        </div>
      )}

      {/* Save status */}
      {msg && (
        <div style={{ fontSize: 12, padding: '6px 12px', borderRadius: 6, marginBottom: 10, fontWeight: 600,
          background: msg.startsWith('✓') ? '#f0fdf4' : '#fef2f2', color: msg.startsWith('✓') ? '#16a34a' : '#dc2626' }}>
          {msg}
        </div>
      )}

      {roles.map(r => {
        const isCustom = !r.options.some((o: any) => o.id === r.current);
        return (
          <div key={r.role} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14, marginBottom: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
              <div>
                <span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{r.label}</span>
                <span style={{ fontSize: 10, color: '#aaa', marginLeft: 8, fontFamily: 'monospace' }}>{r.role}</span>
                <span style={{ fontSize: 9, color: '#888', marginLeft: 6, padding: '1px 6px', background: '#f0f0ee', borderRadius: 3 }}>{r.capability}</span>
              </div>
              {r.is_override
                ? <span style={{ fontSize: 9, fontWeight: 600, color: '#0d9488', padding: '2px 8px', background: '#f0fdfa', borderRadius: 10 }}>OVERRIDE</span>
                : <span style={{ fontSize: 9, color: '#aaa', padding: '2px 8px', background: '#fafaf8', borderRadius: 10 }}>default</span>}
            </div>

            {/* Dropdown selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
              <select
                value={isCustom ? '__custom__' : r.current}
                onChange={e => { if (e.target.value !== '__custom__') setModel(r.role, e.target.value); }}
                disabled={saving === r.role}
                style={{ flex: 1, minWidth: 240, padding: '8px 12px', borderRadius: 8, fontSize: 13, border: '0.5px solid #d5dada', background: '#fff', color: '#1a1a1a', cursor: 'pointer', outline: 'none' }}
              >
                {r.options.map((o: any) => (
                  <option key={o.id} value={o.id}>
                    {o.label} · {o.cost} · {o.provider === 'anthropic' ? 'Anthropic' : 'OpenAI'}{o.id === r.default ? ' (default)' : ''}
                  </option>
                ))}
                {isCustom && <option value="__custom__">Custom: {r.current}</option>}
              </select>

              {r.is_override && (
                <button onClick={() => setModel(r.role, null)} disabled={saving === r.role}
                  style={{ fontSize: 11, padding: '7px 12px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, cursor: 'pointer', whiteSpace: 'nowrap' }}>
                  Reset to default
                </button>
              )}
            </div>

            {/* Current selection indicator */}
            <div style={{ fontSize: 11, color: '#888', marginTop: 6 }}>
              Currently: <strong style={{ color: '#0d9488' }}>{r.current}</strong>
              {!r.is_override && <span> (tier default)</span>}
            </div>

            {/* Advanced free-text */}
            <details style={{ marginTop: 8 }}>
              <summary style={{ fontSize: 10, color: '#aaa', cursor: 'pointer' }}>Advanced: custom model id</summary>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                <input
                  placeholder="e.g. gpt-4o-2024-11-20"
                  value={advanced[r.role] || ''}
                  onChange={e => setAdvanced({ ...advanced, [r.role]: e.target.value })}
                  style={{ fontSize: 11, padding: '5px 10px', border: '0.5px solid #e5eaea', borderRadius: 4, flex: 1, maxWidth: 240, outline: 'none' }}
                />
                <button onClick={() => { if (advanced[r.role]?.trim()) { setModel(r.role, advanced[r.role].trim()); setAdvanced({ ...advanced, [r.role]: '' }); } }}
                  disabled={!advanced[r.role]?.trim() || saving === r.role}
                  style={{ fontSize: 11, padding: '5px 12px', background: '#1a1a1a', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
                  Set custom
                </button>
              </div>
              <div style={{ fontSize: 10, color: '#bbb', marginTop: 4 }}>Make sure you have API access to this model, or scans for this role will fail.</div>
            </details>
          </div>
        );
      })}
    </div>
  );
}
