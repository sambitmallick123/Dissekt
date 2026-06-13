#!/bin/bash
# Dissekt — Crons, social scanners, share, source curation, trust graph
set -e

# ============================================
# 1. CRON SETUP INSTRUCTIONS (manual at cron-job.org)
# ============================================

echo "=========================================="
echo "1. CRON SETUP — Do this manually"
echo "=========================================="
echo ""
echo "Go to https://cron-job.org → Create Account → New Cron Job"
echo ""
echo "CRON 1: Auto-scanner"
echo "  Title: Dissekt Autoscan"
echo "  URL: https://dissekt-api.up.railway.app/api/autoscan"
echo "  Method: POST"
echo "  Headers: Content-Type: application/json"
echo "  Body: {\"secret\":\"dissekt-sambit-2026\"}"
echo "  Schedule: Every day at 06:00 UTC"
echo ""
echo "CRON 2: Weekly Dispatch"
echo "  Title: Dissekt Dispatch"
echo "  URL: https://dissekt-api.up.railway.app/api/dispatch/cron"
echo "  Method: POST"
echo "  Headers: Content-Type: application/json"
echo "  Body: {\"secret\":\"dissekt-sambit-2026\"}"
echo "  Schedule: Every Sunday at 00:00 UTC"
echo ""

# ============================================
# 2. BACKEND: Social scanners + share + curation
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

cat > app/social_scanner.py << 'SOCIALEOF'
"""
Social media scanners for Reddit, YouTube, Substack, Bluesky, Mastodon.
Each returns extracted text suitable for Prism analysis.
"""
import httpx
import logging
import re

logger = logging.getLogger("dissekt.social")


async def scan_reddit(url: str) -> dict:
    """Extract Reddit post/comment text from a URL or subreddit RSS."""
    try:
        # Reddit JSON trick: append .json to any reddit URL
        json_url = url.rstrip('/') + '.json' if 'reddit.com' in url else url
        if not json_url.endswith('.json'):
            json_url += '.json'
        
        async with httpx.AsyncClient(timeout=15, headers={"User-Agent": "Dissekt/1.0"}) as client:
            res = await client.get(json_url)
            data = res.json()
        
        # Single post
        if isinstance(data, list) and len(data) >= 1:
            post = data[0]["data"]["children"][0]["data"]
            title = post.get("title", "")
            selftext = post.get("selftext", "")
            subreddit = post.get("subreddit", "")
            score = post.get("score", 0)
            
            # Get top comments
            comments = []
            if len(data) >= 2:
                for child in data[1]["data"]["children"][:10]:
                    if child["kind"] == "t1":
                        comments.append(child["data"].get("body", ""))
            
            full_text = f"{title}\n\n{selftext}\n\n" + "\n".join(comments[:5])
            return {
                "source": "reddit",
                "subreddit": subreddit,
                "title": title,
                "text": full_text.strip(),
                "score": score,
                "comments": len(comments),
                "url": url,
            }
        return {"source": "reddit", "text": "", "error": "Could not parse Reddit data"}
    except Exception as e:
        logger.warning(f"Reddit scan failed: {e}")
        return {"source": "reddit", "text": "", "error": str(e)}


async def scan_youtube(url: str) -> dict:
    """Extract YouTube video transcript using yt-dlp."""
    try:
        import subprocess, json, tempfile, os
        
        # Extract video ID
        vid_id = ""
        if "youtu.be/" in url:
            vid_id = url.split("youtu.be/")[1].split("?")[0]
        elif "v=" in url:
            vid_id = url.split("v=")[1].split("&")[0]
        
        # Try to get subtitles via yt-dlp
        with tempfile.TemporaryDirectory() as tmp:
            sub_path = os.path.join(tmp, "subs")
            result = subprocess.run([
                "yt-dlp", "--skip-download", "--write-auto-sub", "--sub-lang", "en",
                "--sub-format", "json3", "-o", sub_path, url
            ], capture_output=True, text=True, timeout=30)
            
            # Find the subtitle file
            transcript = ""
            for f in os.listdir(tmp):
                if f.endswith(".json3") or f.endswith(".vtt") or f.endswith(".srt"):
                    content = open(os.path.join(tmp, f)).read()
                    if f.endswith(".json3"):
                        try:
                            subs = json.loads(content)
                            transcript = " ".join(
                                seg.get("segs", [{}])[0].get("utf8", "")
                                for seg in subs.get("events", [])
                                if seg.get("segs")
                            )
                        except:
                            transcript = content
                    else:
                        # Strip VTT/SRT timestamps
                        lines = content.split("\n")
                        transcript = " ".join(
                            l for l in lines
                            if l.strip() and not re.match(r'^\d', l) and '-->' not in l and l.strip() != 'WEBVTT'
                        )
            
            if not transcript:
                # Fallback: get title + description
                info_result = subprocess.run(
                    ["yt-dlp", "--skip-download", "--print", "%(title)s|||%(description)s", url],
                    capture_output=True, text=True, timeout=15
                )
                parts = info_result.stdout.strip().split("|||")
                transcript = f"{parts[0]}\n\n{parts[1] if len(parts) > 1 else ''}"
        
        return {
            "source": "youtube",
            "video_id": vid_id,
            "text": transcript.strip()[:10000],  # Cap at 10K chars
            "url": url,
        }
    except FileNotFoundError:
        return {"source": "youtube", "text": "", "error": "yt-dlp not installed. Run: pip install yt-dlp"}
    except Exception as e:
        logger.warning(f"YouTube scan failed: {e}")
        return {"source": "youtube", "text": "", "error": str(e)}


async def scan_bluesky(url: str) -> dict:
    """Extract Bluesky post text via public API."""
    try:
        # Parse handle and rkey from URL: bsky.app/profile/handle/post/rkey
        parts = url.split("/")
        handle = ""
        rkey = ""
        for i, p in enumerate(parts):
            if p == "profile" and i + 1 < len(parts):
                handle = parts[i + 1]
            if p == "post" and i + 1 < len(parts):
                rkey = parts[i + 1]
        
        if not handle or not rkey:
            return {"source": "bluesky", "text": "", "error": "Could not parse Bluesky URL"}
        
        # Resolve DID
        async with httpx.AsyncClient(timeout=10) as client:
            did_res = await client.get(f"https://bsky.social/xrpc/com.atproto.identity.resolveHandle?handle={handle}")
            did = did_res.json().get("did", "")
            
            if did:
                uri = f"at://{did}/app.bsky.feed.post/{rkey}"
                thread_res = await client.get(f"https://bsky.social/xrpc/app.bsky.feed.getPostThread?uri={uri}&depth=3")
                thread = thread_res.json()
                
                post = thread.get("thread", {}).get("post", {})
                text = post.get("record", {}).get("text", "")
                author = post.get("author", {}).get("displayName", handle)
                
                # Get replies
                replies_text = []
                for reply in thread.get("thread", {}).get("replies", [])[:5]:
                    rt = reply.get("post", {}).get("record", {}).get("text", "")
                    if rt:
                        replies_text.append(rt)
                
                full_text = f"{author}: {text}\n\nReplies:\n" + "\n".join(replies_text)
                return {"source": "bluesky", "handle": handle, "text": full_text.strip(), "url": url}
        
        return {"source": "bluesky", "text": "", "error": "Could not fetch post"}
    except Exception as e:
        logger.warning(f"Bluesky scan failed: {e}")
        return {"source": "bluesky", "text": "", "error": str(e)}


async def scan_mastodon(url: str) -> dict:
    """Extract Mastodon post text via public API."""
    try:
        # Parse instance and status ID from URL: instance/@user/statusid
        parts = url.split("/")
        instance = f"{parts[0]}//{parts[2]}" if len(parts) > 2 else ""
        status_id = parts[-1] if parts[-1].isdigit() else ""
        
        if not instance or not status_id:
            return {"source": "mastodon", "text": "", "error": "Could not parse Mastodon URL"}
        
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.get(f"{instance}/api/v1/statuses/{status_id}")
            data = res.json()
            
            # Strip HTML tags
            content = re.sub(r'<[^>]+>', '', data.get("content", ""))
            author = data.get("account", {}).get("display_name", "")
            
            # Get replies
            ctx_res = await client.get(f"{instance}/api/v1/statuses/{status_id}/context")
            ctx = ctx_res.json()
            replies = [re.sub(r'<[^>]+>', '', r.get("content", "")) for r in ctx.get("descendants", [])[:5]]
            
            full_text = f"{author}: {content}\n\nReplies:\n" + "\n".join(replies)
            return {"source": "mastodon", "instance": instance, "text": full_text.strip(), "url": url}
    except Exception as e:
        logger.warning(f"Mastodon scan failed: {e}")
        return {"source": "mastodon", "text": "", "error": str(e)}


async def scan_substack(url: str) -> dict:
    """Extract Substack article. Trafilatura handles this well, so we just tag it."""
    return {"source": "substack", "text": "", "url": url, "use_beacon": True}


async def detect_and_extract(url: str) -> dict:
    """Auto-detect social platform and extract content."""
    url_lower = url.lower()
    
    if "reddit.com" in url_lower or "redd.it" in url_lower:
        return await scan_reddit(url)
    elif "youtube.com" in url_lower or "youtu.be" in url_lower:
        return await scan_youtube(url)
    elif "bsky.app" in url_lower or "bsky.social" in url_lower:
        return await scan_bluesky(url)
    elif "mastodon" in url_lower or "/@" in url_lower:
        return await scan_mastodon(url)
    elif "substack.com" in url_lower:
        return await scan_substack(url)
    
    return {"source": "web", "text": "", "use_beacon": True}
SOCIALEOF

echo "✅ Social scanner module"

# Wire social scanner into Beacon
python3 -c "
content = open('app/beacon/__init__.py').read()
if 'social_scanner' not in content:
    content = content.replace(
        'import httpx',
        'import httpx\nfrom app.social_scanner import detect_and_extract'
    )
    # Add social detection before URL extraction
    content = content.replace(
        '    # Step 1: Detect input type',
        '''    # Step 0: Check if social media URL
    if content.startswith('http'):
        social = await detect_and_extract(content)
        if social.get('text') and not social.get('use_beacon'):
            content = social['text']
            # Continue with text analysis (skip URL extraction)
    
    # Step 1: Detect input type'''
    )
    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ Beacon: social scanner wired')
"

# ============================================
# 3. BACKEND: Share via email endpoint
# ============================================

python3 -c "
content = open('app/main.py').read()
if '/api/share' not in content:
    endpoint = '''

@app.post(\"/api/share\")
async def share_analysis(body: dict):
    \"\"\"Share an analysis result via email.\"\"\"
    settings = get_settings()
    to_email = body.get(\"to\", \"\")
    report_id = body.get(\"report_id\", \"\")
    sender_name = body.get(\"from_name\", \"Someone\")
    message = body.get(\"message\", \"\")
    
    if not to_email or not report_id:
        from fastapi import HTTPException
        raise HTTPException(400, \"Email and report_id required\")
    
    report_url = f\"https://dissekt.info/report/{report_id}\"
    
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(\"https://api.resend.com/emails\",
                headers={\"Authorization\": f\"Bearer {settings.resend_api_key}\"},
                json={
                    \"from\": \"Dissekt <onboarding@resend.dev>\",
                    \"to\": to_email,
                    \"subject\": f\"{sender_name} shared a Dissekt analysis with you\",
                    \"html\": f\"\"\"<div style=\"font-family:-apple-system,sans-serif;max-width:500px;margin:0 auto;\">
                        <div style=\"background:#0d9488;padding:14px 20px;border-radius:10px 10px 0 0;\">
                            <h2 style=\"color:white;margin:0;font-size:16px;\">Dissekt Analysis Shared</h2>
                        </div>
                        <div style=\"background:#fff;padding:20px;border:1px solid #e5eaea;border-top:none;border-radius:0 0 10px 10px;\">
                            <p style=\"font-size:14px;color:#333;\">{sender_name} shared an analysis with you on Dissekt.</p>
                            {f'<p style=\"font-size:13px;color:#555;background:#f8fafa;padding:10px;border-radius:6px;\">{message}</p>' if message else ''}
                            <div style=\"text-align:center;margin:20px 0;\">
                                <a href=\"{report_url}\" style=\"background:#0d9488;color:white;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:600;\">View analysis</a>
                            </div>
                            <p style=\"font-size:11px;color:#aaa;text-align:center;\">
                                Dissekt — See how information is constructed<br/>
                                <a href=\"https://dissekt.info\" style=\"color:#0d9488;\">dissekt.info</a>
                            </p>
                        </div>
                    </div>\"\"\"
                })
        return {\"success\": res.status_code == 200}
    except Exception as e:
        return {\"success\": False, \"error\": str(e)}

'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + endpoint)
    open('app/main.py', 'w').write(content)
    print('✅ Backend: /api/share endpoint')
"

# ============================================
# 4. BACKEND: Source curation endpoint
# ============================================

python3 -c "
content = open('app/main.py').read()
if '/api/admin/sources' not in content:
    endpoint = '''

@app.get(\"/api/admin/sources\")
async def list_suggested_sources():
    \"\"\"List all user-suggested sources for admin review.\"\"\"
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table(\"feedback\").select(\"*\").eq(\"type\", \"source_suggestion\").order(\"created_at\", desc=True).execute()
    return {\"sources\": result.data or []}

'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + endpoint)
    open('app/main.py', 'w').write(content)
    print('✅ Backend: /api/admin/sources endpoint')
"

# ============================================
# 5. Add Substack feeds to Scope
# ============================================

python3 -c "
content = open('app/radar/__init__.py').read()
if 'substack' not in content.lower():
    # Add popular Substack feeds
    if '\"intl\"' in content:
        content = content.replace(
            '\"intl\": [',
            '\"substack\": [\n        \"https://on.substack.com/feed\",\n        \"https://www.slowboring.com/feed\",\n        \"https://heathercoxrichardson.substack.com/feed\",\n    ],\n    \"intl\": ['
        )
    open('app/radar/__init__.py', 'w').write(content)
    print('✅ Scope: 3 Substack feeds added')
else:
    print('  Substack feeds already exist')
"

echo "✅ Backend complete"

# ============================================
# FRONTEND
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 6. Share button component
# ============================================

cat > src/components/ShareButton.tsx << 'SHAREEOF'
'use client';
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function ShareButton({ reportId, onCopied }: { reportId: string; onCopied?: () => void }) {
  const [showModal, setShowModal] = useState(false);
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const copyLink = () => {
    const url = `${window.location.origin}/report/${reportId}`;
    navigator.clipboard.writeText(url);
    onCopied?.();
  };

  const sendEmail = async () => {
    if (!email) return;
    setStatus('sending');
    try {
      const res = await fetch(`${API_URL}/api/share`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ to: email, report_id: reportId, from_name: name || 'Someone', message }),
      });
      const data = await res.json();
      setStatus(data.success ? 'sent' : 'error');
    } catch { setStatus('error'); }
  };

  return (
    <>
      <div style={{ display: 'flex', gap: 4 }}>
        <button onClick={copyLink}
          style={{ padding: '5px 12px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
          🔗 Copy link
        </button>
        <button onClick={() => setShowModal(true)}
          style={{ padding: '5px 12px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
          📧 Email
        </button>
      </div>

      {showModal && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setShowModal(false)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 14, padding: 24, maxWidth: 400, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Share this analysis</div>
            {status === 'sent' ? (
              <div style={{ textAlign: 'center', padding: '16px 0' }}>
                <div style={{ fontSize: 24, marginBottom: 6 }}>✅</div>
                <div style={{ fontSize: 13, color: '#166534' }}>Email sent!</div>
              </div>
            ) : (
              <>
                <input type="text" placeholder="Your name" value={name} onChange={e => setName(e.target.value)}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
                <input type="email" placeholder="Recipient email *" value={email} onChange={e => setEmail(e.target.value)}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
                <textarea placeholder="Add a note (optional)" value={message} onChange={e => setMessage(e.target.value)} rows={2}
                  style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', resize: 'vertical', marginBottom: 8, boxSizing: 'border-box' as any, fontFamily: 'inherit' }} />
                <button onClick={sendEmail} disabled={!email || status === 'sending'}
                  style={{ width: '100%', padding: '8px 0', background: email ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                  {status === 'sending' ? 'Sending...' : 'Send'}
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
SHAREEOF

echo "✅ ShareButton component"

# Wire share button into AnalysisResult
python3 -c "
content = open('src/components/AnalysisResult.tsx').read()
if 'ShareButton' not in content:
    content = content.replace(
        \"import FactCheckSection from './FactCheckSection';\",
        \"import FactCheckSection from './FactCheckSection';\\nimport ShareButton from './ShareButton';\"
    )
    # Add share button near the top of results
    content = content.replace(
        '{/* Fact-check section */}',
        '{/* Share */}\\n      <div style={{ display: \"flex\", justifyContent: \"flex-end\", marginBottom: 8 }}>\\n        <ShareButton reportId={data.id || data.blockchain?.content_hash?.slice(0, 12) || \"\"} onCopied={() => {}} />\\n      </div>\\n\\n      {/* Fact-check section */}'
    )
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ AnalysisResult: ShareButton wired')
"

# ============================================
# 7. Trust Graph visualization
# ============================================

cat > src/components/TrustGraph.tsx << 'TGEOF'
'use client';
import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function TrustGraph() {
  const [decisions, setDecisions] = useState<any[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    fetch(`${API_URL}/api/decisions`)
      .then(r => r.json())
      .then(d => { setDecisions(d.decisions || []); setLoaded(true); })
      .catch(() => setLoaded(true));
  }, []);

  if (!loaded || decisions.length < 5) return null;

  // Build trust graph data
  const sourceMap: Record<string, { trust: number; unsure: number; reject: number; total: number }> = {};
  
  for (const d of decisions) {
    const preview = d.input_preview || '';
    // Extract domain or first meaningful words as source key
    const match = preview.match(/https?:\/\/([^\/\s]+)/);
    const source = match ? match[1].replace('www.', '') : preview.split(/\s+/).slice(0, 2).join(' ').slice(0, 20);
    if (!source) continue;
    
    if (!sourceMap[source]) sourceMap[source] = { trust: 0, unsure: 0, reject: 0, total: 0 };
    sourceMap[source][d.decision as 'trust' | 'unsure' | 'reject']++;
    sourceMap[source].total++;
  }

  const sources = Object.entries(sourceMap)
    .filter(([_, v]) => v.total >= 2)
    .sort((a, b) => b[1].total - a[1].total)
    .slice(0, 12);

  if (sources.length < 2) return null;

  const maxTotal = Math.max(...sources.map(s => s[1].total));

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{ fontSize: 16 }}>🕸️</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Trust graph</span>
        <span style={{ fontSize: 12, color: '#888' }}>How you've evaluated different sources</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {sources.map(([source, data]) => {
          const trustPct = Math.round((data.trust / data.total) * 100);
          const unsurePct = Math.round((data.unsure / data.total) * 100);
          const rejectPct = Math.round((data.reject / data.total) * 100);
          const barWidth = (data.total / maxTotal) * 100;

          return (
            <div key={source} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 11, width: 100, color: '#555', flexShrink: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{source}</span>
              <div style={{ flex: 1, display: 'flex', height: 16, borderRadius: 4, overflow: 'hidden', background: '#f0f0ee', maxWidth: `${barWidth}%` }}>
                {trustPct > 0 && <div style={{ width: `${trustPct}%`, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.trust}</span></div>}
                {unsurePct > 0 && <div style={{ width: `${unsurePct}%`, background: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.unsure}</span></div>}
                {rejectPct > 0 && <div style={{ width: `${rejectPct}%`, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 8, color: '#fff' }}>{data.reject}</span></div>}
              </div>
              <span style={{ fontSize: 10, color: '#888', width: 20, textAlign: 'right' }}>{data.total}</span>
            </div>
          );
        })}
      </div>

      <div style={{ display: 'flex', gap: 12, marginTop: 10, fontSize: 10, color: '#888' }}>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#16a34a', marginRight: 3 }} />Trust</span>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#d97706', marginRight: 3 }} />Unsure</span>
        <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: '#dc2626', marginRight: 3 }} />Reject</span>
      </div>
    </div>
  );
}
TGEOF

echo "✅ TrustGraph component"

# Wire into analyze page idle state
python3 -c "
content = open('src/app/analyze/page.tsx').read()
if 'TrustGraph' not in content:
    content = content.replace(
        \"import Reflect from '@/components/Reflect';\",
        \"import Reflect from '@/components/Reflect';\\nimport TrustGraph from '@/components/TrustGraph';\"
    )
    content = content.replace(
        '<Reflect />',
        '<TrustGraph />\\n            <Reflect />'
    )
    open('src/app/analyze/page.tsx', 'w').write(content)
    print('✅ Analyze: TrustGraph wired')
"

echo ""
echo "✅ All 8 features built:"
echo ""
echo "  1. Cron setup instructions (autoscan daily + dispatch Sunday)"
echo "  11. Reddit scanner (JSON API, post + comments)"
echo "  12. YouTube scanner (yt-dlp transcripts)"
echo "  14. Share via email (📧 button + modal)"
echo "  17. Substack RSS (3 feeds added to Scope)"
echo "  18. Bluesky + Mastodon (public API extraction)"
echo "  19. Source curation (/api/admin/sources)"
echo "  20. Trust graph (per-source trust/unsure/reject visualization)"
echo ""
echo "Social URLs now auto-detected in scan:"
echo "  reddit.com → extracts post + top 5 comments"
echo "  youtube.com → extracts transcript via yt-dlp"
echo "  bsky.app → extracts post + replies via API"
echo "  mastodon → extracts toot + replies via API"
echo "  substack.com → handled by Trafilatura (full article)"
echo ""
echo "npm run build"
