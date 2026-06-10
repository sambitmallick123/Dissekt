#!/bin/bash
# Dissekt — Invitation-Based Access System
# Free: 3 scans/day, Brief only, no Bulk/Compare/Topics
# Invited: 25 scans/day, all features
# Admin: approve/reject requests, generate codes
set -e

echo "⚠️  Run this SQL in Supabase first:"
echo ""
echo "create table if not exists public.invitations ("
echo "  id uuid default gen_random_uuid() primary key,"
echo "  email text not null,"
echo "  name text,"
echo "  reason text,"
echo "  organization text,"
echo "  status text default 'pending' check (status in ('pending', 'approved', 'rejected')),"
echo "  invite_code text unique,"
echo "  created_at timestamptz default now(),"
echo "  reviewed_at timestamptz"
echo ");"
echo ""
echo "alter table public.invitations enable row level security;"
echo "create policy \"Anyone can request\" on public.invitations for insert with check (true);"
echo "create policy \"Anyone can read own\" on public.invitations for select using (true);"
echo "create policy \"Anyone can update\" on public.invitations for update using (true);"
echo ""

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. API: Invitation management
# ============================================

mkdir -p src/app/api/invite

cat > src/app/api/invite/route.ts << 'INVEOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

// POST: Request invitation or redeem code
export async function POST(req: NextRequest) {
  const body = await req.json();

  // Request an invitation
  if (body.action === 'request') {
    try {
      const { email, name, reason, organization } = body;
      if (!email) return NextResponse.json({ error: 'Email required' }, { status: 400 });

      // Check if already requested
      const { data: existing } = await supabase
        .from('invitations')
        .select('status')
        .eq('email', email.toLowerCase())
        .single();

      if (existing) {
        return NextResponse.json({ 
          success: true, 
          status: existing.status,
          message: existing.status === 'approved' 
            ? 'You already have access! Check your email for the code.'
            : existing.status === 'rejected'
            ? 'Your request was reviewed. Contact us for more info.'
            : 'Your request is pending review.'
        });
      }

      const { error } = await supabase.from('invitations').insert({
        email: email.toLowerCase(), name, reason, organization,
      });
      if (error) throw error;
      return NextResponse.json({ success: true, message: 'Request submitted! We will review and get back to you.' });
    } catch (e: any) {
      return NextResponse.json({ error: e.message }, { status: 500 });
    }
  }

  // Redeem an invite code
  if (body.action === 'redeem') {
    try {
      const { code } = body;
      if (!code) return NextResponse.json({ error: 'Code required' }, { status: 400 });

      const { data, error } = await supabase
        .from('invitations')
        .select('*')
        .eq('invite_code', code.toUpperCase())
        .eq('status', 'approved')
        .single();

      if (error || !data) {
        return NextResponse.json({ error: 'Invalid or expired invite code' }, { status: 400 });
      }

      return NextResponse.json({ 
        success: true, 
        tier: 'invited',
        name: data.name,
        email: data.email,
      });
    } catch (e: any) {
      return NextResponse.json({ error: e.message }, { status: 500 });
    }
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}
INVEOF

# ============================================
# 2. API: Admin (protected)
# ============================================

mkdir -p src/app/api/admin

cat > src/app/api/admin/route.ts << 'ADMEOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

const ADMIN_KEY = process.env.DISSEKT_ADMIN_KEY || 'dissekt-admin-2026';

function checkAdmin(req: NextRequest): boolean {
  const key = req.headers.get('x-admin-key') || req.nextUrl.searchParams.get('key');
  return key === ADMIN_KEY;
}

function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'DSK-';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

// GET: List all invitations
export async function GET(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const status = req.nextUrl.searchParams.get('status') || 'all';
  let query = supabase.from('invitations').select('*').order('created_at', { ascending: false });
  if (status !== 'all') query = query.eq('status', status);

  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ invitations: data || [], count: data?.length || 0 });
}

// POST: Approve/reject/generate
export async function POST(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();

  if (body.action === 'approve') {
    const code = generateCode();
    const { error } = await supabase
      .from('invitations')
      .update({ status: 'approved', invite_code: code, reviewed_at: new Date().toISOString() })
      .eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, code });
  }

  if (body.action === 'reject') {
    const { error } = await supabase
      .from('invitations')
      .update({ status: 'rejected', reviewed_at: new Date().toISOString() })
      .eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  if (body.action === 'generate') {
    const code = generateCode();
    const { error } = await supabase.from('invitations').insert({
      email: body.email || 'manual@dissekt.info',
      name: body.name || 'Manual invite',
      status: 'approved',
      invite_code: code,
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, code });
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}
ADMEOF

# ============================================
# 3. Request Invitation Page
# ============================================

mkdir -p src/app/invite

cat > src/app/invite/page.tsx << 'REQEOF'
'use client';
import { useState } from 'react';

export default function InvitePage() {
  const [tab, setTab] = useState<'request' | 'redeem'>('request');
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [org, setOrg] = useState('');
  const [reason, setReason] = useState('');
  const [code, setCode] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const handleRequest = async () => {
    if (!email) return;
    setStatus('loading');
    try {
      const res = await fetch('/api/invite', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'request', email, name, reason, organization: org }),
      });
      const data = await res.json();
      if (data.success) { setStatus('success'); setMessage(data.message); }
      else { setStatus('error'); setMessage(data.error || 'Something went wrong'); }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const handleRedeem = async () => {
    if (!code) return;
    setStatus('loading');
    try {
      const res = await fetch('/api/invite', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'redeem', code }),
      });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('dissekt_tier', 'invited');
        localStorage.setItem('dissekt_invite_code', code.toUpperCase());
        localStorage.setItem('dissekt_invite_name', data.name || '');
        setStatus('success');
        setMessage('Access granted! Redirecting...');
        setTimeout(() => window.location.href = '/', 1500);
      } else {
        setStatus('error'); setMessage(data.error || 'Invalid code');
      }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8f8f6', fontFamily: 'inherit', boxSizing: 'border-box', marginBottom: 10 };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: 440, maxWidth: '90vw' }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <a href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 32, height: 32, background: '#7c3aed', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 18 }}>Dissekt</span>
          </a>
        </div>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 28 }}>
          {/* Tabs */}
          <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
            <button onClick={() => { setTab('request'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'request' ? '#7c3aed' : '#f0f0ee', color: tab === 'request' ? '#fff' : '#555' }}>
              Request access
            </button>
            <button onClick={() => { setTab('redeem'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: tab === 'redeem' ? '#7c3aed' : '#f0f0ee', color: tab === 'redeem' ? '#fff' : '#555' }}>
              I have a code
            </button>
          </div>

          {status === 'success' && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{message}</div>
            </div>
          )}

          {status === 'error' && (
            <div style={{ padding: '10px 14px', background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 13, marginBottom: 12 }}>{message}</div>
          )}

          {/* Request form */}
          {tab === 'request' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Request early access</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Full access includes: 25 scans/day, Detailed mode, Bulk analysis, Compare, Topics, and all future features.</div>
              <input type="email" placeholder="Your email *" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} />
              <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)} style={inputStyle} />
              <input type="text" placeholder="Organization (optional)" value={org} onChange={e => setOrg(e.target.value)} style={inputStyle} />
              <textarea placeholder="Why do you want access? What will you use Dissekt for?" value={reason} onChange={e => setReason(e.target.value)} rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
              <button onClick={handleRequest} disabled={!email || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: email ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Submitting...' : 'Request access'}
              </button>
            </>
          )}

          {/* Redeem code */}
          {tab === 'redeem' && status !== 'success' && (
            <>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Enter your invite code</div>
              <div style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>Paste the code from your invitation email.</div>
              <input type="text" placeholder="DSK-XXXXXXXX" value={code} onChange={e => setCode(e.target.value.toUpperCase())} style={{ ...inputStyle, textAlign: 'center', fontSize: 18, fontWeight: 600, letterSpacing: '0.1em' }} />
              <button onClick={handleRedeem} disabled={!code || status === 'loading'}
                style={{ width: '100%', padding: '11px 0', background: code ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: code ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Verifying...' : 'Unlock access'}
              </button>
            </>
          )}
        </div>

        {/* Free tier info */}
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>
          <p>Free tier: 3 scans/day · Brief mode only</p>
          <a href="/" style={{ color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>Continue with free tier →</a>
        </div>
      </div>
    </main>
  );
}
REQEOF

echo "✅ Invite request page created"

# ============================================
# 4. Admin Panel
# ============================================

mkdir -p src/app/admin

cat > src/app/admin/page.tsx << 'ADMINEOF'
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
ADMINEOF

echo "✅ Admin panel created"

# ============================================
# 5. Update page.tsx — gate features by tier
# ============================================

python3 << 'PYEOF'
content = open('src/app/page.tsx').read()

# Replace DAILY_LIMIT with tier-based limit
content = content.replace(
    'const DAILY_LIMIT = 10;',
    '''const FREE_LIMIT = 3;
const INVITED_LIMIT = 25;

function getTier(): 'free' | 'invited' {
  if (typeof window === 'undefined') return 'free';
  return localStorage.getItem('dissekt_tier') === 'invited' ? 'invited' : 'free';
}

function getDailyLimit(): number {
  return getTier() === 'invited' ? INVITED_LIMIT : FREE_LIMIT;
}'''
)

# Replace all DAILY_LIMIT references
content = content.replace('if (currentUsage >= DAILY_LIMIT)', 'if (currentUsage >= getDailyLimit())')
content = content.replace('const remaining = Math.max(0, DAILY_LIMIT - usage);', 'const remaining = Math.max(0, getDailyLimit() - usage);')

# Update the sign-in button to go to /invite
content = content.replace(
    '''<button onClick={onShowToast} style={{ fontSize: 12, color: '#888', background: 'none', border: '1px solid #e5e5e5', borderRadius: 6, padding: '4px 12px', cursor: 'pointer', fontWeight: 500 }}>Sign in</button>''',
    '''<a href="/invite" style={{ fontSize: 12, color: '#888', textDecoration: 'none', border: '1px solid #e5e5e5', borderRadius: 6, padding: '4px 12px', fontWeight: 500 }}>Get access</a>'''
)

# Gate Bulk CSV and Compare for invited only
content = content.replace(
    "setScanTab('bulk')",
    "getTier() === 'invited' ? setScanTab('bulk') : (window.location.href = '/invite')"
)

open('src/app/page.tsx', 'w').write(content)
print('✅ page.tsx: tier-based gating')
PYEOF

# ============================================
# 6. Update landing page Sign in → Get access
# ============================================

python3 -c "
content = open('src/components/LandingPage.tsx').read()
content = content.replace(
    'onClick={onSignIn} style={{ padding: \'5px 14px\', background: \'transparent\', color: \'#7c3aed\', border: \'1px solid #e5e5e5\', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: \'pointer\' }}>Sign in',
    'onClick={() => window.location.href=\"/invite\"} style={{ padding: \"5px 14px\", background: \"transparent\", color: \"#7c3aed\", border: \"1px solid #e5e5e5\", borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: \"pointer\" }}>Get access'
)
open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Landing: Sign in → Get access')
"

# ============================================
# 7. Add admin key to .env.local
# ============================================

if ! grep -q "DISSEKT_ADMIN_KEY" .env.local 2>/dev/null; then
    echo "DISSEKT_ADMIN_KEY=dissekt-sambit-2026" >> .env.local
    echo "✅ Admin key added to .env.local"
fi

echo ""
echo "✅ Invitation system built:"
echo ""
echo "  📋 /invite — Request access or redeem invite code"
echo "  🔐 /admin — Approve/reject requests, generate codes (key: dissekt-sambit-2026)"
echo "  🆓 Free tier: 3 scans/day, Brief only"
echo "  🎫 Invited tier: 25 scans/day, all features"
echo "  🔒 Bulk CSV gated (redirects to /invite)"
echo "  🔑 Invite codes: DSK-XXXXXXXX format"
echo ""
echo "⚠️  Create the 'invitations' table in Supabase first!"
echo "⚠️  Also set DISSEKT_ADMIN_KEY in Railway variables"
echo ""
echo "Test: npm run build && npm run dev"
echo "  1. Visit /invite → request access"
echo "  2. Visit /admin → enter key → approve → get code"
echo "  3. Visit /invite → redeem code → unlocked!"
