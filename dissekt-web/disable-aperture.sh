#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Replaces the Aperture/bookmarklet page with a "coming soon" state
set -e

# Back up the existing page so we can restore it later
if [ -f src/app/aperture/page.tsx ]; then
  cp src/app/aperture/page.tsx src/app/aperture/page.tsx.bak
  echo "✅ Backed up existing page → page.tsx.bak (restore later)"
fi

cat > src/app/aperture/page.tsx << 'PAGEEOF'
'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function AperturePage() {
  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 560, margin: '0 auto', padding: '80px 24px', textAlign: 'center' }}>
        <div style={{ fontSize: 44, marginBottom: 16 }}>🔖</div>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: '#1a1a1a', marginBottom: 10 }}>One-click analyze</h1>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '5px 14px', background: '#fffbeb', borderRadius: 20, fontSize: 12, color: '#d97706', fontWeight: 600, marginBottom: 18 }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: '#d97706' }} />
          In development · Coming soon
        </div>
        <p style={{ fontSize: 15, color: '#666', lineHeight: 1.7, marginBottom: 28 }}>
          We&apos;re building a browser bookmarklet that lets you analyze any article in one click — straight from your bookmarks bar. It&apos;s not quite ready yet.
        </p>
        <p style={{ fontSize: 13, color: '#888', lineHeight: 1.7, marginBottom: 28 }}>
          In the meantime, you can analyze any page by copying its URL and pasting it into the scanner.
        </p>
        <a href="/analyze" style={{ display: 'inline-block', padding: '12px 28px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 15, fontWeight: 600, textDecoration: 'none' }}>
          Go to scanner
        </a>
      </div>
      <SiteFooter />
    </main>
  );
}
PAGEEOF
echo "✅ Aperture page replaced with 'coming soon' state"

# Remove the Bookmarklet link from the WelcomeBar so users don't land on a dead feature
python3 << 'PYEOF'
import os
path = 'src/components/WelcomeBar.tsx'
if os.path.exists(path):
    c = open(path).read()
    orig = c
    # Remove the Bookmarklet link line
    import re
    c = re.sub(r'\s*<a href="/aperture"[^>]*>🔖 Bookmarklet</a>', '', c)
    if c != orig:
        open(path, 'w').write(c)
        print('✅ Removed Bookmarklet link from WelcomeBar')
    else:
        print('  (Bookmarklet link not found in WelcomeBar — may use different text)')
else:
    print('  WelcomeBar not found')
PYEOF

echo ""
echo "Run: rm -rf .next && npm run build"
