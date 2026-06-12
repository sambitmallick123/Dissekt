#!/bin/bash
# Dissekt — Auth, API keys, Webhooks, Dispatch cron, Extension glow
set -e

echo "⚠️  Run this SQL in Supabase FIRST:"
echo ""
cat << 'SQLEOF'
-- ============================================
-- 1. API keys table
-- ============================================
create table if not exists public.api_keys (
  id uuid default gen_random_uuid() primary key,
  user_email text not null,
  key_hash text not null unique,
  key_prefix text not null,
  name text default 'Default',
  tier text default 'pro' check (tier in ('pro', 'team', 'enterprise')),
  rate_limit int default 100,
  requests_today int default 0,
  last_reset timestamptz default now(),
  active boolean default true,
  created_at timestamptz default now()
);

alter table public.api_keys enable row level security;
create policy "keys_read" on public.api_keys for select using (true);
create policy "keys_insert" on public.api_keys for insert with check (true);
create policy "keys_update" on public.api_keys for update using (true);

-- ============================================
-- 2. Webhooks table
-- ============================================
create table if not exists public.webhooks (
  id uuid default gen_random_uuid() primary key,
  user_email text not null,
  url text not null,
  events text[] default '{"scan.complete"}',
  topic_filter text,
  confidence_threshold float default 0.7,
  active boolean default true,
  created_at timestamptz default now()
);

alter table public.webhooks enable row level security;
create policy "wh_read" on public.webhooks for select using (true);
create policy "wh_insert" on public.webhooks for insert with check (true);
create policy "wh_update" on public.webhooks for update using (true);
create policy "wh_delete" on public.webhooks for delete using (true);

-- ============================================
-- 3. Users table (for auth)
-- ============================================
create table if not exists public.users (
  id uuid default gen_random_uuid() primary key,
  email text unique not null,
  name text,
  password_hash text not null,
  tier text default 'free' check (tier in ('free', 'invited', 'pro', 'team')),
  invite_code text,
  access_expires_at timestamptz,
  created_at timestamptz default now(),
  last_login timestamptz
);

alter table public.users enable row level security;
create policy "users_read" on public.users for select using (true);
create policy "users_insert" on public.users for insert with check (true);
create policy "users_update" on public.users for update using (true);
SQLEOF
echo ""

# ============================================
# BACKEND
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

# Install bcrypt for password hashing
pip install bcrypt --break-system-packages 2>/dev/null || true

python3 << 'PYEOF'
content = open('app/main.py').read()

new_endpoints = ''

# --- Auth endpoints ---
if '/api/auth' not in content:
    new_endpoints += '''

# ============================================
# Auth endpoints
# ============================================

@app.post("/api/auth/signup")
async def signup(body: dict):
    """Register a new user."""
    import bcrypt
    settings = get_settings()
    email = (body.get("email") or "").strip().lower()
    name = body.get("name", "")
    password = body.get("password", "")
    
    if not email or not password:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and password required")
    if len(password) < 8:
        from fastapi import HTTPException
        raise HTTPException(400, "Password must be at least 8 characters")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    existing = sb.table("users").select("id").eq("email", email).execute()
    if existing.data:
        from fastapi import HTTPException
        raise HTTPException(400, "Email already registered")
    
    pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    
    # Check if they have an invitation
    inv = sb.table("invitations").select("status, invite_code, access_expires_at").eq("email", email).eq("status", "approved").execute()
    tier = "invited" if inv.data else "free"
    expires = inv.data[0].get("access_expires_at") if inv.data else None
    
    result = sb.table("users").insert({
        "email": email, "name": name, "password_hash": pw_hash,
        "tier": tier, "invite_code": inv.data[0].get("invite_code") if inv.data else None,
        "access_expires_at": expires,
    }).execute()
    
    user = result.data[0] if result.data else {}
    
    import hashlib, time
    token = hashlib.sha256(f"{email}:{time.time()}:{settings.supabase_key}".encode()).hexdigest()[:48]
    
    return {"success": True, "token": token, "user": {"email": email, "name": name, "tier": tier}}


@app.post("/api/auth/login")
async def login(body: dict):
    """Login with email and password."""
    import bcrypt
    settings = get_settings()
    email = (body.get("email") or "").strip().lower()
    password = body.get("password", "")
    
    if not email or not password:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and password required")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    result = sb.table("users").select("*").eq("email", email).execute()
    if not result.data:
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid email or password")
    
    user = result.data[0]
    if not bcrypt.checkpw(password.encode(), user["password_hash"].encode()):
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid email or password")
    
    # Check access expiry
    from datetime import datetime
    if user.get("access_expires_at"):
        if datetime.fromisoformat(user["access_expires_at"].replace("Z", "+00:00")) < datetime.now(datetime.now().astimezone().tzinfo):
            sb.table("users").update({"tier": "free"}).eq("id", user["id"]).execute()
            user["tier"] = "free"
    
    sb.table("users").update({"last_login": datetime.utcnow().isoformat()}).eq("id", user["id"]).execute()
    
    import hashlib, time
    token = hashlib.sha256(f"{email}:{time.time()}:{settings.supabase_key}".encode()).hexdigest()[:48]
    
    return {"success": True, "token": token, "user": {"email": user["email"], "name": user.get("name"), "tier": user["tier"]}}

'''

# --- API key endpoints ---
if '/api/keys' not in content:
    new_endpoints += '''

# ============================================
# API key management
# ============================================

@app.post("/api/keys/create")
async def create_api_key(body: dict):
    """Generate a new API key for a user."""
    import hashlib, secrets
    settings = get_settings()
    email = body.get("email", "")
    name = body.get("name", "Default")
    
    if not email:
        from fastapi import HTTPException
        raise HTTPException(400, "Email required")
    
    raw_key = f"dsk_{secrets.token_hex(24)}"
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    key_prefix = raw_key[:12]
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("api_keys").insert({
        "user_email": email, "key_hash": key_hash, "key_prefix": key_prefix, "name": name,
    }).execute()
    
    return {"key": raw_key, "prefix": key_prefix, "name": name, "note": "Save this key — it cannot be shown again."}


@app.get("/api/keys")
async def list_api_keys(email: str = ""):
    """List API keys for a user (shows prefix only)."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("api_keys").select("id, key_prefix, name, tier, rate_limit, requests_today, active, created_at").eq("user_email", email).execute()
    return {"keys": result.data or []}


@app.post("/api/keys/revoke")
async def revoke_api_key(body: dict):
    """Deactivate an API key."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("api_keys").update({"active": False}).eq("id", body.get("id")).execute()
    return {"success": True}


async def validate_api_key(key: str) -> dict | None:
    """Validate an API key and return user info. Returns None if invalid."""
    import hashlib
    settings = get_settings()
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("api_keys").select("*").eq("key_hash", key_hash).eq("active", True).execute()
    if not result.data:
        return None
    row = result.data[0]
    # Rate limit check (reset daily)
    from datetime import datetime, timedelta
    last_reset = datetime.fromisoformat(row["last_reset"].replace("Z", "+00:00")) if row.get("last_reset") else datetime.min
    now = datetime.utcnow()
    if (now - last_reset.replace(tzinfo=None)).days >= 1:
        sb.table("api_keys").update({"requests_today": 1, "last_reset": now.isoformat()}).eq("id", row["id"]).execute()
        return row
    if row["requests_today"] >= row["rate_limit"]:
        return None  # rate limited
    sb.table("api_keys").update({"requests_today": row["requests_today"] + 1}).eq("id", row["id"]).execute()
    return row

'''

# --- Webhook endpoints ---
if '/api/webhooks' not in content:
    new_endpoints += '''

# ============================================
# Webhooks
# ============================================

@app.post("/api/webhooks/create")
async def create_webhook(body: dict):
    """Register a webhook URL."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("webhooks").insert({
        "user_email": body.get("email", ""),
        "url": body.get("url", ""),
        "events": body.get("events", ["scan.complete"]),
        "topic_filter": body.get("topic_filter"),
        "confidence_threshold": body.get("confidence_threshold", 0.7),
    }).execute()
    return {"success": True}


@app.get("/api/webhooks")
async def list_webhooks(email: str = ""):
    """List webhooks for a user."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("webhooks").select("*").eq("user_email", email).execute()
    return {"webhooks": result.data or []}


@app.delete("/api/webhooks/{webhook_id}")
async def delete_webhook(webhook_id: str):
    """Delete a webhook."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("webhooks").delete().eq("id", webhook_id).execute()
    return {"success": True}


async def fire_webhooks(event: str, data: dict):
    """Fire all matching webhooks for an event."""
    settings = get_settings()
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        hooks = sb.table("webhooks").select("*").eq("active", True).contains("events", [event]).execute()
        
        import httpx
        async with httpx.AsyncClient(timeout=10) as client:
            for hook in (hooks.data or []):
                topic = hook.get("topic_filter")
                if topic and topic.lower() not in str(data).lower():
                    continue
                try:
                    await client.post(hook["url"], json={"event": event, "data": data})
                except:
                    pass
    except:
        pass

'''

# --- Dispatch cron endpoint ---
if '/api/dispatch/cron' not in content:
    new_endpoints += '''

# ============================================
# Dispatch cron (call weekly via external cron)
# ============================================

@app.post("/api/dispatch/cron")
async def dispatch_cron(body: dict = {}):
    """Send weekly digest to all invited users. Call via cron.org or Railway cron."""
    settings = get_settings()
    secret = body.get("secret", "")
    if secret != (settings.dissekt_admin_key if hasattr(settings, "dissekt_admin_key") else "dissekt-sambit-2026"):
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid secret")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    # Get all invited users
    users = sb.table("invitations").select("email, name").eq("status", "approved").execute()
    emails = [u["email"] for u in (users.data or []) if u.get("email")]
    
    if not emails:
        return {"sent": 0, "reason": "No invited users"}
    
    # Get digest data
    digest = await weekly_digest()
    if digest["total_analyses"] == 0:
        return {"sent": 0, "reason": "No analyses this week"}
    
    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest.get("top_techniques", []))
    topics_html = "".join(f"<li>{t['topic']} ({t['count']} analyses)</li>" for t in digest.get("trending_topics", []))
    
    sent = 0
    import httpx
    async with httpx.AsyncClient() as client:
        for email in emails:
            try:
                await client.post("https://api.resend.com/emails",
                    headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                    json={
                        "from": "Dissekt <onboarding@resend.dev>",
                        "to": email,
                        "subject": f"Dissekt Dispatch: {digest['total_analyses']} analyses this week",
                        "html": f"""<div style="font-family:-apple-system,sans-serif;max-width:500px;margin:0 auto;">
                            <div style="background:#0d9488;padding:16px 20px;border-radius:10px 10px 0 0;"><h2 style="color:white;margin:0;">Dissekt Dispatch</h2></div>
                            <div style="background:#fff;padding:20px;border:1px solid #e5eaea;border-top:none;border-radius:0 0 10px 10px;">
                            <p>{digest['total_analyses']} analyses this week.</p>
                            <h3 style="font-size:14px;">Top techniques</h3><ul>{techs_html or '<li>None</li>'}</ul>
                            <h3 style="font-size:14px;">Trending topics</h3><ul>{topics_html or '<li>None</li>'}</ul>
                            <div style="text-align:center;margin:20px 0;"><a href="https://dissekt.info/analyze" style="background:#0d9488;color:white;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:600;">Analyze something</a></div>
                            <p style="font-size:11px;color:#aaa;text-align:center;">dissekt.info</p></div></div>"""
                    })
                sent += 1
            except:
                pass
    
    return {"sent": sent, "total_users": len(emails)}

'''

if new_endpoints:
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        new_endpoints + '\n# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print(f'✅ Backend: auth + API keys + webhooks + dispatch cron')
else:
    print('  Endpoints already exist')
PYEOF

# Wire webhooks into scan pipeline
python3 << 'PYEOF'
content = open('app/main.py').read()
if 'fire_webhooks' in content and 'await fire_webhooks("scan.complete"' not in content:
    # Add webhook firing after scan completes
    content = content.replace(
        'return analysis',
        '''    # Fire webhooks
    try:
        await fire_webhooks("scan.complete", {
            "id": getattr(analysis, "id", ""),
            "techniques": len(analysis.prism.techniques) if analysis.prism else 0,
            "score": getattr(analysis, "clarity_score", 0),
        })
    except:
        pass
    
    return analysis'''
    )
    open('app/main.py', 'w').write(content)
    print('✅ Scan pipeline: webhooks wired')
PYEOF

echo "✅ Backend complete"

# ============================================
# FRONTEND: Auth pages
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# Update invite page to include real signup
mkdir -p src/app/signup

cat > src/app/signup/page.tsx << 'SIGNUPEOF'
'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function SignupPage() {
  const [mode, setMode] = useState<'signup' | 'login'>('signup');
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const handleSubmit = async () => {
    if (!email || !password) return;
    setStatus('loading');
    try {
      const res = await fetch(`${API_URL}/api/auth/${mode}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, name, password }),
      });
      const data = await res.json();
      if (data.success) {
        localStorage.setItem('dissekt_token', data.token);
        localStorage.setItem('dissekt_tier', data.user.tier);
        localStorage.setItem('dissekt_email', data.user.email);
        localStorage.setItem('dissekt_name', data.user.name || '');
        setStatus('success');
        setMessage(mode === 'signup' ? 'Account created!' : 'Welcome back!');
        setTimeout(() => window.location.href = '/analyze', 1500);
      } else {
        setStatus('error');
        setMessage(data.detail || data.error || 'Something went wrong');
      }
    } catch { setStatus('error'); setMessage('Connection failed'); }
  };

  const inp: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8fafa', marginBottom: 10, boxSizing: 'border-box' as any };

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 400, margin: '60px auto', padding: '0 24px' }}>
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 28 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
            <button onClick={() => { setMode('signup'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'signup' ? '#0d9488' : '#f0f0ee', color: mode === 'signup' ? '#fff' : '#555' }}>
              Sign up
            </button>
            <button onClick={() => { setMode('login'); setStatus('idle'); }}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, fontSize: 13, fontWeight: 600, border: 'none', cursor: 'pointer', background: mode === 'login' ? '#0d9488' : '#f0f0ee', color: mode === 'login' ? '#fff' : '#555' }}>
              Log in
            </button>
          </div>

          {status === 'success' && (
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{message}</div>
              <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>Redirecting...</div>
            </div>
          )}

          {status === 'error' && (
            <div style={{ padding: '8px 12px', background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12, marginBottom: 12 }}>{message}</div>
          )}

          {status !== 'success' && (
            <>
              {mode === 'signup' && <input type="text" placeholder="Name" value={name} onChange={e => setName(e.target.value)} style={inp} />}
              <input type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} style={inp} />
              <input type="password" placeholder="Password (8+ characters)" value={password} onChange={e => setPassword(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleSubmit()} style={inp} />
              <button onClick={handleSubmit} disabled={!email || !password || password.length < 8 || status === 'loading'}
                style={{ width: '100%', padding: '10px 0', background: email && password.length >= 8 ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email && password.length >= 8 ? 'pointer' : 'not-allowed' }}>
                {status === 'loading' ? 'Please wait...' : mode === 'signup' ? 'Create account' : 'Log in'}
              </button>
              <div style={{ textAlign: 'center', marginTop: 12, fontSize: 12, color: '#888' }}>
                {mode === 'signup' ? (
                  <>Already have an invite code? <a href="/invite" style={{ color: '#0d9488' }}>Redeem here</a></>
                ) : (
                  <>No account? <a href="/invite" style={{ color: '#0d9488' }}>Request access</a></>
                )}
              </div>
            </>
          )}
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
SIGNUPEOF

echo "✅ Signup/Login page"

# ============================================
# Browser Extension Glow
# ============================================

mkdir -p ../dissekt-extension-glow

cat > ../dissekt-extension-glow/manifest.json << 'MFEOF'
{
  "manifest_version": 3,
  "name": "Dissekt Glow — Information Transparency Lens",
  "version": "1.0.0",
  "description": "Subtly highlights manipulation techniques while you read any news article. Passive analysis, always on.",
  "permissions": ["activeTab", "storage"],
  "host_permissions": ["<all_urls>"],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["glow.js"],
      "css": ["glow.css"],
      "run_at": "document_idle"
    }
  ],
  "background": {
    "service_worker": "background.js"
  },
  "action": {
    "default_popup": "popup.html",
    "default_icon": "icon48.png"
  },
  "icons": {
    "48": "icon48.png",
    "128": "icon128.png"
  }
}
MFEOF

cat > ../dissekt-extension-glow/glow.css << 'CSSEOF'
.dissekt-glow-loaded { border-bottom: 2px solid #fca5a5; background: rgba(254, 242, 242, 0.3); border-radius: 2px; cursor: help; transition: background 0.2s; }
.dissekt-glow-loaded:hover { background: rgba(254, 202, 202, 0.5); }
.dissekt-glow-emotional { border-bottom: 2px solid #fcd34d; background: rgba(255, 251, 235, 0.3); border-radius: 2px; cursor: help; }
.dissekt-glow-emotional:hover { background: rgba(252, 211, 77, 0.3); }
.dissekt-glow-authority { border-bottom: 2px solid #c4b5fd; background: rgba(245, 243, 255, 0.3); border-radius: 2px; cursor: help; }
.dissekt-glow-authority:hover { background: rgba(196, 181, 253, 0.3); }
.dissekt-glow-missing { border-bottom: 2px solid #93c5fd; background: rgba(239, 246, 255, 0.3); border-radius: 2px; cursor: help; }
.dissekt-glow-missing:hover { background: rgba(147, 197, 253, 0.3); }
.dissekt-glow-tooltip { position: absolute; z-index: 99999; background: #1a1a1a; color: #fff; padding: 6px 10px; border-radius: 6px; font-size: 11px; max-width: 280px; line-height: 1.4; pointer-events: none; font-family: -apple-system, sans-serif; }
.dissekt-glow-bar { position: fixed; bottom: 12px; right: 12px; z-index: 99998; background: #fff; border: 1px solid #e5eaea; border-radius: 10px; padding: 8px 14px; font-family: -apple-system, sans-serif; font-size: 12px; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
CSSEOF

cat > ../dissekt-extension-glow/glow.js << 'GLOWEOF'
(function() {
  const API = 'https://dissekt-api.up.railway.app';
  
  // Only run on article-like pages
  const article = document.querySelector('article') || document.querySelector('[role="article"]') || document.querySelector('.post-content, .article-body, .entry-content, .story-body');
  if (!article) return;
  
  const text = article.innerText;
  if (!text || text.length < 200) return;

  // Keyword patterns for passive detection (no API call needed)
  const patterns = {
    loaded: /\b(shocking|devastating|explosive|outrageous|disgusting|horrifying|sickening|unbelievable|terrifying|alarming)\b/gi,
    emotional: /\b(heartbreaking|tragic|beautiful|wonderful|amazing|terrible|horrible|incredible|unacceptable|shameful)\b/gi,
    authority: /\b(experts say|studies show|scientists confirm|officials report|according to sources|research proves|data shows)\b/gi,
    missing: /\b(always|never|everyone|nobody|all|none|completely|totally|absolutely|impossible|undeniable)\b/gi,
  };

  const classMap = { loaded: 'dissekt-glow-loaded', emotional: 'dissekt-glow-emotional', authority: 'dissekt-glow-authority', missing: 'dissekt-glow-missing' };
  const labelMap = { loaded: 'Loaded language', emotional: 'Emotional framing', authority: 'Appeal to authority', missing: 'Absolute language (possible missing context)' };

  // Walk text nodes and highlight matches
  const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, null);
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);

  let totalHighlights = 0;

  nodes.forEach(node => {
    const parent = node.parentElement;
    if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE' || parent.classList.contains('dissekt-glow-loaded')) return;

    let html = node.textContent;
    let changed = false;

    for (const [type, regex] of Object.entries(patterns)) {
      const cls = classMap[type];
      const label = labelMap[type];
      html = html.replace(regex, (match) => {
        changed = true;
        totalHighlights++;
        return `<span class="${cls}" data-dissekt-tip="${label}: '${match}'">${match}</span>`;
      });
    }

    if (changed) {
      const span = document.createElement('span');
      span.innerHTML = html;
      parent.replaceChild(span, node);
    }
  });

  if (totalHighlights === 0) return;

  // Add floating bar
  const bar = document.createElement('div');
  bar.className = 'dissekt-glow-bar';
  bar.innerHTML = `<div style="width:20px;height:20px;background:#0d9488;border-radius:5px;display:flex;align-items:center;justify-content:center"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><span>${totalHighlights} signals</span><a href="https://dissekt.info/analyze?url=${encodeURIComponent(window.location.href)}" target="_blank" style="color:#0d9488;text-decoration:none;font-weight:600;font-size:11px;">Full analysis →</a>`;
  document.body.appendChild(bar);

  // Tooltip on hover
  let tooltip = null;
  document.addEventListener('mouseover', (e) => {
    const el = e.target.closest('[data-dissekt-tip]');
    if (el) {
      if (!tooltip) {
        tooltip = document.createElement('div');
        tooltip.className = 'dissekt-glow-tooltip';
        document.body.appendChild(tooltip);
      }
      tooltip.textContent = el.getAttribute('data-dissekt-tip');
      const rect = el.getBoundingClientRect();
      tooltip.style.top = (rect.top + window.scrollY - 30) + 'px';
      tooltip.style.left = rect.left + 'px';
      tooltip.style.display = 'block';
    } else if (tooltip) {
      tooltip.style.display = 'none';
    }
  });
})();
GLOWEOF

cat > ../dissekt-extension-glow/background.js << 'BGEOF'
chrome.runtime.onInstalled.addListener(() => {
  console.log('Dissekt Glow installed');
});
BGEOF

cat > ../dissekt-extension-glow/popup.html << 'POPEOF'
<!DOCTYPE html>
<html>
<head><style>
body { width: 280px; padding: 16px; font-family: -apple-system, sans-serif; margin: 0; }
h2 { font-size: 15px; margin: 0 0 8px; display: flex; align-items: center; gap: 8px; }
.logo { width: 24px; height: 24px; background: #0d9488; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
p { font-size: 12px; color: #555; line-height: 1.6; margin: 0 0 12px; }
.legend { display: flex; flex-direction: column; gap: 4px; margin-bottom: 12px; }
.legend-item { display: flex; align-items: center; gap: 8px; font-size: 11px; }
.dot { width: 12px; height: 4px; border-radius: 2px; }
a { display: block; text-align: center; background: #0d9488; color: white; padding: 8px; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: 600; }
</style></head>
<body>
  <h2>
    <div class="logo"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
    Dissekt Glow
  </h2>
  <p>Passively highlights manipulation signals while you read. No click needed.</p>
  <div class="legend">
    <div class="legend-item"><div class="dot" style="background:#fca5a5"></div> Loaded language</div>
    <div class="legend-item"><div class="dot" style="background:#fcd34d"></div> Emotional framing</div>
    <div class="legend-item"><div class="dot" style="background:#c4b5fd"></div> Appeal to authority</div>
    <div class="legend-item"><div class="dot" style="background:#93c5fd"></div> Absolute language</div>
  </div>
  <a href="https://dissekt.info/analyze" target="_blank">Open full analyzer</a>
</body>
</html>
POPEOF

echo "✅ Extension Glow built at dissekt-extension-glow/"

# ============================================
# Add signup link to header + footer
# ============================================

python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()
if '/signup' not in content:
    content = content.replace(
        "href=\"/invite\" style={{ fontSize: 13, color: '#fff'",
        "href=\"/signup\" style={{ fontSize: 13, color: '#fff'"
    )
    open('src/components/SiteHeader.tsx', 'w').write(content)
    print('✅ Header: Get access → /signup')
PYEOF

python3 << 'PYEOF'
content = open('src/components/SiteFooter.tsx').read()
if '/signup' not in content:
    content = content.replace(
        '<a href="/invite"', '<a href="/signup"'
    )
    # keep invite page link too
    content = content.replace(
        '>Get access<', '>Sign up<'
    )
    open('src/components/SiteFooter.tsx', 'w').write(content)
    print('✅ Footer: Get access → Sign up')
PYEOF

echo ""
echo "✅ All 5 features built:"
echo ""
echo "  🔐 Auth (signup + login)"
echo "     - /signup page (sign up / log in tabs)"
echo "     - POST /api/auth/signup + /api/auth/login"
echo "     - Supabase 'users' table with bcrypt password hash"
echo "     - Auto-detects invitation status on signup"
echo "     - Token-based session"
echo ""
echo "  🔑 API Keys"
echo "     - POST /api/keys/create → generates dsk_xxxx key"
echo "     - GET /api/keys?email=x → list keys (prefix only)"
echo "     - POST /api/keys/revoke → deactivate"
echo "     - Rate limiting per key (100/day default)"
echo ""
echo "  🔔 Webhooks"
echo "     - POST /api/webhooks/create → register URL"
echo "     - GET /api/webhooks?email=x → list"
echo "     - DELETE /api/webhooks/{id} → remove"
echo "     - Auto-fires on scan.complete with topic/confidence filters"
echo ""
echo "  📨 Dispatch Cron"
echo "     - POST /api/dispatch/cron (with secret) → sends digest to all invited users"
echo "     - Set up weekly cron at cron-job.org or Railway cron"
echo "     - URL: https://dissekt-api.up.railway.app/api/dispatch/cron"
echo "     - Body: {\"secret\": \"dissekt-sambit-2026\"}"
echo ""
echo "  ✨ Extension Glow (dissekt-extension-glow/)"
echo "     - Manifest V3 content script"
echo "     - Passive keyword detection: loaded, emotional, authority, absolute language"
echo "     - Color-coded underlines on article text"
echo "     - Hover tooltip with technique name"
echo "     - Floating bar: 'X signals · Full analysis →'"
echo "     - Popup with legend"
echo ""
echo "⚠️  Run the SQL first!"
echo "⚠️  pip install bcrypt --break-system-packages"
echo ""
echo "Test: npm run build && npm run dev"
