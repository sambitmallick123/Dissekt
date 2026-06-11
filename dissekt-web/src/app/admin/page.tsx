'use client';
import { useState, useEffect, useCallback } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions' | 'settings';

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
    if (data.success) { setAuthenticated(true); setAdminKey(password); }
    else alert('Invalid password');
  };

  if (!authenticated) {
    return (
      <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
        <SiteHeader />
        <div style={{ maxWidth: 400, margin: '80px auto', padding: '0 24px' }}>
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 28 }}>
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{ width: 48, height: 48, background: '#f0fdfa', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: 22 }}>🔐</div>
              <div style={{ fontSize: 18, fontWeight: 600 }}>Admin access</div>
              <div style={{ fontSize: 13, color: '#888', marginTop: 4 }}>Enter admin password</div>
            </div>
            <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && login()}
              style={{ width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8fafa', marginBottom: 12, boxSizing: 'border-box' as any }} />
            <button onClick={login} style={{ width: '100%', padding: '10px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Sign in</button>
          </div>
        </div>
        <SiteFooter />
      </main>
    );
  }

  const tabLabels: Record<Tab, string> = {
    overview: '📊 Overview', invitations: '🎟️ Invitations', feedback: '💬 Feedback',
    contacts: '📧 Contacts', corrections: '👍 Corrections', decisions: '📓 Decisions', settings: '⚙️ Settings',
  };

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 1000, margin: '0 auto', padding: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h1 style={{ fontSize: 22, fontWeight: 700 }}>Admin dashboard</h1>
          <button onClick={() => { setAuthenticated(false); setAdminKey(''); }} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#dc2626' }}>Sign out</button>
        </div>
        <div style={{ display: 'flex', gap: 4, marginBottom: 20, overflowX: 'auto' }}>
          {(Object.keys(tabLabels) as Tab[]).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: '7px 16px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === t ? '#0d9488' : '#fff', color: tab === t ? '#fff' : '#555', boxShadow: tab !== t ? '0 0 0 0.5px #e5eaea' : 'none', whiteSpace: 'nowrap' }}>
              {tabLabels[t]}
            </button>
          ))}
        </div>
        {tab === 'overview' && <OverviewTab adminKey={adminKey} />}
        {tab === 'invitations' && <InvitationsTab adminKey={adminKey} />}
        {tab === 'feedback' && <FeedbackTab adminKey={adminKey} />}
        {tab === 'contacts' && <ContactsTab adminKey={adminKey} />}
        {tab === 'corrections' && <CorrectionsTab adminKey={adminKey} />}
        {tab === 'decisions' && <DecisionsTab adminKey={adminKey} />}
        {tab === 'settings' && <SettingsTab adminKey={adminKey} />}
      </div>
      <SiteFooter />
    </main>
  );
}

function OverviewTab({ adminKey }: { adminKey: string }) {
  const [stats, setStats] = useState<any>(null);
  const [showPw, setShowPw] = useState(false);
  const [newPw, setNewPw] = useState('');
  const [pwMsg, setPwMsg] = useState('');
  useEffect(() => { fetch(`/api/admin?key=${adminKey}&view=stats`).then(r => r.json()).then(setStats); }, [adminKey]);
  const changePw = async () => {
    const res = await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'change_password', new_password: newPw }) });
    const data = await res.json();
    setPwMsg(data.message || data.error);
  };
  if (!stats) return <div style={{ color: '#888', fontSize: 13 }}>Loading...</div>;
  const cards = [
    { label: 'Pending invites', value: stats.invitations?.pending || 0, color: '#d97706', icon: '⏳' },
    { label: 'Approved users', value: stats.invitations?.approved || 0, color: '#16a34a', icon: '✅' },
    { label: 'Rejected', value: stats.invitations?.rejected || 0, color: '#dc2626', icon: '❌' },
    { label: 'Total invitations', value: stats.invitations?.total || 0, color: '#0d9488', icon: '🎟️' },
    { label: 'Feedback', value: stats.feedback || 0, color: '#2563eb', icon: '💬' },
    { label: 'Contacts', value: stats.contacts || 0, color: '#0d9488', icon: '📧' },
    { label: 'Corrections', value: stats.corrections || 0, color: '#ea580c', icon: '👍' },
    { label: 'Decisions', value: stats.decisions || 0, color: '#0891b2', icon: '📓' },
  ];
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 20 }}>
        {cards.map((c, i) => (
          <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}><span style={{ fontSize: 11, color: '#888' }}>{c.label}</span><span style={{ fontSize: 14 }}>{c.icon}</span></div>
            <div style={{ fontSize: 26, fontWeight: 700, color: c.color, marginTop: 4 }}>{c.value}</div>
          </div>
        ))}
      </div>
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: 14, fontWeight: 600 }}>🔑 Security</div>
          <button onClick={() => setShowPw(!showPw)} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>{showPw ? 'Cancel' : 'Change password'}</button>
        </div>
        {showPw && (
          <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
            <input type="password" placeholder="New password (8+ chars)" value={newPw} onChange={e => setNewPw(e.target.value)} style={{ flex: 1, padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none' }} />
            <button onClick={changePw} disabled={newPw.length < 8} style={{ padding: '8px 16px', background: newPw.length >= 8 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: newPw.length >= 8 ? 'pointer' : 'not-allowed' }}>Update</button>
          </div>
        )}
        {pwMsg && <div style={{ marginTop: 6, fontSize: 12, color: '#0d9488' }}>{pwMsg}</div>}
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
                  <button onClick={() => action(inv.id, 'revoke')} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>🚫 Revoke</button>
                )}
              </div>
            </div>
          </div>
        );
      })}
      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No {filter} invitations</div>}
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
  const [config, setConfig] = useState<Record<string, any>>({});
  const [draft, setDraft] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);
  const [saveMsg, setSaveMsg] = useState('');

  useEffect(() => {
    fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'get_config' }) })
      .then(r => r.json()).then(d => { 
        const c = d.config || {};
        setConfig(c); 
        setDraft(JSON.parse(JSON.stringify(c)));
        setLoading(false); 
      });
  }, [adminKey]);

  const updateDraft = (key: string, value: any) => {
    setDraft(prev => ({ ...prev, [key]: value }));
    setDirty(true);
    setSaveMsg('');
  };

  const applyChanges = async () => {
    setSaveMsg('Saving...');
    const keys = Object.keys(draft);
    for (const key of keys) {
      if (JSON.stringify(draft[key]) !== JSON.stringify(config[key])) {
        await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: 'update_config', key, value: draft[key] }) });
      }
    }
    setConfig(JSON.parse(JSON.stringify(draft)));
    setDirty(false);
    setSaveMsg('✅ Changes applied across the platform');
    setTimeout(() => setSaveMsg(''), 3000);
  };

  const resetDraft = () => {
    setDraft(JSON.parse(JSON.stringify(config)));
    setDirty(false);
    setSaveMsg('');
  };

  if (loading) return <div style={{ color: '#888', fontSize: 13 }}>Loading...</div>;

  const freeLimits = draft.free_limits || { brief: 3, detailed: 1 };
  const invitedLimits = draft.invited_limits || { brief: 25, detailed: 10 };
  const featuresFree: string[] = draft.features_free || ['single_scan', 'radar', 'help', 'feedback'];
  const featuresInvited: string[] = draft.features_invited || ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'help', 'feedback'];
  const allFeatures = ['single_scan', 'bulk', 'compare', 'topics', 'radar', 'detailed_mode', 'memory', 'journal', 'compass', 'pulse', 'counterfactual', 'claims', 'help', 'feedback'];
  const labels: Record<string, string> = { single_scan: 'Single scan', bulk: 'Bulk CSV', compare: 'Compare', topics: 'Topics', radar: 'Radar', detailed_mode: 'Detailed mode', memory: 'Reader memory', journal: 'Decision journal', compass: 'Compass', pulse: 'Pulse', counterfactual: 'Counterfactual', claims: 'Claims', help: 'Help', feedback: 'Feedback' };
  const inp: React.CSSProperties = { padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', width: 80, textAlign: 'center' as const };

  return (
    <div>
      {/* Apply bar */}
      {dirty && (
        <div style={{ position: 'sticky', top: 48, zIndex: 20, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', background: '#0d9488', borderRadius: 8, marginBottom: 12 }}>
          <span style={{ fontSize: 13, color: '#fff', fontWeight: 500 }}>You have unsaved changes</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={resetDraft} style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Discard</button>
            <button onClick={applyChanges} style={{ padding: '6px 14px', background: '#fff', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Apply changes</button>
          </div>
        </div>
      )}
      {saveMsg && !dirty && <div style={{ padding: 10, background: '#f0fdfa', borderRadius: 8, fontSize: 13, color: '#0d9488', marginBottom: 12 }}>{saveMsg}</div>}

      {/* Scan limits */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>📊 Scan limits (per day, resets 00:00 GMT)</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 8 }}>🆓 Free tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={freeLimits.brief} onChange={e => updateDraft('free_limits', { ...freeLimits, brief: parseInt(e.target.value) || 0 })} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={freeLimits.detailed} onChange={e => updateDraft('free_limits', { ...freeLimits, detailed: parseInt(e.target.value) || 0 })} style={inp} /></div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 8 }}>🎫 Invited tier</div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}><span style={{ fontSize: 12, width: 70 }}>Brief:</span><input type="number" value={invitedLimits.brief} onChange={e => updateDraft('invited_limits', { ...invitedLimits, brief: parseInt(e.target.value) || 0 })} style={inp} /></div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span style={{ fontSize: 12, width: 70 }}>Detailed:</span><input type="number" value={invitedLimits.detailed} onChange={e => updateDraft('invited_limits', { ...invitedLimits, detailed: parseInt(e.target.value) || 0 })} style={inp} /></div>
          </div>
        </div>
      </div>

      {/* Expiry */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>⏰ Access expiry</div>
        <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Code expires:</span><input type="number" value={draft.invite_code_days || 7} onChange={e => updateDraft('invite_code_days', parseInt(e.target.value) || 7)} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>days</span></div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}><span style={{ fontSize: 12 }}>Access valid:</span><input type="number" value={draft.access_months || 6} onChange={e => updateDraft('access_months', parseInt(e.target.value) || 6)} style={inp} /><span style={{ fontSize: 12, color: '#888' }}>months</span></div>
        </div>
      </div>

      {/* Feature toggles */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>🔒 Feature access by tier</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>🆓 Free</div>
            {allFeatures.map(f => (<label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresFree.includes(f)} onChange={e => { const u = e.target.checked ? [...featuresFree, f] : featuresFree.filter(x => x !== f); updateDraft('features_free', u); }} />{labels[f] || f}</label>))}
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', marginBottom: 6 }}>🎫 Invited</div>
            {allFeatures.map(f => (<label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, fontSize: 12, cursor: 'pointer' }}><input type="checkbox" checked={featuresInvited.includes(f)} onChange={e => { const u = e.target.checked ? [...featuresInvited, f] : featuresInvited.filter(x => x !== f); updateDraft('features_invited', u); }} />{labels[f] || f}</label>))}
          </div>
        </div>
      </div>
    </div>
  );
}
