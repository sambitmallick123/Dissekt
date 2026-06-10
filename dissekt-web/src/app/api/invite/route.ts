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
