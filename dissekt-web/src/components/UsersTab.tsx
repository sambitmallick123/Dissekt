'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function UsersTab({ adminKey }: { adminKey: string }) {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState('');
  const [busy, setBusy] = useState('');
  const [activityFor, setActivityFor] = useState<string | null>(null);
  const [activity, setActivity] = useState<any>(null);
  const [limitsFor, setLimitsFor] = useState<string | null>(null);
  const [briefLimit, setBriefLimit] = useState('');
  const [detailedLimit, setDetailedLimit] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/admin/users?adminKey=${encodeURIComponent(adminKey)}`);
      const d = await res.json();
      setUsers(d.users || []);
    } catch { setUsers([]); }
    finally { setLoading(false); }
  };

  useEffect(() => { if (adminKey) load(); }, [adminKey]);

  const flash = (m: string) => { setMsg(m); setTimeout(() => setMsg(''), 4000); };

  const post = async (path: string, body: any) => {
    const res = await fetch(`${API_URL}${path}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ adminKey, ...body }),
    });
    return res.json();
  };

  const doSetRole = async (u: any) => {
    const next = u.role === 'admin' ? 'normal' : 'admin';
    if (!confirm(`Set ${u.email} to ${next}?`)) return;
    setBusy(u.id);
    const d = await post('/api/admin/users/set-role', { user_id: u.id, role: next });
    flash(d.success ? `${u.email} is now ${next}` : `Failed: ${d.detail || 'error'}`);
    await load(); setBusy('');
  };

  const doDelete = async (u: any) => {
    if (!confirm(`Delete ${u.email}? This permanently removes their account.`)) return;
    setBusy(u.id);
    const d = await post('/api/admin/users/delete', { user_id: u.id });
    flash(d.success ? `Deleted ${u.email}` : `Failed: ${d.detail || 'error'}`);
    await load(); setBusy('');
  };

  const doBan = async (u: any) => {
    const isBanned = !!u.banned_until && u.banned_until !== 'None' && u.banned_until !== '';
    setBusy(u.id);
    const d = await post('/api/admin/users/ban', { user_id: u.id, ban: !isBanned });
    flash(d.success ? `${isBanned ? 'Unbanned' : 'Banned'} ${u.email}` : `Failed: ${d.detail || 'error'}`);
    await load(); setBusy('');
  };

  const doReset = async (u: any) => {
    setBusy(u.id);
    const d = await post('/api/admin/users/reset-password', { email: u.email });
    flash(d.success ? `Reset email sent to ${u.email}` : `Failed: ${d.detail || 'error'}`);
    setBusy('');
  };

  const doSetLimits = async (u: any) => {
    setBusy(u.id);
    const d = await post('/api/admin/users/set-limits', {
      user_id: u.id,
      brief_limit: briefLimit ? parseInt(briefLimit) : null,
      detailed_limit: detailedLimit ? parseInt(detailedLimit) : null,
    });
    flash(d.success ? `Limits updated for ${u.email}` : `Failed: ${d.detail || 'error'}`);
    setLimitsFor(null); setBriefLimit(''); setDetailedLimit('');
    await load(); setBusy('');
  };

  const viewActivity = async (u: any) => {
    if (activityFor === u.email) { setActivityFor(null); setActivity(null); return; }
    setActivityFor(u.email); setActivity(null);
    const res = await fetch(`${API_URL}/api/admin/users/activity?adminKey=${encodeURIComponent(adminKey)}&email=${encodeURIComponent(u.email)}`);
    setActivity(await res.json());
  };

  if (loading) return <div style={{ padding: 20, color: '#888', fontSize: 13 }}>Loading users…</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ fontSize: 12, color: '#888' }}>{users.length} registered user{users.length !== 1 ? 's' : ''}</div>
        <button onClick={load} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>Refresh</button>
      </div>

      {msg && <div style={{ fontSize: 12, padding: '6px 12px', borderRadius: 6, marginBottom: 10, fontWeight: 600, background: msg.includes('Failed') ? '#fef2f2' : '#f0fdf4', color: msg.includes('Failed') ? '#dc2626' : '#16a34a' }}>{msg}</div>}

      {users.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13 }}>No users yet. They&apos;ll appear here after signing up.</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {users.map(u => {
            const isBanned = !!u.banned_until && u.banned_until !== 'None' && u.banned_until !== '';
            return (
              <div key={u.id} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 8 }}>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>
                      {u.name || '(no name)'} {isBanned && <span style={{ fontSize: 9, color: '#dc2626', background: '#fef2f2', padding: '1px 6px', borderRadius: 4, marginLeft: 6 }}>BANNED</span>} {u.role === 'admin' && <span style={{ fontSize: 9, color: '#0d9488', background: '#f0fdfa', border: '0.5px solid #cce9e3', padding: '1px 7px', borderRadius: 4, marginLeft: 6, fontWeight: 600 }}>ADMIN</span>}
                    </div>
                    <div style={{ fontSize: 12, color: '#888' }}>{u.email}</div>
                    <div style={{ fontSize: 10, color: '#aaa', marginTop: 2 }}>
                      Joined {u.created_at ? new Date(u.created_at).toLocaleDateString() : '?'}
                      {u.last_sign_in_at && ` · Last seen ${new Date(u.last_sign_in_at).toLocaleDateString()}`}
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    <button onClick={() => viewActivity(u)} disabled={busy === u.id} style={btn('#0d9488')}>Activity</button>
                    <button onClick={() => { setLimitsFor(limitsFor === u.id ? null : u.id); }} disabled={busy === u.id} style={btn('#666')}>Limits</button>
                    <button onClick={() => doReset(u)} disabled={busy === u.id} style={btn('#666')}>Reset PW</button>
                    <button onClick={() => doSetRole(u)} disabled={busy === u.id} style={btn(u.role === 'admin' ? '#7c3aed' : '#0d9488')}>{u.role === 'admin' ? 'Make normal' : 'Make admin'}</button>
                    <button onClick={() => doBan(u)} disabled={busy === u.id} style={btn(isBanned ? '#16a34a' : '#d97706')}>{isBanned ? 'Unban' : 'Ban'}</button>
                    <button onClick={() => doDelete(u)} disabled={busy === u.id} style={btn('#dc2626')}>Delete</button>
                  </div>
                </div>

                {limitsFor === u.id && (
                  <div style={{ marginTop: 10, padding: 10, background: '#fafaf8', borderRadius: 8, display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                    <input placeholder="brief/day" value={briefLimit} onChange={e => setBriefLimit(e.target.value)} style={{ width: 80, padding: '5px 8px', fontSize: 12, border: '0.5px solid #d5dada', borderRadius: 5 }} />
                    <input placeholder="detailed/day" value={detailedLimit} onChange={e => setDetailedLimit(e.target.value)} style={{ width: 90, padding: '5px 8px', fontSize: 12, border: '0.5px solid #d5dada', borderRadius: 5 }} />
                    <button onClick={() => doSetLimits(u)} disabled={busy === u.id} style={btn('#0d9488')}>Save limits</button>
                  </div>
                )}

                {activityFor === u.email && (
                  <div style={{ marginTop: 10, padding: 10, background: '#fafaf8', borderRadius: 8, fontSize: 12 }}>
                    {!activity ? <span style={{ color: '#888' }}>Loading activity…</span>
                      : activity.enabled === false ? <span style={{ color: '#888' }}>🔒 Activity viewing is disabled.</span>
                      : (activity.scans || []).length === 0 ? <span style={{ color: '#888' }}>No scans recorded.</span>
                      : <div>
                          <div style={{ fontWeight: 600, marginBottom: 6 }}>{activity.count} recent scan{activity.count !== 1 ? 's' : ''}</div>
                          {(activity.scans || []).slice(0, 10).map((s: any, i: number) => (
                            <div key={i} style={{ padding: '3px 0', borderBottom: '0.5px solid #eee', color: '#555' }}>
                              {s.created_at ? new Date(s.created_at).toLocaleString() : ''} · {(s.input_content || s.mode || '—').toString().slice(0, 50)}
                            </div>
                          ))}
                        </div>}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function btn(color: string): React.CSSProperties {
  return { fontSize: 11, padding: '4px 10px', background: '#fff', border: `0.5px solid ${color}`, color, borderRadius: 5, cursor: 'pointer', fontWeight: 500 };
}
