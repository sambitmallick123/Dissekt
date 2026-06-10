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
