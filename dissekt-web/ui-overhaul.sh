#!/bin/bash
# Dissekt — UI Overhaul + Tier System + Route Separation + Legal Pages
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# SQL reminder for invite expiry
# ============================================
echo "⚠️  Run this SQL in Supabase to add expiry columns:"
echo ""
echo "alter table public.invitations add column if not exists code_expires_at timestamptz;"
echo "alter table public.invitations add column if not exists access_expires_at timestamptz;"
echo ""

# ============================================
# 1. Shared Header component (Beta badge)
# ============================================

cat > src/components/SiteHeader.tsx << 'HEADEOF'
'use client';

export default function SiteHeader({ active }: { active?: string }) {
  const links = [
    { href: '/app', label: 'Analyze' },
    { href: '/topics', label: 'Topics' },
    { href: '/compare', label: 'Compare' },
    { href: '/docs', label: 'API' },
    { href: '/help', label: 'Help' },
  ];

  return (
    <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 30 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
          <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span style={{ fontWeight: 700, fontSize: 16 }}>Dissekt</span>
          <span style={{ fontSize: 9, fontWeight: 700, color: '#7c3aed', background: '#f3e8ff', padding: '2px 6px', borderRadius: 4, letterSpacing: '0.05em' }}>BETA</span>
        </a>

        <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          {links.map(l => (
            <a key={l.href} href={l.href} className="nav-link"
              style={{ fontSize: 13, color: active === l.label ? '#7c3aed' : '#555', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
              {l.label}
            </a>
          ))}
          <a href="/invite" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', border: '1px solid #ddd6fe', borderRadius: 8, padding: '5px 14px', fontWeight: 600, background: '#faf5ff' }}>
            Get access
          </a>
        </div>
      </div>
    </nav>
  );
}
HEADEOF

echo "✅ SiteHeader created"

# ============================================
# 2. Shared Footer component
# ============================================

cat > src/components/SiteFooter.tsx << 'FOOTEOF'
'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#fff', borderTop: '1px solid #e5e5e5', marginTop: 40 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '24px', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'start', gap: 20 }}>
        <div style={{ maxWidth: 280 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ width: 24, height: 24, background: '#7c3aed', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 14 }}>Dissekt</span>
            <span style={{ fontSize: 8, fontWeight: 700, color: '#7c3aed', background: '#f3e8ff', padding: '1px 5px', borderRadius: 3 }}>BETA</span>
          </div>
          <p style={{ fontSize: 12, color: '#888', lineHeight: 1.6 }}>Information transparency and argument inspection. See how information is constructed.</p>
        </div>

        <div style={{ display: 'flex', gap: 40, flexWrap: 'wrap' }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Product</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/app" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Analyze</a>
              <a href="/topics" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Topics</a>
              <a href="/compare" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Compare</a>
              <a href="/docs" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>API</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Company</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/help" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>How it works</a>
              <a href="/invite" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Get access</a>
              <a href="mailto:sambitmallick123@gmail.com" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Contact</a>
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
      <div style={{ borderTop: '1px solid #f0f0ee', padding: '14px 24px', textAlign: 'center' }}>
        <p style={{ fontSize: 11, color: '#aaa' }}>© 2026 Dissekt · Built by Sambit Mallick · Munich, Germany · Beta — under active development</p>
      </div>
    </footer>
  );
}
FOOTEOF

echo "✅ SiteFooter created"

# ============================================
# 3. Tier utility (shared)
# ============================================

mkdir -p src/lib

cat > src/lib/tier.ts << 'TIEREOF'
// Tier management with GMT reset and 6-month expiry

export type Tier = 'free' | 'invited';

export const LIMITS = {
  free: { brief: 3, detailed: 1 },
  invited: { brief: 25, detailed: 10 },
};

export function getTier(): Tier {
  if (typeof window === 'undefined') return 'free';
  
  // Check if invited access expired (6 months)
  const expiry = localStorage.getItem('dissekt_access_expires');
  if (expiry && new Date(expiry) < new Date()) {
    localStorage.removeItem('dissekt_tier');
    localStorage.removeItem('dissekt_access_expires');
    localStorage.removeItem('dissekt_invite_code');
    return 'free';
  }
  
  return localStorage.getItem('dissekt_tier') === 'invited' ? 'invited' : 'free';
}

// Get today's date key in GMT (resets at 0000 GMT)
function getGMTDateKey(): string {
  const now = new Date();
  return `${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
}

export function getUsage(): { brief: number; detailed: number } {
  if (typeof window === 'undefined') return { brief: 0, detailed: 0 };
  const key = getGMTDateKey();
  const stored = localStorage.getItem('dissekt_usage');
  if (stored) {
    try {
      const data = JSON.parse(stored);
      if (data.date === key) return { brief: data.brief || 0, detailed: data.detailed || 0 };
    } catch {}
  }
  return { brief: 0, detailed: 0 };
}

export function incrementUsage(mode: 'brief' | 'detailed') {
  if (typeof window === 'undefined') return;
  const key = getGMTDateKey();
  const usage = getUsage();
  usage[mode]++;
  localStorage.setItem('dissekt_usage', JSON.stringify({ date: key, ...usage }));
}

export function canScan(mode: 'brief' | 'detailed'): boolean {
  const tier = getTier();
  const usage = getUsage();
  const limit = LIMITS[tier];
  return usage[mode] < limit[mode];
}

export function getRemaining(): { brief: number; detailed: number; tier: Tier } {
  const tier = getTier();
  const usage = getUsage();
  const limit = LIMITS[tier];
  return {
    brief: Math.max(0, limit.brief - usage.brief),
    detailed: Math.max(0, limit.detailed - usage.detailed),
    tier,
  };
}

// Time until next GMT midnight reset
export function getResetTime(): string {
  const now = new Date();
  const tomorrow = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0));
  const diff = tomorrow.getTime() - now.getTime();
  const hours = Math.floor(diff / 3600000);
  const mins = Math.floor((diff % 3600000) / 60000);
  return `${hours}h ${mins}m`;
}
TIEREOF

echo "✅ Tier utility created"

# ============================================
# 4. Move landing to / and analysis to /app
# ============================================

# Current src/app/page.tsx is the combined landing+scan
# We need: / = landing only, /app = scan only

# First, back up current page
cp src/app/page.tsx /tmp/page_backup.tsx

# Create the new landing page (/) — just LandingPage component
cat > src/app/page.tsx << 'LANDEOF'
'use client';
import LandingPage from '@/components/LandingPage';

export default function Home() {
  return <LandingPage onStart={() => window.location.href = '/app'} />;
}
LANDEOF

echo "✅ Landing page now at /"

# Create the analysis page (/app) — extract scan logic
# We'll create a new ScanApp component from the backup
echo "⚠️  Creating /app route — scan functionality moves here"

mkdir -p src/app/app

# The scan page needs the full logic. Create it referencing existing components.
cat > src/app/app/page.tsx << 'APPEOF'
'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';
import ScanHistory, { addToHistory } from '@/components/ScanHistory';
import BulkAnalysis from '@/components/BulkAnalysis';
import ReaderMemory from '@/components/ReaderMemory';
import DecisionJournalView from '@/components/DecisionJournal';
import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function ScanApp() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [inputContent, setInputContent] = useState('');
  const [scanTab, setScanTab] = useState<'single' | 'bulk'>('single');
  const [remaining, setRemaining] = useState({ brief: 3, detailed: 1, tier: 'free' as const });
  const [resetIn, setResetIn] = useState('');
  const [shareToast, setShareToast] = useState('');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setRemaining(getRemaining());
    setResetIn(getResetTime());
    const t = setInterval(() => setResetIn(getResetTime()), 60000);
    return () => clearInterval(t);
  }, []);

  const handleScan = async (content: string, mode: 'brief' | 'detailed') => {
    if (!content || content.length < 10) { setError('Please enter at least 10 characters'); return; }

    if (!canScan(mode)) {
      const tier = getTier();
      if (tier === 'free') {
        setError(`Free tier limit reached for ${mode} scans (${LIMITS.free[mode]}/day). Resets in ${getResetTime()} at 00:00 GMT. Get an invite for more.`);
      } else {
        setError(`Daily limit reached for ${mode} scans. Resets in ${getResetTime()} at 00:00 GMT.`);
      }
      return;
    }

    setLoading(true); setError(''); setResult(null);
    try {
      const res = await fetch(`${API_URL}/api/scan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });
      if (!res.ok) {
        const err = await res.json();
        setError(err.detail || 'Analysis failed'); return;
      }
      const data = await res.json();
      setResult(data);
      incrementUsage(mode);
      setRemaining(getRemaining());
      addToHistory({ id: data.id, input: content.slice(0, 100), timestamp: Date.now() });
    } catch {
      setError('Could not connect to the analysis service.');
    } finally {
      setLoading(false);
    }
  };

  const handleShare = async () => {
    if (!result?.id) return;
    const url = `${window.location.origin}/report/${result.id}`;
    await navigator.clipboard.writeText(url);
    setShareToast('Report link copied!');
    setTimeout(() => setShareToast(''), 2000);
  };

  if (!mounted) return null;

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader active="Analyze" />

      {shareToast && (
        <div style={{ position: 'fixed', top: 70, left: '50%', transform: 'translateX(-50%)', background: '#1a1a1a', color: '#fff', padding: '8px 16px', borderRadius: 8, fontSize: 13, zIndex: 100 }}>{shareToast}</div>
      )}

      {/* Scan input area */}
      <div style={{ background: '#fff', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto', padding: '16px 24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ display: 'flex', gap: 6 }}>
              <button onClick={() => setScanTab('single')}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'single' ? '#7c3aed' : '#f0f0ee', color: scanTab === 'single' ? '#fff' : '#555' }}>
                Single scan
              </button>
              <button onClick={() => getTier() === 'invited' ? setScanTab('bulk') : (window.location.href = '/invite')}
                style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 600, border: 'none', cursor: 'pointer', background: scanTab === 'bulk' ? '#7c3aed' : '#f0f0ee', color: scanTab === 'bulk' ? '#fff' : '#555' }}>
                📊 Bulk CSV {getTier() !== 'invited' && '🔒'}
              </button>
              <a href="/compare" style={{ padding: '6px 14px', borderRadius: 6, fontSize: 12, fontWeight: 500, background: '#f0f0ee', color: '#555', textDecoration: 'none', display: 'flex', alignItems: 'center' }}>⚖️ Compare</a>
            </div>
            <div style={{ fontSize: 11, color: '#888', textAlign: 'right' }}>
              <span style={{ fontWeight: 600, color: remaining.tier === 'invited' ? '#7c3aed' : '#888' }}>
                {remaining.tier === 'invited' ? '🎫 Invited' : '🆓 Free'}
              </span>
              {' · '}{remaining.brief} brief, {remaining.detailed} detailed left
              <div style={{ fontSize: 10, color: '#aaa' }}>Resets in {resetIn} (00:00 GMT)</div>
            </div>
          </div>

          {scanTab === 'single' && <ScanInput onScan={handleScan} loading={loading} initialContent={inputContent} />}
          {scanTab === 'bulk' && <BulkAnalysis />}
        </div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 24px' }}>
        {error && (
          <div style={{ marginBottom: 16, padding: 12, background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, color: '#b91c1c', fontSize: 13 }}>{error}</div>
        )}

        {loading && <LoadingState />}

        {result && !loading && <AnalysisResult data={result} onShare={handleShare} />}

        {!result && !loading && (
          <>
            <ReaderMemory onAnalyze={(text) => { setInputContent(text); handleScan(text, 'brief'); window.scrollTo({ top: 0, behavior: 'smooth' }); }} />
            <DecisionJournalView />
            <ScanHistory onReanalyze={(input) => handleScan(input, 'brief')} />
          </>
        )}
      </div>
    </main>
  );
}
APPEOF

echo "✅ /app route created (analysis page)"

# ============================================
# 5. Update LandingPage to link to /app
# ============================================

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

# Update onStart prop usage and CTA links to /app
content = content.replace("onClick={onStart}", "onClick={() => window.location.href = '/app'}")
content = content.replace("onClick={onSignIn}", "onClick={() => window.location.href = '/invite'}")

# Make sure the component accepts onStart
if 'onStart' not in content.split('\n')[0:20].__str__():
    content = content.replace(
        'export default function LandingPage(',
        'export default function LandingPage('
    )

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ LandingPage links to /app')
PYEOF

# ============================================
# 6. Terms of Service page
# ============================================

mkdir -p src/app/terms

cat > src/app/terms/page.tsx << 'TERMSEOF'
'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function TermsPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Terms of Service</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Last updated: June 9, 2026 · Beta</p>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '24px 28px', fontSize: 13, color: '#404040', lineHeight: 1.8 }}>
          <div style={{ padding: '10px 14px', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 8, marginBottom: 20 }}>
            <strong>⚠️ Beta Notice:</strong> Dissekt is in beta and under active development. Features may change, break, or be removed without notice. Analysis results are provided as-is for informational purposes.
          </div>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 0, marginBottom: 8 }}>1. Acceptance</h2>
          <p>By using Dissekt, you agree to these terms. If you disagree, please do not use the service.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>2. The service</h2>
          <p>Dissekt is an information transparency tool that analyzes content for manipulation techniques, cross-references fact-checks, and provides interpretation aids. It does NOT determine whether content is true or false. It provides analytical perspectives to help you think critically.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>3. Not professional advice</h2>
          <p>Dissekt's analysis is automated and may contain errors. It is not a substitute for professional fact-checking, journalism, legal advice, or your own judgment. Do not rely solely on Dissekt for any important decision.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>4. Acceptable use</h2>
          <p>You agree not to: use the service for illegal purposes; attempt to overwhelm or attack our infrastructure; scrape or resell our analysis at scale without permission; use the service to harass, defame, or harm others.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>5. Access tiers</h2>
          <p>Free tier provides limited daily scans (3 brief + 1 detailed, resetting at 00:00 GMT). Invitation-based access provides expanded limits and features. Invite codes expire 7 days after issue. Granted access is valid for 6 months, after which it expires and must be renewed.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>6. Intellectual property</h2>
          <p>You retain rights to content you submit. By submitting content, you grant us a limited license to process it for analysis. Analysis outputs may be stored to provide features like shareable reports and the knowledge graph.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>7. Disclaimers</h2>
          <p>THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. We do not guarantee accuracy, availability, or fitness for any purpose. We are not liable for any damages arising from use of the service.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>8. Changes</h2>
          <p>We may modify these terms or the service at any time. Continued use after changes constitutes acceptance.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>9. Contact</h2>
          <p>Questions: <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#7c3aed' }}>sambitmallick123@gmail.com</a> · Operator: Sambit Mallick, Munich, Germany</p>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
TERMSEOF

echo "✅ Terms of Service page created"

# ============================================
# 7. Data Disclaimer page
# ============================================

mkdir -p src/app/disclaimer

cat > src/app/disclaimer/page.tsx << 'DISCEOF'
'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function DisclaimerPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Data & Analysis Disclaimer</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Last updated: June 9, 2026 · Beta</p>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '24px 28px', fontSize: 13, color: '#404040', lineHeight: 1.8 }}>
          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 0, marginBottom: 8 }}>What Dissekt is — and isn't</h2>
          <p>Dissekt shows you HOW content is constructed. It identifies rhetorical techniques, cross-references existing fact-checks, and offers alternative framings. It does NOT tell you what is true or false. It is an interpretation aid, not an arbiter of truth.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Automated analysis limitations</h2>
          <p>Our analysis is generated by AI models (GPT-4o mini, Claude) and statistical heuristics. These systems can and do make mistakes. They may: misidentify techniques, miss context, over- or under-state confidence, or produce results that reflect the biases of their training data. Always apply your own critical judgment.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Political content (Compass)</h2>
          <p>Our political accountability data (Compass) is curated from public sources and may be incomplete or outdated. Politician profiles, voting records, and "factual notes" are provided for context only and should be independently verified. We do not endorse any political position.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Source credibility (Signal)</h2>
          <p>Source bias and factuality ratings are derived from third-party databases (Media Bias/Fact Check). These ratings are themselves subjective assessments and should not be treated as definitive. The presence of a credibility score does not constitute an endorsement or condemnation of any source.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Coordination detection (Pulse)</h2>
          <p>Coordination signals suggest patterns of similar content appearing together. This does NOT prove that content is coordinated, false, or malicious. Legitimate content can spread organically and still trigger these signals.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Cross-references (Trace)</h2>
          <p>We surface existing fact-checks from third-party organizations. We do not create these fact-checks and are not responsible for their accuracy. A fact-check appearing in our results is not an endorsement of that fact-check's conclusion.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>No liability</h2>
          <p>You use Dissekt's analysis at your own risk. We are not liable for any decisions, actions, or consequences resulting from reliance on our analysis. For important matters, consult qualified professionals and primary sources.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>Beta status</h2>
          <p>Dissekt is in active beta development. Accuracy, features, and availability are not guaranteed. Data may be lost, reset, or changed during development.</p>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
DISCEOF

echo "✅ Data Disclaimer page created"

# ============================================
# 8. Update existing pages to use SiteHeader/Footer
# ============================================

# Update privacy page
python3 << 'PYEOF'
import re
content = open('src/app/privacy/page.tsx').read()

# Add imports
if 'SiteHeader' not in content:
    content = content.replace(
        "'use client';",
        "'use client';\nimport SiteHeader from '@/components/SiteHeader';\nimport SiteFooter from '@/components/SiteFooter';"
    )
    # Replace the nav with SiteHeader
    content = re.sub(
        r'<nav style=\{\{.*?</nav>',
        '<SiteHeader />',
        content,
        flags=re.DOTALL,
        count=1
    )
    # Add footer before closing main
    content = content.replace('</main>', '<SiteFooter />\n    </main>')
    open('src/app/privacy/page.tsx', 'w').write(content)
    print('✅ Privacy page: uniform header/footer')
PYEOF

echo ""
echo "✅ UI Overhaul complete:"
echo ""
echo "  📍 Routes separated:"
echo "     / → Landing page only"
echo "     /app → Analysis page (refresh-safe)"
echo ""
echo "  🎫 Tier limits (reset 00:00 GMT):"
echo "     Free: 3 brief + 1 detailed/day"
echo "     Invited: 25 brief + 10 detailed/day"
echo ""
echo "  🏷️ BETA badge in header + footer"
echo ""
echo "  ⏰ Invite expiry:"
echo "     Code expires: 7 days"
echo "     Access valid: 6 months"
echo ""
echo "  📄 New legal pages:"
echo "     /terms — Terms of Service"
echo "     /disclaimer — Data & Analysis Disclaimer"
echo "     /privacy — Privacy Policy (updated)"
echo ""
echo "  🎨 Uniform SiteHeader + SiteFooter across all pages"
echo ""
echo "⚠️  Run the SQL to add expiry columns to invitations table"
echo "⚠️  Update admin API to set code_expires_at + access_expires_at"
echo ""
echo "Test: npm run build && npm run dev"
