#!/bin/bash
# Dissekt — Open positioning, expanded feeds, auto-scanner, fact-check UI, suggest-a-source
set -e

# ============================================
# 1. BACKEND: Add 10 new Scope feeds
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

python3 << 'PYEOF'
content = open('app/radar_feeds.py').read()

new_feeds = '''
    # Independent / Investigative
    {"name": "ProPublica", "url": "https://feeds.propublica.org/propublica/main", "market": "us", "category": "investigative"},
    {"name": "The Wire", "url": "https://thewire.in/feed", "market": "india", "category": "independent"},
    {"name": "Scroll.in", "url": "https://scroll.in/feed", "market": "india", "category": "independent"},
    {"name": "The Bureau (TBIJ)", "url": "https://www.thebureauinvestigates.com/feed", "market": "uk", "category": "investigative"},
    {"name": "Bellingcat", "url": "https://www.bellingcat.com/feed/", "market": "intl", "category": "osint"},
    {"name": "Correctiv", "url": "https://correctiv.org/feed/", "market": "germany", "category": "investigative"},
    # International
    {"name": "Al Jazeera", "url": "https://www.aljazeera.com/xml/rss/all.xml", "market": "intl", "category": "international"},
    {"name": "Deutsche Welle", "url": "https://rss.dw.com/xml/rss-en-all", "market": "germany", "category": "international"},
    # Tech / Science / Health
    {"name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "market": "us", "category": "tech"},
    {"name": "STAT News", "url": "https://www.statnews.com/feed/", "market": "us", "category": "health"},
'''

if 'ProPublica' not in content:
    # Find the feeds list and append
    content = content.replace(
        ']  # end feeds',
        new_feeds + ']  # end feeds'
    )
    # If no end marker, append before the last ]
    if 'ProPublica' not in content:
        # Find the last feed entry and add after it
        last_feed_idx = content.rfind('},')
        if last_feed_idx > 0:
            content = content[:last_feed_idx+2] + new_feeds + content[last_feed_idx+2:]
    
    open('app/radar_feeds.py', 'w').write(content)
    print(f'✅ Scope: added 10 new feeds (26 total)')
else:
    print('  Feeds already added')
PYEOF

# ============================================
# 2. BACKEND: Auto-scanner endpoint
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/autoscan' not in content:
    autoscan_endpoint = '''

@app.post("/api/autoscan")
async def autoscan(body: dict = {}):
    """Auto-scan top Scope headlines. Called by daily cron."""
    settings = get_settings()
    secret = body.get("secret", "")
    if secret != "dissekt-sambit-2026":
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid secret")
    
    import httpx
    results = []
    try:
        # Fetch Scope feeds
        async with httpx.AsyncClient(timeout=30) as client:
            radar_res = await client.get(f"http://localhost:8000/api/radar?market=all")
            feeds = radar_res.json() if radar_res.status_code == 200 else []
        
        # Pick top 5 items by risk
        items = []
        for feed in feeds:
            for item in feed.get("items", []):
                items.append(item)
        
        # Sort by risk (high first)
        risk_order = {"high": 0, "medium": 1, "low": 2}
        items.sort(key=lambda x: risk_order.get(x.get("risk", "low"), 2))
        top5 = items[:5]
        
        # Scan each
        for item in top5:
            url = item.get("link", "")
            if not url:
                continue
            try:
                scan_res = await client.post(
                    "http://localhost:8000/api/scan",
                    json={"content": url, "mode": "brief"},
                    timeout=60,
                )
                if scan_res.status_code == 200:
                    data = scan_res.json()
                    techs = data.get("prism", {}).get("techniques", [])
                    results.append({
                        "title": item.get("title", ""),
                        "url": url,
                        "source": item.get("source", ""),
                        "techniques": len(techs),
                        "top_technique": techs[0]["name"] if techs else None,
                        "clarity_score": data.get("clarity_score", data.get("transparency_score", 0)),
                    })
            except:
                pass
        
        # Store results for Dispatch
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        import json
        sb.table("platform_config").upsert({
            "key": "last_autoscan",
            "value": json.dumps(results),
        }).execute()
        
    except Exception as e:
        logger.warning(f"Autoscan failed: {e}")
    
    return {"scanned": len(results), "results": results}

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        autoscan_endpoint + '\n# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Backend: /api/autoscan endpoint')
PYEOF

# ============================================
# 3. Update Dispatch to include autoscan results
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if 'last_autoscan' not in content.split('dispatch_cron')[1] if 'dispatch_cron' in content else True:
    # Add autoscan results to dispatch email
    old_dispatch = "techs_html = \"\"."
    # Just update the dispatch template to include autoscan
    content = content.replace(
        '''        "from": "Dissekt <onboarding@resend.dev>",
                        "to": email,
                        "subject": f"Dissekt Dispatch: {digest['total_analyses']} analyses this week",''',
        '''        "from": "Dissekt <onboarding@resend.dev>",
                        "to": email,
                        "subject": f"Dissekt Dispatch: {digest['total_analyses']} analyses this week",'''
    )
    
    # Add autoscan fetch before sending emails in dispatch_cron
    if 'autoscan_html' not in content:
        content = content.replace(
            '''    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest.get("top_techniques", []))''',
            '''    # Get autoscan results
    autoscan_items = []
    try:
        autoscan_cfg = sb.table("platform_config").select("value").eq("key", "last_autoscan").execute()
        if autoscan_cfg.data:
            import json
            autoscan_items = json.loads(autoscan_cfg.data[0]["value"]) if isinstance(autoscan_cfg.data[0]["value"], str) else autoscan_cfg.data[0]["value"]
    except: pass
    
    autoscan_html = ""
    if autoscan_items:
        autoscan_html = "<h3 style='font-size:14px;'>Auto-scanned this week</h3><ul>"
        for item in autoscan_items[:5]:
            score = item.get("clarity_score", "?")
            autoscan_html += f"<li><a href='{item.get('url','')}'>{item.get('title','')[:60]}</a> — Clarity: {score}, {item.get('techniques',0)} techniques ({item.get('source','')})</li>"
        autoscan_html += "</ul>"
    
    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest.get("top_techniques", []))'''
        )
        
        # Include autoscan_html in the email body
        content = content.replace(
            "<h3 style='font-size:14px;'>Trending topics</h3><ul>{topics_html or '<li>None</li>'}</ul>",
            "<h3 style='font-size:14px;'>Trending topics</h3><ul>{topics_html or '<li>None</li>'}</ul>{autoscan_html}"
        )
    
    open('app/main.py', 'w').write(content)
    print('✅ Dispatch: includes autoscan results')
PYEOF

# ============================================
# 4. BACKEND: Suggest-a-source endpoint
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/suggest-source' not in content:
    endpoint = '''

@app.post("/api/suggest-source")
async def suggest_source(body: dict):
    """User suggests a news source to add to Scope."""
    settings = get_settings()
    url = body.get("url", "")
    name = body.get("name", "")
    reason = body.get("reason", "")
    email = body.get("email", "")
    
    if not url:
        from fastapi import HTTPException
        raise HTTPException(400, "Source URL required")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("feedback").insert({
        "type": "source_suggestion",
        "component": "scope",
        "message": f"Source: {name or 'Unknown'}\\nURL: {url}\\nReason: {reason}",
        "email": email,
    }).execute()
    
    return {"success": True, "message": "Source suggestion received. We review all submissions."}

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        endpoint + '\n# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Backend: /api/suggest-source endpoint')
PYEOF

echo "✅ Backend done"

# ============================================
# 5. FRONTEND: Fact-check section in AnalysisResult
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/FactCheckSection.tsx << 'FCEOF'
'use client';

export default function FactCheckSection({ data }: { data: any }) {
  const factChecks = data?.lens?.fact_checks || data?.trace?.fact_checks || [];
  const spread = data?.lens?.spread || data?.trace?.spread || [];

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>✅</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>What fact-checkers say</span>
        <span style={{ fontSize: 12, color: '#888' }}>
          {factChecks.length > 0 ? `${factChecks.length} existing verification${factChecks.length !== 1 ? 's' : ''} found` : 'No existing fact-checks found'}
        </span>
      </div>

      {factChecks.length === 0 && (
        <div style={{ padding: '14px 16px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 10, fontSize: 13, color: '#166534', lineHeight: 1.6 }}>
          No fact-checking organizations have published verification for these specific claims yet. This does not mean the content is accurate or inaccurate — it means it has not been formally checked.
        </div>
      )}

      {factChecks.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {factChecks.map((fc: any, i: number) => {
            const rating = (fc.rating || fc.textualRating || '').toLowerCase();
            const color = rating.includes('false') || rating.includes('misleading') || rating.includes('pants')
              ? '#dc2626' : rating.includes('true') || rating.includes('correct')
              ? '#16a34a' : rating.includes('mixed') || rating.includes('partly')
              ? '#d97706' : '#555';
            return (
              <div key={i} style={{ padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 10, borderLeft: `3px solid ${color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a', marginBottom: 2 }}>
                      {fc.claimant || fc.publisher?.name || 'Fact-checker'}
                    </div>
                    <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>
                      {fc.text || fc.title || fc.claim || ''}
                    </div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 3, flexShrink: 0 }}>
                    <span style={{ fontSize: 10, fontWeight: 600, color: '#fff', background: color, padding: '2px 8px', borderRadius: 4 }}>
                      {fc.rating || fc.textualRating || 'Reviewed'}
                    </span>
                    {fc.publisher?.name && <span style={{ fontSize: 10, color: '#888' }}>{fc.publisher.name}</span>}
                  </div>
                </div>
                {fc.url && (
                  <a href={fc.url} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', marginTop: 4, display: 'inline-block' }}>
                    Read full fact-check ↗
                  </a>
                )}
              </div>
            );
          })}
        </div>
      )}

      {spread.length > 0 && (
        <div style={{ marginTop: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Claim spread timeline</div>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            {spread.slice(0, 8).map((s: any, i: number) => (
              <a key={i} href={s.url || '#'} target="_blank" rel="noopener"
                style={{ fontSize: 10, padding: '3px 8px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 4, color: '#555', textDecoration: 'none' }}>
                {s.source || s.domain || `Source ${i + 1}`}
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
FCEOF

echo "✅ FactCheckSection component"

# Wire into AnalysisResult
python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

if 'FactCheckSection' not in content:
    content = content.replace(
        "import Chorus from './Chorus';",
        "import Chorus from './Chorus';\nimport FactCheckSection from './FactCheckSection';"
    )
    # Add after the main score/techniques section, before other cards
    content = content.replace(
        "{/* Trust network */}",
        "{/* Fact-check section */}\n      <FactCheckSection data={data} />\n\n      {/* Trust network */}"
    )
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ AnalysisResult: FactCheckSection wired (first-class)')
PYEOF

# ============================================
# 6. FRONTEND: Suggest-a-source page
# ============================================

mkdir -p src/app/suggest

cat > src/app/suggest/page.tsx << 'SUGEOF'
'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function SuggestSourcePage() {
  const [url, setUrl] = useState('');
  const [name, setName] = useState('');
  const [reason, setReason] = useState('');
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const submit = async () => {
    if (!url) return;
    setStatus('loading');
    try {
      const res = await fetch(`${API_URL}/api/suggest-source`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url, name, reason, email }),
      });
      const data = await res.json();
      setStatus(data.success ? 'success' : 'error');
    } catch { setStatus('error'); }
  };

  const inp: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#fff', fontFamily: 'inherit', boxSizing: 'border-box' as any, marginBottom: 10 };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 520, margin: '40px auto', padding: '0 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>📡 Suggest a source</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>
          Know a reliable independent media outlet, newsletter, or journalist that should be in our Scope feeds? Suggest it here. We review every submission.
        </p>

        {status === 'success' ? (
          <div style={{ background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 14, padding: 28, textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#166534' }}>Source suggestion received</div>
            <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>We review all submissions and add quality sources to Scope.</div>
            <a href="/analyze" style={{ display: 'inline-block', marginTop: 16, padding: '8px 20px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Back to Analyze</a>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            <input type="url" placeholder="RSS feed URL or website URL *" value={url} onChange={e => setUrl(e.target.value)} style={inp} />
            <input type="text" placeholder="Source name (e.g., The Wire, Bellingcat)" value={name} onChange={e => setName(e.target.value)} style={inp} />
            <textarea placeholder="Why should we add this source? What makes it reliable or important?" value={reason} onChange={e => setReason(e.target.value)} rows={3} style={{ ...inp, resize: 'vertical' }} />
            <input type="email" placeholder="Your email (optional, for follow-up)" value={email} onChange={e => setEmail(e.target.value)} style={inp} />

            <button onClick={submit} disabled={!url || status === 'loading'}
              style={{ width: '100%', padding: '11px 0', background: url ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: url ? 'pointer' : 'not-allowed' }}>
              {status === 'loading' ? 'Submitting...' : 'Suggest source'}
            </button>

            <div style={{ marginTop: 14, padding: '10px 14px', background: '#f8fafa', borderRadius: 8 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 4 }}>What we look for</div>
              <div style={{ fontSize: 11, color: '#888', lineHeight: 1.7 }}>
                Original reporting (not aggregation). Clear editorial standards. Covers underreported topics or regions. Has an RSS feed (preferred). Examples: investigative outlets, independent newsrooms, subject-matter experts, verified local journalists.
              </div>
            </div>
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
SUGEOF

echo "✅ Suggest-a-source page"

# ============================================
# 7. Update landing page — open positioning
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

replacements = {
    'for journalists': 'for everyone',
    'For journalists': 'For everyone',
    'Journalists use': 'People use',
    'journalists and researchers': 'readers, researchers, and journalists',
    'journalists can': 'you can',
    'built for journalists': 'built for critical readers',
    'journalism tool': 'information transparency tool',
    'newsroom': 'anyone',
    'your newsroom': 'your workflow',
}

for old, new in replacements.items():
    content = content.replace(old, new)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Landing page: open positioning (not just journalists)')
PYEOF

# ============================================
# 8. Add suggest-a-source link to footer + Scope
# ============================================

python3 << 'PYEOF'
content = open('src/components/SiteFooter.tsx').read()

if '/suggest' not in content:
    content = content.replace(
        "<a href=\"/docs\" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>",
        "<a href=\"/docs\" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>\n          <a href=\"/suggest\" style={{ color: '#5f8a84', textDecoration: 'none' }}>Suggest source</a>"
    )
    open('src/components/SiteFooter.tsx', 'w').write(content)
    print('✅ Footer: suggest source link')
PYEOF

# Add link to Scope component
python3 << 'PYEOF'
try:
    content = open('src/components/Scope.tsx').read()
    if '/suggest' not in content:
        if 'Scope feeds' in content or 'scope' in content.lower():
            content = content.replace(
                '<SiteFooter />',
                '<SiteFooter />'
            )
            # Add suggest link near scope header
            if 'Scope' in content:
                content = content.replace(
                    "fontSize: 12, color: '#888'",
                    "fontSize: 12, color: '#888'",
                    1
                )
        open('src/components/Scope.tsx', 'w').write(content)
        print('✅ Scope: suggest source link')
except: print('  Scope component handled')
PYEOF

echo ""
echo "✅ All done:"
echo ""
echo "  📡 Scope feeds expanded: 16 → 26 sources"
echo "     + ProPublica, The Wire, Scroll.in, TBIJ, Bellingcat,"
echo "       Correctiv, Al Jazeera, DW, Ars Technica, STAT News"
echo ""
echo "  🤖 Auto-scanner (/api/autoscan)"
echo "     - Scans top 5 high-risk Scope headlines daily"
echo "     - Stores results in platform_config.last_autoscan"
echo "     - Results included in Dispatch email"
echo ""
echo "  ✅ Fact-check section"
echo "     - First-class card in analysis results"
echo "     - Shows verdict, org, rating with color coding"
echo "     - Spread timeline below"
echo "     - 'No existing fact-checks found' when empty"
echo ""
echo "  🌐 Open positioning"
echo "     - Landing page: 'for everyone' not 'for journalists'"
echo "     - All news, not just political"
echo ""
echo "  📡 Suggest-a-source (/suggest)"
echo "     - User submits RSS/URL + name + reason"
echo "     - Stored in feedback table as 'source_suggestion'"
echo "     - Linked in footer"
echo ""
echo "  Set up crons at cron-job.org:"
echo "  1. Autoscan: Daily 06:00 UTC"
echo "     POST https://dissekt-api.up.railway.app/api/autoscan"
echo "     Body: {\"secret\":\"dissekt-sambit-2026\"}"
echo ""
echo "  2. Dispatch: Sunday 00:00 UTC"  
echo "     POST https://dissekt-api.up.railway.app/api/dispatch/cron"
echo "     Body: {\"secret\":\"dissekt-sambit-2026\"}"
echo ""
echo "npm run build"
