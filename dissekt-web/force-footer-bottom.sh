#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# The issue: flex on body works ONLY if every page wraps content in <main> with flex:1
# AND no page sets its own height. Let's use a more bulletproof CSS approach.

# Add a wrapper-agnostic rule to globals.css
python3 << 'PYEOF'
content = open('src/app/globals.css').read()

# Remove old sticky footer block if present
import re
content = re.sub(r'/\* Sticky footer.*?footer \{ flex-shrink: 0; \}', '', content, flags=re.DOTALL)

# Add bulletproof version at the end
content += '''

/* ===== STICKY FOOTER (bulletproof) ===== */
html, body {
  height: 100%;
  margin: 0;
}
body {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
body > * {
  flex-shrink: 0;
}
main {
  flex: 1 0 auto;
}
footer {
  margin-top: auto;
  flex-shrink: 0;
}
'''
open('src/app/globals.css', 'w').write(content)
print('✅ globals.css: bulletproof sticky footer')
PYEOF

# Ensure EVERY main tag does NOT have minHeight and HAS flex
find src/app -name "page.tsx" -exec sed -i "s/minHeight: '100vh', //g; s/minHeight: '100vh'//g" {} \;

echo "✅ Done. Run: npm run build"
