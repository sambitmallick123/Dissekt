#!/bin/bash
# Dissekt — Source curation admin tab + API usage dashboard
set -e

# ============================================
# 1. BACKEND: API usage stats endpoint
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt

python3 -c "
content = open('app/main.py').read()
added = False

if '/api/keys/usage' not in content:
    endpoint = '''

@app.get(\"/api/keys/usage\")
async def api_key_usage(email: str = \"\"):
    \"\"\"Get API usage stats for a user.\"\"\"
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    keys = sb.table(\"api_keys\").select(\"*\").eq(\"user_email\", email).execute()
    
    total_requests = 0
    active_keys = 0
    key_stats = []
    
    for k in (keys.data or []):
        total_requests += k.get(\"requests_today\", 0)
        if k.get(\"active\"): active_keys += 1
        key_stats.append({
            \"id\": k[\"id\"],
            \"prefix\": k[\"key_prefix\"],
            \"name\": k.get(\"name\", \"Default\"),
            \"tier\": k.get(\"tier\", \"pro\"),
            \"rate_limit\": k.get(\"rate_limit\", 100),
            \"requests_today\": k.get(\"requests_today\", 0),
            \"active\": k.get(\"active\", True),
            \"created_at\": k.get(\"created_at\", \"\"),
            \"usage_pct\": round((k.get(\"requests_today\", 0) / max(k.get(\"rate_limit\", 100), 1)) * 100),
        })
    
    return {
        \"email\": email,
        \"total_keys\": len(keys.data or []),
        \"active_keys\": active_keys,
        \"total_requests_today\": total_requests,
        \"keys\": key_stats,
    }

'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + endpoint)
    added = True

if '/api/admin/sources/action' not in content:
    endpoint2 = '''

@app.post(\"/api/admin/sources/action\")
async def admin_source_action(body: dict):
    \"\"\"Admin approves/rejects a suggested source.\"\"\"
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    source_id = body.get(\"id\")
    action = body.get(\"action\")  # approve, reject
    
    if not source_id or action not in (\"approve\", \"reject\"):
        from fastapi import HTTPException
        raise HTTPException(400, \"id and action (approve/reject) required\")
    
    status = \"approved\" if action == \"approve\" else \"rejected\"
    sb.table(\"feedback\").update({\"status\": status}).eq(\"id\", source_id).execute()
    
    return {\"success\": True, \"status\": status}

'''
    content = content.replace('app = FastAPI()', 'app = FastAPI()' + endpoint2)
    added = True

if added:
    open('app/main.py', 'w').write(content)
    print('✅ Backend: /api/keys/usage + /api/admin/sources/action')
"

echo "✅ Backend endpoints"

# ============================================
# 2. FRONTEND: API Usage Dashboard page
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

mkdir -p src/app/dashboard

cat > src/app/dashboard/page.tsx << 'DASHEOF'
'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function DashboardPage() {
  const [email, setEmail] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [newKeyName, setNewKeyName] = useState('');
  const [newKey, setNewKey] = useState('');
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    const stored = typeof window !== 'undefined' ? localStorage.getItem('dissekt_email') : '';
    if (stored) { setEmail(stored); loadUsage(stored); }
  }, []);

  const loadUsage = async (e: string) => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/keys/usage?email=${encodeURIComponent(e)}`);
      setData(await res.json());
    } catch {}
    finally { setLoading(false); }
  };

  const createKey = async () => {
    if (!email) return;
    setCreating(true);
    try {
      const res = await fetch(`${API_URL}/api/keys/create`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, name: newKeyName || 'Default' }),
      });
      const d = await res.json();
      setNewKey(d.key || '');
      setNewKeyName('');
      loadUsage(email);
    } catch {}
    finally { setCreating(false); }
  };

  const revokeKey = async (id: string) => {
    await fetch(`${API_URL}/api/keys/revoke`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id }),
    });
    loadUsage(email);
  };

  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>🔑 API Dashboard</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>Manage your API keys and monitor usage.</p>

        {!email && (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Enter your email to view API keys</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input type="email" placeholder="your@email.com" value={email} onChange={e => setEmail(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && loadUsage(email)}
                style={{ flex: 1, padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none' }} />
              <button onClick={() => loadUsage(email)} disabled={!email}
                style={{ padding: '10px 20px', background: email ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: email ? 'pointer' : 'not-allowed' }}>
                Load
              </button>
            </div>
          </div>
        )}

        {data && (
          <>
            {/* Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 10, marginBottom: 20 }}>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>{data.total_keys}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Total keys</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#16a34a' }}>{data.active_keys}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Active</div>
              </div>
              <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#2563eb' }}>{data.total_requests_today}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Requests today</div>
              </div>
            </div>

            {/* Keys list */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Your API keys</div>
              {data.keys?.length === 0 && (
                <div style={{ padding: 20, textAlign: 'center', color: '#888', fontSize: 13 }}>No API keys yet. Create one below.</div>
              )}
              {data.keys?.map((k: any) => (
                <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '0.5px solid #f0f0ee' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                      <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'monospace', color: '#1a1a1a' }}>{k.prefix}...</span>
                      <span style={{ fontSize: 11, color: '#888' }}>{k.name}</span>
                      {!k.active && <span style={{ fontSize: 9, padding: '1px 6px', background: '#fef2f2', color: '#dc2626', borderRadius: 3, fontWeight: 600 }}>Revoked</span>}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{ flex: 1, maxWidth: 200, height: 6, background: '#f0f0ee', borderRadius: 3 }}>
                        <div style={{ height: '100%', width: `${Math.min(k.usage_pct, 100)}%`, background: k.usage_pct > 80 ? '#dc2626' : k.usage_pct > 50 ? '#d97706' : '#0d9488', borderRadius: 3 }} />
                      </div>
                      <span style={{ fontSize: 10, color: '#888' }}>{k.requests_today}/{k.rate_limit} today</span>
                    </div>
                  </div>
                  {k.active && (
                    <button onClick={() => revokeKey(k.id)}
                      style={{ padding: '4px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 5, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>
                      Revoke
                    </button>
                  )}
                </div>
              ))}
            </div>

            {/* Create new key */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Create new key</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <input type="text" placeholder="Key name (e.g., My App)" value={newKeyName} onChange={e => setNewKeyName(e.target.value)}
                  style={{ flex: 1, padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none' }} />
                <button onClick={createKey} disabled={creating}
                  style={{ padding: '8px 18px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
                  {creating ? '...' : 'Generate'}
                </button>
              </div>
              {newKey && (
                <div style={{ marginTop: 10, padding: '10px 14px', background: '#f0fdf4', border: '0.5px solid #dcfce7', borderRadius: 8 }}>
                  <div style={{ fontSize: 11, fontWeight: 600, color: '#166534', marginBottom: 4 }}>Save this key — it cannot be shown again:</div>
                  <div style={{ fontSize: 13, fontFamily: 'monospace', color: '#1a1a1a', wordBreak: 'break-all', userSelect: 'all' }}>{newKey}</div>
                </div>
              )}
            </div>

            {/* Usage example */}
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Quick start</div>
              <div style={{ background: '#1a1a1a', borderRadius: 8, padding: '14px 16px', fontSize: 12, fontFamily: 'monospace', color: '#5eead4', lineHeight: 1.8, overflowX: 'auto' }}>
                <span style={{ color: '#888' }}>{'# Analyze content'}</span><br />
                curl -X POST https://dissekt-api.up.railway.app/api/scan \<br />
                {'  '}-H "Content-Type: application/json" \<br />
                {'  '}-H "X-API-Key: dsk_your_key_here" \<br />
                {'  '}-d {"'{'}"}{"\"content\": \"https://example.com/article\", \"mode\": \"brief\""}{"'}'"}
              </div>
            </div>
          </>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
DASHEOF

echo "✅ API Dashboard page (/dashboard)"

# ============================================
# 3. Add source curation to admin page
# ============================================

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Check if Sources tab already exists
if 'SourcesTab' not in content:
    # Add SourcesTab component
    sources_tab = '''

function SourcesTab() {
  const [sources, setSources] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

  const load = async () => {
    try {
      const res = await fetch(`${API_URL}/api/admin/sources`);
      const data = await res.json();
      setSources(data.sources || []);
    } catch {}
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const action = async (id: string, act: string) => {
    await fetch(`${API_URL}/api/admin/sources/action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, action: act }),
    });
    load();
  };

  if (loading) return <div style={{ padding: 20, textAlign: 'center', color: '#888' }}>Loading...</div>;

  return (
    <div>
      <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Suggested sources ({sources.length})</div>
      {sources.length === 0 && (
        <div style={{ padding: 30, textAlign: 'center', color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No source suggestions yet</div>
      )}
      {sources.map((s, i) => {
        const lines = (s.message || '').split('  ');
        const srcName = lines.find((l: string) => l.startsWith('Source:'))?.replace('Source:', '').trim() || '';
        const srcUrl = lines.find((l: string) => l.startsWith('URL:'))?.replace('URL:', '').trim() || '';
        const srcReason = lines.find((l: string) => l.startsWith('Reason:'))?.replace('Reason:', '').trim() || '';
        const statusColor = s.status === 'approved' ? '#16a34a' : s.status === 'rejected' ? '#dc2626' : '#d97706';
        return (
          <div key={i} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: '12px 16px', marginBottom: 8 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{srcName || 'Unknown source'}</div>
                {srcUrl && <a href={srcUrl} target="_blank" rel="noopener" style={{ fontSize: 11, color: '#0d9488', textDecoration: 'none' }}>{srcUrl}</a>}
                {s.email && <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>Suggested by: {s.email}</div>}
              </div>
              <span style={{ fontSize: 10, fontWeight: 600, color: statusColor, padding: '2px 8px', borderRadius: 4, background: s.status === 'approved' ? '#f0fdf4' : s.status === 'rejected' ? '#fef2f2' : '#fffbeb' }}>
                {s.status || 'pending'}
              </span>
            </div>
            {srcReason && <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5, marginBottom: 8 }}>{srcReason}</div>}
            {(!s.status || s.status === 'unread' || s.status === 'pending') && (
              <div style={{ display: 'flex', gap: 6 }}>
                <button onClick={() => action(s.id, 'approve')}
                  style={{ padding: '5px 14px', background: '#f0fdf4', color: '#16a34a', border: '0.5px solid #dcfce7', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                  ✅ Approve
                </button>
                <button onClick={() => action(s.id, 'reject')}
                  style={{ padding: '5px 14px', background: '#fef2f2', color: '#dc2626', border: '0.5px solid #fecaca', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                  ❌ Reject
                </button>
              </div>
            )}
            <div style={{ fontSize: 10, color: '#aaa', marginTop: 4 }}>{new Date(s.created_at).toLocaleDateString()}</div>
          </div>
        );
      })}
    </div>
  );
}

'''

    # Insert SourcesTab component before the main AdminPage function
    content = content.replace(
        'export default function AdminPage()',
        sources_tab + 'export default function AdminPage()'
    )

    # Add Sources as an 8th tab
    content = content.replace(
        "{ id: 'settings', label: '⚙️ Settings' },",
        "{ id: 'settings', label: '⚙️ Settings' },\n    { id: 'sources', label: '📡 Sources' },"
    )

    # Add the tab content render
    content = content.replace(
        "{activeTab === 'settings' && <SettingsTab",
        "{activeTab === 'sources' && <SourcesTab />}\n        {activeTab === 'settings' && <SettingsTab"
    )

    open('src/app/admin/page.tsx', 'w').write(content)
    print('✅ Admin: Sources tab added (8th tab)')
else:
    print('  SourcesTab already exists')
PYEOF

# ============================================
# 4. Add dashboard link to header + footer
# ============================================

python3 -c "
content = open('src/components/SiteFooter.tsx').read()
if '/dashboard' not in content:
    content = content.replace(
        '<a href=\"/docs\" style={{ color: \"#5f8a84\", textDecoration: \"none\" }}>API</a>',
        '<a href=\"/docs\" style={{ color: \"#5f8a84\", textDecoration: \"none\" }}>API</a>\n          <a href=\"/dashboard\" style={{ color: \"#5f8a84\", textDecoration: \"none\" }}>Dashboard</a>'
    )
    open('src/components/SiteFooter.tsx', 'w').write(content)
    print('✅ Footer: dashboard link')
"

echo ""
echo "✅ Both features built:"
echo ""
echo "  📡 Source Curation (Admin → Sources tab)"
echo "     - Lists all user-suggested sources"
echo "     - Shows: name, URL, reason, submitter email, status"
echo "     - Actions: ✅ Approve / ❌ Reject"
echo "     - Admin dashboard now has 8 tabs"
echo ""
echo "  🔑 API Usage Dashboard (/dashboard)"
echo "     - Stats: total keys, active keys, requests today"
echo "     - Per-key usage bar (color: green/yellow/red)"
echo "     - Create new key (generates dsk_xxx)"
echo "     - Revoke keys"
echo "     - Quick start curl example"
echo "     - Linked in footer"
echo ""
echo "npm run build"
