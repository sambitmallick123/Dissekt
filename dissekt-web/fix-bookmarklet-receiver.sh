#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# 1. Import useSearchParams (Next.js requires it wrapped in Suspense, but for client component this works)
if 'useSearchParams' not in content:
    content = content.replace(
        "import { useState, useEffect } from 'react';",
        "import { useState, useEffect } from 'react';\nimport { useSearchParams } from 'next/navigation';"
    )

# 2. Add the searchParams hook + a ref to avoid double-fire
if 'const searchParams = useSearchParams' not in content:
    content = content.replace(
        "const { lockedFeature, checkFeature, closePopup } = useFeatureGate();",
        "const { lockedFeature, checkFeature, closePopup } = useFeatureGate();\n  const searchParams = useSearchParams();\n  const [urlHandled, setUrlHandled] = useState(false);"
    )

# 3. Add an effect that reads ?url= and pre-fills + scans
# Insert after the mounted/config useEffect closes (after the clearInterval return)
hook = '''
  // Bookmarklet / shared-link support: read ?url= and auto-fill the scanner
  useEffect(() => {
    if (!mounted || urlHandled) return;
    const incoming = searchParams.get('url') || searchParams.get('content');
    if (incoming) {
      setUrlHandled(true);
      setInputContent(incoming);
      // Auto-run a brief scan if we have a usable value
      if (incoming.length >= 10) {
        handleScan(incoming, 'brief');
      }
    }
  }, [mounted, searchParams, urlHandled]);
'''

# Insert right after the first useEffect's closing "}, []);"
marker = "return () => clearInterval(t);\n  }, []);"
if marker in content:
    content = content.replace(marker, marker + "\n" + hook)
    print('✅ Added ?url= receiver effect')
else:
    print('⚠️ Could not find insertion point — paste the useEffect block')

open('src/app/analyze/page.tsx', 'w').write(content)
PYEOF

python3 -c "print('checking...'); open('src/app/analyze/page.tsx').read()" && echo "✅ file written"
echo ""
echo "NOTE: Next.js may require Suspense around useSearchParams during build."
echo "If build complains, the next script wraps it."
echo ""
echo "Run: npm run build"
