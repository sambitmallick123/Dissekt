import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  const { text, kind } = await req.json();

  if (!text || !text.trim()) {
    return NextResponse.json({ error: 'Text required' }, { status: 400 });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return NextResponse.json({ formatted: text, note: 'no_api_key' });

  const context =
    kind === 'feedback'
      ? 'The message is product feedback for Dissekt, a journalism tool that detects manipulation in content.'
      : 'The message is an inquiry to the Dissekt team.';

  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        max_tokens: 400,
        temperature: 0.5,
        messages: [
          {
            role: 'system',
            content: `You turn rough input into clear, professional message text. ${context}

The user may give you only keywords, fragments, half-finished sentences, or brainstorming notes. Work out what they are trying to say and express it as polished, complete, professional sentences.

Rules:
- Expand keywords and fragments into full, well-structured sentences.
- Fix all grammar, spelling, and phrasing.
- Preserve the user's actual intent and any specific details they mention (names, numbers, feature or component names). Do NOT invent facts, examples, or details they did not imply.
- Keep it concise and to the point — no padding or filler.
- Do not add greetings, signoffs, or address the reader.
- Return ONLY the rewritten message text, with no preamble, quotes, or markdown.`,
          },
          { role: 'user', content: text },
        ],
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      return NextResponse.json({ formatted: text, note: 'openai_error', detail: err.slice(0, 300) });
    }
    const data = await res.json();
    const formatted = data.choices?.[0]?.message?.content?.trim() || text;
    return NextResponse.json({ formatted });
  } catch (e: any) {
    return NextResponse.json({ formatted: text, note: 'exception', detail: String(e).slice(0, 300) });
  }
}
