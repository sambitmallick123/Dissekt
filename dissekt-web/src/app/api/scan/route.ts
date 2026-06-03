import { NextRequest, NextResponse } from 'next/server';

async function extractTextFromImage(imageBase64: string): Promise<string> {
  const openaiKey = process.env.OPENAI_API_KEY;
  if (!openaiKey) throw new Error('OpenAI key not configured for image analysis');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${openaiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      max_tokens: 1500,
      messages: [
        {
          role: 'system',
          content: `You are an expert content analyst. Given an image, do the following:
1. Extract ALL visible text from the image exactly as written.
2. Describe the image context briefly (what kind of content is this — news screenshot, social media post, WhatsApp forward, meme, infographic, etc.)
3. Note any visual manipulation signals (misleading graphics, emotional imagery, out-of-context photos, doctored images).

Format your response as:
EXTRACTED TEXT:
[all text from the image]

CONTENT TYPE: [type]

VISUAL NOTES: [any manipulation signals in the visuals]`
        },
        {
          role: 'user',
          content: [
            { type: 'image_url', image_url: { url: imageBase64 } },
            { type: 'text', text: 'Extract and analyze this image.' }
          ]
        }
      ]
    }),
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error?.message || 'Image analysis failed');
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { content, mode, image } = body;
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    let textToAnalyze = content || '';
    const isImage = !!image;

    // If image provided, extract text using GPT-4o mini vision
    if (isImage) {
      try {
        const extracted = await extractTextFromImage(image);
        if (textToAnalyze) {
          textToAnalyze = `${textToAnalyze}\n\n--- Extracted from uploaded image ---\n${extracted}`;
        } else {
          textToAnalyze = extracted;
        }
      } catch (e: any) {
        return NextResponse.json(
          { detail: `Image analysis failed: ${e.message}` },
          { status: 400 }
        );
      }
    }

    if (!textToAnalyze || textToAnalyze.trim().length < 10) {
      return NextResponse.json(
        { detail: 'Could not extract enough text from the image. Try a clearer image or paste the text directly.' },
        { status: 400 }
      );
    }

    // For images: always use "brief" mode (GPT-4o mini) since vision
    // extraction already used the same model — keeps analysis consistent
    const analysisMode = isImage ? 'brief' : mode;

    const response = await fetch(`${apiUrl}/api/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: textToAnalyze, mode: analysisMode }),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { detail: 'Analysis service unavailable. Please try again.' },
      { status: 503 }
    );
  }
}
