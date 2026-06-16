#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# 1. handleScan must accept image param
content = content.replace(
    'const handleScan = async (content: string, modeArg: string) => {',
    'const handleScan = async (content: string, modeArg: string, image?: string) => {'
)

# 2. Skip the 10-char check when an image is present
content = content.replace(
    "if (!content || content.length < 10) { setError('Please enter at least 10 characters'); return; }",
    "if (!image && (!content || content.length < 10)) { setError('Please enter at least 10 characters, or attach an image'); return; }"
)

# 3. Include image in the POST body
content = content.replace(
    "body: JSON.stringify({ content, mode }),",
    "body: JSON.stringify({ content, mode, image }),"
)

open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ handleScan accepts + sends image, skips char-check when image present')
PYEOF

echo "Run: npm run build"
