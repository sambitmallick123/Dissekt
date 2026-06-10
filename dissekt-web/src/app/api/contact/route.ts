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
