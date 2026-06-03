#!/bin/bash
# Dissekt — Image analysis + drag-drop + camera capture
# Run from inside dissekt-web/
set -e

# ============================================
# Updated ScanInput with image support
# ============================================
cat > src/components/ScanInput.tsx << 'SCANEOF'
'use client';
import { useState, useRef, useCallback } from 'react';

interface Props {
  onScan: (content: string, mode: string, image?: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading }: Props) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');
  const [image, setImage] = useState<string | null>(null);
  const [imageName, setImageName] = useState('');
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const cameraRef = useRef<HTMLInputElement>(null);

  const isUrl = content.trim().startsWith('http');
  const canSubmit = (content.trim().length >= 10 || image) && !loading;

  const processFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) return;
    if (file.size > 10 * 1024 * 1024) { alert('Image must be under 10MB'); return; }
    setImageName(file.name);
    const reader = new FileReader();
    reader.onload = (e) => setImage(e.target?.result as string);
    reader.readAsDataURL(file);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault(); setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) processFile(file);
  }, [processFile]);

  const handlePaste = useCallback((e: React.ClipboardEvent) => {
    const items = e.clipboardData?.items;
    if (!items) return;
    for (const item of Array.from(items)) {
      if (item.type.startsWith('image/')) {
        e.preventDefault();
        const file = item.getAsFile();
        if (file) processFile(file);
        return;
      }
    }
  }, [processFile]);

  const handleSubmit = () => {
    if (!canSubmit) return;
    onScan(content.trim(), mode, image || undefined);
  };

  const removeImage = () => { setImage(null); setImageName(''); };

  return (
    <div>
      {/* Main input row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
          style={{
            flex: 1, display: 'flex', alignItems: 'center', gap: 10,
            background: dragOver ? '#f3e8ff' : '#f5f5f4',
            borderRadius: 10, padding: '10px 14px',
            border: dragOver ? '2px dashed #7c3aed' : '1px solid #e5e5e5',
            transition: 'all 0.15s ease',
          }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#aaa" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input
            type="text" value={content} onChange={e => setContent(e.target.value)}
            placeholder={image ? "Add optional text context..." : "Paste a URL, text, or drop an image..."}
            onKeyDown={e => { if (e.key === 'Enter') handleSubmit(); }}
            onPaste={handlePaste}
            style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: '#1a1a1a' }}
          />
          {isUrl && !image && (
            <span style={{ fontSize: 11, fontWeight: 600, color: '#7c3aed', background: '#f3e8ff', padding: '3px 10px', borderRadius: 20, whiteSpace: 'nowrap' }}>URL</span>
          )}

          {/* Image upload button */}
          <button onClick={() => fileRef.current?.click()} title="Upload image"
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4, display: 'flex', alignItems: 'center', color: '#888' }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/>
            </svg>
          </button>

          {/* Camera capture button */}
          <button onClick={() => cameraRef.current?.click()} title="Capture from camera"
            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4, display: 'flex', alignItems: 'center', color: '#888' }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/><circle cx="12" cy="13" r="4"/>
            </svg>
          </button>

          {/* Hidden file inputs */}
          <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }}
            onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
          <input ref={cameraRef} type="file" accept="image/*" capture="environment" style={{ display: 'none' }}
            onChange={e => { const f = e.target.files?.[0]; if (f) processFile(f); e.target.value = ''; }} />
        </div>

        {/* Mode toggle */}
        <div style={{ display: 'flex', background: '#f0f0ee', borderRadius: 8, padding: 3 }}>
          {(['brief', 'detailed'] as const).map(m => (
            <button key={m} onClick={() => setMode(m)} style={{
              padding: '6px 12px', borderRadius: 6, fontSize: 12, fontWeight: 500, border: 'none', cursor: 'pointer',
              background: mode === m ? '#fff' : 'transparent', color: mode === m ? '#1a1a1a' : '#888',
              boxShadow: mode === m ? '0 1px 3px rgba(0,0,0,0.08)' : 'none', textTransform: 'capitalize'
            }}>{m}</button>
          ))}
        </div>

        {/* Scan button */}
        <button onClick={handleSubmit} disabled={!canSubmit}
          style={{
            display: 'flex', alignItems: 'center', gap: 7, padding: '10px 20px',
            background: canSubmit ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10,
            fontSize: 13, fontWeight: 600, cursor: canSubmit ? 'pointer' : 'not-allowed', whiteSpace: 'nowrap'
          }}>
          {loading ? (
            <><svg style={{ animation: 'spin 0.8s linear infinite' }} width="14" height="14" viewBox="0 0 24 24"><circle opacity="0.25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" fill="none"/><path opacity="0.75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg> Scanning</>
          ) : (
            <><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg> Scan</>
          )}
        </button>
      </div>

      {/* Image preview */}
      {image && (
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'start', gap: 12, padding: 12, background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10 }}>
          <img src={image} alt="Upload preview" style={{ width: 80, height: 80, objectFit: 'cover', borderRadius: 8, border: '1px solid #e5e5e5' }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 500, color: '#404040', marginBottom: 2 }}>{imageName || 'Captured image'}</div>
            <div style={{ fontSize: 12, color: '#888' }}>Image will be analyzed using AI vision to extract text and detect manipulation.</div>
          </div>
          <button onClick={removeImage} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#888', fontSize: 18, padding: 4 }}>✕</button>
        </div>
      )}

      {/* Drop zone hint (shown when dragging) */}
      {dragOver && (
        <div style={{ marginTop: 8, padding: 20, border: '2px dashed #7c3aed', borderRadius: 10, background: '#faf5ff', textAlign: 'center' }}>
          <div style={{ fontSize: 14, fontWeight: 500, color: '#7c3aed' }}>Drop image here</div>
          <div style={{ fontSize: 12, color: '#888', marginTop: 2 }}>PNG, JPG, WEBP up to 10MB</div>
        </div>
      )}
    </div>
  );
}
SCANEOF

echo "✅ ScanInput updated with image upload, drag-drop, camera, paste"

# ============================================
# Updated API route — handles images via GPT-4o vision
# ============================================
cat > src/app/api/scan/route.ts << 'APIEOF'
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

    // If image is provided, extract text using GPT-4o vision
    if (image) {
      try {
        const extracted = await extractTextFromImage(image);
        // Combine: user text (if any) + extracted text from image
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

    // Send extracted text to the Dissekt backend
    const response = await fetch(`${apiUrl}/api/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: textToAnalyze, mode }),
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
APIEOF

echo "✅ API route updated with GPT-4o vision for image text extraction"

# ============================================
# AnalysisResult — remove PDF download
# ============================================
cat > src/components/AnalysisResult.tsx << 'AREOF'
'use client';
import ThreatScore from './ThreatScore';
import PrismCard from './PrismCard';
import SignalCard from './SignalCard';
import TraceCard from './TraceCard';
import MetaCard from './MetaCard';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div>
      <div className="anim-fade"><ThreatScore data={data} /></div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
        <div className="anim-fade anim-d1"><PrismCard prism={data.prism} /></div>
        <div className="anim-fade anim-d2"><TraceCard trace={data.trace} /></div>
        <div className="anim-fade anim-d3"><SignalCard signal={data.signal} /></div>
        <div className="anim-fade anim-d4"><MetaCard data={data} /></div>
      </div>
    </div>
  );
}
AREOF

echo "✅ AnalysisResult simplified (PDF download removed)"
echo ""
echo "Features added:"
echo "  📷 Upload image (click camera/image icon)"
echo "  📋 Paste image from clipboard (Ctrl+V)"
echo "  🖱️ Drag & drop image onto input"
echo "  📱 Camera capture (mobile)"
echo "  🔍 GPT-4o vision extracts text + detects visual manipulation"
echo "  ❌ PDF download removed"
echo ""
echo "Run: npm run dev"
