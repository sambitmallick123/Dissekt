import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { name, email, subject, message } = await req.json();
    if (!message) return NextResponse.json({ error: 'Message required' }, { status: 400 });

    const RESEND_KEY = process.env.RESEND_API_KEY || '';
    if (!RESEND_KEY) return NextResponse.json({ error: 'Email not configured' }, { status: 500 });

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'Dissekt Contact <onboarding@resend.dev>',
        to: 'sambitmallick123@gmail.com',
        subject: `[Dissekt Contact] ${subject || 'New message'}`,
        html: `
          <h3>New contact from Dissekt</h3>
          <p><strong>Subject:</strong> ${subject || 'General'}</p>
          <p><strong>Name:</strong> ${name || 'Not provided'}</p>
          <p><strong>Email:</strong> ${email || 'Not provided'}</p>
          <hr/>
          <p>${message.replace(/\n/g, '<br/>')}</p>
        `,
      }),
    });

    if (res.ok) return NextResponse.json({ success: true });
    return NextResponse.json({ error: 'Failed to send' }, { status: 500 });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
