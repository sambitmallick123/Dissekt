#!/bin/bash
# Dissekt — Positioning Changes
# 1. Rename "fact-checks" → "cross-references" across UI
# 2. API documentation page at /docs
# 3. Organization-focused section on landing page
# 4. Update help page messaging
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Rename "fact-checks" → "cross-references" in UI
# ============================================

python3 << 'PYEOF'
import glob

renames = {
    'Trace — fact-checks': 'Trace — cross-references',
    'Fact-checks': 'Cross-references',
    'fact-checks': 'cross-references',
    'Fact-check': 'Cross-reference',
    'FACT-CHECKS': 'CROSS-REFERENCES',
    'No sources found': 'No cross-references found',
}

# Files to update
files = [
    'src/components/TraceCard.tsx',
    'src/components/ThreatScore.tsx',
    'src/components/AnalysisResult.tsx',
    'src/app/help/page.tsx',
]

for filepath in files:
    try:
        content = open(filepath).read()
        changed = False
        for old, new in renames.items():
            if old in content:
                content = content.replace(old, new)
                changed = True
        if changed:
            open(filepath, 'w').write(content)
            print(f'✅ {filepath}: renamed')
        else:
            print(f'  OK {filepath}: no changes needed')
    except FileNotFoundError:
        print(f'  ⚠️ {filepath}: not found')

# Also rename in the backend Telegram bot
try:
    content = open('../app/telegram_bot/__init__.py').read()
    content = content.replace('Fact-checks', 'Cross-references')
    content = content.replace('fact-checks', 'cross-references')
    open('../app/telegram_bot/__init__.py', 'w').write(content)
    print('✅ Telegram bot: renamed')
except: pass

# Chrome extension
try:
    content = open('../dissekt-extension/content.js').read()
    content = content.replace('Fact-checks', 'Cross-references')
    content = content.replace('fact-checks', 'cross-references')
    open('../dissekt-extension/content.js', 'w').write(content)
    print('✅ Chrome extension: renamed')
except: pass

print('✅ Rename complete')
PYEOF

# ============================================
# 2. API Documentation Page
# ============================================

mkdir -p src/app/docs

cat > src/app/docs/page.tsx << 'DOCSEOF'
'use client';
import { useState } from 'react';

export default function DocsPage() {
  const [tab, setTab] = useState<'overview' | 'scan' | 'compare' | 'radar'>('overview');
  const apiUrl = 'https://dissekt-api.up.railway.app';

  const codeStyle: React.CSSProperties = {
    background: '#1a1a1a', color: '#e5e5e5', padding: 16, borderRadius: 10,
    fontSize: 12, lineHeight: 1.7, overflow: 'auto', fontFamily: 'monospace',
  };
  const keywordStyle: React.CSSProperties = { color: '#7c3aed' };
  const stringStyle: React.CSSProperties = { color: '#22c55e' };
  const commentStyle: React.CSSProperties = { color: '#666' };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
            <span style={{ fontSize: 13, color: '#888' }}>API Docs</span>
          </a>
          <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>← Back</a>
        </div>
      </nav>

      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Dissekt API</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 6 }}>Interpretation infrastructure for information systems. Integrate manipulation detection into any platform.</p>
        <p style={{ fontSize: 12, color: '#aaa', marginBottom: 24 }}>Base URL: <code style={{ background: '#f0f0ee', padding: '2px 6px', borderRadius: 4 }}>{apiUrl}</code></p>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 20, borderBottom: '1px solid #e5e5e5', paddingBottom: 0 }}>
          {(['overview', 'scan', 'compare', 'radar'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)}
              style={{ padding: '8px 16px', fontSize: 13, fontWeight: 500, border: 'none', cursor: 'pointer', background: 'none', color: tab === t ? '#7c3aed' : '#888', borderBottom: tab === t ? '2px solid #7c3aed' : '2px solid transparent', marginBottom: -1 }}>
              {t === 'overview' ? 'Overview' : t === 'scan' ? 'POST /scan' : t === 'compare' ? 'POST /compare' : 'GET /radar'}
            </button>
          ))}
        </div>

        {tab === 'overview' && (
          <div>
            <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>What Dissekt analyzes</h2>
            <p style={{ fontSize: 13, color: '#555', lineHeight: 1.7, marginBottom: 16 }}>
              Send any text, URL, or claim. Dissekt returns a structured analysis with manipulation techniques, cross-references from 100+ fact-checking organizations, source credibility scores, extracted claims, political context, and coordination signals.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 24 }}>
              {[
                { icon: '👁', name: 'Prism', desc: '20 manipulation techniques with confidence scores' },
                { icon: '🌐', name: 'Trace', desc: 'Cross-references from 100+ fact-checking orgs' },
                { icon: '📊', name: 'Signal', desc: 'Toxicity, sentiment, source bias from 231 sources' },
                { icon: '🔒', name: 'Anchor', desc: 'SHA-256 hash + blockchain timestamp' },
                { icon: '🏛', name: 'Compass', desc: 'Political accountability (India, more coming)' },
                { icon: '📡', name: 'Pulse', desc: 'Coordination detection signals' },
                { icon: '📋', name: 'Claims', desc: 'Extracted verifiable claims with types' },
                { icon: '🔍', name: 'Similar', desc: 'Past analyses from knowledge graph' },
              ].map((e, i) => (
                <div key={i} style={{ display: 'flex', gap: 10, padding: '10px 12px', border: '1px solid #e5e5e5', borderRadius: 8, background: '#fff' }}>
                  <span style={{ fontSize: 18 }}>{e.icon}</span>
                  <div><div style={{ fontSize: 13, fontWeight: 600 }}>{e.name}</div><div style={{ fontSize: 11, color: '#888' }}>{e.desc}</div></div>
                </div>
              ))}
            </div>

            <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>Authentication</h2>
            <p style={{ fontSize: 13, color: '#555', lineHeight: 1.7, marginBottom: 8 }}>
              The API is currently open during beta. API key authentication coming soon.
            </p>
            <div style={codeStyle}>
              <span style={commentStyle}># No auth required during beta</span><br/>
              curl -X POST {apiUrl}/api/scan \<br/>
              {'  '}-H "Content-Type: application/json" \<br/>
              {'  '}-d '{`{"content": "your text here", "mode": "brief"}`}'
            </div>

            <h2 style={{ fontSize: 18, fontWeight: 600, marginTop: 24, marginBottom: 12 }}>Rate limits</h2>
            <p style={{ fontSize: 13, color: '#555', lineHeight: 1.7 }}>
              50 requests/day per IP during beta. Contact us for higher limits.
            </p>
          </div>
        )}

        {tab === 'scan' && (
          <div>
            <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 4 }}>POST /api/scan</h2>
            <p style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>Analyze any text or URL for manipulation techniques.</p>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Request</h3>
            <div style={codeStyle}>
              <span style={commentStyle}>POST /api/scan</span><br/>
              <span style={commentStyle}>Content-Type: application/json</span><br/><br/>
              {'{'}<br/>
              {'  '}<span style={keywordStyle}>"content"</span>: <span style={stringStyle}>"COVID vaccines contain microchips"</span>,<br/>
              {'  '}<span style={keywordStyle}>"mode"</span>: <span style={stringStyle}>"brief"</span> <span style={commentStyle}>// "brief" or "detailed"</span><br/>
              {'}'}
            </div>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginTop: 16, marginBottom: 8 }}>Response</h3>
            <div style={codeStyle}>
              {'{'}<br/>
              {'  '}<span style={keywordStyle}>"id"</span>: <span style={stringStyle}>"a1b2c3d4"</span>,<br/>
              {'  '}<span style={keywordStyle}>"prism"</span>: {'{'}<br/>
              {'    '}<span style={keywordStyle}>"techniques"</span>: [{'{'}<br/>
              {'      '}<span style={keywordStyle}>"name"</span>: <span style={stringStyle}>"loaded_language"</span>,<br/>
              {'      '}<span style={keywordStyle}>"confidence"</span>: 0.9,<br/>
              {'      '}<span style={keywordStyle}>"explanation"</span>: <span style={stringStyle}>"Uses emotionally charged..."</span>,<br/>
              {'      '}<span style={keywordStyle}>"evidence"</span>: <span style={stringStyle}>"microchips for tracking"</span><br/>
              {'    '}{'}'} ],<br/>
              {'    '}<span style={keywordStyle}>"brief"</span>: <span style={stringStyle}>"2-3 sentence analysis..."</span>,<br/>
              {'    '}<span style={keywordStyle}>"model_used"</span>: <span style={stringStyle}>"gpt-4o-mini"</span><br/>
              {'  }'},<br/>
              {'  '}<span style={keywordStyle}>"trace"</span>: {'{'} <span style={keywordStyle}>"fact_checks"</span>: [...], <span style={keywordStyle}>"spread_timeline"</span>: [...] {'}'},<br/>
              {'  '}<span style={keywordStyle}>"signal"</span>: {'{'} <span style={keywordStyle}>"toxicity_score"</span>: 0.01, <span style={keywordStyle}>"sentiment"</span>: <span style={stringStyle}>"negative"</span>, ... {'}'},<br/>
              {'  '}<span style={keywordStyle}>"compass"</span>: {'{'} <span style={keywordStyle}>"politicians"</span>: [...], <span style={keywordStyle}>"context"</span>: [...] {'}'},<br/>
              {'  '}<span style={keywordStyle}>"pulse"</span>: {'{'} <span style={keywordStyle}>"detected"</span>: false, <span style={keywordStyle}>"signals"</span>: [] {'}'},<br/>
              {'  '}<span style={keywordStyle}>"extracted_claims"</span>: [{'{'} <span style={keywordStyle}>"claim"</span>: <span style={stringStyle}>"..."</span>, <span style={keywordStyle}>"type"</span>: <span style={stringStyle}>"causal"</span> {'}'}],<br/>
              {'  '}<span style={keywordStyle}>"similar_claims"</span>: [...],<br/>
              {'  '}<span style={keywordStyle}>"detected_language"</span>: <span style={stringStyle}>"en"</span>,<br/>
              {'  '}<span style={keywordStyle}>"blockchain"</span>: {'{'} <span style={keywordStyle}>"content_hash"</span>: <span style={stringStyle}>"sha256..."</span> {'}'},<br/>
              {'  '}<span style={keywordStyle}>"analysis_time_ms"</span>: 3200<br/>
              {'}'}
            </div>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginTop: 16, marginBottom: 8 }}>Example (Python)</h3>
            <div style={codeStyle}>
              <span style={keywordStyle}>import</span> requests<br/><br/>
              response = requests.post(<br/>
              {'  '}<span style={stringStyle}>"{apiUrl}/api/scan"</span>,<br/>
              {'  '}json={'{'}<span style={stringStyle}>"content"</span>: <span style={stringStyle}>"your text"</span>, <span style={stringStyle}>"mode"</span>: <span style={stringStyle}>"brief"</span>{'}'}<br/>
              )<br/>
              data = response.json()<br/>
              <span style={keywordStyle}>print</span>(data[<span style={stringStyle}>"prism"</span>][<span style={stringStyle}>"techniques"</span>])
            </div>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginTop: 16, marginBottom: 8 }}>Example (JavaScript)</h3>
            <div style={codeStyle}>
              <span style={keywordStyle}>const</span> response = <span style={keywordStyle}>await</span> fetch(<span style={stringStyle}>'{apiUrl}/api/scan'</span>, {'{'}<br/>
              {'  '}method: <span style={stringStyle}>'POST'</span>,<br/>
              {'  '}headers: {'{'} <span style={stringStyle}>'Content-Type'</span>: <span style={stringStyle}>'application/json'</span> {'}'},<br/>
              {'  '}body: JSON.stringify({'{'} content: <span style={stringStyle}>'your text'</span>, mode: <span style={stringStyle}>'brief'</span> {'}'})<br/>
              {'}'});<br/>
              <span style={keywordStyle}>const</span> data = <span style={keywordStyle}>await</span> response.json();
            </div>
          </div>
        )}

        {tab === 'compare' && (
          <div>
            <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 4 }}>POST /api/scan/compare</h2>
            <p style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>Compare two pieces of content side-by-side.</p>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Request</h3>
            <div style={codeStyle}>
              {'{'}<br/>
              {'  '}<span style={keywordStyle}>"content_a"</span>: <span style={stringStyle}>"First article or claim..."</span>,<br/>
              {'  '}<span style={keywordStyle}>"content_b"</span>: <span style={stringStyle}>"Second article or claim..."</span>,<br/>
              {'  '}<span style={keywordStyle}>"mode"</span>: <span style={stringStyle}>"brief"</span><br/>
              {'}'}
            </div>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginTop: 16, marginBottom: 8 }}>Response includes</h3>
            <div style={{ fontSize: 13, color: '#555', lineHeight: 1.8 }}>
              • <code>result_a</code> — Full analysis of content A<br/>
              • <code>result_b</code> — Full analysis of content B<br/>
              • <code>comparison.summary</code> — AI-generated comparison<br/>
              • <code>comparison.shared_techniques</code> — Techniques found in both<br/>
              • <code>comparison.only_a_techniques</code> — Techniques only in A<br/>
              • <code>comparison.only_b_techniques</code> — Techniques only in B
            </div>
          </div>
        )}

        {tab === 'radar' && (
          <div>
            <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 4 }}>GET /api/radar</h2>
            <p style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>Live news intelligence feed from 16 sources across 4 markets.</p>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Parameters</h3>
            <div style={{ fontSize: 13, color: '#555', lineHeight: 1.8 }}>
              • <code>market</code> — <code>all</code>, <code>india</code>, <code>germany</code>, <code>us</code>, <code>uk</code><br/>
              • <code>limit</code> — Number of items (default: 20)<br/>
              • <code>refresh</code> — <code>true</code> to bypass 6-hour cache
            </div>

            <h3 style={{ fontSize: 14, fontWeight: 600, marginTop: 16, marginBottom: 8 }}>Example</h3>
            <div style={codeStyle}>
              curl "{apiUrl}/api/radar?market=india&limit=10"
            </div>
          </div>
        )}

        {/* Use cases */}
        <div style={{ marginTop: 32, paddingTop: 24, borderTop: '1px solid #e5e5e5' }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>Use cases</h2>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {[
              { icon: '📰', title: 'Newsrooms', desc: 'Integrate into editorial workflows. Auto-scan incoming tips and wire stories.' },
              { icon: '💬', title: 'Messaging platforms', desc: 'Scan shared links and forwards before they go viral.' },
              { icon: '🏫', title: 'Education', desc: 'Teach media literacy with real-time analysis of any content.' },
              { icon: '🏢', title: 'Corporate comms', desc: 'Monitor how your brand is being framed in media coverage.' },
            ].map((u, i) => (
              <div key={i} style={{ padding: 16, background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10 }}>
                <div style={{ fontSize: 20, marginBottom: 6 }}>{u.icon}</div>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{u.title}</div>
                <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{u.desc}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ textAlign: 'center', marginTop: 32, paddingTop: 20, borderTop: '1px solid #e5e5e5' }}>
          <p style={{ fontSize: 13, color: '#888', marginBottom: 12 }}>Need higher limits or a custom integration? Get in touch.</p>
          <a href="mailto:sambitmallick123@gmail.com" style={{ padding: '10px 20px', background: '#7c3aed', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Contact us</a>
        </div>
      </div>
    </main>
  );
}
DOCSEOF

echo "✅ API docs page created at /docs"

# ============================================
# 3. Update landing page — add "For organizations" section
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Add "For organizations" section before the CTA
org_section = '''
      {/* For Organizations */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#888', textAlign: 'center', marginBottom: 4 }}>For organizations</div>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 6 }}>Interpretation infrastructure for your platform</div>
        <p style={{ fontSize: 13, color: '#888', textAlign: 'center', maxWidth: 540, margin: '0 auto 20px' }}>Dissekt is not a fact-checker. It is an interpretation layer that makes manipulation visible — for any system that processes information.</p>
        <div className="landing-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
            <div style={{ fontSize: 22, marginBottom: 8 }}>📰</div>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>Newsrooms</div>
            <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>Auto-scan incoming tips and wire stories. Flag manipulation before publication. One API call per article.</div>
          </div>
          <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
            <div style={{ fontSize: 22, marginBottom: 8 }}>💬</div>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>Messaging platforms</div>
            <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>Scan links and forwards before they go viral. Overlay manipulation signals without blocking content.</div>
          </div>
          <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
            <div style={{ fontSize: 22, marginBottom: 8 }}>🏢</div>
            <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>Enterprise</div>
            <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>Monitor how your brand is framed. Detect coordinated narratives targeting your organization. API + webhooks.</div>
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <a href="/docs" style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '10px 20px', background: '#fff', color: '#7c3aed', border: '1px solid #e5e5e5', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>View API documentation →</a>
        </div>
      </div>

'''

if 'For organizations' not in content:
    # Insert before the CTA section
    content = content.replace(
        "      {/* CTA */}",
        org_section + "      {/* CTA */}"
    )
    open('src/components/LandingPage.tsx', 'w').write(content)
    print('✅ Landing page: "For organizations" section added')
else:
    print('Already has org section')
PYEOF

# ============================================
# 4. Add Docs link to nav
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

if "'/docs'" not in content:
    content = content.replace(
        "<a href=\"#features\" style={{ color: '#737373', textDecoration: 'none' }}>Features</a>",
        "<a href=\"#features\" style={{ color: '#737373', textDecoration: 'none' }}>Features</a>\n            <a href=\"/docs\" style={{ color: '#737373', textDecoration: 'none' }}>API</a>"
    )
    open('src/components/LandingPage.tsx', 'w').write(content)
    print('✅ Landing page: API link added to nav')
else:
    print('Already has docs link')
PYEOF

# Also add Docs to scan page nav
python3 << 'PYEOF'
content = open('src/app/page.tsx').read()

if "'/docs'" not in content:
    content = content.replace(
        "<a href='/help' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Help</a>",
        "<a href='/docs' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>API</a>\n            <a href='/help' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Help</a>"
    )
    open('src/app/page.tsx', 'w').write(content)
    print('✅ Scan page: API link added to nav')
else:
    print('Already has docs link')
PYEOF

# ============================================
# 5. Update help page "Our approach" messaging
# ============================================

python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

if 'interpretation infrastructure' not in content:
    content = content.replace(
        "Dissekt never tells you what\\'s true or false.",
        "Dissekt is interpretation infrastructure for information systems. It never tells you what\\'s true or false."
    )
    # Try without escaped quotes
    content = content.replace(
        "Dissekt never tells you what's true or false.",
        "Dissekt is interpretation infrastructure for the information age. It never tells you what's true or false."
    )
    open('src/app/help/page.tsx', 'w').write(content)
    print('✅ Help page: updated messaging')
else:
    print('Already updated')
PYEOF

echo ""
echo "✅ All positioning changes applied:"
echo "  1. 'fact-checks' → 'cross-references' across all UI"
echo "  2. API docs page at /docs (overview, endpoints, examples, use cases)"
echo "  3. 'For organizations' section on landing page"
echo "  4. 'API' link in both landing nav + scan nav"
echo "  5. Help page updated with 'interpretation infrastructure' framing"
echo ""
echo "Build and deploy: npm run build && vercel --prod"
