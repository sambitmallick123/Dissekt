#!/bin/bash
# Dissekt — Comprehensive Admin Dashboard
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

echo "⚠️  Run this SQL in Supabase:"
echo ""
echo "create table if not exists public.contacts ("
echo "  id uuid default gen_random_uuid() primary key,"
echo "  name text,"
echo "  email text,"
echo "  subject text,"
echo "  message text not null,"
echo "  status text default 'unread' check (status in ('unread', 'read', 'replied')),"
echo "  created_at timestamptz default now()"
echo ");"
echo ""
echo "alter table public.contacts enable row level security;"
echo "create policy \"Anyone can insert\" on public.contacts for insert with check (true);"
echo "create policy \"Anyone can read\" on public.contacts for select using (true);"
echo "create policy \"Anyone can update\" on public.contacts for update using (true);"
echo ""
echo "-- Add status column to feedback if missing:"
echo "alter table public.feedback add column if not exists status text default 'unread';"
echo "alter table public.feedback add column if not exists component text;"
echo "alter table public.feedback add column if not exists type text;"
echo ""

# ============================================
# 1. Update contact API to also save to Supabase
# ============================================

cat > src/app/api/contact/route.ts << 'CAPI'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  try {
    const { name, email, subject, message } = await req.json();
    if (!message) return NextResponse.json({ error: 'Message required' }, { status: 400 });

    // Save to Supabase
    await supabase.from('contacts').insert({ name, email, subject, message });

    // Send email via Resend
    const RESEND_KEY = process.env.RESEND_API_KEY || '';
    if (RESEND_KEY) {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          from: 'Dissekt Contact <onboarding@resend.dev>',
          to: 'sambitmallick123@gmail.com',
          subject: `[Dissekt] ${subject || 'New message'} from ${name || 'Anonymous'}`,
          html: `<p><strong>From:</strong> ${name || '-'} (${email || '-'})</p><p><strong>Subject:</strong> ${subject}</p><hr/><p>${message.replace(/\n/g, '<br/>')}</p>`,
        }),
      });
    }

    return NextResponse.json({ success: true });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
CAPI

echo "✅ Contact API: saves to Supabase + emails"

# ============================================
# 2. Admin API — add feedback, contacts, stats endpoints
# ============================================

# Keep existing admin API but add GET params for different data
python3 << 'PYEOF'
content = open('src/app/api/admin/route.ts').read()

# Add feedback + contacts + stats to GET handler
old_get = '''// GET: List invitations
export async function GET(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const status = req.nextUrl.searchParams.get('status') || 'all';
  let query = supabase.from('invitations').select('*').order('created_at', { ascending: false });
  if (status !== 'all') query = query.eq('status', status);
  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const stats = {
    total: data?.length || 0,
    pending: data?.filter(d => d.status === 'pending').length || 0,
    approved: data?.filter(d => d.status === 'approved').length || 0,
    rejected: data?.filter(d => d.status === 'rejected').length || 0,
  };

  return NextResponse.json({ invitations: data || [], stats });
}'''

new_get = '''// GET: List invitations, feedback, contacts, stats
export async function GET(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  
  const view = req.nextUrl.searchParams.get('view') || 'invitations';
  const status = req.nextUrl.searchParams.get('status') || 'all';

  if (view === 'feedback') {
    let q = supabase.from('feedback').select('*').order('created_at', { ascending: false }).limit(100);
    if (status !== 'all') q = q.eq('status', status);
    const { data } = await q;
    return NextResponse.json({ items: data || [] });
  }

  if (view === 'contacts') {
    let q = supabase.from('contacts').select('*').order('created_at', { ascending: false }).limit(100);
    if (status !== 'all') q = q.eq('status', status);
    const { data } = await q;
    return NextResponse.json({ items: data || [] });
  }

  if (view === 'corrections') {
    const { data } = await supabase.from('corrections').select('*').order('created_at', { ascending: false }).limit(100);
    return NextResponse.json({ items: data || [] });
  }

  if (view === 'decisions') {
    const { data } = await supabase.from('decisions').select('*').order('created_at', { ascending: false }).limit(100);
    return NextResponse.json({ items: data || [] });
  }

  if (view === 'stats') {
    const [inv, fb, ct, cor, dec] = await Promise.all([
      supabase.from('invitations').select('status', { count: 'exact' }),
      supabase.from('feedback').select('id', { count: 'exact' }),
      supabase.from('contacts').select('id', { count: 'exact' }),
      supabase.from('corrections').select('id', { count: 'exact' }),
      supabase.from('decisions').select('id', { count: 'exact' }),
    ]);
    
    const invData = inv.data || [];
    return NextResponse.json({
      invitations: {
        total: invData.length,
        pending: invData.filter((d: any) => d.status === 'pending').length,
        approved: invData.filter((d: any) => d.status === 'approved').length,
        rejected: invData.filter((d: any) => d.status === 'rejected').length,
      },
      feedback: fb.count || 0,
      contacts: ct.count || 0,
      corrections: cor.count || 0,
      decisions: dec.count || 0,
    });
  }

  // Default: invitations
  let query = supabase.from('invitations').select('*').order('created_at', { ascending: false });
  if (status !== 'all') query = query.eq('status', status);
  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const stats = {
    total: data?.length || 0,
    pending: data?.filter(d => d.status === 'pending').length || 0,
    approved: data?.filter(d => d.status === 'approved').length || 0,
    rejected: data?.filter(d => d.status === 'rejected').length || 0,
  };

  return NextResponse.json({ invitations: data || [], stats });
}'''

# Add mark_read action to POST
mark_read = '''
  // Mark feedback/contact as read/replied
  if (body.action === 'mark_status') {
    const table = body.table;
    const newStatus = body.status;
    if (!['feedback', 'contacts'].includes(table)) return NextResponse.json({ error: 'Invalid table' }, { status: 400 });
    const { error } = await supabase.from(table).update({ status: newStatus }).eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

'''

content = content.replace(old_get, new_get)
content = content.replace("  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });\n}", mark_read + "  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });\n}")

open('src/app/api/admin/route.ts', 'w').write(content)
print('✅ Admin API: feedback, contacts, corrections, decisions, stats views')
PYEOF

# ============================================
# 3. Full Admin Dashboard Page
# ============================================

cat > src/app/admin/page.tsx << 'ADMINEOF'
'use client';
import { useState, useEffect, useCallback } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

type Tab = 'overview' | 'invitations' | 'feedback' | 'contacts' | 'corrections' | 'decisions';

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

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 1000, margin: '0 auto', padding: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h1 style={{ fontSize: 22, fontWeight: 700 }}>Admin dashboard</h1>
          <button onClick={() => { setAuthenticated(false); setAdminKey(''); }} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#dc2626' }}>Sign out</button>
        </div>
        <div style={{ display: 'flex', gap: 4, marginBottom: 20, overflowX: 'auto' }}>
          {(['overview', 'invitations', 'feedback', 'contacts', 'corrections', 'decisions'] as Tab[]).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: '7px 16px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === t ? '#0d9488' : '#fff', color: tab === t ? '#fff' : '#555', boxShadow: tab !== t ? '0 0 0 0.5px #e5eaea' : 'none', whiteSpace: 'nowrap' }}>
              {t === 'overview' ? '📊 Overview' : t === 'invitations' ? '🎟️ Invitations' : t === 'feedback' ? '💬 Feedback' : t === 'contacts' ? '📧 Contacts' : t === 'corrections' ? '👍 Corrections' : '📓 Decisions'}
            </button>
          ))}
        </div>
        {tab === 'overview' && <OverviewTab adminKey={adminKey} />}
        {tab === 'invitations' && <InvitationsTab adminKey={adminKey} />}
        {tab === 'feedback' && <FeedbackTab adminKey={adminKey} />}
        {tab === 'contacts' && <ContactsTab adminKey={adminKey} />}
        {tab === 'corrections' && <CorrectionsTab adminKey={adminKey} />}
        {tab === 'decisions' && <DecisionsTab adminKey={adminKey} />}
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

  useEffect(() => {
    fetch(`/api/admin?key=${adminKey}&view=stats`).then(r => r.json()).then(setStats);
  }, [adminKey]);

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
    { label: 'Feedback received', value: stats.feedback || 0, color: '#2563eb', icon: '💬' },
    { label: 'Contact messages', value: stats.contacts || 0, color: '#7c3aed', icon: '📧' },
    { label: 'Technique corrections', value: stats.corrections || 0, color: '#ea580c', icon: '👍' },
    { label: 'User decisions', value: stats.decisions || 0, color: '#0891b2', icon: '📓' },
  ];

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 20 }}>
        {cards.map((c, i) => (
          <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 11, color: '#888' }}>{c.label}</span>
              <span style={{ fontSize: 14 }}>{c.icon}</span>
            </div>
            <div style={{ fontSize: 26, fontWeight: 700, color: c.color, marginTop: 4 }}>{c.value}</div>
          </div>
        ))}
      </div>
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 16 }}>
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
    setItems(data.invitations || []);
    setStats(data.stats || stats);
  }, [adminKey, filter]);

  useEffect(() => { load(); }, [load]);

  const action = async (id: string, act: 'approve' | 'reject') => {
    setMsg('');
    const res = await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey }, body: JSON.stringify({ action: act, id }) });
    const data = await res.json();
    setMsg(act === 'approve' ? `✅ Approved! Code: ${data.code} · Email sent` : '❌ Rejected · User notified');
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
        {genResult && <div style={{ marginTop: 8, padding: '8px', background: '#f0fdf4', borderRadius: 6, fontSize: 13, fontWeight: 600, color: '#166534', textAlign: 'center' }}>{genResult}</div>}
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
                {inv.reason && <div style={{ fontSize: 11, color: '#888', fontStyle: 'italic', marginTop: 2 }}>"{inv.reason}"</div>}
                <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>
                  {new Date(inv.created_at).toLocaleDateString()}
                  {inv.invite_code && <span style={{ marginLeft: 8, color: '#0d9488', fontWeight: 600 }}>{inv.invite_code}</span>}
                </div>
              </div>
              {inv.status === 'pending' && (
                <div style={{ display: 'flex', gap: 6 }}>
                  <button onClick={() => action(inv.id, 'approve')} style={{ padding: '6px 14px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>✅ Approve</button>
                  <button onClick={() => action(inv.id, 'reject')} style={{ padding: '6px 14px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>❌ Reject</button>
                </div>
              )}
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
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                <span>{typeIcons[fb.type] || '💬'}</span>
                <span style={{ fontSize: 12, fontWeight: 600 }}>{fb.name || 'Anonymous'}</span>
                {fb.component && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#f0fdfa', color: '#0d9488' }}>{fb.component}</span>}
                {fb.type && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: '#eff6ff', color: '#2563eb' }}>{fb.type}</span>}
                <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: fb.status === 'read' ? '#f0fdf4' : '#fffbeb', color: fb.status === 'read' ? '#166534' : '#92400e' }}>{fb.status || 'unread'}</span>
              </div>
              {fb.email && <div style={{ fontSize: 11, color: '#888' }}>{fb.email}</div>}
              <div style={{ fontSize: 12, color: '#404040', marginTop: 4, lineHeight: 1.6, maxWidth: 600 }}>{fb.message}</div>
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
              <div style={{ fontSize: 12, color: '#404040', marginTop: 4, lineHeight: 1.6, maxWidth: 600 }}>{ct.message}</div>
              <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>{new Date(ct.created_at).toLocaleString()}</div>
            </div>
            <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
              {ct.status === 'unread' && <button onClick={() => markStatus(ct.id, 'read')} style={{ padding: '4px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, fontSize: 10, cursor: 'pointer', fontWeight: 600 }}>Mark read</button>}
              {ct.email && <a href={`mailto:${ct.email}?subject=Re: ${ct.subject || 'Your Dissekt inquiry'}`} onClick={() => markStatus(ct.id, 'replied')} style={{ padding: '4px 10px', background: '#0d9488', color: '#fff', borderRadius: 5, fontSize: 10, textDecoration: 'none', fontWeight: 600 }}>Reply</a>}
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
            {c.comment && <span style={{ fontSize: 11, color: '#888', marginLeft: 8 }}>"{c.comment}"</span>}
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
ADMINEOF

echo "✅ Admin dashboard: 6 tabs, stats, feedback, contacts, corrections, decisions"
echo ""
echo "⚠️  Create 'contacts' table in Supabase (SQL shown above)"
echo "⚠️  Add status + component + type columns to feedback table"
echo ""
echo "Test: npm run build && npm run dev → /admin"
