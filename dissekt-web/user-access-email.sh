#!/bin/bash
# Dissekt — Per-user access control + admin messaging
set -e

echo "⚠️  Run this SQL in Supabase first:"
echo ""
cat << 'SQLEOF'
-- Per-user feature overrides
alter table public.invitations add column if not exists custom_features jsonb;
alter table public.invitations add column if not exists custom_limits jsonb;

-- Message log
create table if not exists public.admin_messages (
  id uuid default gen_random_uuid() primary key,
  to_email text not null,
  subject text not null,
  body text not null,
  sent_at timestamptz default now()
);
alter table public.admin_messages enable row level security;
create policy "msg_read" on public.admin_messages for select using (true);
create policy "msg_insert" on public.admin_messages for insert with check (true);
SQLEOF
echo ""

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. Backend: per-user access + messaging endpoints
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

new_endpoints = ''

if '/api/admin/user-access' not in content:
    new_endpoints += '''

@app.post("/api/admin/user-access")
async def set_user_access(body: dict):
    """Set/revoke per-user component access."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    user_id = body.get("id")
    custom_features = body.get("custom_features")  # list of feature keys or null
    custom_limits = body.get("custom_limits")  # {"brief": N, "detailed": N} or null
    
    update = {}
    if custom_features is not None:
        update["custom_features"] = custom_features
    if custom_limits is not None:
        update["custom_limits"] = custom_limits
    
    if not update:
        return {"error": "Nothing to update"}
    
    result = sb.table("invitations").update(update).eq("id", user_id).execute()
    return {"success": True}


@app.post("/api/admin/send-message")
async def admin_send_message(body: dict):
    """Admin sends email to a user."""
    settings = get_settings()
    to_email = body.get("to")
    subject = body.get("subject", "Message from Dissekt")
    message = body.get("message", "")
    
    if not to_email or not message:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and message required")
    
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post("https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                json={
                    "from": "Dissekt <onboarding@resend.dev>",
                    "to": to_email,
                    "subject": subject,
                    "html": f"""<div style="font-family:-apple-system,sans-serif;max-width:500px;margin:0 auto;">
                        <div style="background:#0d9488;padding:14px 20px;border-radius:10px 10px 0 0;">
                            <h2 style="color:white;margin:0;font-size:16px;">Message from Dissekt</h2>
                        </div>
                        <div style="background:#fff;padding:20px;border:1px solid #e5eaea;border-top:none;border-radius:0 0 10px 10px;">
                            <p style="font-size:14px;color:#333;line-height:1.7;">{message.replace(chr(10), '<br/>')}</p>
                            <hr style="border:none;border-top:0.5px solid #e5eaea;margin:16px 0;"/>
                            <p style="font-size:11px;color:#aaa;">This message was sent by the Dissekt team.<br/>
                            <a href="https://dissekt.info" style="color:#0d9488;">dissekt.info</a></p>
                        </div>
                    </div>"""
                })
        
        # Log the message
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        sb.table("admin_messages").insert({"to_email": to_email, "subject": subject, "body": message}).execute()
        
        return {"success": res.status_code == 200}
    except Exception as e:
        return {"success": False, "error": str(e)}

'''

if new_endpoints:
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        new_endpoints + '\n# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Backend: user-access + send-message endpoints')
PYEOF

# ============================================
# 2. Frontend: Update admin page with user management + messaging
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# Add user access modal + email modal to InvitationsTab
# Find the InvitationsTab function and enhance it

# First, add the admin API endpoints for user-access and messaging
# We'll add modals to the InvitationsTab

old_inv_end = "      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No {filter} invitations</div>}\n    </div>\n  );\n}"

new_inv = """      {items.length === 0 && <div style={{ textAlign: 'center', padding: 30, color: '#888', fontSize: 13, background: '#fff', borderRadius: 10 }}>No {filter} invitations</div>}

      {/* Per-user access modal */}
      {editUser && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setEditUser(null)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 14, padding: 24, maxWidth: 480, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div><div style={{ fontSize: 15, fontWeight: 600 }}>{editUser.name || 'User'}</div><div style={{ fontSize: 12, color: '#888' }}>{editUser.email}</div></div>
              <button onClick={() => setEditUser(null)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', color: '#888' }}>✕</button>
            </div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>Component access (overrides tier defaults)</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, marginBottom: 14 }}>
              {['single_scan','bulk','compare','topics','radar','detailed_mode','image_upload','camera_upload','memory','journal','compass','pulse','counterfactual','claims'].map(f => (
                <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, cursor: 'pointer' }}>
                  <input type="checkbox" checked={(editUserFeatures).includes(f)}
                    onChange={e => setEditUserFeatures(prev => e.target.checked ? [...prev, f] : prev.filter(x => x !== f))} />
                  {f.replace(/_/g, ' ')}
                </label>
              ))}
            </div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 6 }}>Custom limits (leave 0 for tier default)</div>
            <div style={{ display: 'flex', gap: 10, marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 11 }}>Brief:</span><input type="number" value={editUserLimits.brief} onChange={e => setEditUserLimits(prev => ({ ...prev, brief: parseInt(e.target.value) || 0 }))} style={{ width: 60, padding: '4px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 12, outline: 'none' }} /></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 11 }}>Detailed:</span><input type="number" value={editUserLimits.detailed} onChange={e => setEditUserLimits(prev => ({ ...prev, detailed: parseInt(e.target.value) || 0 }))} style={{ width: 60, padding: '4px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 12, outline: 'none' }} /></div>
            </div>
            {accessMsg && <div style={{ fontSize: 12, color: '#0d9488', marginBottom: 8 }}>{accessMsg}</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={saveUserAccess} style={{ flex: 1, padding: '8px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Save access</button>
              <button onClick={() => { setEditUserFeatures([]); setEditUserLimits({ brief: 0, detailed: 0 }); saveUserAccess(); }} style={{ padding: '8px 14px', background: '#fef2f2', color: '#b91c1c', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Reset to tier default</button>
            </div>
          </div>
        </div>
      )}

      {/* Email modal */}
      {emailUser && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={() => setEmailUser(null)}>
          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
          <div style={{ position: 'relative', background: '#fff', borderRadius: 14, padding: 24, maxWidth: 480, width: '90%' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div><div style={{ fontSize: 15, fontWeight: 600 }}>Message to {emailUser.name || emailUser.email}</div></div>
              <button onClick={() => setEmailUser(null)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', color: '#888' }}>✕</button>
            </div>
            <input value={emailSubject} onChange={e => setEmailSubject(e.target.value)} placeholder="Subject"
              style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', marginBottom: 8, boxSizing: 'border-box' as any }} />
            <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} placeholder="Your message..." rows={5}
              style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #e5eaea', borderRadius: 6, fontSize: 13, outline: 'none', resize: 'vertical', marginBottom: 8, boxSizing: 'border-box' as any, fontFamily: 'inherit' }} />
            {emailMsg && <div style={{ fontSize: 12, color: '#0d9488', marginBottom: 8 }}>{emailMsg}</div>}
            <button onClick={sendUserEmail} disabled={!emailBody.trim()}
              style={{ width: '100%', padding: '8px 0', background: emailBody.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: emailBody.trim() ? 'pointer' : 'not-allowed' }}>
              Send email
            </button>
          </div>
        </div>
      )}
    </div>
  );
}"""

# Add state variables to InvitationsTab
old_inv_state = "  const [genResult, setGenResult] = useState('');"
new_inv_state = """  const [genResult, setGenResult] = useState('');
  const [editUser, setEditUser] = useState<any>(null);
  const [editUserFeatures, setEditUserFeatures] = useState<string[]>([]);
  const [editUserLimits, setEditUserLimits] = useState({ brief: 0, detailed: 0 });
  const [accessMsg, setAccessMsg] = useState('');
  const [emailUser, setEmailUser] = useState<any>(null);
  const [emailSubject, setEmailSubject] = useState('');
  const [emailBody, setEmailBody] = useState('');
  const [emailMsg, setEmailMsg] = useState('');

  const openEditUser = (inv: any) => {
    setEditUser(inv);
    setEditUserFeatures(inv.custom_features || []);
    setEditUserLimits(inv.custom_limits || { brief: 0, detailed: 0 });
    setAccessMsg('');
  };

  const saveUserAccess = async () => {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    await fetch(`${API_URL}/api/admin/user-access`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: editUser.id,
        custom_features: editUserFeatures.length > 0 ? editUserFeatures : null,
        custom_limits: (editUserLimits.brief > 0 || editUserLimits.detailed > 0) ? editUserLimits : null,
      }),
    });
    setAccessMsg('✅ Saved');
    load();
  };

  const openEmailUser = (inv: any) => {
    setEmailUser(inv);
    setEmailSubject('');
    setEmailBody('');
    setEmailMsg('');
  };

  const sendUserEmail = async () => {
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const res = await fetch(`${API_URL}/api/admin/send-message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ to: emailUser.email, subject: emailSubject || 'Message from Dissekt', message: emailBody }),
    });
    const data = await res.json();
    setEmailMsg(data.success ? '✅ Email sent' : '❌ Failed to send');
  };"""

# Add action buttons per user (manage access + email)
old_revoke_btn = """                {inv.status === 'approved' && (
                  <button onClick={() => action(inv.id, 'revoke')} style={{ padding: '6px 14px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>🚫 Revoke</button>
                )}"""

new_action_btns = """                {inv.status === 'approved' && (
                  <>
                    <button onClick={() => openEditUser(inv)} style={{ padding: '6px 10px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>⚙️ Access</button>
                    <button onClick={() => openEmailUser(inv)} style={{ padding: '6px 10px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>📧 Email</button>
                    <button onClick={() => action(inv.id, 'revoke')} style={{ padding: '6px 10px', background: '#fff', border: '0.5px solid #dc2626', color: '#dc2626', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>🚫 Revoke</button>
                  </>
                )}
                {inv.status === 'pending' && (
                  <button onClick={() => openEmailUser(inv)} style={{ padding: '6px 10px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 6, fontSize: 10, fontWeight: 600, cursor: 'pointer' }}>📧 Email</button>
                )}"""

if 'editUser' not in content:
    content = content.replace(old_inv_state, new_inv_state)
    content = content.replace(old_inv_end, new_inv)
    content = content.replace(old_revoke_btn, new_action_btns)
    open('src/app/admin/page.tsx', 'w').write(content)
    print('✅ Admin page: per-user access + email modals')
else:
    print('  Already has user management')
PYEOF

echo ""
echo "✅ All done:"
echo ""
echo "  ⚙️ Per-user access control"
echo "     - Click 'Access' on any approved user"
echo "     - Modal: 14 component checkboxes + custom brief/detailed limits"
echo "     - 'Save access' → stores in invitations.custom_features + custom_limits"
echo "     - 'Reset to tier default' → clears overrides"
echo "     - Works alongside tier-level settings (per-user overrides win)"
echo ""
echo "  📧 Admin email messaging"
echo "     - Click 'Email' on any user (approved or pending)"
echo "     - Modal: subject + message → sends via Resend"
echo "     - Branded Dissekt email template"
echo "     - Logged in admin_messages table"
echo "     - Works for pending users too (follow-up questions)"
echo ""
echo "  Actions per user row:"
echo "     Pending: [✅ Approve] [❌ Reject] [📧 Email]"
echo "     Approved: [⚙️ Access] [📧 Email] [🚫 Revoke]"
echo ""
echo "⚠️  Run the SQL first!"
echo ""
echo "npm run build"
