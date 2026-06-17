#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Surgically remove the corrupted email-spam block and rebuild the contact section.
set -e

python3 << 'PYEOF'
lines = open('src/app/help/page.tsx').read().split('\n')

# Find the corruption boundaries:
# START: the "How does invite access work?" Collapsible closes cleanly, THEN corruption begins.
# We keep up through that </Collapsible>, then drop everything until the references div.
start_keep = None  # last good line index (the </Collapsible> after invite-access)
end_resume = None  # the references div line index

for i, ln in enumerate(lines):
    if 'Invite access currently runs for 6 months.' in ln:
        # the </Collapsible> is the next line
        start_keep = i + 1  # this line is "</Collapsible>"
    if 'id="references"' in ln:
        end_resume = i
        break

if start_keep is None or end_resume is None:
    print(f'⚠️ boundaries not found: start_keep={start_keep}, end_resume={end_resume}')
else:
    # The clean block to insert between the kept </Collapsible> and the references div
    clean = '''            <Collapsible title="What can I do in the community?" subtitle="Discord & GitHub">
              <strong>Discord</strong> is for quick feedback, bug reports, and chatting with other users.<br />
              <strong>GitHub</strong> hosts issues and discussions for anything you want tracked to a resolution — feature requests, bugs, and how-to questions.
            </Collapsible>
            <div style={{ marginTop: 16, padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 6 }}>📨 Have a question?</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.7 }}>
                For any question, bug, or feedback, use the <a href="/contact" style={{ color: '#0d9488', fontWeight: 600 }}>contact form</a> or email me directly at <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#0d9488', fontWeight: 600 }}>sambitmallick123@gmail.com</a>. I read everything and usually reply within a day or two.
              </div>
            </div>
          </div>

'''
    # Reconstruct: lines[0 .. start_keep] (inclusive of </Collapsible>) + clean + lines[end_resume ..]
    # start_keep points at the line with "Invite access...6 months." — the NEXT line is </Collapsible>
    # We want to keep through that </Collapsible>. Find it:
    close_idx = start_keep
    # start_keep is the index AFTER the text line; verify it's the </Collapsible>
    while close_idx < len(lines) and '</Collapsible>' not in lines[close_idx]:
        close_idx += 1
    # keep through close_idx
    new_lines = lines[:close_idx+1] + clean.split('\n') + lines[end_resume:]
    open('src/app/help/page.tsx', 'w').write('\n'.join(new_lines))
    print(f'✅ Excised corruption (kept through line {close_idx+1}, resumed at references)')
PYEOF

echo ""
echo "Verify — no more email spam, contact section present:"
grep -c "sambitmallick123@gmail.com" src/app/help/page.tsx
echo "(should be 2: the mailto href + the visible text)"
echo ""
grep -n "Have a question\|contact form\|id=\"references\"" src/app/help/page.tsx | head

echo ""
echo "Run: rm -rf .next && npm run build"
