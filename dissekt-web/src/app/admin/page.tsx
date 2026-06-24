'use client';
import { useState, useEffect, useCallback } from 'react';
import UsersTab from '@/components/UsersTab';
import SiteHeader from '@/components/SiteHeader';
import FeedsTab from '@/components/FeedsTab';
import ModelsTab from '@/components/ModelsTab';
import SiteFooter from '@/components/SiteFooter';

type Tab = 'users' | 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions' | 'settings' | 'sources' | 'feeds' | 'models';



function SourcesTab() {
  const [sources, setSources] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

  const load = async () => {
    try {
      const res = await fetch(`${API_URL}/api/admin/sources`);
      const data = await res.json();
      setSources(data.sources || []);
    } catch {}
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const action = async (id: string, act: string) => {
    await fetch(`${API_URL}/api/admin/sources/action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, action: act }),
    });
    load();
  };

  if (loading) return <div style={{ padding: 20, textAlign: 'center', color: '#888' }}>Loading...</div>;

  return (
    <div>
      <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Suggested sources ({sources.length})</div>
      {sources.length === 0 && (
        <div style={{ padding: 30, textAlign: 'center', color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No source suggestions yet</div>
      )}
      {sources.map((s, i) => {
        const lines = (s.message || '').split('  ');
        const srcName = lines.find((l: string) => l.startsWith('Source:'))?.replace('Source:', '').trim() || '';
        const srcUrl = lines.find((l: string) => l.startsWith('URL:'))?.replace('URL:', '').trim() || '';
        const srcReason = lines.find((l: string) => l.startsWith('Reason:'))?.replace('Reason:', '').trim() || '';
        const statusColor = s.status === 'approved' ? '#16a34a' : s.status === 'rejected' ? '#dc2626' : '#d97706';
        return (
          <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '12px 16px', marginBottom: 8 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{srcName || 'Unknown source'}</div>
                {srcUrl && <a href={srcUrl} target="_blank" rel="noopener" style={{ fontSize: 11, color: '#0d9488', textDecoration: 'none' }}>{srcUrl}</a>}
                {s.email && <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>Suggested by: {s.email}</div>}
              </div>
              <span style={{ fontSize: 10, fontWeight: 600, color: statusColor, padding: '2px 8px', borderRadius: 4, background: s.status === 'approved' ? '#f0fdf4' : s.status === 'rejected' ? '#fef2f2' : '#fffbeb' }}>
                {s.status || 'pending'}
              </span>
            </div>
            {srcReason && <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5, marginBottom: 8 }}>{srcReason}</div>}
            {(!s.status || s.status === 'unread' || s.status === 'pending') && (
              <div style={{ display: 'flex', gap: 6 }}>
                <button onClick={() => action(s.id, 'approve')}
                  style={{ padding: '5px 14px', background: '#f0fdf4', color: '#16a34a', border: '0.5px solid #dcfce7', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                  ✅ Approve
                </button>
                <button onClick={() => action(s.id, 'reject')}
                  style={{ padding: '5px 14px', background: '#fef2f2', color: '#dc2626', border: '0.5px solid #fecaca', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                  ❌ Reject
                </button>
              </div>
            )}
            <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>{new Date(s.created_at).toLocaleDateString()}</div>
          </div>
        );
      })}
    </div>
  );
}

export default function AdminPage() {
  const [password, setPassword] = useState('');
  const [authenticated, setAuthenticated] = useState(false);
  const [adminKey, setAdminKey] = useState('');
  const [tab, setTab] = useState<Tab>('overview');

  const login = async () => {
    const res = await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'login', password }),
    });
    const data = await res.json();
    if (data.success) { setAuthenticated(true); setAdminKey(password); if (typeof window !== 'undefined') localStorage.setItem('dissekt_admin', 'true'); }
    else alert('Invalid password');
  };

  if (!authenticated) {
    return (
      <main style={{ flex: 1, background: '#fafaf8' }}>
        <SiteHeader />
        <div style={{ maxWidth: 400, margin: '80px auto', padding: '0 24px' }}>
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 28 }}>
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{ width: 48, height: 48, background: '#f0fdfa', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: 22 }}>🔐</div>
              <div style={{ fontSize: 18, fontWeight: 600 }}>Admin access</div>
              <div style={{ fontSize: 13, color: '#888', marginTop: 4 }}>Enter admin password</div>
            </div>
            <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && login()}
              style={{ width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fafaf8', marginBottom: 12, boxSizing: 'border-box' as any }} />
            <button onClick={login} style={{ width: '100%', padding: '10px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Sign in</button>
          </div>
        </div>
        <SiteFooter />
      </main>
    );
  }

  const tabLabels: Record<Tab, string> = {
    overview: '📊 Overview', users: '👤 Users', invitations: '🎟️ Invitations', feedback: '💬 Feedback',
    contacts: '📧 Contacts', corrections: '👍 Corrections', decisions: '📓 Decisions', models: '🤖 Models', settings: '⚙️ Settings', sources: '📡 Sources', feeds: '📰 Feeds',
  };
  const TAB_GROUPS: { id: string; label: string; tabs: Tab[] }[] = [
    { id: 'monitor', label: '📊 Monitor', tabs: ['overview', 'decisions'] },
    { id: 'people',  label: '👥 People',  tabs: ['users', 'feedback', 'contacts', 'corrections'] },
    { id: 'content', label: '🗂️ Content', tabs: ['sources', 'feeds'] },
    { id: 'config',  label: '⚙️ Config',  tabs: ['models', 'settings'] },
  ];
  const activeGroup = TAB_GROUPS.find(g => g.tabs.includes(tab)) || TAB_GROUPS[0];

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>Admin</span>
              <span style={{ fontSize: 9, padding: '2px 8px', background: '#f0fdfa', color: '#0d9488', borderRadius: 4, fontWeight: 600 }}>LIVE</span>
            </div>
          <button onClick={() => { setAuthenticated(false); setAdminKey(''); if (typeof window !== 'undefined') localStorage.removeItem('dissekt_admin'); }} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#dc2626' }}>Sign out</button>
        </div>
        {/* Top-level group tabs */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 10, flexWrap: 'wrap' }}>
          {TAB_GROUPS.map(g => {
            const isActive = g.id === activeGroup.id;
            return (
              <button key={g.id}
                onClick={() => { if (!g.tabs.includes(tab)) setTab(g.tabs[0]); }}
                style={{ padding: '8px 18px', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer',
                  background: isActive ? '#0d9488' : '#fff', color: isActive ? '#fff' : '#555',
                  boxShadow: isActive ? 'none' : '0 0 0 0.5px #e5eaea', whiteSpace: 'nowrap' }}>
                {g.label}
              </button>
            );
          })}
        </div>
        {/* Sub-tabs for the active group */}
        <div style={{ display: 'flex', gap: 0, marginBottom: 16, borderBottom: '0.5px solid #e5eaea', flexWrap: 'wrap', overflowX: 'auto', WebkitOverflowScrolling: 'touch' }}>
          {activeGroup.tabs.map(t => (
            <button key={t} onClick={() => setTab(t)}
              style={{ padding: '8px 16px', borderRadius: 0, fontSize: 12.5, fontWeight: 500, border: 'none', cursor: 'pointer', background: 'transparent',
                color: tab === t ? '#0d9488' : '#888', borderBottom: tab === t ? '2px solid #0d9488' : '2px solid transparent', whiteSpace: 'nowrap' }}>
              {tabLabels[t]}
            </button>
          ))}
        </div>
        {tab === 'overview' && <OverviewTab adminKey={adminKey} setTab={setTab} />}
        {tab === 'users' && <UsersTab adminKey={adminKey} />}
        {tab === 'invitations' && <InvitationsTab adminKey={adminKey} />}
        {tab === 'feedback' && <FeedbackTab adminKey={adminKey} />}
        {tab === 'contacts' && <ContactsTab adminKey={adminKey} />}
        {tab === 'corrections' && <CorrectionsTab adminKey={adminKey} />}
        {tab === 'decisions' && <DecisionsTab adminKey={adminKey} />}
        {tab === 'feeds' && <FeedsTab adminKey={adminKey} />}
        {tab === 'sources' && <SourcesTab />}
        {tab === 'models' && <ModelsTab adminKey={adminKey} />}
        {tab === 'settings' && <SettingsTab adminKey={adminKey} />}
      </div>
      <SiteFooter />
    </main>
  );
}

function OverviewTab({ adminKey, setTab }: { adminKey: string; setTab: (t: any) => void }) {
  const [stats, setStats] = useState<any>({});
  const [users, setUsers] = useState<any[]>([]);
  const [newPw, setNewPw] = useState('');

  useEffect(() => {
    fetch(`/api/admin?view=stats&key=${encodeURIComponent(adminKey)}`)
      .then(r => r.json()).then(d => setStats(d || {})).catch(() => {});
    // users for the overview table come from the FastAPI admin list (Supabase Auth)
    const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    fetch(`${API}/api/admin/users?adminKey=${encodeURIComponent(adminKey)}`)
      .then(r => r.json()).then(d => setUsers(d.users || [])).catch(() => {});
  }, [adminKey]);

  const changePassword = async () => {
    if (!newPw) return;
    await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'change_password', adminKey, newPassword: newPw }) });
    setNewPw('');
    alert('Password changed');
  };

  const Spark = ({ color }: { color: string }) => {
    const bars = [4, 7, 5, 10, 8, 14, 11];
    return (
      <div style={{ height: 16, display: 'flex', alignItems: 'flex-end', gap: 1.5, marginTop: 4 }}>
        {bars.map((h, i) => (
          <div key={i} style={{ width: 3, height: h, background: i >= bars.length - 3 ? color : '#e5eaea', borderRadius: 1 }} />
        ))}
      </div>
    );
  };

  const inv = stats.invitations || {};
  const metrics = [
    { label: 'Users', value: users.length ?? 0, color: '#16a34a', spark: true, trend: '' },
    { label: 'Approved', value: inv.approved ?? 0, color: '#2563eb', spark: false, trend: '' },
    { label: 'Pending', value: inv.pending ?? 0, color: '#d97706', spark: false, trend: '' },
    { label: 'Feedback', value: stats.feedback ?? 0, color: '#7c3aed', spark: false, trend: '' },
    { label: 'Contacts', value: stats.contacts ?? 0, color: '#0d9488', spark: false, trend: '' },
    { label: 'Corrections', value: stats.corrections ?? 0, color: '#dc2626', spark: false, trend: '' },
  ];

  return (
    <div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 14, flexWrap: 'wrap' }}>
        {metrics.map(m => (
          <div key={m.label} style={{ flex: '1 1 110px', minWidth: 110, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '10px 12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 9, color: '#888', textTransform: 'uppercase', letterSpacing: '0.04em' }}>{m.label}</span>
              {m.trend && <span style={{ fontSize: 9, color: '#16a34a' }}>{m.trend}</span>}
            </div>
            <div style={{ fontSize: 20, fontWeight: 700, color: m.color }}>{m.value}</div>
            {m.spark && <Spark color={m.color} />}
          </div>
        ))}
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, overflow: 'hidden', marginBottom: 14 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 70px', padding: '7px 14px', background: '#f8fafa', fontSize: 10, color: '#888', fontWeight: 600 }}>
          <span>User</span><span>Joined</span><span></span>
        </div>
        {users.length === 0 && (<div style={{ padding: 20, textAlign: 'center', color: '#888', fontSize: 12 }}>No users yet</div>)}
        {users.map((u, i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 70px', padding: '9px 14px', fontSize: 11, borderTop: '0.5px solid #f0f0ee', alignItems: 'center' }}>
            <span style={{ fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.email || u.user_email || '—'}</span>
            <span style={{ color: '#888' }}>{u.created_at ? new Date(u.created_at).toLocaleDateString('en', { month: 'short', day: 'numeric' }) : '—'}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              <span onClick={() => setTab('users')} title="Manage user" style={{ fontSize: 10, padding: '2px 6px', background: '#f0fdfa', color: '#0d9488', borderRadius: 3, cursor: 'pointer' }}>⚙</span>
            </div>
          </div>
        ))}
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 14 }}>🔑</span>
          <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>Security</span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <input type="password" placeholder="New password" value={newPw} onChange={e => setNewPw(e.target.value)} style={{ padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 11, outline: 'none', width: 140 }} />
          <button onClick={changePassword} style={{ fontSize: 11, padding: '6px 14px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>Change password</button>
        </div>
      </div>
    </div>
  );
}

function InvitationsTab({ adminKey }: { adminKey: string }) {
  const [items, setItems] = useState<any[]>([]);
  const [filter, setFilter] = useState('pending');
  const [stats, setStats] = useState({ total: 0, pending: 0, approved: 0, rejected: 0 });
  const [msg, setMsg] = useState('');
  const [genEmail, setGenEmail] = useState('');
  const [genName, setGenName] = useState('');
  const [genResult, setGenResult] = useState('');
  const [editUser, setEditUser] = useState<any>(null);
  const [editUserFeatures, setEditUserFeatures] = useState<string[]>([]);
  const [editUserLimits, setEditUserLimits] = useState({ brief: 0, detailed: 0 });
  const [accessMsg, setAccessMsg] = useState('');
  const [emailUser, setEmailUser] = useState<any>(null);
  const [emailSubject, setEmailSubject] = useState('');
  const [emailBody, setEmailBody] = useState('');
  const [emailMsg, setEmailMsg] = useState('');

  const openEditUser = (inv: any) => {
    setEditUser(inv);
    setEditUserFeatures(inv.custom_features || []);
    setEditUserLimits(inv.custom_limits || { brief: 0, detailed: 0 });
    setAccessMsg('');
  };

  const saveUserAccess = async () => {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    await fetch(`${API_URL}/api/admin/user-access`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: editUser.id,
        custom_features: editUserFeatures.length > 0 ? editUserFeatures : null,
        custom_limits: (editUserLimits.brief > 0 || editUserLimits.detailed > 0) ? editUserLimits : null,
      }),
    });
    setAccessMsg('✅ Saved');
    load();
  };

  const openEmailUser = (inv: any) => {
    setEmailUser(inv);
    setEmailSubject('');
    setEmailBody('');
    setEmailMsg('');
  };

  const sendUserEmail = async () => {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const res = await fetch(`${API_URL}/api/admin/send-message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ to: emailUser.email, subject: emailSubject || 'Message from Dissekt', message: emailBody }),
    });
    const data = await res.json();
    setEmailMsg(data.success ? '✅ Email sent' : '❌ Failed to send');
  };
  const load = useCallback(async () => {
    const res = await fetch(`/api/admin?key=${adminKey}&status=${filter}`);
    const data = await res.json();
    setItems(data.invitations || []); setStats(data.stats || stats);
  }, [adminKey, filter]);
  useEffect(() => { load(); }, [load]);
  const action = async (id: string, act: 'approve' | 'reject' | 'revoke') => {
    setMsg('');
    const res = await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: act, id }) });
    const data = await res.json();
    setMsg(act === 'approve' ? `✅ Approved! Code: ${data.code} · Email sent` : act === 'revoke' ? '🚫 Revoked · User notified' : '❌ Rejected · User notified');
    load();
  };
  const generate = async () => {
    const res = await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'generate', email: genEmail, name: genName }) });
    const data = await res.json();
    if (data.success) { setGenResult(data.code); setGenEmail(''); setGenName(''); load(); }
  };
  const sc: Record<string, { bg: string; color: string }> = { pending: { bg: '#fffbeb', color: '#92400e' }, approved: { bg: '#f0fdf4', color: '#166534' }, rejected: { bg: '#fef2f2', color: '#b91c1c' } };
  return (
    <div>
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Generate invite</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <input placeholder="Email" value={genEmail} onChange={e => setGenEmail(e.target.value)} style={{ flex: 1, padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none' }} />
          <input placeholder="Name" value={genName} onChange={e => setGenName(e.target.value)} style={{ flex: 1, padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none' }} />
          <button onClick={generate} style={{ padding: '8px 16px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' }}>Generate + send</button>
        </div>
        {genResult && <div style={{ marginTop: 8, padding: 8, background: '#f0fdf4', borderRadius: 6, fontSize: 13, fontWeight: 600, color: '#166534', textAlign: 'center' }}>{genResult}</div>}
      </div>
      {msg && <div style={{ padding: 10, background: '#f0fdfa', borderRadius: 8, fontSize: 13, color: '#0d9488', marginBottom: 12 }}>{msg}</div>}
      <div style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
        {['pending', 'approved', 'rejected', 'all'].map(s => (
          <button key={s} onClick={() => setFilter(s)} style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: filter === s ? '#0d9488' : '#fff', color: filter === s ? '#fff' : '#555', boxShadow: filter !== s ? '0 0 0 0.5px #e5eaea' : 'none' }}>
            {s.charAt(0).toUpperCase() + s.slice(1)} {s === 'pending' && stats.pending > 0 ? `(${stats.pending})` : ''}
          </button>
        ))}
      </div>
      {items.map((inv, i) => {
        const s = sc[inv.status] || sc.pending;
        return (
          <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '12px 16px', marginBottom: 6 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
                  <span style={{ fontWeight: 600, fontSize: 14 }}>{inv.name || 'No name'}</span>
                  <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 5, background: s.bg, color: s.color, fontWeight: 600 }}>{inv.status}</span>
                </div>
                <div style={{ fontSize: 12, color: '#555' }}>{inv.email}</div>
                {inv.organization && <div style={{ fontSize: 11, color: '#888' }}>🏢 {inv.organization}</div>}
                {inv.reason && <div style={{ fontSize: 11, color: '#888', fontStyle: 'italic', marginTop: 2 }}>{inv.reason}</div>}
                <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>
                  {new Date(inv.created_at).toLocaleDateString()}
                  {inv.invite_code && <span style={{ marginLeft: 8, color: '#0d9488', fontWeight: 600 }}>{inv.invite_code}</span>}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                {inv.status === 'pending' && (<>
                  <button onClick={() => action(inv.id, 'approve')} style={{ padding: '6px 14px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>✅ Approve</button>
                  <button onClick={() => action(inv.id, 'reject')} style={{ padding: '6px 14px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>❌ Reject</button>
                </>)}
                {inv.status === 'approved' && (
                  <>
                    <button onClick={() => openEditUser(inv)} style={{ padding: '6px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>⚙️ Access</button>
                    <button onClick={() => openEmailUser(inv)} style={{ padding: '6px 10px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>📧 Email</button>
                    <button onClick={() => action(inv.id, 'revoke')} style={{ padding: '6px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>🚫 Revoke</button>
                  </>
                )}
                {inv.status === 'pending' && (
                  <button onClick={() => openEmailUser(inv)} style={{ padding: '6px 10px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>📧 Email</button>
                )}
              </div>
            </div>
          </div>
        );
      })}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No {filter} invitations</div>}

      {/* Per-user access modal */}
      {editUser && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setEditUser(null)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 10, padding: 24, maxWidth: 480, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div><div style={{ fontSize: 15, fontWeight: 600 }}>{editUser.name || 'User'}</div><div style={{ fontSize: 12, color: '#888' }}>{editUser.email}</div></div>
              <button onClick={() => setEditUser(null)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', color: '#888' }}>✕</button>
            </div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>Component access (overrides tier defaults)</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, marginBottom: 14 }}>
              {['single_scan','bulk','compare','topics','radar','detailed_mode','image_upload','camera_upload','memory','journal','compass','pulse','counterfactual','claims'].map(f => (
                <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, cursor: 'pointer' }}>
                  <input type="checkbox" checked={(editUserFeatures).includes(f)}
                    onChange={e => setEditUserFeatures(prev => e.target.checked ? [...prev, f] : prev.filter(x => x !== f))} />
                  {f.replace(/_/g, ' ')}
                </label>
              ))}
            </div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>Custom limits (leave 0 for tier default)</div>
            <div style={{ display: 'flex', gap: 10, marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 11 }}>Brief:</span><input type="number" value={editUserLimits.brief} onChange={e => setEditUserLimits(prev => ({ ...prev, brief: parseInt(e.target.value) || 0 }))} style={{ width: 60, padding: '4px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 12, outline: 'none' }} /></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 11 }}>Detailed:</span><input type="number" value={editUserLimits.detailed} onChange={e => setEditUserLimits(prev => ({ ...prev, detailed: parseInt(e.target.value) || 0 }))} style={{ width: 60, padding: '4px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 12, outline: 'none' }} /></div>
            </div>
            {accessMsg && <div style={{ fontSize: 12, color: '#0d9488', marginBottom: 8 }}>{accessMsg}</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={saveUserAccess} style={{ flex: 1, padding: '8px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Save access</button>
              <button onClick={() => { setEditUserFeatures([]); setEditUserLimits({ brief: 0, detailed: 0 }); saveUserAccess(); }} style={{ padding: '8px 14px', background: '#fef2f2', color: '#b91c1c', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Reset to tier default</button>
            </div>
          </div>
        </div>
      )}

      {/* Email modal */}
      {emailUser && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setEmailUser(null)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 10, padding: 24, maxWidth: 480, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div><div style={{ fontSize: 15, fontWeight: 600 }}>Message to {emailUser.name || emailUser.email}</div></div>
              <button onClick={() => setEmailUser(null)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', color: '#888' }}>✕</button>
            </div>
            <input value={emailSubject} onChange={e => setEmailSubject(e.target.value)} placeholder="Subject"
              style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
            <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} placeholder="Your message..." rows={5}
              style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', resize: 'vertical', marginBottom: 8, boxSizing: 'border-box' as any, fontFamily: 'inherit' }} />
            {emailMsg && <div style={{ fontSize: 12, color: '#0d9488', marginBottom: 8 }}>{emailMsg}</div>}
            <button onClick={sendUserEmail} disabled={!emailBody.trim()}
              style={{ width: '100%', padding: '8px 0', background: emailBody.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: emailBody.trim() ? 'pointer' : 'not-allowed' }}>
              Send email
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function FeedbackTab({ adminKey }: { adminKey: string }) {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => { fetch(`/api/admin?key=${adminKey}&view=feedback`).then(r => r.json()).then(d => setItems(d.items || [])); }, [adminKey]);
  const markStatus = async (id: string, status: string) => {
    await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'mark_status', table: 'feedback', id, status }) });
    setItems(prev => prev.map(i => i.id === id ? { ...i, status } : i));
  };
  const typeIcons: Record<string, string> = { feedback: '💬', bug: '🐛', feature: '💡', question: '❓' };
  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>{items.length} feedback submissions</div>
      {items.map((fb, i) => (
        <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '12px 16px', marginBottom: 6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4, flexWrap: 'wrap' }}>
                <span>{typeIcons[fb.type] || '💬'}</span>
                <span style={{ fontSize: 12, fontWeight: 600 }}>{fb.name || 'Anonymous'}</span>
                {fb.component && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#f0fdfa', color: '#0d9488' }}>{fb.component}</span>}
                {fb.type && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#eff6ff', color: '#2563eb' }}>{fb.type}</span>}
                <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: fb.status === 'read' ? '#f0fdf4' : '#fffbeb', color: fb.status === 'read' ? '#166534' : '#92400e' }}>{fb.status || 'unread'}</span>
              </div>
              {fb.email && <div style={{ fontSize: 11, color: '#888' }}>{fb.email}</div>}
              <div style={{ fontSize: 12, color: '#404040', marginTop: 4, lineHeight: 1.6 }}>{fb.message}</div>
              <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>{new Date(fb.created_at).toLocaleString()}</div>
            </div>
            <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
              {fb.status !== 'read' && <button onClick={() => markStatus(fb.id, 'read')} style={{ padding: '4px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, fontSize: 10, cursor: 'pointer', fontWeight: 600 }}>Mark read</button>}
              {fb.email && <a href={`mailto:${fb.email}?subject=Re: Dissekt feedback`} style={{ padding: '4px 10px', background: '#eff6ff', color: '#2563eb', borderRadius: 5, fontSize: 10, textDecoration: 'none', fontWeight: 600 }}>Reply</a>}
            </div>
          </div>
        </div>
      ))}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No feedback yet</div>}
    </div>
  );
}

function ContactsTab({ adminKey }: { adminKey: string }) {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => { fetch(`/api/admin?key=${adminKey}&view=contacts`).then(r => r.json()).then(d => setItems(d.items || [])); }, [adminKey]);
  const markStatus = async (id: string, status: string) => {
    await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'mark_status', table: 'contacts', id, status }) });
    setItems(prev => prev.map(i => i.id === id ? { ...i, status } : i));
  };
  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>{items.length} contact messages</div>
      {items.map((ct, i) => (
        <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '12px 16px', marginBottom: 6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                <span>📧</span>
                <span style={{ fontSize: 12, fontWeight: 600 }}>{ct.name || 'Anonymous'}</span>
                {ct.subject && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#f0fdfa', color: '#0d9488' }}>{ct.subject}</span>}
                <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: ct.status === 'replied' ? '#f0fdf4' : ct.status === 'read' ? '#eff6ff' : '#fffbeb', color: ct.status === 'replied' ? '#166534' : ct.status === 'read' ? '#2563eb' : '#92400e' }}>{ct.status || 'unread'}</span>
              </div>
              {ct.email && <div style={{ fontSize: 11, color: '#888' }}>{ct.email}</div>}
              <div style={{ fontSize: 12, color: '#404040', marginTop: 4, lineHeight: 1.6 }}>{ct.message}</div>
              <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>{new Date(ct.created_at).toLocaleString()}</div>
            </div>
            <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
              {ct.status === 'unread' && <button onClick={() => markStatus(ct.id, 'read')} style={{ padding: '4px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, fontSize: 10, cursor: 'pointer', fontWeight: 600 }}>Mark read</button>}
              {ct.email && <a href={`mailto:${ct.email}?subject=Re: ${ct.subject || 'Dissekt inquiry'}`} onClick={() => markStatus(ct.id, 'replied')} style={{ padding: '4px 10px', background: '#0d9488', color: '#fff', borderRadius: 5, fontSize: 10, textDecoration: 'none', fontWeight: 600 }}>Reply</a>}
            </div>
          </div>
        </div>
      ))}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No contact messages yet</div>}
    </div>
  );
}

function CorrectionsTab({ adminKey }: { adminKey: string }) {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => { fetch(`/api/admin?key=${adminKey}&view=corrections`).then(r => r.json()).then(d => setItems(d.items || [])); }, [adminKey]);
  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>{items.length} technique corrections (training data for Cortex)</div>
      {items.map((c, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '8px 14px', marginBottom: 4 }}>
          <span style={{ fontSize: 14 }}>{c.vote === 'agree' ? '👍' : '👎'}</span>
          <div style={{ flex: 1 }}>
            <span style={{ fontSize: 12, fontWeight: 600 }}>{c.technique_name?.replace(/_/g, ' ')}</span>
            {c.comment && <span style={{ fontSize: 11, color: '#888', marginLeft: 8 }}>{c.comment}</span>}
          </div>
          <span style={{ fontSize: 10, color: '#aaa' }}>{new Date(c.created_at).toLocaleDateString()}</span>
        </div>
      ))}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No corrections yet</div>}
    </div>
  );
}

function DecisionsTab({ adminKey }: { adminKey: string }) {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => { fetch(`/api/admin?key=${adminKey}&view=decisions`).then(r => r.json()).then(d => setItems(d.items || [])); }, [adminKey]);
  const icons: Record<string, string> = { trust: '✅', unsure: '🤔', reject: '❌' };
  const colors: Record<string, { bg: string; color: string }> = { trust: { bg: '#f0fdf4', color: '#166534' }, unsure: { bg: '#fffbeb', color: '#92400e' }, reject: { bg: '#fef2f2', color: '#b91c1c' } };
  return (
    <div>
      <div style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>{items.length} user decisions</div>
      {items.map((d, i) => {
        const c = colors[d.decision] || colors.unsure;
        return (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, background: c.bg, border: '0.5px solid #e5eaea', borderRadius: 8, padding: '8px 14px', marginBottom: 4 }}>
            <span style={{ fontSize: 14 }}>{icons[d.decision]}</span>
            <div style={{ flex: 1 }}>
              <span style={{ fontSize: 12, color: '#404040' }}>{d.input_preview}</span>
              {d.note && <span style={{ fontSize: 11, color: '#888', marginLeft: 8 }}>Note: {d.note}</span>}
            </div>
            <span style={{ fontSize: 10, color: '#aaa' }}>{new Date(d.created_at).toLocaleDateString()}</span>
          </div>
        );
      })}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No decisions yet</div>}
    </div>
  );
}

function SettingsTab({ adminKey }: { adminKey: string }) {
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);
  const [saveMsg, setSaveMsg] = useState('');
  const [freeBrief, setFreeBrief] = useState(3);
  const [freeDetailed, setFreeDetailed] = useState(1);
  const [invBrief, setInvBrief] = useState(25);
  const [invDetailed, setInvDetailed] = useState(10);
  const [codeDays, setCodeDays] = useState(7);
  const [accessMonths, setAccessMonths] = useState(6);
  const [featuresFree, setFeaturesFree] = useState<string[]>(['single_scan', 'radar']);
  const [featuresInv, setFeaturesInv] = useState<string[]>(['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'image_upload', 'camera_upload']);

  useEffect(() => {
    fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'get_config' }) })
      .then(r => r.json()).then(d => {
        const c = d.config || {};
        if (c.free_limits) { setFreeBrief(c.free_limits.brief ?? 3); setFreeDetailed(c.free_limits.detailed ?? 1); }
        if (c.invited_limits) { setInvBrief(c.invited_limits.brief ?? 25); setInvDetailed(c.invited_limits.detailed ?? 10); }
        if (c.invite_code_days) setCodeDays(c.invite_code_days);
        if (c.access_months) setAccessMonths(c.access_months);
        if (c.features_free) setFeaturesFree(c.features_free);
        if (c.features_invited) setFeaturesInv(c.features_invited);
        setLoading(false);
      }).catch(() => setLoading(false));
  }, [adminKey]);

  const markDirty = () => { setDirty(true); setSaveMsg(''); };

  const toggleFree = (key: string) => {
    setFeaturesFree(prev => prev.includes(key) ? prev.filter(x => x !== key) : [...prev, key]);
    markDirty();
  };

  const toggleInv = (key: string) => {
    setFeaturesInv(prev => prev.includes(key) ? prev.filter(x => x !== key) : [...prev, key]);
    markDirty();
  };

  const applyChanges = async () => {
    setSaveMsg('Saving...');
    const updates: [string, any][] = [
      ['free_limits', { brief: freeBrief, detailed: freeDetailed }],
      ['invited_limits', { brief: invBrief, detailed: invDetailed }],
      ['invite_code_days', codeDays],
      ['access_months', accessMonths],
      ['features_free', featuresFree],
      ['features_invited', featuresInv],
    ];
    for (const [key, value] of updates) {
      await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'update_config', key, value }) });
    }
    setDirty(false);
    setSaveMsg('✅ Changes applied — live on all pages now');
    setTimeout(() => setSaveMsg(''), 4000);
  };

  if (loading) return <div style={{ color: '#888', fontSize: 13 }}>Loading...</div>;

  const toggleable = [
    { key: 'single_scan', label: 'Single scan' },
    { key: 'bulk', label: 'Bulk CSV analysis' },
    { key: 'compare', label: 'Compare sources' },
    { key: 'topics', label: 'Topic tracking' },
    { key: 'radar', label: 'Scope feeds' },
    { key: 'detailed_mode', label: 'Detailed mode' },
    { key: 'image_upload', label: 'Image upload' },
    { key: 'camera_upload', label: 'Camera upload' },
    { key: 'memory', label: 'Recall' },
    { key: 'journal', label: 'Ledger' },
    { key: 'compass', label: 'Meridian (political)' },
    { key: 'pulse', label: 'Flare (coordination)' },
    { key: 'counterfactual', label: 'Mirror view' },
    { key: 'claims', label: 'Facet extraction' },
  ];

  const inp: React.CSSProperties = { padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', width: 80, textAlign: 'center' as const };

  return (
    <div>
      {dirty && (
        <div style={{ position: 'sticky', top: 48, zIndex: 20, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', background: '#0d9488', borderRadius: 8, marginBottom: 12 }}>
          <span style={{ fontSize: 13, color: '#fff', fontWeight: 500 }}>You have unsaved changes</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => { setDirty(false); setSaveMsg(''); }} style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Discard</button>
            <button onClick={applyChanges} style={{ padding: '6px 14px', background: '#fff', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Apply changes</button>
          </div>
        </div>
      )}
      {saveMsg && !dirty && <div style={{ padding: 10, background: '#f0fdfa', borderRadius: 8, fontSize: 13, color: '#0d9488', marginBottom: 12 }}>{saveMsg}</div>}

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>📊 Scan limits (per day, resets 00:00 GMT)</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>🆓 Free tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={freeBrief} onChange={e => { setFreeBrief(parseInt(e.target.value) || 0); markDirty(); }} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={freeDetailed} onChange={e => { setFreeDetailed(parseInt(e.target.value) || 0); markDirty(); }} style={inp} /></div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>🎫 Invited tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={invBrief} onChange={e => { setInvBrief(parseInt(e.target.value) || 0); markDirty(); }} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={invDetailed} onChange={e => { setInvDetailed(parseInt(e.target.value) || 0); markDirty(); }} style={inp} /></div>
          </div>
        </div>
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>⏰ Access expiry</div>
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Code expires:</span><input type="number" value={codeDays} onChange={e => { setCodeDays(parseInt(e.target.value) || 7); markDirty(); }} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>days</span></div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Access valid:</span><input type="number" value={accessMonths} onChange={e => { setAccessMonths(parseInt(e.target.value) || 6); markDirty(); }} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>months</span></div>
        </div>
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>🔒 Component access by tier</div>
        <div style={{ fontSize: 11, color: '#888', marginBottom: 12 }}>Help and Feedback are always available to all users.</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>🆓 Free</div>
            {toggleable.map(f => (
              <label key={f.key} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4, fontSize: 12, cursor: 'pointer' }}>
                <input type="checkbox" checked={featuresFree.includes(f.key)} onChange={() => toggleFree(f.key)} />
                {f.label}
              </label>
            ))}
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>🎫 Invited</div>
            {toggleable.map(f => (
              <label key={f.key} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4, fontSize: 12, cursor: 'pointer' }}>
                <input type="checkbox" checked={featuresInv.includes(f.key)} onChange={() => toggleInv(f.key)} />
                {f.label}
              </label>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
