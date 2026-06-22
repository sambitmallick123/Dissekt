import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  const { name, email, message, type, component, source } = await req.json();

  if (!message || !message.trim()) {
    return NextResponse.json({ error: 'Message required' }, { status: 400 });
  }

  const senderEmail = email || 'sambitmallick123@gmail.com';
  const meta = `Type: ${type || 'feedback'} | Component: ${component || 'general'} | Source: ${source || 'unknown'}`;
  const rawWithMeta = `${meta}\n\n${message}`;

  // Store in Supabase (same columns the old route used)
  await supabase.from('feedback').insert({
    name: name || 'Anonymous',
    email: senderEmail,
    raw_feedback: rawWithMeta,
    formatted_feedback: message,
  });

  // Send email via Resend
  const resendKey = process.env.RESEND_API_KEY;
  if (resendKey) {
    try {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${resendKey}`,
        },
        body: JSON.stringify({
          from: 'Dissekt Feedback <onboarding@resend.dev>',
          to: ['sambitmallick123@gmail.com'],
          subject: `Dissekt Feedback (${type || 'feedback'}) from ${name || 'Anonymous'}`,
          text: `${meta}\nFrom: ${name || 'Anonymous'} (${senderEmail})\n\n${message}`,
          reply_to: senderEmail,
        }),
      });
    } catch (e) {
      console.error('Resend failed:', e);
    }
  }

  return NextResponse.json({ success: true });
}
