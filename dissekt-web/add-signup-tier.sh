#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Add a disabled "Sign up / Sign in — Coming soon" tier card to the landing page
set -e

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# 1. Change grid from 2 to 3 columns (responsive: stacks on mobile via auto-fit)
content = content.replace(
    "<div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>",
    "<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: 12 }}>"
)

# Also widen the container so 3 cards fit comfortably
content = content.replace(
    "<div style={{ maxWidth: 600, margin: '0 auto' }}>\n          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 20px', textAlign: 'center' }}>Start free. Go deeper with access.</h2>",
    "<div style={{ maxWidth: 820, margin: '0 auto' }}>\n          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 20px', textAlign: 'center' }}>Start free. Go deeper with access.</h2>"
)

# 2. Add the disabled Sign up / Sign in card AFTER the Invited card
invited_card_end = '''              <a href="/invite" style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Request access</a>
            </div>'''

signup_card = invited_card_end + '''
            <div style={{ padding: 20, background: '#fafaf8', border: '0.5px dashed #d5dada', borderRadius: 10, opacity: 0.75, position: 'relative' }}>
              <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 9, fontWeight: 600, color: '#888', background: '#f0f0ee', padding: '2px 8px', borderRadius: 10 }}>COMING SOON</span>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#888' }}>🔐 Sign up / Sign in</div>
              <div style={{ fontSize: 11, color: '#aaa', marginBottom: 10 }}>Personal account</div>
              <div style={{ fontSize: 12, color: '#999', lineHeight: 2 }}>Save your history<br />Sync across devices<br />Custom preferences</div>
              <div style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#f0f0ee', color: '#aaa', borderRadius: 6, fontSize: 13, cursor: 'not-allowed' }}>In development</div>
            </div>'''

content = content.replace(invited_card_end, signup_card)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Added disabled "Sign up / Sign in — Coming soon" tier card')
PYEOF

echo ""
echo "Verify:"
grep -n "Coming soon\|COMING SOON\|Sign up / Sign in\|In development" src/components/LandingPage.tsx

echo ""
echo "Run: rm -rf .next && npm run build"
