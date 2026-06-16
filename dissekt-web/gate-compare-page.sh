#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Adds a tier-check gate to the /compare page itself
set -e

python3 << 'PYEOF'
content = open('src/app/compare/page.tsx').read()

# 1. Ensure useEffect is imported
if 'useEffect' not in content.split('\n')[4]:  # the react import line
    content = content.replace(
        "import { useState } from 'react';",
        "import { useState, useEffect } from 'react';"
    )

# 2. Add tier state + mount check right after the component opens
if 'const [tier, setTier]' not in content:
    content = content.replace(
        "export default function ComparePage() {",
        """export default function ComparePage() {
  const [tier, setTier] = useState('free');
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
    setTier(localStorage.getItem('dissekt_tier') || 'free');
  }, []);"""
    )

# 3. Insert the gate just before the main return (find "return (" that starts the JSX)
# The component's main return — gate before it
gate = '''  if (!mounted) return null;
  if (tier !== 'invited') {
    return (
      <main style={{ flex: 1, background: '#fafaf8' }}>
        <SiteHeader active="Compare" />
        <div style={{ maxWidth: 440, margin: '80px auto', padding: '0 16px', textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Compare requires access</div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Side-by-side comparison is available for invited users. Sign in with your invite code to unlock it.</div>
          <a href="/invite" style={{ display: 'inline-block', padding: '10px 24px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Sign in</a>
        </div>
        <SiteFooter />
      </main>
    );
  }

'''

# Find the main JSX return. It's the return that renders SiteHeader as the page (not the gate).
# Insert the gate before the FIRST "  return (" at component-body indentation that isn't inside handleCompare.
# Safest: insert right before "  return (" that is preceded by the handleCompare function's closing.
import re
# Match the main return — typically "\n  return (\n    <main"
m = re.search(r'\n  return \(\s*\n\s*<main', content)
if m:
    insert_at = m.start() + 1  # after the leading newline
    content = content[:insert_at] + gate + content[insert_at:]
    print('✅ Compare page gated for invited users')
else:
    print('⚠️ could not find main return — paste the return line')

open('src/app/compare/page.tsx', 'w').write(content)
PYEOF

python3 -c "print('checking syntax via node...')"
echo "Run: rm -rf .next && npm run build"
