'use client';
import { useState, useEffect } from 'react';

export default function AdminPage() {
  const [key, setKey] = useState('');
  const [authenticated, setAuthenticated] = useState(false);
  const [invitations, setInvitations] = useState<any[]>([]);
  const [filter, setFilter] = useState('pending');
  const [genEmail, setGenEmail] = useState('');
  const [genName, setGenName] = useState('');
  const [genResult, setGenResult] = useState('');

  const fetchInvitations = async (status: string) => {
    const res = await fetch(`/api/admin?key=${key}&status=${status}`);
    const data = await res.json();
    if (data.error) { setAuthenticated(false); return; }
    setInvitations(data.invitations || []);
    setAuthenticated(true);
  };

  const handleAction = async (id: string, action: 'approve' | 'reject') => {
    const res = await fetch(`/api/admin?key=${key}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, id }),
    });
    const data = await res.json();
    if (data.success && action === 'approve') {
      alert(`Approved! Code: ${data.code}`);
    }
    fetchInvitations(filter);
  };

  const handleGenerate = async () => {
    const res = await fetch(`/api/admin?key=${key}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'generate', email: genEmail, name: genName }),
    });
    const data = await res.json();
    if (data.success) setGenResult(data.code);
  };

  useEffect(() => { if (authenticated) fetchInvitations(filter); }, [filter]);

  const statusColors: Record<string, { bg: string; color: string }> = {
    pending: { bg: '#fffbeb', color: '#92400e' },
    approved: { bg: '#f0fdf4', color: '#166534' },
    rejected: { bg: '#fef2f2', color: '#b91c1c' },
  };

  if (!authenticated) {
    return (
      <main style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 28, width: 360 }}>
          <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>🔐 Admin access</div>
          <input type="password" placeholder="Admin key" value={key} onChange={e => setKey(e.target.value)}
            style={{ width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, marginBottom: 10, outline: 'none', boxSizing: 'border-box' }} />
          <button onClick={() => fetchInvitations('pending')}
            style={{ width: '100%', padding: '10px 0', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
            Enter
          </button>
        </div>
      </main>
    );
  }

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontWeight: 600 }}>🔐 Dissekt Admin</span>
          <span style={{ fontSize: 12, color: '#888' }}>{invitations.length} invitations</span>
        </div>
        <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none' }}>← Back</a>
      </nav>

      <div style={{ maxWidth: 900, margin: '0 auto', padding: '24px 24px' }}>
        {/* Generate code */}
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>Generate invite code</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <input type="email" placeholder="Email" value={genEmail} onChange={e => setGenEmail(e.target.value)}
              style={{ flex: 1, padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 6, fontSize: 13, outline: 'none' }} />
            <input type="text" placeholder="Name" value={genName} onChange={e => setGenName(e.target.value)}
              style={{ flex: 1, padding: '8px 12px', border: '1px solid #e5e5e5', borderRadius: 6, fontSize: 13, outline: 'none' }} />
            <button onClick={handleGenerate}
              style={{ padding: '8px 16px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>
              Generate
            </button>
          </div>
          {genResult && (
            <div style={{ marginTop: 8, padding: '8px 12px', background: '#f0fdf4', border: '1px solid #dcfce7', borderRadius: 6, fontSize: 14, fontWeight: 700, color: '#166534', textAlign: 'center', letterSpacing: '0.1em' }}>
              {genResult}
            </div>
          )}
        </div>

        {/* Filter tabs */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 16 }}>
          {['pending', 'approved', 'rejected', 'all'].map(s => (
            <button key={s} onClick={() => setFilter(s)}
              style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: filter === s ? '#7c3aed' : '#fff', color: filter === s ? '#fff' : '#555', boxShadow: filter === s ? 'none' : '0 0 0 1px #e5e5e5' }}>
              {s.charAt(0).toUpperCase() + s.slice(1)}
            </button>
          ))}
        </div>

        {/* Invitations table */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {invitations.map((inv, i) => {
            const sc = statusColors[inv.status] || statusColors.pending;
            return (
              <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '12px 16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <div>
                    <div style={{ fontSize: 14, fontWeight: 600 }}>{inv.name || 'No name'}</div>
                    <div style={{ fontSize: 12, color: '#555' }}>{inv.email}</div>
                    {inv.organization && <div style={{ fontSize: 11, color: '#888' }}>🏢 {inv.organization}</div>}
                    {inv.reason && <div style={{ fontSize: 11, color: '#888', marginTop: 4, maxWidth: 500 }}>"{inv.reason}"</div>}
                    <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>
                      {new Date(inv.created_at).toLocaleString()}
                      {inv.invite_code && <span style={{ marginLeft: 8, fontWeight: 600, color: '#166534' }}>Code: {inv.invite_code}</span>}
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: sc.bg, color: sc.color, fontWeight: 600 }}>{inv.status}</span>
                    {inv.status === 'pending' && (
                      <>
                        <button onClick={() => handleAction(inv.id, 'approve')}
                          style={{ padding: '5px 12px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                          ✅ Approve
                        </button>
                        <button onClick={() => handleAction(inv.id, 'reject')}
                          style={{ padding: '5px 12px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                          ❌ Reject
                        </button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
          {invitations.length === 0 && (
            <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13 }}>No {filter} invitations</div>
          )}
        </div>
      </div>
    </main>
  );
}
