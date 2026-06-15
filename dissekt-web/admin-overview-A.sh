#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Replaces the admin OverviewTab with Option A (metric strip + sparklines + table)
set -e

python3 << 'PYEOF'
import re
content = open('src/app/admin/page.tsx').read()

# Find the OverviewTab function and replace it entirely
# First, locate it
start = content.find('function OverviewTab')
if start == -1:
    print('❌ OverviewTab not found')
    exit(1)

# Find the matching closing brace by counting braces
i = content.find('{', start)
depth = 0
end = i
for j in range(i, len(content)):
    if content[j] == '{': depth += 1
    elif content[j] == '}': depth -= 1
    if depth == 0:
        end = j + 1
        break

new_overview = '''function OverviewTab({ adminKey }: { adminKey: string }) {
  const [stats, setStats] = useState<any>({});
  const [users, setUsers] = useState<any[]>([]);
  const [newPw, setNewPw] = useState('');
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

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

  // Mini sparkline component
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
    { label: 'Users', value: stats.approved ?? users.length ?? 0, color: '#16a34a', spark: true, trend: '↑' },
    { label: 'Scans', value: stats.total_scans ?? 0, color: '#2563eb', spark: true },
    { label: 'Avg Clarity', value: (stats.avg_clarity ?? 0.54).toFixed(2), color: '#d97706', spark: false },
    { label: 'Pending', value: stats.pending ?? 0, color: '#d97706', spark: false },
    { label: 'Feedback', value: stats.feedback ?? 0, color: '#7c3aed', spark: false },
    { label: 'Contacts', value: stats.contacts ?? 0, color: '#0d9488', spark: false },
  ];

  return (
    <div>
      {/* Metric strip with sparklines */}
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

      {/* User table */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, overflow: 'hidden', marginBottom: 14 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr 70px', padding: '7px 14px', background: '#f8fafa', fontSize: 10, color: '#888', fontWeight: 600 }}>
          <span>User</span><span>Status</span><span>Scans</span><span>Joined</span><span></span>
        </div>
        {users.length === 0 && (
          <div style={{ padding: 20, textAlign: 'center', color: '#888', fontSize: 12 }}>No users yet</div>
        )}
        {users.map((u, i) => (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr 70px', padding: '9px 14px', fontSize: 11, borderTop: '0.5px solid #f0f0ee', alignItems: 'center' }}>
            <span style={{ fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.email || u.user_email || '—'}</span>
            <span><span style={{ padding: '2px 7px', background: u.status === 'approved' || u.active ? '#f0fdf4' : '#fffbeb', color: u.status === 'approved' || u.active ? '#16a34a' : '#d97706', borderRadius: 3, fontSize: 9, fontWeight: 600 }}>{u.status === 'approved' || u.active ? 'Active' : (u.status || 'Pending')}</span></span>
            <span style={{ color: '#555' }}>{u.scans ?? u.scan_count ?? 0}</span>
            <span style={{ color: '#888' }}>{u.created_at ? new Date(u.created_at).toLocaleDateString('en', { month: 'short', day: 'numeric' }) : '—'}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              <span style={{ fontSize: 10, padding: '2px 6px', background: '#f0fdfa', color: '#0d9488', borderRadius: 3, cursor: 'pointer' }} title="Access">⚙</span>
              <span style={{ fontSize: 10, padding: '2px 6px', background: '#eff6ff', color: '#2563eb', borderRadius: 3, cursor: 'pointer' }} title="Email">✉</span>
            </div>
          </div>
        ))}
      </div>

      {/* Security */}
      <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 14 }}>🔑</span>
          <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>Security</span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <input type="password" placeholder="New password" value={newPw} onChange={e => setNewPw(e.target.value)} style={{ padding: '6px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 11, outline: 'none', width: 140 }} />
          <button onClick={changePassword} style={{ fontSize: 11, padding: '6px 14px', background: '#f0fdfa', color: '#0d9488', border: 'none', borderRadius: 5, cursor: 'pointer', fontWeight: 600 }}>Change password</button>
        </div>
      </div>
    </div>
  );
}'''

content = content[:start] + new_overview + content[end:]
open('src/app/admin/page.tsx', 'w').write(content)
print('✅ OverviewTab replaced with Option A')
PYEOF

echo ""
echo "Run: npm run build"
