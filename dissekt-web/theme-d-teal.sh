#!/bin/bash
# Dissekt — Theme D: Teal Intelligence + Feedback form + Contact form
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Global color replacement: purple → teal
# ============================================

python3 << 'PYEOF'
import glob

# Color mappings: purple → teal
replacements = {
    '#7c3aed': '#0d9488',    # primary
    '#6d28d9': '#0f766e',    # primary dark
    '#6b21a8': '#115e59',    # primary darker
    '#f3e8ff': '#f0fdfa',    # primary-50
    '#faf5ff': '#f0fdfa',    # primary-50 alt
    '#ede9fe': '#ccfbf1',    # primary-100
    '#ddd6fe': '#99f6e4',    # primary-200
    '#c4b5fd': '#5eead4',    # primary-300
    '#e9e5f5': '#e5eaea',    # border purple → teal border
}

files = glob.glob('src/**/*.tsx', recursive=True)
count = 0

for filepath in files:
    try:
        content = open(filepath).read()
        original = content
        for old, new in replacements.items():
            content = content.replace(old, new)
        if content != original:
            open(filepath, 'w').write(content)
            count += 1
    except: pass

print(f'✅ Updated {count} files with teal theme')
PYEOF

# ============================================
# 2. SiteHeader — teal stripe + teal accent
# ============================================

cat > src/components/SiteHeader.tsx << 'HEADEOF'
'use client';

export default function SiteHeader({ active }: { active?: string }) {
  const links = [
    { href: '/analyze', label: 'Analyze' },
    { href: '/topics', label: 'Topics' },
    { href: '/compare', label: 'Compare' },
    { href: '/docs', label: 'API' },
    { href: '/help', label: 'Help' },
  ];

  return (
    <nav style={{ position: 'sticky', top: 0, zIndex: 30 }}>
      <div style={{ height: 3, background: '#0d9488' }} />
      <div style={{ background: '#fff', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#0d9488', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 16, color: '#1a1a1a' }}>Dissekt</span>
            <span style={{ fontSize: 9, fontWeight: 700, color: '#0d9488', background: '#f0fdfa', padding: '2px 6px', borderRadius: 4, letterSpacing: '0.05em' }}>BETA</span>
          </a>

          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            {links.map(l => (
              <a key={l.href} href={l.href}
                style={{ fontSize: 13, color: active === l.label ? '#0d9488' : '#777', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
                {l.label}
              </a>
            ))}
            <a href="/invite" style={{ fontSize: 13, color: '#fff', textDecoration: 'none', borderRadius: 8, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>
              Get access
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}
HEADEOF

echo "✅ SiteHeader: teal stripe theme"

# ============================================
# 3. SiteFooter — teal links
# ============================================

cat > src/components/SiteFooter.tsx << 'FOOTEOF'
'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#fff', borderTop: '0.5px solid #e5eaea', marginTop: 40 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '24px', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'start', gap: 20 }}>
        <div style={{ maxWidth: 280 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ width: 24, height: 24, background: '#0d9488', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 14, color: '#1a1a1a' }}>Dissekt</span>
            <span style={{ fontSize: 8, fontWeight: 700, color: '#0d9488', background: '#f0fdfa', padding: '1px 5px', borderRadius: 3 }}>BETA</span>
          </div>
          <p style={{ fontSize: 12, color: '#888', lineHeight: 1.6 }}>Information transparency and argument inspection. See how information is constructed.</p>
        </div>

        <div style={{ display: 'flex', gap: 40, flexWrap: 'wrap' }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Product</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/analyze" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Analyze</a>
              <a href="/topics" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Topics</a>
              <a href="/compare" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Compare</a>
              <a href="/docs" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>API</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Resources</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/help" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>How it works</a>
              <a href="/invite" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Get access</a>
              <a href="/feedback" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Feedback</a>
              <a href="/contact" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Contact</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Legal</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/privacy" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Privacy Policy</a>
              <a href="/terms" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Terms of Service</a>
              <a href="/disclaimer" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Data Disclaimer</a>
            </div>
          </div>
        </div>
      </div>
      <div style={{ borderTop: '0.5px solid #e5eaea', padding: '14px 24px', textAlign: 'center' }}>
        <p style={{ fontSize: 11, color: '#aaa' }}>© 2026 Dissekt · Built by Sambit Mallick · Munich, Germany · Beta — under active development</p>
      </div>
    </footer>
  );
}
FOOTEOF

echo "✅ SiteFooter: teal theme + feedback/contact links"

# ============================================
# 4. Feedback page with component selector
# ============================================

mkdir -p src/app/feedback

cat > src/app/feedback/page.tsx << 'FBEOF'
'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const COMPONENTS = [
  { key: 'general', label: 'General feedback' },
  { key: 'transparency_score', label: 'Transparency Score' },
  { key: 'prism', label: 'Prism — techniques detection' },
  { key: 'trace', label: 'Trace — cross-references' },
  { key: 'signal', label: 'Signal — evidence/credibility' },
  { key: 'compass', label: 'Compass — political context' },
  { key: 'pulse', label: 'Pulse — coordination detection' },
  { key: 'counterfactual', label: 'Counterfactual — alternative framings' },
  { key: 'claims', label: 'Claim extraction' },
  { key: 'radar', label: 'Radar — news feed' },
  { key: 'bulk', label: 'Bulk CSV analysis' },
  { key: 'compare', label: 'Comparative analysis' },
  { key: 'topics', label: 'Topic tracking' },
  { key: 'telegram', label: 'Telegram bot' },
  { key: 'extension', label: 'Chrome extension' },
  { key: 'ui', label: 'UI/UX design' },
  { key: 'performance', label: 'Performance/speed' },
  { key: 'bug', label: 'Bug report' },
  { key: 'feature', label: 'Feature request' },
];

const TYPES = [
  { key: 'feedback', label: 'Feedback', icon: '💬' },
  { key: 'bug', label: 'Bug report', icon: '🐛' },
  { key: 'feature', label: 'Feature request', icon: '💡' },
  { key: 'question', label: 'Question', icon: '❓' },
];

export default function FeedbackPage() {
  const [type, setType] = useState('feedback');
  const [component, setComponent] = useState('general');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async () => {
    if (!message.trim()) return;
    setStatus('sending');
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name, email, message,
          type,
          component,
          source: 'feedback_page',
        }),
      });
      if (res.ok) { setStatus('sent'); setMessage(''); }
      else setStatus('error');
    } catch { setStatus('error'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8fafa', fontFamily: 'inherit', boxSizing: 'border-box' as const };

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>Feedback</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Help us improve Dissekt. Your feedback shapes the product.</p>

        {status === 'sent' ? (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 32, textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Thanks for your feedback!</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>We read every submission and use it to improve.</div>
            <button onClick={() => setStatus('idle')} style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Send another</button>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            {/* Type selector */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>Type</label>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                {TYPES.map(t => (
                  <button key={t.key} onClick={() => setType(t.key)}
                    style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, border: 'none', cursor: 'pointer', fontWeight: 500, background: type === t.key ? '#0d9488' : '#f0fdfa', color: type === t.key ? '#fff' : '#0d9488' }}>
                    {t.icon} {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Component selector */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 6 }}>About which component?</label>
              <select value={component} onChange={e => setComponent(e.target.value)}
                style={{ ...inputStyle, cursor: 'pointer' }}>
                {COMPONENTS.map(c => (
                  <option key={c.key} value={c.key}>{c.label}</option>
                ))}
              </select>
            </div>

            {/* Name + Email */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Name (optional)</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="Your name" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Email (optional)</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="For follow-up" style={inputStyle} />
              </div>
            </div>

            {/* Message */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Message *</label>
              <textarea value={message} onChange={e => setMessage(e.target.value)} rows={5} placeholder="What did you notice? What would you improve?" style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            {status === 'error' && (
              <div style={{ marginBottom: 12, padding: 10, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12 }}>Failed to send. Please try again.</div>
            )}

            <button onClick={handleSubmit} disabled={!message.trim() || status === 'sending'}
              style={{ width: '100%', padding: '11px 0', background: message.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: message.trim() ? 'pointer' : 'not-allowed' }}>
              {status === 'sending' ? 'Sending...' : 'Send feedback'}
            </button>
          </div>
        )}
      </div>
      <SiteFooter />
    </main>
  );
}
FBEOF

echo "✅ Feedback page: type + component selector"

# ============================================
# 5. Contact page with form (sends to your email)
# ============================================

mkdir -p src/app/contact
mkdir -p src/app/api/contact

cat > src/app/api/contact/route.ts << 'CAPI'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { name, email, subject, message } = await req.json();
    if (!message) return NextResponse.json({ error: 'Message required' }, { status: 400 });

    const RESEND_KEY = process.env.RESEND_API_KEY || '';
    if (!RESEND_KEY) return NextResponse.json({ error: 'Email not configured' }, { status: 500 });

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'Dissekt Contact <onboarding@resend.dev>',
        to: 'sambitmallick123@gmail.com',
        subject: `[Dissekt Contact] ${subject || 'New message'}`,
        html: `
          <h3>New contact from Dissekt</h3>
          <p><strong>Subject:</strong> ${subject || 'General'}</p>
          <p><strong>Name:</strong> ${name || 'Not provided'}</p>
          <p><strong>Email:</strong> ${email || 'Not provided'}</p>
          <hr/>
          <p>${message.replace(/\n/g, '<br/>')}</p>
        `,
      }),
    });

    if (res.ok) return NextResponse.json({ success: true });
    return NextResponse.json({ error: 'Failed to send' }, { status: 500 });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
CAPI

cat > src/app/contact/page.tsx << 'CONTEOF'
'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const SUBJECTS = [
  'General inquiry',
  'API access / integration',
  'Partnership / collaboration',
  'Press / media inquiry',
  'Bug report',
  'Feature request',
  'Data deletion request',
  'Other',
];

export default function ContactPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [subject, setSubject] = useState('General inquiry');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleSubmit = async () => {
    if (!message.trim()) return;
    setStatus('sending');
    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, subject, message }),
      });
      if (res.ok) { setStatus('sent'); setMessage(''); }
      else setStatus('error');
    } catch { setStatus('error'); }
  };

  const inputStyle: React.CSSProperties = { width: '100%', padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 8, fontSize: 14, outline: 'none', background: '#f8fafa', fontFamily: 'inherit', boxSizing: 'border-box' as const };

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>Contact us</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Questions, partnerships, or just want to say hi? We'll get back to you.</p>

        {status === 'sent' ? (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 32, textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>Message sent!</div>
            <div style={{ fontSize: 13, color: '#888', marginBottom: 16 }}>We typically respond within 24 hours.</div>
            <button onClick={() => setStatus('idle')} style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Send another</button>
          </div>
        ) : (
          <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
            {/* Subject */}
            <div style={{ marginBottom: 12 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Subject</label>
              <select value={subject} onChange={e => setSubject(e.target.value)} style={{ ...inputStyle, cursor: 'pointer' }}>
                {SUBJECTS.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>

            {/* Name + Email */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Name</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="Your name" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Email</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="For reply" style={inputStyle} />
              </div>
            </div>

            {/* Message */}
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: '#555', display: 'block', marginBottom: 4 }}>Message *</label>
              <textarea value={message} onChange={e => setMessage(e.target.value)} rows={5} placeholder="How can we help?" style={{ ...inputStyle, resize: 'vertical' }} />
            </div>

            {status === 'error' && (
              <div style={{ marginBottom: 12, padding: 10, background: '#fef2f2', border: '0.5px solid #fecaca', borderRadius: 8, color: '#b91c1c', fontSize: 12 }}>Failed to send. Try again or email sambitmallick123@gmail.com directly.</div>
            )}

            <button onClick={handleSubmit} disabled={!message.trim() || status === 'sending'}
              style={{ width: '100%', padding: '11px 0', background: message.trim() ? '#0d9488' : '#ccc', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: message.trim() ? 'pointer' : 'not-allowed' }}>
              {status === 'sending' ? 'Sending...' : 'Send message'}
            </button>
          </div>
        )}

        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#aaa' }}>
          Or email directly: <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#0d9488', textDecoration: 'none' }}>sambitmallick123@gmail.com</a>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
CONTEOF

echo "✅ Contact page: form → emails to you via Resend"

# ============================================
# 6. Make sure RESEND_API_KEY is in .env.local
# ============================================

if ! grep -q "RESEND_API_KEY" .env.local 2>/dev/null; then
    echo "⚠️  Add RESEND_API_KEY to .env.local:"
    echo "  RESEND_API_KEY=re_VQ8eSGFH_EtcQUiWHMsWYJFc6X3TQewRn"
fi

# ============================================
# 7. Update invite page — teal theme
# ============================================

python3 -c "
content = open('src/app/invite/page.tsx').read()
# Just replace purple colors with teal
content = content.replace('#7c3aed', '#0d9488')
content = content.replace('#f3e8ff', '#f0fdfa')
content = content.replace('#faf5ff', '#f0fdfa')
content = content.replace('#ede9fe', '#ccfbf1')
content = content.replace('#6d28d9', '#0f766e')
open('src/app/invite/page.tsx', 'w').write(content)
print('✅ Invite page: teal theme')
"

# ============================================
# 8. Update admin page — teal theme
# ============================================

python3 -c "
content = open('src/app/admin/page.tsx').read()
content = content.replace('#7c3aed', '#0d9488')
content = content.replace('#f3e8ff', '#f0fdfa')
open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin page: teal theme')
"

# ============================================
# 9. Update analyze page background
# ============================================

python3 -c "
content = open('src/app/analyze/page.tsx').read()
content = content.replace(\"background: '#f5f5f4'\", \"background: '#f8fafa'\")
open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze page: teal background')
"

echo ""
echo "✅ Theme D (Teal Intelligence) applied:"
echo "  - Global purple → teal across all components"
echo "  - SiteHeader: teal top stripe + teal accent"
echo "  - SiteFooter: feedback + contact links"
echo "  - /feedback: type selector + component picker + Supabase"
echo "  - /contact: subject dropdown + form → Resend → your Gmail"
echo "  - /invite + /admin: teal themed"
echo "  - /analyze: teal background"
echo ""
echo "Test: npm run build && npm run dev"
