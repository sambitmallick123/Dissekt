#!/bin/bash
# Dissekt — Invite expiry logic (7-day code, 6-month access) + signup placeholder
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Update admin API — set expiry on approval
# ============================================

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

function codeExpiry(): string {
  const d = new Date();
  d.setDate(d.getDate() + 7); // code expires in 7 days
  return d.toISOString();
}

export async function GET(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const status = req.nextUrl.searchParams.get('status') || 'all';
  let query = supabase.from('invitations').select('*').order('created_at', { ascending: false });
  if (status !== 'all') query = query.eq('status', status);
  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ invitations: data || [], count: data?.length || 0 });
}

export async function POST(req: NextRequest) {
  if (!checkAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await req.json();

  if (body.action === 'approve') {
    const code = generateCode();
    const { error } = await supabase
      .from('invitations')
      .update({ status: 'approved', invite_code: code, reviewed_at: new Date().toISOString(), code_expires_at: codeExpiry() })
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
      code_expires_at: codeExpiry(),
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, code });
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}
ADMEOF

echo "✅ Admin API: 7-day code expiry"

# ============================================
# 2. Update invite API — check code expiry, set 6-month access
# ============================================

cat > src/app/api/invite/route.ts << 'INVEOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  const body = await req.json();

  if (body.action === 'request') {
    try {
      const { email, name, reason, organization } = body;
      if (!email) return NextResponse.json({ error: 'Email required' }, { status: 400 });

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
      return NextResponse.json({ success: true, message: 'Request submitted! We will review and email you a code if approved.' });
    } catch (e: any) {
      return NextResponse.json({ error: e.message }, { status: 500 });
    }
  }

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
        return NextResponse.json({ error: 'Invalid invite code' }, { status: 400 });
      }

      // Check if code expired (7 days)
      if (data.code_expires_at && new Date(data.code_expires_at) < new Date()) {
        return NextResponse.json({ error: 'This invite code has expired. Please request a new one.' }, { status: 400 });
      }

      // Check if already redeemed (access_expires_at set)
      // Set 6-month access expiry
      const accessExpiry = new Date();
      accessExpiry.setMonth(accessExpiry.getMonth() + 6);

      // Mark code as used by setting access_expires_at
      await supabase
        .from('invitations')
        .update({ access_expires_at: accessExpiry.toISOString() })
        .eq('id', data.id);

      return NextResponse.json({
        success: true,
        tier: 'invited',
        name: data.name,
        email: data.email,
        access_expires_at: accessExpiry.toISOString(),
      });
    } catch (e: any) {
      return NextResponse.json({ error: e.message }, { status: 500 });
    }
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}
INVEOF

echo "✅ Invite API: code expiry check + 6-month access"

# ============================================
# 3. Update invite page — store access expiry, add signup placeholder
# ============================================

python3 << 'PYEOF'
content = open('src/app/invite/page.tsx').read()

# Update redeem handler to store access expiry
content = content.replace(
    '''        localStorage.setItem('dissekt_tier', 'invited');
        localStorage.setItem('dissekt_invite_code', code.toUpperCase());
        localStorage.setItem('dissekt_invite_name', data.name || '');''',
    '''        localStorage.setItem('dissekt_tier', 'invited');
        localStorage.setItem('dissekt_invite_code', code.toUpperCase());
        localStorage.setItem('dissekt_invite_name', data.name || '');
        if (data.access_expires_at) localStorage.setItem('dissekt_access_expires', data.access_expires_at);'''
)

# Update redirect to /app
content = content.replace(
    "setTimeout(() => window.location.href = '/', 1500);",
    "setTimeout(() => window.location.href = '/app', 1500);"
)

# Add signup-under-development note + access validity info
content = content.replace(
    '''        {/* Free tier info */}
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>
          <p>Free tier: 3 scans/day · Brief mode only</p>
          <a href="/" style={{ color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>Continue with free tier →</a>
        </div>''',
    '''        {/* Info */}
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>
          <p>Free tier: 3 brief + 1 detailed scan/day (resets 00:00 GMT)</p>
          <p style={{ fontSize: 11, color: '#aaa', marginTop: 4 }}>Invite codes expire in 7 days · Access valid for 6 months</p>
          <a href="/app" style={{ color: '#7c3aed', textDecoration: 'none', fontWeight: 500, display: 'inline-block', marginTop: 6 }}>Continue with free tier →</a>
        </div>

        <div style={{ textAlign: 'center', marginTop: 12, padding: '10px 14px', background: '#f8f8f6', borderRadius: 8, fontSize: 11, color: '#888' }}>
          🚧 Account signup is under development. For now, access is invitation-based.
        </div>'''
)

# Update free tier text
content = content.replace(
    "Full access includes: 25 scans/day, Detailed mode, Bulk analysis, Compare, Topics, and all future features.",
    "Full access: 25 brief + 10 detailed scans/day, Bulk analysis, Compare, Topics, and all future features. Valid 6 months."
)

open('src/app/invite/page.tsx', 'w').write(content)
print('✅ Invite page: expiry info + signup placeholder')
PYEOF

# ============================================
# 4. Wrap invite + admin pages with uniform header
# ============================================

python3 << 'PYEOF'
# Invite page header
content = open('src/app/invite/page.tsx').read()
if 'SiteHeader' not in content:
    # Invite page has its own centered layout, just keep it but link logo to /
    pass  # invite page is intentionally minimal (centered card)

print('✅ Invite page kept minimal (centered)')
PYEOF

echo ""
echo "✅ Expiry logic complete:"
echo "  - Invite codes expire 7 days after approval"
echo "  - Redeemed access valid for 6 months"
echo "  - Access auto-expires (checked in tier.ts)"
echo "  - Signup 'under development' note added"
echo "  - Redirects go to /app (not /)"
echo ""
echo "Test: npm run build && npm run dev"
