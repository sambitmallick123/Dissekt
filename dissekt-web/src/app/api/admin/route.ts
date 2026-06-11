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


  // Mark feedback/contact as read/replied
  if (body.action === 'mark_status') {
    const table = body.table;
    const newStatus = body.status;
    if (!['feedback', 'contacts'].includes(table)) return NextResponse.json({ error: 'Invalid table' }, { status: 400 });
    const { error } = await supabase.from(table).update({ status: newStatus }).eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }


  // Revoke user access
  if (body.action === 'revoke') {
    const { error } = await supabase
      .from('invitations')
      .update({ status: 'rejected', access_expires_at: new Date().toISOString() })
      .eq('id', body.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Notify user
    const { data: inv } = await supabase.from('invitations').select('email, name').eq('id', body.id).single();
    if (inv?.email) {
      await sendEmail(inv.email, 'Dissekt access update', '<p>Your Dissekt access has been revoked. Contact us for more info.</p>');
    }
    return NextResponse.json({ success: true });
  }

  // Update platform config
  if (body.action === 'update_config') {
    const { key, value } = body;
    const { error } = await supabase
      .from('platform_config')
      .upsert({ key, value, updated_at: new Date().toISOString() });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  // Get platform config
  if (body.action === 'get_config') {
    const { data } = await supabase.from('platform_config').select('*');
    const config: Record<string, any> = {};
    (data || []).forEach((row: any) => { config[row.key] = row.value; });
    return NextResponse.json({ config });
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}

// GET: List invitations, feedback, contacts, stats
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
}
