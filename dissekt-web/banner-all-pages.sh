#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# Make WelcomeBar self-aware: hide on admin + landing, show everywhere else when logged in
cat > src/components/WelcomeBar.tsx << 'WBEOF'
'use client';
import { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';

// Pages where the banner should NOT appear
const EXCLUDED = ['/', '/admin', '/invite', '/signup'];

export default function WelcomeBar() {
  const [name, setName] = useState('');
  const [tier, setTier] = useState('free');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
    setTier(localStorage.getItem('dissekt_tier') || 'free');
    const expiry = localStorage.getItem('dissekt_access_expires');
    if (expiry) {
      const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
      if (days > 0) setExpiryText(`${days}d remaining`);
    }
    // One-time cache migration
    try {
      if (localStorage.getItem('dissekt_scan_schema') !== 'v2') {
        localStorage.removeItem('dissekt_scans');
        localStorage.removeItem('dissekt_history');
        localStorage.removeItem('dissekt_recent');
        localStorage.setItem('dissekt_scan_schema', 'v2');
      }
    } catch {}
  }, []);

  if (!mounted || tier !== 'invited') return null;
  if (EXCLUDED.includes(pathname)) return null;

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <div style={{ background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', color: 'white' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10 }}>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>{greeting}{name ? `, ${name}` : ''}</div>
          <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>See how information is constructed{expiryText ? ` · ${expiryText}` : ''}</div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <a href="/dashboard" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>📊 My insights</a>
          <a href="/aperture" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔖 Bookmarklet</a>
          <a href="/dashboard" style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.15)', borderRadius: 6, fontSize: 11, color: 'white', textDecoration: 'none', fontWeight: 500 }}>🔑 API keys</a>
        </div>
      </div>
    </div>
  );
}
WBEOF
echo "✅ WelcomeBar is now path-aware (auto-hides on landing/admin/invite)"

# Put WelcomeBar in SiteHeader so it renders on EVERY page that uses the header
python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

# Import WelcomeBar
if "import WelcomeBar" not in content:
    # add import after the first import line
    lines = content.split('\n')
    for i, l in enumerate(lines):
        if l.startswith('import ') or l.startswith("'use client'"):
            continue
        else:
            # insert after last leading import
            break
    # simpler: add right after 'use client'
    content = content.replace("'use client';", "'use client';\nimport WelcomeBar from '@/components/WelcomeBar';", 1)

# Render <WelcomeBar /> right after the closing </nav> so it sits under the header bar
# Find the last </> before the component returns — inject after nav closes
# The header returns a fragment; we append WelcomeBar after the nav block.
# Easiest: wrap — find "</nav>" and add WelcomeBar after it
if "<WelcomeBar />" not in content:
    if "</nav>" in content:
        content = content.replace("</nav>", "</nav>\n      <WelcomeBar />", 1)
        print("✅ WelcomeBar injected after </nav> in SiteHeader")
    else:
        print("⚠️ no </nav> found — paste SiteHeader and I'll wire manually")

open('src/components/SiteHeader.tsx', 'w').write(content)
PYEOF

# Remove standalone <WelcomeBar /> from individual pages to avoid duplicates
python3 << 'PYEOF'
import glob, re
removed = 0
for path in glob.glob('src/app/**/page.tsx', recursive=True):
    try:
        c = open(path).read()
    except: continue
    if '<WelcomeBar />' in c and 'SiteHeader' in c:
        # remove the standalone WelcomeBar line (header now renders it)
        new = re.sub(r'\n\s*<WelcomeBar />', '', c)
        # also remove now-unused import
        new = new.replace("import WelcomeBar from '@/components/WelcomeBar';\n", "")
        if new != c:
            open(path, 'w').write(new)
            removed += 1
print(f"✅ Removed duplicate WelcomeBar from {removed} pages (header handles it now)")
PYEOF

echo ""
echo "Run: rm -rf .next && npm run dev"
