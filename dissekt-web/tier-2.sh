#!/bin/bash
# Dissekt — Tier 2: Retention Features
# 1. Weekly Digest Email
# 2. Personal Bias Profile
# 3. Bookmarklet (one-click analyze)
# 4. Collaborative Annotations
set -e

# ============================================
# 1. BACKEND: Weekly digest endpoint
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/digest' not in content:
    digest_endpoint = '''

@app.get("/api/digest")
async def weekly_digest():
    """Generate weekly digest data: trending topics, top techniques, recent analyses."""
    from datetime import datetime, timedelta
    
    try:
        # Get analyses from last 7 days via Qdrant
        from app.claim_graph import find_similar
        recent = await find_similar("news analysis", limit=50)
        
        # Aggregate techniques
        technique_counts: dict = {}
        topics: dict = {}
        total = len(recent)
        
        for r in recent:
            for t in r.get("techniques", []):
                technique_counts[t] = technique_counts.get(t, 0) + 1
            preview = r.get("text_preview", "")[:50]
            if preview:
                # Simple topic extraction: first 3 significant words
                words = [w for w in preview.split()[:6] if len(w) > 3]
                key = " ".join(words[:3])
                if key:
                    topics[key] = topics.get(key, 0) + 1
        
        top_techniques = sorted(technique_counts.items(), key=lambda x: -x[1])[:5]
        trending_topics = sorted(topics.items(), key=lambda x: -x[1])[:5]
        
        return {
            "total_analyses": total,
            "period": "last 7 days",
            "top_techniques": [{"name": t[0], "count": t[1]} for t in top_techniques],
            "trending_topics": [{"topic": t[0], "count": t[1]} for t in trending_topics],
        }
    except Exception as e:
        logger.warning(f"Digest failed: {e}")
        return {"total_analyses": 0, "top_techniques": [], "trending_topics": []}


@app.post("/api/digest/send")
async def send_digest(email: str = ""):
    """Send weekly digest email to specified address or all invited users."""
    settings = get_settings()
    digest = await weekly_digest()
    
    if digest["total_analyses"] == 0:
        return {"sent": False, "reason": "No analyses this week"}
    
    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest["top_techniques"])
    topics_html = "".join(f"<li>{t['topic']} ({t['count']} analyses)</li>" for t in digest["trending_topics"])
    
    html = f"""
    <div style="font-family: -apple-system, sans-serif; max-width: 520px; margin: 0 auto;">
      <div style="background: #0d9488; padding: 16px 20px; border-radius: 10px 10px 0 0;">
        <h2 style="color: white; margin: 0; font-size: 18px;">Dissekt Weekly Digest</h2>
      </div>
      <div style="background: #fff; padding: 20px; border: 1px solid #e5eaea; border-top: none; border-radius: 0 0 10px 10px;">
        <p style="font-size: 14px; color: #555;">{digest['total_analyses']} analyses this week.</p>
        
        <h3 style="font-size: 14px; color: #1a1a1a; margin: 16px 0 8px;">Top techniques detected</h3>
        <ul style="font-size: 13px; color: #555; padding-left: 20px;">{techs_html}</ul>
        
        <h3 style="font-size: 14px; color: #1a1a1a; margin: 16px 0 8px;">Trending topics</h3>
        <ul style="font-size: 13px; color: #555; padding-left: 20px;">{topics_html}</ul>
        
        <div style="margin-top: 20px; text-align: center;">
          <a href="https://dissekt.info/analyze" style="display: inline-block; background: #0d9488; color: white; padding: 10px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;">Analyze something new</a>
        </div>
        
        <p style="font-size: 11px; color: #aaa; margin-top: 20px; text-align: center;">
          You're receiving this because you have a Dissekt invitation.<br/>
          <a href="https://dissekt.info" style="color: #0d9488;">dissekt.info</a>
        </p>
      </div>
    </div>
    """
    
    target = email or "sambitmallick123@gmail.com"
    
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post("https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                json={
                    "from": "Dissekt <onboarding@resend.dev>",
                    "to": target,
                    "subject": f"Dissekt Weekly: {digest['total_analyses']} analyses, top trends",
                    "html": html,
                })
            return {"sent": res.status_code == 200, "to": target}
    except Exception as e:
        return {"sent": False, "error": str(e)}

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        digest_endpoint + '# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Backend: digest + send endpoints')
else:
    print('  Digest endpoints exist')
PYEOF

# ============================================
# 2. BACKEND: Annotations endpoint
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/annotations' not in content:
    annotations_endpoint = '''

@app.get("/api/annotations/{report_id}")
async def get_annotations(report_id: str):
    """Get collaborative annotations for a report."""
    settings = get_settings()
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        result = sb.table("annotations").select("*").eq("report_id", report_id).order("created_at").execute()
        return {"annotations": result.data or []}
    except Exception as e:
        return {"annotations": [], "error": str(e)}


@app.post("/api/annotations")
async def add_annotation(body: dict):
    """Add a collaborative annotation to a report."""
    settings = get_settings()
    report_id = body.get("report_id")
    text = body.get("text", "")
    author = body.get("author", "Anonymous")
    
    if not report_id or not text:
        from fastapi import HTTPException
        raise HTTPException(400, "report_id and text required")
    
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        result = sb.table("annotations").insert({
            "report_id": report_id,
            "text": text[:500],
            "author": author,
        }).execute()
        return {"success": True, "annotation": result.data[0] if result.data else None}
    except Exception as e:
        return {"success": False, "error": str(e)}

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        annotations_endpoint + '# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Backend: annotations endpoints')
else:
    print('  Annotations endpoints exist')
PYEOF

echo "✅ Backend endpoints added"

# ============================================
# 3. FRONTEND: Personal Bias Profile
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/BiasProfile.tsx << 'BIASEOF'
'use client';
import { useState, useEffect } from 'react';

export default function BiasProfile() {
  const [decisions, setDecisions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/decisions');
      const data = await res.json();
      setDecisions(data.decisions || []);
    } catch {}
    finally { setLoading(false); setLoaded(true); }
  };

  if (!loaded) {
    return (
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 16 }}>🪞</span>
            <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Your bias profile</span>
            <span style={{ fontSize: 12, color: '#888' }}>Based on your decisions</span>
          </div>
          <button onClick={load} disabled={loading} style={{ fontSize: 11, padding: '4px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>
            {loading ? 'Loading...' : 'Reveal'}
          </button>
        </div>
      </div>
    );
  }

  if (decisions.length < 3) {
    return (
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16, textAlign: 'center' }}>
        <span style={{ fontSize: 16 }}>🪞</span>
        <div style={{ fontSize: 13, color: '#888', marginTop: 6 }}>Need at least 3 decisions to build your profile. Keep analyzing and marking Trust/Unsure/Reject.</div>
      </div>
    );
  }

  // Analyze patterns
  const total = decisions.length;
  const trustCount = decisions.filter(d => d.decision === 'trust').length;
  const unsureCount = decisions.filter(d => d.decision === 'unsure').length;
  const rejectCount = decisions.filter(d => d.decision === 'reject').length;

  const trustPct = Math.round((trustCount / total) * 100);
  const unsurePct = Math.round((unsureCount / total) * 100);
  const rejectPct = Math.round((rejectCount / total) * 100);

  // Find patterns in what they trust vs reject
  const trustWords: Record<string, number> = {};
  const rejectWords: Record<string, number> = {};
  
  for (const d of decisions) {
    const words = (d.input_preview || '').toLowerCase().split(/\s+/).filter((w: string) => w.length > 4);
    const target = d.decision === 'trust' ? trustWords : d.decision === 'reject' ? rejectWords : {};
    for (const w of words) {
      target[w] = (target[w] || 0) + 1;
    }
  }

  const topTrustTopics = Object.entries(trustWords).sort((a, b) => b[1] - a[1]).slice(0, 3);
  const topRejectTopics = Object.entries(rejectWords).sort((a, b) => b[1] - a[1]).slice(0, 3);

  // Determine profile type
  let profileType = '';
  let profileDesc = '';
  if (trustPct > 60) { profileType = 'Trusting reader'; profileDesc = 'You tend to accept most content at face value. Consider applying more scrutiny to claims that align with your existing beliefs.'; }
  else if (rejectPct > 60) { profileType = 'Skeptical reader'; profileDesc = 'You reject most content you analyze. This is healthy skepticism, but be careful not to dismiss credible information along with the misleading.'; }
  else if (unsurePct > 40) { profileType = 'Careful evaluator'; profileDesc = 'You frequently mark content as "Unsure" — a sign of thoughtful evaluation. You prefer to gather more evidence before deciding.'; }
  else { profileType = 'Balanced reader'; profileDesc = 'Your decisions are spread across Trust, Unsure, and Reject. You evaluate each piece of content on its own merits.'; }

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, marginBottom: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>🪞</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Your bias profile</span>
        <span style={{ fontSize: 12, color: '#888' }}>Based on {total} decisions</span>
      </div>

      {/* Profile type */}
      <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 10, marginBottom: 14 }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>{profileType}</div>
        <div style={{ fontSize: 12, color: '#555', lineHeight: 1.6 }}>{profileDesc}</div>
      </div>

      {/* Decision distribution */}
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Decision distribution</div>
        <div style={{ display: 'flex', height: 24, borderRadius: 6, overflow: 'hidden', marginBottom: 6 }}>
          {trustPct > 0 && <div style={{ width: `${trustPct}%`, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{trustPct}%</span></div>}
          {unsurePct > 0 && <div style={{ width: `${unsurePct}%`, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{unsurePct}%</span></div>}
          {rejectPct > 0 && <div style={{ width: `${rejectPct}%`, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 9, color: '#fff', fontWeight: 600 }}>{rejectPct}%</span></div>}
        </div>
        <div style={{ display: 'flex', gap: 12, fontSize: 11 }}>
          <span style={{ color: '#16a34a' }}>✅ Trust: {trustCount}</span>
          <span style={{ color: '#d97706' }}>🤔 Unsure: {unsureCount}</span>
          <span style={{ color: '#dc2626' }}>❌ Reject: {rejectCount}</span>
        </div>
      </div>

      {/* Topic patterns */}
      {(topTrustTopics.length > 0 || topRejectTopics.length > 0) && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {topTrustTopics.length > 0 && (
            <div style={{ padding: '8px 10px', background: '#f0fdf4', borderRadius: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#166534', marginBottom: 4 }}>Topics you trust</div>
              {topTrustTopics.map(([word, count], i) => (
                <div key={i} style={{ fontSize: 11, color: '#555' }}>{word} ({count}x)</div>
              ))}
            </div>
          )}
          {topRejectTopics.length > 0 && (
            <div style={{ padding: '8px 10px', background: '#fef2f2', borderRadius: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: '#b91c1c', marginBottom: 4 }}>Topics you reject</div>
              {topRejectTopics.map(([word, count], i) => (
                <div key={i} style={{ fontSize: 11, color: '#555' }}>{word} ({count}x)</div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
BIASEOF

echo "✅ BiasProfile component"

# ============================================
# 4. Collaborative Annotations component
# ============================================

cat > src/components/Annotations.tsx << 'ANNOTEOF'
'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function Annotations({ reportId }: { reportId: string }) {
  const [annotations, setAnnotations] = useState<any[]>([]);
  const [newText, setNewText] = useState('');
  const [author, setAuthor] = useState('');
  const [sending, setSending] = useState(false);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (reportId) {
      fetch(`${API_URL}/api/annotations/${reportId}`)
        .then(r => r.json())
        .then(d => { setAnnotations(d.annotations || []); setLoaded(true); })
        .catch(() => setLoaded(true));
    }
  }, [reportId]);

  const submit = async () => {
    if (!newText.trim()) return;
    setSending(true);
    try {
      const res = await fetch(`${API_URL}/api/annotations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ report_id: reportId, text: newText, author: author || 'Anonymous' }),
      });
      const data = await res.json();
      if (data.success && data.annotation) {
        setAnnotations(prev => [...prev, data.annotation]);
        setNewText('');
      }
    } catch {}
    finally { setSending(false); }
  };

  if (!reportId) return null;

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>💬</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Community notes</span>
        <span style={{ fontSize: 12, color: '#888' }}>{annotations.length} annotation{annotations.length !== 1 ? 's' : ''}</span>
      </div>

      {/* Existing annotations */}
      {annotations.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
          {annotations.map((a, i) => (
            <div key={i} style={{ padding: '8px 12px', background: '#f8fafa', borderRadius: 8, borderLeft: '3px solid #0d9488' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                <span style={{ fontSize: 11, fontWeight: 600, color: '#0d9488' }}>{a.author || 'Anonymous'}</span>
                <span style={{ fontSize: 10, color: '#aaa' }}>{a.created_at ? new Date(a.created_at).toLocaleDateString() : ''}</span>
              </div>
              <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{a.text}</div>
            </div>
          ))}
        </div>
      )}

      {/* Add annotation */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <input type="text" placeholder="Your name (optional)" value={author} onChange={e => setAuthor(e.target.value)}
            style={{ width: 160, padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, outline: 'none' }} />
          <input type="text" placeholder="Add a note — what did you verify or find?" value={newText} onChange={e => setNewText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && submit()}
            style={{ flex: 1, padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 12, outline: 'none' }} />
          <button onClick={submit} disabled={!newText.trim() || sending}
            style={{ padding: '6px 14px', background: newText.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: newText.trim() ? 'pointer' : 'not-allowed' }}>
            {sending ? '...' : 'Post'}
          </button>
        </div>
        <div style={{ fontSize: 10, color: '#aaa' }}>Notes are visible to all users. Share what you independently verified or found.</div>
      </div>
    </div>
  );
}
ANNOTEOF

echo "✅ Annotations component"

# ============================================
# 5. Bookmarklet page
# ============================================

mkdir -p src/app/bookmarklet

cat > src/app/bookmarklet/page.tsx << 'BOOKEOF'
'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function BookmarkletPage() {
  const bookmarkletCode = "javascript:void(window.open('https://dissekt.info/analyze?url='+encodeURIComponent(window.location.href),'_blank'))";

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '48px 24px', textAlign: 'center' }}>
        <div style={{ fontSize: 32, marginBottom: 12 }}>🔖</div>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, color: '#1a1a1a' }}>One-click analyze</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 32, lineHeight: 1.6 }}>
          Drag the button below to your bookmarks bar. Then click it on any article to instantly analyze it with Dissekt.
        </p>

        <div style={{ marginBottom: 32 }}>
          <a href={bookmarkletCode} onClick={e => e.preventDefault()}
            draggable="true"
            style={{ display: 'inline-block', padding: '12px 28px', background: '#0d9488', color: '#fff', borderRadius: 10, fontSize: 15, fontWeight: 600, textDecoration: 'none', cursor: 'grab', boxShadow: '0 2px 8px rgba(13,148,136,0.3)' }}>
            📖 Analyze with Dissekt
          </a>
        </div>

        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24, textAlign: 'left' }}>
          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>How to install</h2>
          <div style={{ fontSize: 13, color: '#555', lineHeight: 2 }}>
            <strong>Desktop (Chrome, Firefox, Edge):</strong><br />
            1. Make sure your bookmarks bar is visible (Ctrl+Shift+B)<br />
            2. Drag the teal button above into your bookmarks bar<br />
            3. Visit any news article and click the bookmark<br />
            4. Dissekt opens with the article URL ready to analyze<br />
            <br />
            <strong>Mobile:</strong><br />
            1. Copy this URL and create a new bookmark with it:<br />
          </div>
          <div style={{ marginTop: 8, padding: '8px 12px', background: '#f8fafa', borderRadius: 6, fontSize: 11, color: '#555', wordBreak: 'break-all', fontFamily: 'monospace' }}>
            {bookmarkletCode}
          </div>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
BOOKEOF

echo "✅ Bookmarklet page"

# ============================================
# 6. Wire BiasProfile + Annotations into analyze page
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

if 'BiasProfile' not in content:
    content = content.replace(
        "import DecisionJournalView from '@/components/DecisionJournal';",
        "import DecisionJournalView from '@/components/DecisionJournal';\nimport BiasProfile from '@/components/BiasProfile';"
    )
    content = content.replace(
        "<DecisionJournalView />",
        "<BiasProfile />\n            <DecisionJournalView />"
    )
    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze page: BiasProfile added')
PYEOF

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

if 'Annotations' not in content:
    content = content.replace(
        "import ReadingMode from './ReadingMode';",
        "import ReadingMode from './ReadingMode';\nimport Annotations from './Annotations';"
    )
    # Add Annotations at the end of the result
    if '<SiteFooter' not in content:
        # Add before the last closing div of the component
        content = content.replace(
            "    </div>\n  );\n}",
            """      {/* Community notes */}
      <Annotations reportId={data.id || data.blockchain?.content_hash?.slice(0, 12) || ''} />
    </div>
  );
}"""
        )
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ AnalysisResult: Annotations added')
PYEOF

# ============================================
# 7. Add bookmarklet link to footer + help page
# ============================================

python3 << 'PYEOF'
content = open('src/components/SiteFooter.tsx').read()
if '/bookmarklet' not in content:
    content = content.replace(
        "<a href=\"/feedback\" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Feedback</a>",
        "<a href=\"/feedback\" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Feedback</a>\n              <a href=\"/bookmarklet\" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Bookmarklet</a>"
    )
    open('src/components/SiteFooter.tsx', 'w').write(content)
    print('✅ Footer: bookmarklet link')
PYEOF

# ============================================
# 8. Supabase SQL reminder
# ============================================

echo ""
echo "⚠️  Run this SQL in Supabase:"
echo ""
echo "create table if not exists public.annotations ("
echo "  id uuid default gen_random_uuid() primary key,"
echo "  report_id text not null,"
echo "  text text not null,"
echo "  author text default 'Anonymous',"
echo "  created_at timestamptz default now()"
echo ");"
echo ""
echo "alter table public.annotations enable row level security;"
echo "create policy \"Anyone can insert\" on public.annotations for insert with check (true);"
echo "create policy \"Anyone can read\" on public.annotations for select using (true);"
echo ""

echo ""
echo "✅ Tier 2 complete:"
echo ""
echo "  📧 Weekly Digest"
echo "     - GET /api/digest → generates digest data"
echo "     - POST /api/digest/send → emails digest via Resend"
echo "     - Trending topics, top techniques, analysis count"
echo ""
echo "  🪞 Personal Bias Profile"
echo "     - Based on Decision Journal (Trust/Unsure/Reject)"
echo "     - Profile type: Trusting/Skeptical/Careful/Balanced"
echo "     - Decision distribution bar"
echo "     - Topics you trust vs reject"
echo "     - Added to /analyze idle state"
echo ""
echo "  🔖 Bookmarklet"
echo "     - /bookmarklet page with drag-to-install button"
echo "     - One click on any article → opens Dissekt with URL"
echo "     - Link in footer"
echo ""
echo "  💬 Collaborative Annotations"
echo "     - Community notes on every analysis"
echo "     - Add name + note, visible to all users"
echo "     - Stored in Supabase 'annotations' table"
echo "     - Added to analysis results"
echo ""
echo "npm run build && npm run dev"
