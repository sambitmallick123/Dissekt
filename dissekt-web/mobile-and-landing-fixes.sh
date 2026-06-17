#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

# ═══ FIX 1: Global overflow-x guard + Help sidebar hide on mobile ═══
python3 << 'PYEOF'
css = open('src/app/globals.css').read()

# Add global overflow-x guard if not present
if 'overflow-x: hidden' not in css:
    css = css.replace(
        'html, body { height: 100%; margin: 0; }',
        '''html, body { height: 100%; margin: 0; overflow-x: hidden; max-width: 100vw; }
* { box-sizing: border-box; }'''
    )
    print('✅ Global overflow-x guard added')

# Hide the help sidebar on mobile + make content full width
if '.help-nav' not in css:
    css += '''

/* Help page: hide sidebar nav on mobile, content goes full width */
@media (max-width: 768px) {
  .help-nav { display: none !important; }
  .help-container { flex-direction: column !important; gap: 0 !important; padding-left: 16px !important; padding-right: 16px !important; }
}
'''
    print('✅ Help sidebar hidden on mobile')

open('src/app/globals.css', 'w').write(css)
PYEOF

# Add help-container class to the Help page flex wrapper
python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()
content = content.replace(
    "<div style={{ maxWidth: 1000, margin: '0 auto', padding: '28px 16px', display: 'flex', gap: 28 }}>",
    "<div className=\"help-container\" style={{ maxWidth: 1000, margin: '0 auto', padding: '28px 16px', display: 'flex', gap: 28 }}>"
)
open('src/app/help/page.tsx', 'w').write(content)
print('✅ help-container class added to Help layout')
PYEOF

# ═══ FIX 2: Add Community & Access section to Help ═══
python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

# Add to SECTIONS nav array (before references)
content = content.replace(
    "  { id: 'references', label: 'References', icon: '📚' },",
    "  { id: 'community', label: 'Community & Access', icon: '💬' },\n  { id: 'references', label: 'References', icon: '📚' },"
)

# Add the section content before the references div
community_section = '''          {/* COMMUNITY & ACCESS */}
          <div id="community" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="💬" title="Community & access" sub="Join the conversation and get full access." />
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, marginBottom: 16 }}>
              <a href="https://discord.gg/Bkv4zpmdJD" target="_blank" rel="noopener" style={{ textDecoration: 'none', padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, display: 'block' }}>
                <div style={{ fontSize: 22, marginBottom: 4 }}>💬</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#5865F2' }}>Discord</div>
                <div style={{ fontSize: 12, color: '#888' }}>Report bugs, share ideas, follow updates</div>
              </a>
              <a href="https://github.com/sambitmallick123/Dissekt" target="_blank" rel="noopener" style={{ textDecoration: 'none', padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, display: 'block' }}>
                <div style={{ fontSize: 22, marginBottom: 4 }}>⌨️</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>GitHub</div>
                <div style={{ fontSize: 12, color: '#888' }}>Open issues, discussions, contribute</div>
              </a>
            </div>
            <Collapsible title="How does invite access work?" subtitle="Getting full features">
              Dissekt is in beta. Anyone can run single scans for free. <strong>Invited members</strong> get higher limits, all features (Bulk, Compare, Dashboard, API), and access to the community channels. Request an invite from the landing page, or ask in our Discord. Invite access currently runs for 6 months.
            </Collapsible>
            <Collapsible title="What can I do in the community?" subtitle="Discord & GitHub">
              <strong>Discord</strong> is for quick feedback, bug reports, and chatting with other users.<br />
              <strong>GitHub</strong> hosts issues and discussions for anything you want tracked to a resolution — feature requests, bugs, and how-to questions.
            </Collapsible>
          </div>

'''

content = content.replace(
    '          <div id="references" style={{ marginBottom: 40, scrollMarginTop: 80 }}>',
    community_section + '          <div id="references" style={{ marginBottom: 40, scrollMarginTop: 80 }}>',
    1
)
open('src/app/help/page.tsx', 'w').write(content)
print('✅ Community & Access section added to Help')
PYEOF

# ═══ FIX 3: Remove "4 seconds" claims from landing ═══
python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Line 83: "all in parallel, under 4 seconds." → "all in parallel."
content = content.replace(
    'Technique detection, fact-checker cross-references, source credibility, toxicity, political context — all in parallel, under 4 seconds.',
    'Technique detection, fact-checker cross-references, source credibility, toxicity, political context — all in parallel.'
)

# Line 238: remove the "✓ Under 4 seconds" span
content = content.replace(
    "<span>✓ Free</span><span>✓ No signup</span><span>✓ Under 4 seconds</span><span>✓ Research-backed</span>",
    "<span>✓ Free</span><span>✓ No signup</span><span>✓ Research-backed</span>"
)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Removed "4 seconds" claims (both spots)')
PYEOF

echo ""
echo "Verify no '4 second' claims remain:"
grep -n "4 second\|Under 4\|under 4" src/components/LandingPage.tsx || echo "  ✅ none"
echo ""
echo "Next: tier card script (separate, needs the tier section layout)"
