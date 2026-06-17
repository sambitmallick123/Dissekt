#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Gate Discord/GitHub in Help to invited users; add request-access note + contact section
# IMPORTANT: replace YOUR_EMAIL below before running
set -e

YOUR_EMAIL="sambitmallick123@gmail.com"

python3 << PYEOF
email = "$YOUR_EMAIL"
content = open('src/app/help/page.tsx').read()

# ── 1. Add isInvited state to the main HelpPage component ──
# The main component has: const [active, setActive] = useState('overview'); + a useEffect
if 'isInvited' not in content:
    content = content.replace(
        "  const [active, setActive] = useState('overview');",
        "  const [active, setActive] = useState('overview');\n  const [isInvited, setIsInvited] = useState(false);\n  useEffect(() => {\n    if (typeof window !== 'undefined') {\n      const invited = localStorage.getItem('dissekt_tier') === 'invited';\n      const admin = localStorage.getItem('dissekt_admin') === 'true';\n      setIsInvited(invited || admin);\n    }\n  }, []);",
        1
    )
    print('✅ Added isInvited state to Help page')

# ── 2. Replace the community section's Discord/GitHub block with a gated version ──
old_cards = '''            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, marginBottom: 16 }}>
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
            </div>'''

new_cards = '''            {isInvited ? (
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
            ) : (
              <div style={{ marginBottom: 16 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, marginBottom: 12 }}>
                  <div style={{ padding: 16, background: '#fafaf8', border: '0.5px dashed #d5dada', borderRadius: 10, opacity: 0.6, position: 'relative' }}>
                    <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 13 }}>🔒</span>
                    <div style={{ fontSize: 22, marginBottom: 4 }}>💬</div>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#888' }}>Discord</div>
                    <div style={{ fontSize: 12, color: '#aaa' }}>Members only</div>
                  </div>
                  <div style={{ padding: 16, background: '#fafaf8', border: '0.5px dashed #d5dada', borderRadius: 10, opacity: 0.6, position: 'relative' }}>
                    <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 13 }}>🔒</span>
                    <div style={{ fontSize: 22, marginBottom: 4 }}>⌨️</div>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#888' }}>GitHub</div>
                    <div style={{ fontSize: 12, color: '#aaa' }}>Members only</div>
                  </div>
                </div>
                <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 8, fontSize: 13, color: '#0d7a6e', lineHeight: 1.6 }}>
                  🔑 Community channels are for invited members. <a href="/invite" style={{ color: '#0d9488', fontWeight: 600 }}>Request an invite</a> to join the Discord and GitHub. Personal sign-up is coming soon.
                </div>
              </div>
            )}'''

content = content.replace(old_cards, new_cards)
print('✅ Discord/GitHub gated to invited users + request-access note')

# ── 3. Add a contact subsection at the end of the community section ──
old_end = '''            <Collapsible title="What can I do in the community?" subtitle="Discord & GitHub">
              <strong>Discord</strong> is for quick feedback, bug reports, and chatting with other users.<br />
              <strong>GitHub</strong> hosts issues and discussions for anything you want tracked to a resolution — feature requests, bugs, and how-to questions.
            </Collapsible>
          </div>'''

new_end = '''            <Collapsible title="What can I do in the community?" subtitle="Discord & GitHub">
              <strong>Discord</strong> is for quick feedback, bug reports, and chatting with other users.<br />
              <strong>GitHub</strong> hosts issues and discussions for anything you want tracked to a resolution — feature requests, bugs, and how-to questions.
            </Collapsible>
            <div style={{ marginTop: 16, padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 6 }}>📨 Have a question?</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.7 }}>
                For any question, bug, or feedback, use the <a href="/contact" style={{ color: '#0d9488', fontWeight: 600 }}>contact form</a> or email me directly at <a href={`mailto:${EMAIL_PLACEHOLDER}`} style={{ color: '#0d9488', fontWeight: 600 }}>{EMAIL_PLACEHOLDER}</a>. I read everything and usually reply within a day or two.
              </div>
            </div>
          </div>'''

new_end = new_end.replace('{EMAIL_PLACEHOLDER}', email).replace('${EMAIL_PLACEHOLDER}', email)
content = content.replace(old_end, new_end)
print('✅ Added contact subsection (form + email)')

open('src/app/help/page.tsx', 'w').write(content)
PYEOF

echo ""
echo "Verify:"
grep -n "isInvited\|Members only\|Request an invite\|contact form\|mailto" src/app/help/page.tsx | head

echo ""
if grep -q "REPLACE_ME@example.com" src/app/help/page.tsx; then
  echo "⚠️ EMAIL NOT SET — edit YOUR_EMAIL at the top of this script and re-run"
else
  echo "✅ Email wired in"
fi
echo ""
echo "Run: rm -rf .next && npm run build"
