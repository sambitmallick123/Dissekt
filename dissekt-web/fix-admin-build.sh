#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Fixes the broken OverviewTab from the previous botched replacement
set -e

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

# The previous script left a broken fragment. Find the corrupted OverviewTab.
# Pattern: there's an orphaned "}: { adminKey: string }) {" around line 247
# We need to find the broken function and replace cleanly.

# Strategy: find "function OverviewTab" and find the NEXT "function " or "export default"
# then replace everything between with a clean version.

import re

start = content.find('function OverviewTab')
if start == -1:
    print('❌ OverviewTab not found — checking for orphan fragment')
    # The replacement may have left a fragment. Find the orphan.
    orphan = content.find('}: { adminKey: string }) {')
    if orphan != -1:
        # Walk back to find where the broken block starts
        # Find the previous "function " before the orphan
        prev_fn = content.rfind('function ', 0, orphan)
        print(f'Found orphan at {orphan}, previous function at {prev_fn}')
        start = prev_fn
    else:
        print('No orphan found either')
        exit(1)

# Find where the NEXT top-level function or component starts after our broken block
# Look for the next "\nfunction " or "\nexport default function"
next_fn = len(content)
for marker in ['\nfunction InvitationsTab', '\nfunction FeedbackTab', '\nfunction ContactsTab', '\nfunction CorrectionsTab', '\nfunction DecisionsTab', '\nfunction SettingsTab', '\nfunction SourcesTab', '\nexport default function']:
    idx = content.find(marker, start + 10)
    if idx != -1 and idx < next_fn:
        next_fn = idx

clean_overview = '''function OverviewTab({ adminKey }: { adminKey: string }) {
  const [stats, setStats] = useState<any>({});
  const [users, setUsers] = useState<any[]>([]);
  const [newPw, setNewPw] = useState('');

  useEffect(() => {
    fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'stats', adminKey }) })
      .then(r => r.json()).then(d => { setStats(d.stats || d || {}); setUsers(d.users || []); }).catch(() => {});
  }, [adminKey]);

  const changePassword = async () => {
    if (!newPw) return;
    await fetch('/api/admin', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'change_password', adminKey, newPassword: newPw }) });
    setNewPw('');
    alert('Password changed');
  };

  const Spark = ({ color }: { color: string }) => {
    const bars = [4, 7, 5, 10, 8, 14, 11];
    return (
      <div style={{ height: 16, display: 'flex', alignItems: 'flex-end', gap: 1.5, marginTop: 4 }}>
        {bars.map((h, i) => (
          <div key={i} style={{ width: 3, height: h, background: i >= bars.length - 3 ? color : '#e5eaea', borderRadius: 1 }} />
        ))}
      </div>
    );
  };

  const metrics = [
    { label: 'Users', value: stats.approved ?? users.length ?? 0, color: '#16a34a', spark: true, trend: '\\u2191' },
    { label: 'Scans', value: stats.total_scans ?? stats.scans ?? 0, color: '#2563eb', spark: true, trend: '' },
    { label: 'Avg Clarity', value: Number(stats.avg_clarity ?? 0.54).toFixed(2), color: '#d97706', spark: false, trend: '' },
    { label: 'Pending', value: stats.pending ?? 0, color: '#d97706', spark: false, trend: '' },
    { label: 'Feedback', value: stats.feedback ?? 0, color: '#7c3aed', spark: false, trend: '' },
    { label: 'Contacts', value: stats.contacts ?? 0, color: '#0d9488', spark: false, trend: '' },
  ];

  return (
    <div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 14, flexWrap: 'wrap' }}>
        {metrics.map(m => (
          <div key={m.label} style={{ flex: '1 1 110px', minWidth: 110, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '10px 12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 9, color: '#888', textTransform: 'uppercase', letterSpacing: '0.04em' }}>{m.label}</span>
              {m.trend && <span style={{ fontSize: 9, color: '#16a34a' }}>{m.trend}</span>}
            </div>
            <div style={{ fontSize: 20, fontWeight: 700, color: m.color }}>{m.value}</div>
            {m.spark && <Spark color={m.color} />}
          </div>
        ))}
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, overflow: 'hidden', marginBottom: 14 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr 70px', padding: '7px 14px', background: '#f8fafa', fontSize: 10, color: '#888', fontWeight: 600 }}>
          <span>User</span><span>Status</span><span>Scans</span><span>Joined</span><span></span>
        </div>
        {users.length === 0 && (<div style={{ padding: 20, textAlign: 'center', color: '#888', fontSize: 12 }}>No users yet</div>)}
        {users.map((u, i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr 70px', padding: '9px 14px', fontSize: 11, borderTop: '0.5px solid #f0f0ee', alignItems: 'center' }}>
            <span style={{ fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.email || u.user_email || '\\u2014'}</span>
            <span><span style={{ padding: '2px 7px', background: (u.status === 'approved' || u.active) ? '#f0fdf4' : '#fffbeb', color: (u.status === 'approved' || u.active) ? '#16a34a' : '#d97706', borderRadius: 3, fontSize: 9, fontWeight: 600 }}>{(u.status === 'approved' || u.active) ? 'Active' : (u.status || 'Pending')}</span></span>
            <span style={{ color: '#555' }}>{u.scans ?? u.scan_count ?? 0}</span>
            <span style={{ color: '#888' }}>{u.created_at ? new Date(u.created_at).toLocaleDateString('en', { month: 'short', day: 'numeric' }) : '\\u2014'}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              <span style={{ fontSize: 10, padding: '2px 6px', background: '#f0fdfa', color: '#0d9488', borderRadius: 3, cursor: 'pointer' }}>\\u2699</span>
              <span style={{ fontSize: 10, padding: '2px 6px', background: '#eff6ff', color: '#2563eb', borderRadius: 3, cursor: 'pointer' }}>\\u2709</span>
            </div>
          </div>
        ))}
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 14 }}>\\ud83d\\udd11</span>
          <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>Security</span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <input type="password" placeholder="New password" value={newPw} onChange={e => setNewPw(e.target.value)} style={{ padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 11, outline: 'none', width: 140 }} />
          <button onClick={changePassword} style={{ fontSize: 11, padding: '6px 14px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>Change password</button>
        </div>
      </div>
    </div>
  );
}

'''

content = content[:start] + clean_overview + content[next_fn+1:]
open('src/app/admin/page.tsx', 'w').write(content)
print('\u2705 OverviewTab fixed cleanly')
PYEOF

# Also fix duplicate import in beacon
python3 << 'PYEOF'
content = open('app/beacon/__init__.py').read()
# Remove duplicate "from app.scoring import compute_full_score"
lines = content.split('\n')
seen = False
out = []
for line in lines:
    if 'from app.scoring import compute_full_score' in line:
        if seen:
            continue  # skip duplicate
        seen = True
    out.append(line)
open('app/beacon/__init__.py', 'w').write('\n'.join(out))
print('\u2705 Removed duplicate scoring import in beacon')
PYEOF

echo ""
echo "Run: npm run build"
