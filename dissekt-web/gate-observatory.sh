#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Member-gate the Observatory (topic tracking) page via Supabase session
set -e

python3 << 'PYEOF'
c = open('src/app/observatory/page.tsx').read()

# 1. Add imports (useEffect + session helpers)
if 'refreshAuth' not in c:
    c = c.replace(
        "import { useState } from 'react';",
        "import { useState, useEffect } from 'react';\nimport { refreshAuth, isMember } from '@/lib/tier';"
    )
    print("✅ imports added")

# 2. Add gate state + warming in the component body (right after the existing useState lines)
anchor = "  const [loading, setLoading] = useState(false);"
gate_state = anchor + '''
  const [mounted, setMounted] = useState(false);
  const [member, setMember] = useState(false);

  useEffect(() => {
    refreshAuth().then(() => { setMember(isMember()); setMounted(true); });
  }, []);'''
c = c.replace(anchor, gate_state)
print("✅ gate state + session warming added")

# 3. Insert the gate screen before the main return. Find "  return (" + the main <main>
# We gate by inserting an early-return right before the existing return statement.
gate_screen = '''  if (!mounted) return null;

  if (!member) {
    return (
      <main style={{ flex: 1, background: '#fafaf8' }}>
        <SiteHeader />
        <div style={{ maxWidth: 440, margin: '80px auto', padding: '0 16px', textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a', marginBottom: 8 }}>Observatory requires an account</div>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 20, lineHeight: 1.6 }}>Topic tracking shows how a subject has been analyzed over time. Sign up free to explore it.</div>
          <a href="/signup" style={{ display: 'inline-block', padding: '10px 24px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Sign up free</a>
          <div style={{ marginTop: 12, fontSize: 12, color: '#aaa' }}>Already have an account? <a href="/login" style={{ color: '#0d9488', textDecoration: 'none' }}>Sign in</a></div>
        </div>
        <SiteFooter />
      </main>
    );
  }

  return ('''

# Replace the FIRST "  return (" (the main component return) with the gate + return
# The component's main return is the one rendering <main ...><SiteHeader />
import re
# Find "  return (\n    <main" specifically to avoid matching inner returns
m = re.search(r"  return \(\s*\n\s*<main", c)
if m:
    # Replace just the "  return (" part at that location
    start = m.start()
    c = c[:start] + gate_screen + c[start + len("  return ("):]
    print("✅ gate screen inserted before main return")
else:
    print("⚠️ main return not matched — needs manual placement")

open('src/app/observatory/page.tsx','w').write(c)
PYEOF

echo ""
echo "Verify gate present:"
grep -n "refreshAuth\|isMember\|requires an account\|if (!member)" src/app/observatory/page.tsx | head

echo ""
echo "Parses check:"
node -e "require('fs').readFileSync('src/app/observatory/page.tsx','utf8')" && echo "  readable"

echo ""
echo "Run: rm -rf .next && npm run build"
