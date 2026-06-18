#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Wire header to Supabase session; landing → 2 cards (Free + Account); remove /invite
set -e

# ═══ HEADER: read Supabase session ═══
python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

# 1. Import supabase
content = content.replace(
    "import { useEffect, useState } from 'react';",
    "import { useEffect, useState } from 'react';\nimport { supabase } from '@/lib/supabase';"
)

# 2. Replace the localStorage tier logic with Supabase session
old_effect = '''  const [tier, setTier] = useState('free');
  const [name, setName] = useState('');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      setTier(localStorage.getItem('dissekt_tier') || 'free');
      setName(localStorage.getItem('dissekt_invite_name') || localStorage.getItem('dissekt_name') || '');
      const expiry = localStorage.getItem('dissekt_access_expires');
      if (expiry) {
        const days = Math.round((new Date(expiry).getTime() - Date.now()) / 86400000);
        if (days > 0) setExpiryText(`${days}d`);
        else { localStorage.removeItem('dissekt_tier'); localStorage.removeItem('dissekt_access_expires'); setTier('free'); }
      }
    }
  }, []);

  const signOut = () => {
    ['dissekt_tier','dissekt_invite_code','dissekt_invite_name','dissekt_access_expires','dissekt_token','dissekt_email','dissekt_name','dissekt_usage','dissekt_admin'].forEach(k => localStorage.removeItem(k));
    window.location.href = '/';
  };

  const isLoggedIn = tier === 'invited';'''

new_effect = '''  const [name, setName] = useState('');
  const [expiryText, setExpiryText] = useState('');
  const [mounted, setMounted] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    setMounted(true);
    // Read the Supabase session
    supabase.auth.getSession().then(({ data }) => {
      const session = data.session;
      setIsLoggedIn(!!session);
      if (session?.user) {
        const meta = session.user.user_metadata || {};
        setName(meta.name || session.user.email?.split('@')[0] || 'User');
      }
    });
    // React to auth changes (login/logout in any tab)
    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsLoggedIn(!!session);
      if (session?.user) {
        const meta = session.user.user_metadata || {};
        setName(meta.name || session.user.email?.split('@')[0] || 'User');
      } else {
        setName('');
      }
    });
    return () => { sub.subscription.unsubscribe(); };
  }, []);

  const signOut = async () => {
    await supabase.auth.signOut();
    // clear any legacy flags too
    ['dissekt_tier','dissekt_invite_code','dissekt_invite_name','dissekt_access_expires','dissekt_token','dissekt_email','dissekt_name','dissekt_usage','dissekt_admin'].forEach(k => localStorage.removeItem(k));
    window.location.href = '/';
  };'''

content = content.replace(old_effect, new_effect)
print('✅ Header reads Supabase session + proper signOut')

# 3. Logged-out right side: add "Sign in" next to Get access. Replace "Get access" → "Request access" label too? No—keep Get access but point to /signup.
# Desktop logged-out branch (the <a href="/invite">Get access</a>)
content = content.replace(
    '''<a href="/invite" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Get access</a>''',
    '''<>
                <a href="/login" style={{ fontSize: 12, color: '#888780', textDecoration: 'none', fontWeight: 500 }}>Sign in</a>
                <a href="/signup" style={{ fontSize: 11, color: '#fff', textDecoration: 'none', borderRadius: 5, padding: '5px 14px', fontWeight: 600, background: '#0d9488' }}>Sign up</a>
                </>'''
)
print('✅ Header logged-out: Sign in + Sign up (replaces Get access→invite)')

open('src/components/SiteHeader.tsx', 'w').write(content)
PYEOF

# ═══ LANDING: 2 cards (Free + Account), remove Invited ═══
python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Replace the Invited card + the disabled "Sign up/Sign in" card with a single Account card
old_cards = '''            <div style={{ padding: 20, background: '#fff', border: '2px solid #0d9488', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>🎫 Invited</div>
              <div style={{ fontSize: 11, color: '#0d9488', marginBottom: 10 }}>6 months access</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>25 brief / day<br />10 detailed / day<br />All features + API + Dashboard</div>
              <a href="/invite" style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Request access</a>
            </div>
            <div style={{ padding: 20, background: '#fafaf8', border: '0.5px dashed #d5dada', borderRadius: 10, opacity: 0.75, position: 'relative' }}>
              <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 9, fontWeight: 600, color: '#888', background: '#f0f0ee', padding: '2px 8px', borderRadius: 10 }}>COMING SOON</span>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#888' }}>🔐 Sign up / Sign in</div>
              <div style={{ fontSize: 11, color: '#aaa', marginBottom: 10 }}>Personal account</div>
              <div style={{ fontSize: 12, color: '#999', lineHeight: 2 }}>Save your history<br />Sync across devices<br />Custom preferences</div>
              <div style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#f0f0ee', color: '#aaa', borderRadius: 6, fontSize: 13, cursor: 'not-allowed' }}>In development</div>
            </div>'''

new_cards = '''            <div style={{ padding: 20, background: '#fff', border: '2px solid #0d9488', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>🔐 Account</div>
              <div style={{ fontSize: 11, color: '#0d9488', marginBottom: 10 }}>Free — sign up with email</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>25 brief / day<br />10 detailed / day<br />All features + API + Dashboard</div>
              <a href="/signup" style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Sign up</a>
              <a href="/login" style={{ display: 'block', textAlign: 'center', marginTop: 6, fontSize: 12, color: '#0d9488', textDecoration: 'none' }}>or sign in</a>
            </div>'''

content = content.replace(old_cards, new_cards)

# Grid was minmax(170px) for 3 cards; with 2 cards, widen to 1fr 1fr and narrow container
content = content.replace(
    "<div style={{ maxWidth: 820, margin: '0 auto' }}>\n          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 20px', textAlign: 'center' }}>Start free. Go deeper with access.</h2>",
    "<div style={{ maxWidth: 560, margin: '0 auto' }}>\n          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 20px', textAlign: 'center' }}>Start free. Go deeper with an account.</h2>"
)
content = content.replace(
    "<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: 12 }}>",
    "<div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>"
)
print('✅ Landing: 2 cards (Free + Account), Invited removed')

open('src/components/LandingPage.tsx', 'w').write(content)
PYEOF

echo ""
echo "Verify no stray /invite links in header/landing:"
grep -n "/invite" src/components/SiteHeader.tsx src/components/LandingPage.tsx || echo "  ✅ none"

echo ""
echo "Run: rm -rf .next && npm run build"
