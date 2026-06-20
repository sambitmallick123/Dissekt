#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Remove all "no signup" messaging from the landing page
set -e

python3 << 'PYEOF'
c = open('src/components/LandingPage.tsx').read()

# Line 15: "Beta · Free to use · No signup required" → "Beta · Free to use"
c = c.replace("Beta · Free to use · No signup required", "Beta · Free to use")

# Line 217: Free card subtitle "No signup" → "Start instantly"
c = c.replace(
    '<div style={{ fontSize: 11, color: \'#888\', marginBottom: 10 }}>No signup</div>',
    '<div style={{ fontSize: 11, color: \'#888\', marginBottom: 10 }}>Start instantly</div>'
)

# Line 236: "Paste any article, claim, or URL. Free, no signup." → "Paste any article, claim, or URL."
c = c.replace(
    "Paste any article, claim, or URL. Free, no signup.",
    "Paste any article, claim, or URL."
)

# Line 239: badge row — remove the "✓ No signup" span
c = c.replace(
    "<span>✓ Free</span><span>✓ No signup</span><span>✓ Research-backed</span>",
    "<span>✓ Free to start</span><span>✓ Research-backed</span>"
)

open('src/components/LandingPage.tsx','w').write(c)
print("✅ All 'no signup' messaging removed")
PYEOF

echo ""
echo "Verify gone:"
grep -ni 'no signup\|no sign up\|free, no' src/components/LandingPage.tsx || echo "  ✅ no 'no signup' references remain"

echo ""
echo "Run: rm -rf .next && npm run build"
