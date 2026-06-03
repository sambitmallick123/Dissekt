#!/bin/bash
# Dissekt Landing Page — Concept D: Full-page story with live demo
# Run from inside dissekt-web/ directory
set -e
echo "Applying Concept D landing page..."

# ============================================
# Landing page component (public, no auth needed)
# ============================================
cat > src/components/LandingPage.tsx << 'LANDEOF'
'use client';

const S = {
  page: { minHeight: '100vh', background: '#f5f5f4' } as React.CSSProperties,
  nav: { background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky' as const, top: 0, zIndex: 20 },
  navInner: { maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  logoWrap: { display: 'flex', alignItems: 'center', gap: 10 },
  logoIcon: { width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' },
  logoText: { fontWeight: 600, fontSize: 15, letterSpacing: '-0.01em' },
  navLinks: { display: 'flex', gap: 16, fontSize: 13, color: '#737373', alignItems: 'center' },
  navBtn: { padding: '6px 16px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },

  hero: { background: '#fff', borderBottom: '1px solid #e5e5e5', textAlign: 'center' as const, padding: '48px 24px 40px' },
  heroProblem: { fontSize: 13, color: '#888', marginBottom: 12, maxWidth: 500, margin: '0 auto 12px' },
  heroTitle: { fontSize: 36, fontWeight: 700, lineHeight: 1.2, marginBottom: 12, letterSpacing: '-0.02em', maxWidth: 600, margin: '0 auto 12px' },
  heroSub: { fontSize: 15, color: '#555', lineHeight: 1.6, maxWidth: 520, margin: '0 auto 20px' },
  heroCta: { display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 28px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' },
  heroNote: { fontSize: 12, color: '#aaa', marginTop: 10 },

  section: { maxWidth: 1100, margin: '0 auto', padding: '40px 24px' },
  sectionBorder: { borderBottom: '1px solid #e5e5e5' },
  sectionLabel: { fontSize: 11, fontWeight: 600, textTransform: 'uppercase' as const, letterSpacing: '0.08em', color: '#888', marginBottom: 6, textAlign: 'center' as const },
  sectionTitle: { fontSize: 22, fontWeight: 600, textAlign: 'center' as const, marginBottom: 6 },
  sectionSub: { fontSize: 14, color: '#888', textAlign: 'center' as const, marginBottom: 24, maxWidth: 500, margin: '0 auto 24px' },

  grid3: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 } as React.CSSProperties,
  grid4: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 } as React.CSSProperties,

  card: { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 20 },
  cardIcon: { width: 40, height: 40, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  cardTitle: { fontSize: 15, fontWeight: 600, marginBottom: 4 },
  cardDesc: { fontSize: 13, color: '#555', lineHeight: 1.6 },

  statCard: { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '20px 16px', textAlign: 'center' as const },
  statNum: { fontSize: 28, fontWeight: 700 },
  statLabel: { fontSize: 12, color: '#888', marginTop: 2 },

  demoWrap: { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' },
  demoHeader: { padding: '12px 16px', borderBottom: '1px solid #e5e5e5', fontSize: 12, color: '#888', display: 'flex', justifyContent: 'space-between', alignItems: 'center' },
  demoGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 0 } as React.CSSProperties,
  demoPanel: { padding: 16, borderRight: '1px solid #e5e5e5' } as React.CSSProperties,

  howStep: { display: 'flex', alignItems: 'start', gap: 16, marginBottom: 20 } as React.CSSProperties,
  howNum: { width: 36, height: 36, borderRadius: 18, background: '#f3e8ff', color: '#7c3aed', fontSize: 14, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 } as React.CSSProperties,
  howTitle: { fontSize: 15, fontWeight: 600, marginBottom: 2 },
  howDesc: { fontSize: 13, color: '#555', lineHeight: 1.5 },

  trustGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginTop: 24 } as React.CSSProperties,
  trustCard: { background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 20, textAlign: 'center' as const },

  ctaSection: { background: '#7c3aed', borderRadius: 16, padding: '40px 24px', textAlign: 'center' as const, margin: '40px auto', maxWidth: 800 },
  ctaTitle: { fontSize: 24, fontWeight: 700, color: '#fff', marginBottom: 8 },
  ctaSub: { fontSize: 14, color: '#d4bfff', marginBottom: 20 },
  ctaBtn: { display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 28px', background: '#fff', color: '#7c3aed', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' },

  footer: { borderTop: '1px solid #e5e5e5', padding: '20px 24px', textAlign: 'center' as const, fontSize: 12, color: '#aaa' },
};

export default function LandingPage({ onSignIn }: { onSignIn: () => void }) {
  return (
    <div style={S.page}>
      {/* Nav */}
      <nav style={S.nav}>
        <div style={S.navInner}>
          <div style={S.logoWrap}>
            <div style={S.logoIcon}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={S.logoText}>Dissekt</span>
          </div>
          <div style={S.navLinks}>
            <a href="#features" style={{ color: '#737373', textDecoration: 'none' }}>Features</a>
            <a href="#how" style={{ color: '#737373', textDecoration: 'none' }}>How it works</a>
            <a href="#demo" style={{ color: '#737373', textDecoration: 'none' }}>Live demo</a>
            <button onClick={onSignIn} style={S.navBtn}>Sign in</button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <div style={S.hero}>
        <p style={S.heroProblem}>Journalists spend 30-90 minutes per claim verifying manually. There's a better way.</p>
        <h1 style={S.heroTitle}>Dissekt explains how content manipulates — in seconds.</h1>
        <p style={S.heroSub}>
          Paste any URL or text. Get manipulation techniques, fact-checks from 100+ organizations,
          source credibility scores, and blockchain-verified evidence. No verdicts — just explanation.
        </p>
        <button onClick={onSignIn} style={S.heroCta}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          Try it free
        </button>
        <p style={S.heroNote}>No credit card required · 10 free scans per day</p>
      </div>

      {/* Live demo */}
      <div id="demo" style={{ ...S.section, ...S.sectionBorder }}>
        <div style={S.sectionLabel}>Live analysis example</div>
        <div style={{ ...S.sectionTitle, marginBottom: 4 }}>What Dissekt finds in 3 seconds</div>
        <p style={S.sectionSub}>Real analysis of: "COVID-19 vaccines contain microchips for tracking people"</p>

        <div style={S.demoWrap}>
          <div style={S.demoHeader}>
            <span>Analysis result · Threat score: <strong style={{ color: '#dc2626' }}>76/100 High risk</strong></span>
            <span>3.1s · GPT-4o mini</span>
          </div>
          <div style={S.demoGrid}>
            {/* Prism */}
            <div style={S.demoPanel}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, background: '#f3e8ff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2" strokeLinecap="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                </div>
                <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Prism</span>
              </div>
              <div style={{ border: '1px solid #e5e5e5', borderRadius: 8, padding: 10, marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: 600 }}>Loaded language</span>
                  <span style={{ fontSize: 12, fontWeight: 700, color: '#dc2626' }}>90%</span>
                </div>
                <div style={{ height: 4, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: '90%', background: '#dc2626', borderRadius: 2 }}></div></div>
                <p style={{ fontSize: 11, color: '#555', marginTop: 6, lineHeight: 1.5 }}>The term "microchips" is designed to provoke fear about surveillance and privacy violation.</p>
              </div>
              <div style={{ background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, padding: 8 }}>
                <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#7c3aed', marginBottom: 3 }}>Summary</div>
                <p style={{ fontSize: 10, color: '#404040', lineHeight: 1.5, margin: 0 }}>Employs emotionally charged language to provoke fear without providing factual evidence.</p>
              </div>
            </div>

            {/* Trace */}
            <div style={S.demoPanel}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, background: '#dbeafe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/></svg>
                </div>
                <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Trace</span>
                <span style={{ fontSize: 11, color: '#888', marginLeft: 'auto' }}>10 checks</span>
              </div>
              {[
                { pub: 'FactCheck.org', title: 'Vaccines Don\'t Have Tracking Devices' },
                { pub: 'Full Fact', title: 'Covid-19 vaccines do not make you magnetic' },
                { pub: 'AP News', title: 'No, vaccines don\'t contain nanotech' },
              ].map((fc, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 8px', border: '1px solid #e5e5e5', borderRadius: 6, marginBottom: 4, fontSize: 11 }}>
                  <div><div style={{ fontWeight: 600, fontSize: 11 }}>{fc.pub}</div><div style={{ color: '#888', fontSize: 10 }}>{fc.title}</div></div>
                  <span style={{ fontSize: 9, fontWeight: 600, padding: '2px 6px', borderRadius: 4, background: '#fef2f2', color: '#b91c1c', whiteSpace: 'nowrap' }}>False</span>
                </div>
              ))}
              <div style={{ fontSize: 11, color: '#2563eb', fontWeight: 500, textAlign: 'center', marginTop: 6 }}>+ 7 more fact-checks</div>
            </div>

            {/* Signal */}
            <div style={{ ...S.demoPanel, borderRight: 'none' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#d97706" strokeWidth="2" strokeLinecap="round"><path d="M2 20h.01M7 20v-4M12 20v-8M17 20V8M22 4v16"/></svg>
                </div>
                <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Signal</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
                {[
                  { label: 'Toxicity', value: '0.1%', color: '#059669' },
                  { label: 'Sentiment', value: 'Neutral', color: '#404040' },
                  { label: 'Bias', value: 'N/A', color: '#888' },
                  { label: 'Factuality', value: 'N/A', color: '#888' },
                ].map((s, i) => (
                  <div key={i} style={{ background: '#f8f8f6', borderRadius: 8, padding: 8 }}>
                    <div style={{ fontSize: 9, color: '#888', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: 2 }}>{s.label}</div>
                    <div style={{ fontSize: 13, fontWeight: 600, color: s.color }}>{s.value}</div>
                  </div>
                ))}
              </div>
              <div style={{ marginTop: 10, padding: 8, background: '#f8f8f6', borderRadius: 8, textAlign: 'center' }}>
                <div style={{ fontSize: 9, color: '#888', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: 2 }}>Blockchain hash</div>
                <div style={{ fontSize: 9, fontFamily: 'monospace', color: '#aaa' }}>4f86bad8e6976d46...ee4e</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* How it works */}
      <div id="how" style={{ ...S.section, ...S.sectionBorder }}>
        <div style={S.sectionLabel}>How it works</div>
        <div style={{ ...S.sectionTitle, marginBottom: 24 }}>Four steps to a complete investigation</div>

        <div style={{ maxWidth: 560, margin: '0 auto' }}>
          {[
            { num: '1', title: 'Paste', desc: 'Drop any URL, article text, WhatsApp forward, or social media claim into the scan bar.' },
            { num: '2', title: 'Prism analyzes', desc: 'AI identifies specific manipulation techniques — loaded language, cherry-picking, appeal to authority, and 17 more — with confidence scores and evidence quotes.' },
            { num: '3', title: 'Trace verifies', desc: 'Simultaneously searches 100+ fact-checking organizations (FactCheck.org, Full Fact, Alt News, Correctiv) and traces the claim to its earliest online appearance.' },
            { num: '4', title: 'Signal assesses', desc: 'Scores source bias (231 rated outlets), toxicity, sentiment, and emotion — all running locally with zero data sent externally.' },
          ].map((step) => (
            <div key={step.num} style={S.howStep}>
              <div style={S.howNum}>{step.num}</div>
              <div>
                <div style={S.howTitle}>{step.title}</div>
                <div style={S.howDesc}>{step.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Features */}
      <div id="features" style={{ ...S.section, ...S.sectionBorder }}>
        <div style={S.sectionLabel}>Core engines</div>
        <div style={{ ...S.sectionTitle, marginBottom: 24 }}>Built for journalists, not algorithms</div>

        <div style={S.grid3}>
          {[
            { icon: '👁', bg: '#f3e8ff', title: 'Prism — Manipulation detection', desc: 'Identifies 20 manipulation techniques across 4 categories: framing, logical fallacies, credibility manipulation, and deflection. Never says "true" or "false" — explains HOW content is constructed.' },
            { icon: '🌐', bg: '#dbeafe', title: 'Trace — Source origins', desc: 'Searches 100+ fact-checking organizations across India, Germany, US, and UK. Traces claims to their earliest online appearance. Builds a spread timeline across platforms.' },
            { icon: '📊', bg: '#fef3c7', title: 'Signal — Source credibility', desc: '231 news sources rated for political bias and factual reliability. Detoxify toxicity scoring. VADER sentiment analysis. All models run locally — zero API cost, full privacy.' },
          ].map((f, i) => (
            <div key={i} style={S.card}>
              <div style={{ ...S.cardIcon, background: f.bg, fontSize: 18 }}>{f.icon}</div>
              <div style={S.cardTitle}>{f.title}</div>
              <div style={S.cardDesc}>{f.desc}</div>
            </div>
          ))}
        </div>

        <div style={{ ...S.grid3, marginTop: 16 }}>
          {[
            { icon: '🔒', bg: '#f0fdf4', title: 'Anchor — Blockchain evidence', desc: 'Every analysis gets a SHA-256 hash for tamper-proof evidence integrity. OpenTimestamps anchoring to Bitcoin for court-admissible proof of existence.' },
            { icon: '📡', bg: '#fef2f2', title: 'Radar — News intelligence', desc: 'Real-time RSS feeds from 16 sources across 4 markets. Monitor India, Germany, US, and UK news for emerging manipulation patterns.' },
            { icon: '⚡', bg: '#f5f5f4', title: 'Smart routing', desc: 'Three-tier cost optimization: heuristic-only (1s, €0) for obvious cases, GPT-4o mini for Brief mode, Claude for Detailed deep analysis. Average cost: €0.005 per scan.' },
          ].map((f, i) => (
            <div key={i} style={S.card}>
              <div style={{ ...S.cardIcon, background: f.bg, fontSize: 18 }}>{f.icon}</div>
              <div style={S.cardTitle}>{f.title}</div>
              <div style={S.cardDesc}>{f.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div style={S.section}>
        <div style={S.grid4}>
          {[
            { num: '20', label: 'Manipulation techniques', color: '#7c3aed' },
            { num: '100+', label: 'Fact-checker organizations', color: '#2563eb' },
            { num: '231', label: 'Rated news sources', color: '#d97706' },
            { num: '~3s', label: 'Average analysis time', color: '#059669' },
          ].map((s, i) => (
            <div key={i} style={S.statCard}>
              <div style={{ ...S.statNum, color: s.color }}>{s.num}</div>
              <div style={S.statLabel}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Markets */}
      <div style={{ ...S.section, ...S.sectionBorder }}>
        <div style={S.sectionLabel}>Global coverage</div>
        <div style={{ ...S.sectionTitle, marginBottom: 24 }}>Four markets, local fact-checkers</div>
        <div style={S.grid4}>
          {[
            { flag: '🇮🇳', name: 'India', checkers: 'Alt News, BOOM Live, Vishvas News, Factly', note: '500M+ WhatsApp users' },
            { flag: '🇩🇪', name: 'Germany', checkers: 'Correctiv, dpa-Faktencheck, Tagesschau', note: 'Best open gov data' },
            { flag: '🇺🇸', name: 'US', checkers: 'PolitiFact, Snopes, FactCheck.org, AP', note: 'Largest journalism market' },
            { flag: '🇬🇧', name: 'UK', checkers: 'Full Fact, BBC Reality Check', note: 'Full Fact ecosystem' },
          ].map((m, i) => (
            <div key={i} style={S.card}>
              <div style={{ fontSize: 28, marginBottom: 6 }}>{m.flag}</div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{m.name}</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5, marginBottom: 6 }}>{m.checkers}</div>
              <div style={{ fontSize: 11, color: '#888' }}>{m.note}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Trust */}
      <div style={S.section}>
        <div style={S.trustGrid}>
          {[
            { icon: '🔒', title: 'Privacy first', desc: 'Toxicity and bias analysis runs entirely on our servers. No content is sent to third parties for Signal analysis.' },
            { icon: '⛓️', title: 'Blockchain verified', desc: 'Every analysis is timestamped with a SHA-256 hash. OpenTimestamps anchoring provides tamper-proof evidence.' },
            { icon: '🚫', title: 'No verdicts', desc: 'Dissekt never says "true" or "false." It explains HOW content is constructed to manipulate — the journalist decides what to believe.' },
          ].map((t, i) => (
            <div key={i} style={S.trustCard}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>{t.icon}</div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{t.title}</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.6 }}>{t.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '0 24px' }}>
        <div style={S.ctaSection}>
          <div style={S.ctaTitle}>Start analyzing content for free</div>
          <div style={S.ctaSub}>No credit card required · 10 free scans per day · Works with any URL or text</div>
          <button onClick={onSignIn} style={S.ctaBtn}>
            Create free account
          </button>
        </div>
      </div>

      {/* Footer */}
      <div style={S.footer}>
        <span style={{ fontWeight: 600, color: '#555' }}>Dissekt</span>
        <span style={{ margin: '0 8px' }}>·</span>
        Built for journalists
        <span style={{ margin: '0 8px' }}>·</span>
        <a href="mailto:sambit@dissekt.info" style={{ color: '#7c3aed', textDecoration: 'none' }}>sambit@dissekt.info</a>
        <span style={{ margin: '0 8px' }}>·</span>
        Munich, Germany · 2026
      </div>
    </div>
  );
}
LANDEOF

# ============================================
# Updated page.tsx — landing + auth + scan
# ============================================
cat > src/app/page.tsx << 'PAGEEOF'
'use client';
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';
import LandingPage from '@/components/LandingPage';
import AuthGate from '@/components/AuthGate';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';
import { getDailyUsage, logScan } from '@/lib/auth';

const DAILY_LIMIT = 10;

function ScanPage() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [usage, setUsage] = useState(0);
  const [userEmail, setUserEmail] = useState('');

  useEffect(() => {
    getDailyUsage().then(setUsage);
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) setUserEmail(user.email || '');
    });
  }, []);

  const handleScan = async (content: string, mode: string) => {
    if (usage >= DAILY_LIMIT) {
      setError(`Daily limit reached (${DAILY_LIMIT}/day). Resets at midnight UTC.`);
      return;
    }
    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });
      if (!res.ok) { const err = await res.json(); setError(err.detail || 'Analysis failed'); return; }
      const data = await res.json();
      setResult(data);
      setUsage(prev => prev + 1);
      await logScan({
        content_preview: content.slice(0, 100),
        mode,
        threat_score: 0,
        techniques_count: data.prism?.techniques?.length || 0,
        analysis_time_ms: data.analysis_time_ms || 0,
      });
    } catch (e) { setError('Could not connect to analysis service.'); }
    finally { setLoading(false); }
  };

  const handleSignOut = async () => { await supabase.auth.signOut(); };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <span style={{ fontSize: 12, color: '#888' }}>{usage}/{DAILY_LIMIT} scans today</span>
            <span style={{ fontSize: 12, color: '#aaa' }}>{userEmail}</span>
            <button onClick={handleSignOut} style={{ fontSize: 12, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>Sign out</button>
          </div>
        </div>
      </nav>
      <div style={{ background: '#fff', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px 24px' }}>
          <ScanInput onScan={handleScan} loading={loading} />
        </div>
      </div>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 24px' }}>
        {error && (
          <div style={{ marginBottom: 16, padding: 14, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>
        )}
        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
        {!result && !loading && !error && (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div style={{ width: 48, height: 48, margin: '0 auto 12px', background: '#f0f0ee', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <div style={{ fontSize: 15, fontWeight: 500, color: '#404040', marginBottom: 4 }}>Paste a URL or text to begin</div>
            <div style={{ fontSize: 13, color: '#aaa', maxWidth: 360, margin: '0 auto' }}>
              Dissekt detects manipulation techniques, finds existing fact-checks, and assesses source credibility — in seconds.
            </div>
          </div>
        )}
      </div>
    </main>
  );
}

export default function Home() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [showAuth, setShowAuth] = useState(false);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUser(user);
      setLoading(false);
    });
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) setShowAuth(false);
    });
    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return <div style={{ minHeight: '100vh', background: '#f5f5f4', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888' }}>Loading...</div>;
  }

  // Not logged in: show landing page or auth
  if (!user) {
    if (showAuth) {
      return <AuthGate><ScanPage /></AuthGate>;
    }
    return <LandingPage onSignIn={() => setShowAuth(true)} />;
  }

  // Logged in: show scan dashboard
  return <ScanPage />;
}
PAGEEOF

echo ""
echo "✅ Concept D landing page applied"
echo ""
echo "Flow:"
echo "  1. Not logged in → sees full landing page with product info"
echo "  2. Clicks 'Try it free' or 'Sign in' → auth screen"
echo "  3. After login → scan dashboard"
echo ""
echo "Run: npm run dev (or vercel --prod to deploy)"
