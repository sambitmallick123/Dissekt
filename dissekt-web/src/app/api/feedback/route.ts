import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  const { action, name, email, feedback, formatted } = await req.json();

  // Action 1: Format feedback with GPT-4o mini
  if (action === 'format') {
    try {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          max_tokens: 300,
          messages: [
            {
              role: 'system',
              content: `You are a feedback formatter for Dissekt, a journalism tool that detects manipulation in content. Take the user's raw feedback and reformat it into a clean, structured summary. Keep their voice but fix grammar and organize. Format:

**From:** [name] ([email])
**Type:** [Bug Report / Feature Request / General Feedback / Praise / Complaint]
**Summary:** [1-2 sentence summary]
**Details:** [cleaned up version, keep their intent intact]
**Suggested Action:** [what the team could do, if applicable]`
            },
            {
              role: 'user',
              content: `Name: ${name || 'Anonymous'}\nEmail: ${email || 'Not provided'}\nRaw feedback: ${feedback}`
            }
          ]
        }),
      });

      if (!response.ok) return NextResponse.json({ formatted: feedback });
      const data = await response.json();
      return NextResponse.json({ formatted: data.choices?.[0]?.message?.content || feedback });
    } catch {
      return NextResponse.json({ formatted: feedback });
    }
  }

  // Action 2: Send feedback (store in Supabase + send email)
  if (action === 'send') {
    const senderEmail = email || 'sambitmallick123@gmail.com';

    // Store in Supabase
    try {
      await supabase.from('feedback').insert({
        name: name || 'Anonymous',
        email: senderEmail,
        raw_feedback: feedback,
        formatted_feedback: formatted,
      });
    } catch (e) {
      console.error('Supabase insert failed:', e);
    }

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
            subject: `Dissekt Feedback from ${name || 'Anonymous'}`,
            text: formatted || feedback,
            reply_to: senderEmail,
          }),
        });
      } catch (e) {
        console.error('Resend failed:', e);
      }
    }

    return NextResponse.json({ success: true });
  }

  return NextResponse.json({ error: 'Unknown action' }, { status: 400 });
}
