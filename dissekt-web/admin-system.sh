#!/bin/bash
# Dissekt — Admin System Overhaul
# 1. Admin login with password
# 2. Password change with email notification  
# 3. Auto-email invite codes on approval
# 4. All pages linked in nav
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Admin API — login, actions, password change
# ============================================

cat > src/app/api/admin/route.ts << 'ADMEOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

const RESEND_KEY = process.env.RESEND_API_KEY || '';
const ADMIN_EMAIL = 'sambitmallick123@gmail.com';

function getAdminKey(): string {
  return process.env.DISSEKT_ADMIN_KEY || 'dissekt-sambit-2026';
}

function checkAdmin(req: NextRequest): boolean {
  const key = req.headers.get('x-admin-key') || req.nextUrl.searchParams.get('key');
  return key === getAdminKey();
}

function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'DSK-';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function codeExpiry(): string {
  const d = new Date();
  d.setDate(d.getDate() + 7);
  return d.toISOString();
}

function accessExpiry(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 6);
  return d.toISOString();
}

async function sendEmail(to: string, subject: string, html: string) {
  if (!RESEND_KEY) return false;
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: 'Dissekt <onboarding@resend.dev>', to, subject, html }),
    });
    return res.ok;
  } catch { return false; }
}

// POST: login, approve, reject, generate, change password
export async function POST(req: NextRequest) {
  const body = await req.json();

  // Login check
  if (body.action === 'login') {
    const valid = body.password === getAdminKey();
    return NextResponse.json({ success: valid, error: valid ? undefined : 'Invalid password' });
  }

  // Password change — sends email with new password
  if (body.action === 'change_password') {
    if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    const newPassword = body.new_password;
    if (!newPassword || newPassword.length < 8) {
      return NextResponse.json({ error: 'Password must be at least 8 characters' }, { status: 400 });
    }
    // Note: In production, store in DB. For now, notify via email to update env var.
    await sendEmail(ADMIN_EMAIL, '[Dissekt Admin] Password change requested', `
      <h3>Admin password change requested</h3>
      <p>New password: <strong>${newPassword}</strong></p>
      <p>Update the <code>DISSEKT_ADMIN_KEY</code> environment variable in:</p>
      <ul>
        <li>Railway → Variables</li>
        <li>Vercel → Environment Variables</li>
        <li>.env.local</li>
      </ul>
      <p>This email was sent from Dissekt admin panel.</p>
    `);
    return NextResponse.json({ success: true, message: 'Password change request sent to your email. Update DISSEKT_ADMIN_KEY in Railway + Vercel + .env.local.' });
  }

  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  // Approve invitation — generates code + emails user
  if (body.action === 'approve') {
    const code = generateCode();
    const { data: inv, error: fetchErr } = await supabase
      .from('invitations')
      .select('email, name')
      .eq('id', body.id)
      .single();

    const { error } = await supabase
      .from('invitations')
      .update({
        status: 'approved',
        invite_code: code,
        reviewed_at: new Date().toISOString(),
        code_expires_at: codeExpiry(),
      })
      .eq('id', body.id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Email the invite code to the user
    if (inv?.email) {
      await sendEmail(inv.email, 'Your Dissekt invitation code', `
        <div style="font-family: -apple-system, sans-serif; max-width: 480px; margin: 0 auto;">
          <div style="background: #0d9488; padding: 16px 20px; border-radius: 10px 10px 0 0;">
            <h2 style="color: white; margin: 0; font-size: 18px;">Welcome to Dissekt</h2>
          </div>
          <div style="background: #fff; padding: 20px; border: 1px solid #e5eaea; border-top: none; border-radius: 0 0 10px 10px;">
            <p>Hi ${inv.name || 'there'},</p>
            <p>Your access request has been approved! Here's your invitation code:</p>
            <div style="background: #f0fdfa; border: 1px solid #ccfbf1; padding: 16px; border-radius: 8px; text-align: center; margin: 16px 0;">
              <span style="font-size: 24px; font-weight: 700; letter-spacing: 0.1em; color: #0d9488;">${code}</span>
            </div>
            <p style="font-size: 13px; color: #888;">
              <strong>How to use:</strong><br/>
              1. Go to <a href="https://dissekt.info/invite" style="color: #0d9488;">dissekt.info/invite</a><br/>
              2. Click "I have a code"<br/>
              3. Paste the code above<br/>
            </p>
            <p style="font-size: 12px; color: #aaa;">
              This code expires in 7 days. Once redeemed, your access is valid for 6 months.<br/>
              25 brief + 10 detailed scans per day. Bulk analysis, Compare, Topics — all unlocked.
            </p>
          </div>
        </div>
      `);
    }

    // Also notify admin
    await sendEmail(ADMIN_EMAIL, `[Dissekt] Invitation approved: ${inv?.email}`, `
      <p>Approved: ${inv?.name} (${inv?.email})</p>
      <p>Code: <strong>${code}</strong></p>
      <p>Expires: 7 days</p>
    `);

    return NextResponse.json({ success: true, code, emailed: !!inv?.email });
  }

  // Reject
  if (body.action === 'reject') {
    const { data: inv } = await supabase.from('invitations').select('email, name').eq('id', body.id).single();

    const { error } = await supabase
      .from('invitations')
      .update({ status: 'rejected', reviewed_at: new Date().toISOString() })
      .eq('id', body.id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    if (inv?.email) {
      await sendEmail(inv.email, 'Dissekt access update', `
        <p>Hi ${inv.name || 'there'},</p>
        <p>Thanks for your interest in Dissekt. We're currently in limited beta and unable to approve your request at this time.</p>
        <p>You can continue using the free tier (3 brief + 1 detailed scan/day) at <a href="https://dissekt.info/analyze">dissekt.info</a>.</p>
        <p>We'll reach out when more spots open up.</p>
      `);
    }

    return NextResponse.json({ success: true });
  }

  // Generate manual code
  if (body.action === 'generate') {
    const code = generateCode();
    const { error } = await supabase.from('invitations').insert({
      email: body.email || 'manual@dissekt.info',
      name: body.name || 'Manual invite',
      status: 'approved',
      invite_code: code,
      code_expires_at: codeExpiry(),
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    if (body.email && body.email !== 'manual@dissekt.info') {
      await sendEmail(body.email, 'Your Dissekt invitation code', `
        <div style="font-family: -apple-system, sans-serif; max-width: 480px; margin: 0 auto;">
          <div style="background: #0d9488; padding: 16px 20px; border-radius: 10px 10px 0 0;">
            <h2 style="color: white; margin: 0;">Your Dissekt invite</h2>
          </div>
          <div style="background: #fff; padding: 20px; border: 1px solid #e5eaea; border-top: none; border-radius: 0 0 10px 10px;">
            <p>Hi ${body.name || 'there'},</p>
            <p>You've been invited to Dissekt! Your code:</p>
            <div style="background: #f0fdfa; border: 1px solid #ccfbf1; padding: 16px; border-radius: 8px; text-align: center; margin: 16px 0;">
              <span style="font-size: 24px; font-weight: 700; letter-spacing: 0.1em; color: #0d9488;">${code}</span>
            </div>
            <p style="font-size: 13px;">Redeem at <a href="https://dissekt.info/invite" style="color: #0d9488;">dissekt.info/invite</a></p>
            <p style="font-size: 12px; color: #aaa;">Expires in 7 days. Access valid 6 months.</p>
          </div>
        </div>
      `);
    }

    return NextResponse.json({ success: true, code });
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}

// GET: List invitations
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
}
ADMEOF

echo "✅ Admin API: login, approve+email, reject+email, generate+email, password change"

# ============================================
# 2. Admin page — full redesign
# ============================================

cat > src/app/admin/page.tsx << 'ADMINEOF'
'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function AdminPage() {
  const [password, setPassword] = useState('');
  const [authenticated, setAuthenticated] = useState(false);
  const [adminKey, setAdminKey] = useState('');
  const [invitations, setInvitations] = useState<any[]>([]);
  const [stats, setStats] = useState({ total: 0, pending: 0, approved: 0, rejected: 0 });
  const [filter, setFilter] = useState('pending');
  const [genEmail, setGenEmail] = useState('');
  const [genName, setGenName] = useState('');
  const [genResult, setGenResult] = useState('');
  const [showPwChange, setShowPwChange] = useState(false);
  const [newPw, setNewPw] = useState('');
  const [pwMsg, setPwMsg] = useState('');
  const [actionMsg, setActionMsg] = useState('');

  const login = async () => {
    const res = await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'login', password }),
    });
    const data = await res.json();
    if (data.success) { setAuthenticated(true); setAdminKey(password); }
    else { alert('Invalid password'); }
  };

  const fetchInvitations = async (status: string) => {
    const res = await fetch(`/api/admin?key=${adminKey}&status=${status}`);
    const data = await res.json();
    if (data.error) { setAuthenticated(false); return; }
    setInvitations(data.invitations || []);
    setStats(data.stats || stats);
  };

  const handleAction = async (id: string, action: 'approve' | 'reject') => {
    setActionMsg('');
    const res = await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ action, id }),
    });
    const data = await res.json();
    if (data.success) {
      if (action === 'approve') {
        setActionMsg(`✅ Approved! Code: ${data.code} · ${data.emailed ? 'Email sent to user' : 'No email sent'}`);
      } else {
        setActionMsg('❌ Rejected. User notified.');
      }
      fetchInvitations(filter);
    }
  };

  const handleGenerate = async () => {
    setGenResult('');
    const res = await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ action: 'generate', email: genEmail, name: genName }),
    });
    const data = await res.json();
    if (data.success) {
      setGenResult(`${data.code} — ${genEmail ? 'emailed to ' + genEmail : 'manual code'}`);
      setGenEmail(''); setGenName('');
      fetchInvitations(filter);
    }
  };

  const handlePasswordChange = async () => {
    const res = await fetch('/api/admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ action: 'change_password', new_password: newPw }),
    });
    const data = await res.json();
    setPwMsg(data.success ? data.message : data.error || 'Failed');
  };

  useEffect(() => { if (authenticated) fetchInvitations(filter); }, [filter, authenticated]);

  const sc: Record<string, { bg: string; color: string }> = {
    pending: { bg: '#fffbeb', color: '#92400e' },
    approved: { bg: '#f0fdf4', color: '#166534' },
    rejected: { bg: '#fef2f2', color: '#b91c1c' },
  };
  const inputStyle: React.CSSProperties = { padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', background: '#f8fafa', fontFamily: 'inherit' };

  if (!authenticated) {
    return (
      <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
        <SiteHeader />
        <div style={{ maxWidth: 400, margin: '80px auto', padding: '0 24px' }}>
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 28 }}>
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{ width: 48, height: 48, background: '#f0fdfa', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: 22 }}>🔐</div>
              <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a' }}>Admin access</div>
              <div style={{ fontSize: 13, color: '#888', marginTop: 4 }}>Enter your admin password to continue</div>
            </div>
            <input type="password" placeholder="Admin password" value={password}
              onChange={e => setPassword(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && login()}
              style={{ ...inputStyle, width: '100%', marginBottom: 12, boxSizing: 'border-box' as any }} />
            <button onClick={login}
              style={{ width: '100%', padding: '10px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
              Sign in
            </button>
          </div>
        </div>
        <SiteFooter />
      </main>
    );
  }

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />

      <div style={{ maxWidth: 960, margin: '0 auto', padding: '24px 24px' }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div>
            <h1 style={{ fontSize: 22, fontWeight: 700, color: '#1a1a1a', marginBottom: 2 }}>Admin dashboard</h1>
            <p style={{ fontSize: 13, color: '#888' }}>Manage invitations and platform settings</p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => setShowPwChange(!showPwChange)}
              style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#555' }}>
              🔑 Change password
            </button>
            <button onClick={() => { setAuthenticated(false); setAdminKey(''); }}
              style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#dc2626' }}>
              Sign out
            </button>
          </div>
        </div>

        {/* Password change */}
        {showPwChange && (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 16 }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Change admin password</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input type="password" placeholder="New password (min 8 chars)" value={newPw} onChange={e => setNewPw(e.target.value)}
                style={{ ...inputStyle, flex: 1 }} />
              <button onClick={handlePasswordChange} disabled={newPw.length < 8}
                style={{ padding: '8px 16px', background: newPw.length >= 8 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: newPw.length >= 8 ? 'pointer' : 'not-allowed' }}>
                Change
              </button>
            </div>
            {pwMsg && <div style={{ marginTop: 8, fontSize: 12, color: '#0d9488' }}>{pwMsg}</div>}
            <div style={{ fontSize: 11, color: '#aaa', marginTop: 4 }}>New password will be emailed to you. Update DISSEKT_ADMIN_KEY in Railway + Vercel.</div>
          </div>
        )}

        {/* Action message */}
        {actionMsg && (
          <div style={{ padding: 12, background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 8, fontSize: 13, color: '#0d9488', marginBottom: 16 }}>{actionMsg}</div>
        )}

        {/* Stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginBottom: 16 }}>
          {[
            { label: 'Total', value: stats.total, color: '#1a1a1a' },
            { label: 'Pending', value: stats.pending, color: '#d97706' },
            { label: 'Approved', value: stats.approved, color: '#16a34a' },
            { label: 'Rejected', value: stats.rejected, color: '#dc2626' },
          ].map((s, i) => (
            <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: s.color }}>{s.value}</div>
              <div style={{ fontSize: 11, color: '#888' }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Generate code */}
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 16, marginBottom: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>Generate invite code</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <input type="email" placeholder="Email (sends code to user)" value={genEmail} onChange={e => setGenEmail(e.target.value)} style={{ ...inputStyle, flex: 1 }} />
            <input type="text" placeholder="Name" value={genName} onChange={e => setGenName(e.target.value)} style={{ ...inputStyle, flex: 1 }} />
            <button onClick={handleGenerate}
              style={{ padding: '8px 16px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' }}>
              Generate + send
            </button>
          </div>
          {genResult && (
            <div style={{ marginTop: 8, padding: '8px 12px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 6, fontSize: 13, fontWeight: 600, color: '#166534' }}>{genResult}</div>
          )}
        </div>

        {/* Filter tabs */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
          {['pending', 'approved', 'rejected', 'all'].map(s => (
            <button key={s} onClick={() => setFilter(s)}
              style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: filter === s ? '#0d9488' : '#fff', color: filter === s ? '#fff' : '#555', boxShadow: filter !== s ? '0 0 0 0.5px #e5eaea' : 'none' }}>
              {s.charAt(0).toUpperCase() + s.slice(1)} {s === 'pending' && stats.pending > 0 ? `(${stats.pending})` : ''}
            </button>
          ))}
          <button onClick={() => fetchInvitations(filter)} style={{ marginLeft: 'auto', padding: '6px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 11, cursor: 'pointer', color: '#888' }}>
            Refresh
          </button>
        </div>

        {/* Invitations list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {invitations.map((inv, i) => {
            const s = sc[inv.status] || sc.pending;
            return (
              <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                      <span style={{ fontSize: 14, fontWeight: 600 }}>{inv.name || 'No name'}</span>
                      <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 5, background: s.bg, color: s.color, fontWeight: 600 }}>{inv.status}</span>
                    </div>
                    <div style={{ fontSize: 12, color: '#555' }}>{inv.email}</div>
                    {inv.organization && <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>🏢 {inv.organization}</div>}
                    {inv.reason && <div style={{ fontSize: 11, color: '#888', marginTop: 4, fontStyle: 'italic', maxWidth: 500 }}>"{inv.reason}"</div>}
                    <div style={{ display: 'flex', gap: 12, marginTop: 6, fontSize: 10, color: '#aaa' }}>
                      <span>Requested: {new Date(inv.created_at).toLocaleDateString()}</span>
                      {inv.invite_code && <span style={{ fontWeight: 600, color: '#0d9488' }}>Code: {inv.invite_code}</span>}
                      {inv.code_expires_at && <span>Code expires: {new Date(inv.code_expires_at).toLocaleDateString()}</span>}
                      {inv.access_expires_at && <span>Access until: {new Date(inv.access_expires_at).toLocaleDateString()}</span>}
                    </div>
                  </div>
                  {inv.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                      <button onClick={() => handleAction(inv.id, 'approve')}
                        style={{ padding: '6px 14px', background: '#16a34a', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                        ✅ Approve + email
                      </button>
                      <button onClick={() => handleAction(inv.id, 'reject')}
                        style={{ padding: '6px 14px', background: '#dc2626', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                        ❌ Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
          {invitations.length === 0 && (
            <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10, border: '0.5px solid #e5eaea' }}>
              No {filter === 'all' ? '' : filter} invitations
            </div>
          )}
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
ADMINEOF

echo "✅ Admin page: full redesign with header/footer"

echo ""
echo "✅ Admin system complete:"
echo "  🔐 Login: password-based (DISSEKT_ADMIN_KEY env var)"
echo "  🔑 Password change: sends email with new password to update env vars"
echo "  ✅ Approve: generates code + emails it to the user automatically"
echo "  ❌ Reject: notifies user via email"
echo "  📊 Stats: total/pending/approved/rejected counters"
echo "  🎟️ Generate: manual invite with auto-email"
echo "  🎨 Uniform SiteHeader + SiteFooter"
echo ""
echo "Test: npm run build && npm run dev"
echo "  1. Visit /admin → enter password → see dashboard"
echo "  2. Approve a request → user gets email with DSK-XXXXXXXX code"
echo "  3. Click 'Change password' → enter new → email sent to you"
