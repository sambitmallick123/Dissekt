#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Update privacy policy for accounts + per-member scan metadata + SerpAPI (GDPR)
set -e

python3 << 'PYEOF'
c = open('src/app/privacy/page.tsx').read()

c = c.replace('Last updated: June 9, 2026', 'Last updated: June 21, 2026')

old_usage = '''          <p><strong>Usage data:</strong> We track the number of scans per day for rate limiting. No personal identifying information is collected.</p>'''
new_usage = '''          <p><strong>Account data:</strong> If you create an account, we collect and store your email address, display name, and a securely hashed password (managed by our authentication provider, Supabase). You can use most of Dissekt without an account; an account is required only for member features such as Constellation, detailed analysis, and saved history.</p>
          <p><strong>Member scan history (metadata only):</strong> If you are signed in, we store <em>metadata</em> about each analysis you run — the entities and topics detected, the manipulation techniques identified, clarity and toxicity scores, the detected language, a reference ID linking to the full report, and a timestamp. We do <strong>not</strong> store the raw text you analyze as part of this history. This metadata powers personalized features like your Constellation knowledge graph and Topic Tracking. It is linked to your account.</p>
          <p><strong>Usage data:</strong> We track the number of scans per day per user for rate limiting.</p>'''
c = c.replace(old_usage, new_usage)

old_fc = '''          <p>• <strong>Google Fact Check API</strong> — for finding existing fact-checks. Only the claim text is sent.</p>'''
new_fc = '''          <p>• <strong>Google Fact Check API</strong> — for finding existing fact-checks. Only the claim text is sent.</p>
          <p>• <strong>SerpAPI</strong> — for the Keyword Topic feature, to find recent articles on a topic. Only your search keywords are sent (not personal data).</p>'''
c = c.replace(old_fc, new_fc)

old_ret = '''          <p>• Analysis reports are stored indefinitely to support shareable links.</p>
          <p>• Feedback and corrections are stored indefinitely to improve the system.</p>
          <p>• Chrome extension local storage can be cleared by the user at any time via Chrome settings.</p>'''
new_ret = '''          <p>• Analysis reports are stored indefinitely to support shareable links.</p>
          <p>• Feedback and corrections are stored indefinitely to improve the system.</p>
          <p>• Account data and member scan metadata are retained for as long as your account is active. When you request account deletion, your account data and associated scan metadata are removed.</p>
          <p>• Chrome extension local storage can be cleared by the user at any time via Chrome settings.</p>'''
c = c.replace(old_ret, new_ret)

old_rights = '''          <p>• Request deletion of your data by contacting us at sambitmallick123@gmail.com</p>
          <p>• Clear Chrome extension local storage at any time</p>
          <p>• Use the service without creating an account</p>
          <p>If you are located in the EU, you have additional rights under GDPR including the right to access, rectify, and erase your personal data.</p>'''
new_rights = '''          <p>• Request deletion of your account and all associated data (including your stored scan metadata) by contacting us at sambitmallick123@gmail.com</p>
          <p>• Request a copy of the personal data we hold about you</p>
          <p>• Clear Chrome extension local storage at any time</p>
          <p>• Use most of the service without creating an account</p>
          <p>If you are located in the EU/EEA, you have rights under the GDPR including the right to access (Art. 15), rectify (Art. 16), erase (Art. 17, the "right to be forgotten"), restrict processing (Art. 18), and data portability (Art. 20). As the data controller is based in Germany, you may also lodge a complaint with your local data protection authority.</p>'''
c = c.replace(old_rights, new_rights)

open('src/app/privacy/page.tsx','w').write(c)
print("✅ privacy policy updated")
PYEOF

echo ""
echo "Verify key additions:"
grep -n "Account data\|Member scan history\|SerpAPI\|Art. 17\|hashed password" src/app/privacy/page.tsx | head
