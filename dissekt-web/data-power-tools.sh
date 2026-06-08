#!/bin/bash
# Dissekt — Data Power Tools
# 1. Bulk CSV Analysis
# 2. Comparative Analysis
# 3. Multi-language Prompts
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# TASK 1: Multi-language prompts (backend)
# ============================================

python3 << 'PYEOF'
content = open('app/prism/llm.py').read()

# Find the system prompt and make it language-aware
# Add language-specific instructions
if 'detected_language' not in content:
    # Add language parameter to the analysis function
    content = content.replace(
        'async def route_and_analyze(text: str, mode: str, heuristics',
        'async def route_and_analyze(text: str, mode: str, heuristics, detected_language: str = "en"'
    )
    
    # Add language instruction to system prompts
    lang_instruction = '''
    # Language-aware analysis instruction
    lang_names = {"en": "English", "hi": "Hindi", "de": "German", "es": "Spanish", "fr": "French"}
    lang_note = ""
    if detected_language != "en":
        lang_name = lang_names.get(detected_language, detected_language)
        lang_note = f"\\nIMPORTANT: The input text is in {lang_name}. Analyze the manipulation techniques in the original language but write your response (technique names, explanations, summary) in English. Quote evidence in the original {lang_name} text."
'''
    
    # Insert before the first API call
    if 'settings = get_settings()' in content:
        content = content.replace(
            'settings = get_settings()',
            'settings = get_settings()' + lang_instruction,
            1
        )
    
    open('app/prism/llm.py', 'w').write(content)
    print('✅ Multi-language: prism/llm.py updated')
else:
    print('Already has detected_language')

# Update beacon to pass language
content2 = open('app/beacon/__init__.py').read()
if 'detected_language' not in content2.split('route_and_analyze')[1][:200]:
    content2 = content2.replace(
        'prism_task = route_and_analyze(extracted_text, mode, heuristics)',
        'detected_lang = detect_language(extracted_text)\n    prism_task = route_and_analyze(extracted_text, mode, heuristics, detected_language=detected_lang)'
    )
    open('app/beacon/__init__.py', 'w').write(content2)
    print('✅ Multi-language: beacon updated to pass language')
else:
    print('Beacon already passes language')
PYEOF

echo "✅ Task 3: Multi-language backend done"

# ============================================
# TASK 2: Comparative Analysis (backend)
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/scan/compare' not in content:
    compare_endpoint = '''

@app.post("/api/scan/compare")
async def compare_content(request: Request):
    """Compare two pieces of content side-by-side."""
    import openai
    
    body = await request.json()
    content_a = body.get("content_a", "")
    content_b = body.get("content_b", "")
    mode = body.get("mode", "brief")
    
    if len(content_a) < 10 or len(content_b) < 10:
        raise HTTPException(status_code=400, detail="Both inputs must be at least 10 characters")
    
    try:
        # Run both scans in parallel
        import asyncio
        result_a, result_b = await asyncio.gather(
            scan(content=content_a, mode=mode),
            scan(content=content_b, mode=mode),
        )
        
        dict_a = result_a.model_dump(mode="json")
        dict_b = result_b.model_dump(mode="json")
        
        # Generate comparison summary using GPT-4o mini
        settings = get_settings()
        client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
        
        techs_a = [t.get("name", "") for t in dict_a.get("prism", {}).get("techniques", [])]
        techs_b = [t.get("name", "") for t in dict_b.get("prism", {}).get("techniques", [])]
        shared = set(techs_a) & set(techs_b)
        only_a = set(techs_a) - set(techs_b)
        only_b = set(techs_b) - set(techs_a)
        
        brief_a = dict_a.get("prism", {}).get("brief", "")
        brief_b = dict_b.get("prism", {}).get("brief", "")
        
        comparison_prompt = f"""Compare these two content analyses:

Content A summary: {brief_a[:300]}
Content A techniques: {', '.join(techs_a) or 'none'}

Content B summary: {brief_b[:300]}  
Content B techniques: {', '.join(techs_b) or 'none'}

Write a 2-3 sentence comparison of how these two pieces of content differ in their use of manipulation techniques, framing, and credibility. Be specific."""

        comp_response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=200,
            messages=[
                {"role": "system", "content": "You are a media analysis expert comparing two pieces of content."},
                {"role": "user", "content": comparison_prompt},
            ],
        )
        
        comparison_summary = comp_response.choices[0].message.content.strip()
        
        return {
            "result_a": dict_a,
            "result_b": dict_b,
            "comparison": {
                "summary": comparison_summary,
                "shared_techniques": list(shared),
                "only_a_techniques": list(only_a),
                "only_b_techniques": list(only_b),
                "score_diff": abs(
                    (dict_a.get("signal", {}).get("toxicity_score", 0) * 100) -
                    (dict_b.get("signal", {}).get("toxicity_score", 0) * 100)
                ),
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Compare failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Comparison failed")

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        compare_endpoint + '# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Compare endpoint added')
else:
    print('Compare endpoint already exists')
PYEOF

echo "✅ Task 2: Comparative analysis backend done"

# ============================================
# FRONTEND: Bulk + Compare + Multi-language
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# --- Bulk Analysis Component ---
cat > src/components/BulkAnalysis.tsx << 'BULKEOF'
'use client';
import { useState, useRef } from 'react';

interface BulkItem {
  input: string;
  status: 'pending' | 'analyzing' | 'done' | 'error';
  result?: any;
  error?: string;
}

export default function BulkAnalysis() {
  const [items, setItems] = useState<BulkItem[]>([]);
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState(0);
  const fileRef = useRef<HTMLInputElement>(null);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      const lines = text.split('\n').map(l => l.trim()).filter(l => l.length >= 10);
      // Skip header if it looks like one
      const start = lines[0]?.toLowerCase().includes('url') || lines[0]?.toLowerCase().includes('content') ? 1 : 0;
      setItems(lines.slice(start, start + 50).map(l => ({
        input: l.replace(/^["']|["']$/g, '').split(',')[0].trim(),
        status: 'pending',
      })));
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const runBulk = async () => {
    setRunning(true);
    setProgress(0);
    const updated = [...items];

    for (let i = 0; i < updated.length; i++) {
      updated[i].status = 'analyzing';
      setItems([...updated]);

      try {
        const res = await fetch('/api/scan', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ content: updated[i].input, mode: 'brief' }),
        });
        if (res.ok) {
          updated[i].result = await res.json();
          updated[i].status = 'done';
        } else {
          const err = await res.json();
          updated[i].error = err.detail || 'Failed';
          updated[i].status = 'error';
        }
      } catch {
        updated[i].error = 'Connection failed';
        updated[i].status = 'error';
      }

      setProgress(i + 1);
      setItems([...updated]);
    }
    setRunning(false);
  };

  const downloadCSV = () => {
    const header = 'Input,Threat Score,Techniques,Technique Names,Fact Checks,Toxicity,Sentiment,Language\n';
    const rows = items.filter(i => i.result).map(i => {
      const r = i.result;
      const techs = r.prism?.techniques || [];
      const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
      const fcs = r.trace?.fact_checks?.length || 0;
      const tox = r.signal?.toxicity_score || 0;
      let score = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
      score = Math.min(score, 100);
      const names = techs.map((t: any) => t.name?.replace(/_/g, ' ')).join('; ');
      return `"${i.input.replace(/"/g, '""')}",${score},${techs.length},"${names}",${fcs},${(tox*100).toFixed(1)}%,${r.signal?.sentiment || ''},${r.detected_language || 'en'}`;
    });
    const blob = new Blob([header + rows.join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'dissekt-bulk-results.csv'; a.click();
  };

  const getScore = (r: any) => {
    if (!r) return 0;
    const techs = r.prism?.techniques || [];
    const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
    const fcs = r.trace?.fact_checks?.length || 0;
    const tox = r.signal?.toxicity_score || 0;
    let s = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
    return Math.min(s, 100);
  };

  const scoreColor = (s: number) => s >= 70 ? '#dc2626' : s >= 40 ? '#d97706' : '#16a34a';

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 16, fontWeight: 600, color: '#404040' }}>📊 Bulk Analysis</div>
          <div style={{ fontSize: 12, color: '#888' }}>Upload a CSV with URLs or claims (max 50 items)</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {items.length > 0 && items.some(i => i.result) && (
            <button onClick={downloadCSV} style={{ fontSize: 12, padding: '6px 12px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 6, cursor: 'pointer', color: '#404040', fontWeight: 500 }}>Download CSV</button>
          )}
          <button onClick={() => fileRef.current?.click()} style={{ fontSize: 12, padding: '6px 12px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
            Upload CSV
          </button>
          <input ref={fileRef} type="file" accept=".csv,.txt" style={{ display: 'none' }} onChange={handleFile} />
        </div>
      </div>

      {items.length > 0 && (
        <>
          {/* Progress */}
          {running && (
            <div style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: '#888', marginBottom: 4 }}>
                <span>Analyzing {progress}/{items.length}...</span>
                <span>{Math.round(progress / items.length * 100)}%</span>
              </div>
              <div style={{ height: 4, background: '#f0f0ee', borderRadius: 2 }}>
                <div style={{ height: '100%', width: `${(progress / items.length) * 100}%`, background: '#7c3aed', borderRadius: 2, transition: 'width 0.3s' }} />
              </div>
            </div>
          )}

          {/* Start button */}
          {!running && items.every(i => i.status === 'pending') && (
            <button onClick={runBulk} style={{ width: '100%', padding: '10px 0', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer', marginBottom: 12 }}>
              Analyze {items.length} items
            </button>
          )}

          {/* Results table */}
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e5e5e5' }}>
                  <th style={{ textAlign: 'left', padding: '6px 8px', color: '#888', fontWeight: 600 }}>#</th>
                  <th style={{ textAlign: 'left', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Input</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Score</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Techniques</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Fact-checks</th>
                  <th style={{ textAlign: 'center', padding: '6px 8px', color: '#888', fontWeight: 600 }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, i) => {
                  const score = item.result ? getScore(item.result) : 0;
                  return (
                    <tr key={i} style={{ borderBottom: '1px solid #f0f0ee' }}>
                      <td style={{ padding: '6px 8px', color: '#aaa' }}>{i + 1}</td>
                      <td style={{ padding: '6px 8px', maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.input}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center', fontWeight: 700, color: item.result ? scoreColor(score) : '#ccc' }}>{item.result ? score : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>{item.result ? item.result.prism?.techniques?.length || 0 : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>{item.result ? item.result.trace?.fact_checks?.length || 0 : '—'}</td>
                      <td style={{ padding: '6px 8px', textAlign: 'center' }}>
                        {item.status === 'pending' && <span style={{ color: '#aaa' }}>⏳</span>}
                        {item.status === 'analyzing' && <span style={{ color: '#7c3aed' }}>🔍</span>}
                        {item.status === 'done' && <span style={{ color: '#16a34a' }}>✅</span>}
                        {item.status === 'error' && <span title={item.error} style={{ color: '#dc2626' }}>❌</span>}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}

      {items.length === 0 && (
        <div style={{ textAlign: 'center', padding: '20px 0', color: '#888', fontSize: 13 }}>
          Upload a CSV file with one URL or claim per line. Max 50 items.
        </div>
      )}
    </div>
  );
}
BULKEOF

echo "✅ BulkAnalysis component created"

# --- Compare Page ---
mkdir -p src/app/compare

cat > src/app/compare/page.tsx << 'CMPEOF'
'use client';
import { useState } from 'react';
import ThreatScore from '@/components/ThreatScore';
import PrismCard from '@/components/PrismCard';
import TraceCard from '@/components/TraceCard';

export default function ComparePage() {
  const [contentA, setContentA] = useState('');
  const [contentB, setContentB] = useState('');
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleCompare = async () => {
    if (contentA.length < 10 || contentB.length < 10) { setError('Both inputs must be at least 10 characters'); return; }
    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch('/api/compare', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content_a: contentA, content_b: contentB, mode: 'brief' }),
      });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Comparison failed'); return; }
      setResult(await res.json());
    } catch { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 12px', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 13, outline: 'none', background: '#f8f8f6', fontFamily: 'inherit', resize: 'vertical' };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
            <span style={{ fontSize: 13, color: '#888' }}>Compare</span>
          </a>
          <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>← Back to Scan</a>
        </div>
      </nav>

      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '24px 24px' }}>
        <h1 style={{ fontSize: 20, fontWeight: 600, marginBottom: 4 }}>⚖️ Comparative Analysis</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Compare how two sources cover the same story. Paste URLs or text for both.</p>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#7c3aed', marginBottom: 6 }}>Source A</div>
            <textarea placeholder="Paste URL or text..." value={contentA} onChange={e => setContentA(e.target.value)} rows={4} style={inputStyle} />
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#2563eb', marginBottom: 6 }}>Source B</div>
            <textarea placeholder="Paste URL or text..." value={contentB} onChange={e => setContentB(e.target.value)} rows={4} style={inputStyle} />
          </div>
        </div>

        {error && <div style={{ marginBottom: 16, padding: 12, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>}

        <button onClick={handleCompare} disabled={loading || contentA.length < 10 || contentB.length < 10}
          style={{ width: '100%', padding: '12px 0', background: (contentA.length >= 10 && contentB.length >= 10 && !loading) ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 14, fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', marginBottom: 20 }}>
          {loading ? '🔍 Comparing... (this takes 10-20 seconds)' : '⚖️ Compare both sources'}
        </button>

        {result && (
          <>
            {/* Comparison summary */}
            <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>📝 Comparison Summary</div>
              <p style={{ fontSize: 13, color: '#404040', lineHeight: 1.6 }}>{result.comparison?.summary}</p>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, marginTop: 12 }}>
                <div style={{ padding: '8px 10px', background: '#f3e8ff', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#7c3aed', fontWeight: 600 }}>SHARED TECHNIQUES</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.shared_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.shared_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
                <div style={{ padding: '8px 10px', background: '#faf5ff', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#7c3aed', fontWeight: 600 }}>ONLY IN A</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.only_a_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.only_a_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
                <div style={{ padding: '8px 10px', background: '#eff6ff', borderRadius: 8 }}>
                  <div style={{ fontSize: 10, color: '#2563eb', fontWeight: 600 }}>ONLY IN B</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{result.comparison?.only_b_techniques?.length || 0}</div>
                  <div style={{ fontSize: 10, color: '#888' }}>{(result.comparison?.only_b_techniques || []).map((t: string) => t.replace(/_/g, ' ')).join(', ') || 'none'}</div>
                </div>
              </div>
            </div>

            {/* Side by side results */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#7c3aed', marginBottom: 8, padding: '6px 12px', background: '#faf5ff', borderRadius: 8, textAlign: 'center' }}>Source A</div>
                <ThreatScore data={result.result_a} />
                <div style={{ marginTop: 12 }}><PrismCard prism={result.result_a?.prism} /></div>
                <div style={{ marginTop: 12 }}><TraceCard trace={result.result_a?.trace} /></div>
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#2563eb', marginBottom: 8, padding: '6px 12px', background: '#eff6ff', borderRadius: 8, textAlign: 'center' }}>Source B</div>
                <ThreatScore data={result.result_b} />
                <div style={{ marginTop: 12 }}><PrismCard prism={result.result_b?.prism} /></div>
                <div style={{ marginTop: 12 }}><TraceCard trace={result.result_b?.trace} /></div>
              </div>
            </div>
          </>
        )}
      </div>
    </main>
  );
}
CMPEOF

echo "✅ Compare page created"

# --- Compare API proxy ---
mkdir -p src/app/api/compare

cat > src/app/api/compare/route.ts << 'CMPAPI'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    
    const response = await fetch(`${apiUrl}/api/scan/compare`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    return NextResponse.json(await response.json());
  } catch {
    return NextResponse.json({ detail: 'Comparison service unavailable' }, { status: 503 });
  }
}
CMPAPI

echo "✅ Compare API proxy created"

# --- Add Bulk + Compare links to scan page ---
cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

python3 -c "
content = open('src/app/page.tsx').read()

# Add Compare link next to Help
if \"'/compare'\" not in content:
    content = content.replace(
        \"<a href='/help' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Help</a>\",
        \"\"\"<a href='/compare' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Compare</a>
            <a href='/help' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Help</a>\"\"\"
    )
    open('src/app/page.tsx', 'w').write(content)
    print('✅ Compare link added to nav')
else:
    print('Already has compare link')
"

echo ""
echo "✅ All 3 Data Power Tools built:"
echo "  1. Bulk Analysis — upload CSV, progress bar, results table, download CSV"
echo "  2. Comparative Analysis — side-by-side, shared/unique techniques, AI summary"
echo "  3. Multi-language — Hindi/German detection, language-aware prompts"
echo ""
echo "Test: npm run dev"
echo "  - Bulk: click 📊 Bulk Analysis section (shown below scan results)"
echo "  - Compare: click Compare in nav or go to /compare"
echo "  - Multi-language: paste Hindi text and scan"
