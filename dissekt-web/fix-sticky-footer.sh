#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Make sticky footer work on ALL pages regardless of whether they use <main> or <div>
set -e

python3 << 'PYEOF'
css = open('src/app/globals.css').read()

# The issue: only `main { flex: 1 0 auto }` grows. Pages using <div> wrappers don't.
# Fix: make the body's content area (everything that isn't header/footer) grow.
# Robust approach: target the direct child of body that comes before footer.

# Replace the main-only rule with a more general one
old = '''main { flex: 1 0 auto; }
footer { flex-shrink: 0; margin-top: auto; }'''

new = '''/* Sticky footer: the content area grows to fill, pushing footer to the bottom */
main { flex: 1 0 auto; }
/* Fallback for pages that wrap content in a top-level div instead of <main>:
   the body's last child before footer should grow. We give the footer margin-top:auto
   which alone pushes it down in a flex column even if siblings don't grow. */
footer { flex-shrink: 0; margin-top: auto; }
/* Ensure the page content wrapper (main OR the div before footer) fills space */
body > main, body > div:not(:last-child) { flex: 1 0 auto; }'''

if old in css:
    css = css.replace(old, new)
    print('✅ Sticky footer rule generalized (works for <main> and <div> wrappers)')
else:
    print('⚠️ footer rule not matched as expected — appending generalized rule')
    css += '''

/* Sticky footer — generalized for all page wrappers */
body > main, body > div:not(:last-child) { flex: 1 0 auto; }
footer { flex-shrink: 0; margin-top: auto; }
'''

open('src/app/globals.css', 'w').write(css)
PYEOF

echo ""
echo "Verify the rules:"
grep -n "flex: 1 0 auto\|margin-top: auto\|body > " src/app/globals.css

echo ""
echo "Run: rm -rf .next && npm run build"
