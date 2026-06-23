'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

// ── Checklist data ──────────────────────────────────────────────
const CHECKLIST: { section: string; items: { id: string; label: string; note?: string }[] }[] = [
  {
    section: 'A · Access & first impressions',
    items: [
      { id: 'a1', label: 'Opened the portal', note: 'Landing page loads, clear what Dissekt does' },
      { id: 'a2', label: 'Understood the value in under 30s', note: 'Hero + sample report make the purpose clear' },
      { id: 'a3', label: 'Ran a scan without an account' },
      { id: 'a4', label: 'Created a free account', note: 'Email sign-up, raised limits unlocked' },
    ],
  },
  {
    section: 'B · Single scan — the core loop',
    items: [
      { id: 'b1', label: 'Scanned a URL', note: 'Article fetched & extracted automatically' },
      { id: 'b2', label: 'Scanned pasted text' },
      { id: 'b3', label: 'Tried Brief vs Detailed', note: 'Noticed the difference in depth' },
      { id: 'b4', label: 'Clarity Score believable', note: 'Matches your own read of the content' },
      { id: 'b5', label: 'Three dimensions make sense', note: 'Construction / Verification / Intent' },
    ],
  },
  {
    section: 'C · Analysis components',
    items: [
      { id: 'c1', label: 'Prism — techniques are fair & useful; evidence shown' },
      { id: 'c2', label: 'Lens — fact-checks found; verdicts link out; spread timeline' },
      { id: 'c3', label: 'Spectrum — credibility / bias / toxicity look right' },
      { id: 'c4', label: 'Facet — claims extracted' },
      { id: 'c5', label: 'Meridian — political context (when relevant)' },
      { id: 'c6', label: 'Result layout — readable, nothing overflows or breaks' },
    ],
  },
  {
    section: 'D · Keyword topic analysis',
    items: [
      { id: 'd1', label: 'Added keywords & suggestions' },
      { id: 'd2', label: 'Coverage report makes sense', note: 'Avg clarity, dominant techniques, summary line' },
      { id: 'd3', label: 'Source links open the original article' },
    ],
  },
  {
    section: 'E · Dashboard',
    items: [
      { id: 'e1', label: 'Logged Trust / Unsure / Reject on a result' },
      { id: 'e2', label: 'Overview profile builds', note: 'Reflect + reader profile reflect your decisions' },
      { id: 'e3', label: 'Ledger shows decisions, with a working Rescan' },
      { id: 'e4', label: 'Past scans + Rescan' },
      { id: 'e5', label: 'API key — generate & test', note: 'Optional; technical reviewers' },
    ],
  },
  {
    section: 'F · Observatory',
    items: [
      { id: 'f1', label: 'Constellation graph renders', note: 'Builds up as you scan more' },
      { id: 'f2', label: 'Useful for your work?' },
    ],
  },
  {
    section: 'G · Help & language',
    items: [
      { id: 'g1', label: 'Help page answered your questions' },
      { id: 'g2', label: 'Terminology was clear', note: 'Any term you had to guess at? Note it in your feedback' },
    ],
  },
];

const OPEN_QUESTIONS = [
  'Would you actually use this in your work? Why / why not?',
  'Single most confusing thing?',
  "What's missing that you'd need?",
  'Did you trust the analysis? Where did it lose you?',
  'One thing you would change first.',
];

const STORAGE_KEY = 'dissekt_review_checklist';
const teal = '#0d9488';

// ── Helpers ─────────────────────────────────────────────────────
const H = ({ id, children }: { id?: string; children: React.ReactNode }) => (
  <h2 id={id} style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', margin: '30px 0 10px', scrollMarginTop: 70, fontFamily: 'Charter, Georgia, serif' }}>{children}</h2>
);
const P = ({ children }: { children: React.ReactNode }) => (
  <p style={{ fontSize: 14, color: '#404040', lineHeight: 1.75, margin: '0 0 12px' }}>{children}</p>
);
const Tip = ({ children }: { children: React.ReactNode }) => (
  <div style={{ fontSize: 13, color: '#0f6e56', background: '#f0fdfa', border: '0.5px solid #cce9e3', borderRadius: 8, padding: '10px 14px', margin: '0 0 12px' }}>{children}</div>
);
const Card = ({ title, sub, children }: { title: string; sub?: string; children: React.ReactNode }) => (
  <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, padding: 14 }}>
    {sub && <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: teal, marginBottom: 3 }}>{sub}</div>}
    <div style={{ fontSize: 14, fontWeight: 700, color: '#1a1a1a', marginBottom: 3 }}>{title}</div>
    <div style={{ fontSize: 12.5, color: '#666', lineHeight: 1.6 }}>{children}</div>
  </div>
);
const Metric = ({ name, children }: { name: string; children: React.ReactNode }) => (
  <div style={{ marginBottom: 6 }}>
    <span style={{ fontSize: 12.5, fontWeight: 600, color: '#1a1a1a' }}>{name}</span>
    <span style={{ fontSize: 12.5, color: '#666' }}> — {children}</span>
  </div>
);

export default function ReviewPage() {
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    try { const raw = localStorage.getItem(STORAGE_KEY); if (raw) setChecked(JSON.parse(raw)); } catch {}
  }, []);

  const toggle = (id: string) => {
    setChecked(prev => {
      const next = { ...prev, [id]: !prev[id] };
      try { localStorage.setItem(STORAGE_KEY, JSON.stringify(next)); } catch {}
      return next;
    });
  };
  const reset = () => { setChecked({}); try { localStorage.removeItem(STORAGE_KEY); } catch {} };

  const totalItems = CHECKLIST.reduce((n, s) => n + s.items.length, 0);
  const doneItems = Object.values(checked).filter(Boolean).length;
  const pct = totalItems ? Math.round((doneItems / totalItems) * 100) : 0;

  const grid2: React.CSSProperties = { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 10, margin: '6px 0 12px' };
  const grid3: React.CSSProperties = { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, margin: '6px 0 12px' };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />

      {/* Hero */}
      <div style={{ background: 'linear-gradient(135deg, #0d9488, #0b6e62)', color: '#fff' }}>
        <div style={{ maxWidth: 820, margin: '0 auto', padding: '40px 16px 34px' }}>
          <div style={{ display: 'inline-block', background: 'rgba(255,255,255,0.18)', borderRadius: 20, padding: '3px 14px', fontSize: 11, letterSpacing: '0.05em', textTransform: 'uppercase', marginBottom: 12 }}>Beta · Reviewer hub</div>
          <h1 style={{ fontSize: 30, fontWeight: 700, margin: '0 0 10px', fontFamily: 'Charter, Georgia, serif' }}>Review Dissekt</h1>
          <p style={{ fontSize: 16, lineHeight: 1.6, margin: '0 0 18px', color: 'rgba(255,255,255,0.92)', maxWidth: 560 }}>
            Thanks for helping shape Dissekt. This page is your guide and checklist — what it does, how the score works, and how to send feedback that moves the product.
          </p>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <a href="/analyze" style={{ padding: '10px 22px', background: '#fff', color: teal, borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Start a scan</a>
            <a href="/contact?mode=feedback" style={{ padding: '10px 22px', background: 'rgba(255,255,255,0.15)', color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none', border: '0.5px solid rgba(255,255,255,0.4)' }}>Give feedback →</a>
          </div>
        </div>
      </div>

      <div style={{ maxWidth: 820, margin: '0 auto', padding: '28px 16px 48px' }}>

        {/* ── GUIDE ── */}
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: '8px 28px 28px' }}>
          <H id="what">What it is</H>
          <P>Dissekt is a web tool for journalists and researchers. Paste a URL or text, and it returns a structured analysis of how that content is <em>constructed</em> — manipulation techniques, existing fact-checks, source credibility, and missing context.</P>
          <div style={{ background: '#fafaf8', borderLeft: `3px solid ${teal}`, borderRadius: 8, padding: '11px 15px', margin: '8px 0 12px', fontSize: 13.5, lineHeight: 1.7, color: '#404040' }}>
            <strong>It does not tell you whether something is true or false.</strong> It shows <em>how</em> a piece is built and argued, cross-references existing fact-checks, and scores source credibility — the judgment stays with you. The score is about transparency of construction, not truth.
          </div>
          <Tip><strong>In one line:</strong> Paste any article, URL, or social post → a transparency report in seconds.</Tip>

          <H id="who">Who it&apos;s for</H>
          <div style={grid2}>
            <Card title="📰 Journalists">Check a claim before filing, see how a source frames a story, cross-reference fact-checks.</Card>
            <Card title="🎓 Researchers">Systematic framing analysis across sources, with credibility data and API access.</Card>
            <Card title="👩‍🏫 Editors & educators">Show how framing works and build media literacy.</Card>
            <Card title="🎯 This round">We most want feedback from working journalists and fact-checkers.</Card>
          </div>

          <H id="access">Getting access</H>
          <P>Run a few scans with <strong>no account</strong> (3 brief + 1 detailed/day) to get a feel. For the full review, <strong>create a free account</strong> (email) → 25 brief + 10 detailed/day, plus Dashboard, Observatory, and API access. Limits reset at 00:00 GMT; brief and detailed are counted separately.</P>

          <H id="workflow">Core workflow — single scan</H>
          <P>Go to <strong>Analyze → Single scan</strong>, paste text or a URL (or attach an image), choose <strong>Brief</strong> (fast) or <strong>Detailed</strong> (deeper), and read the Clarity Score, techniques, cross-references, and source credibility.</P>
          <Tip><strong>If a URL fails to load:</strong> some sites block automated access or are paywalled — paste the text directly instead.</Tip>

          <H id="score">The Clarity Score, at a glance</H>
          <P>Every scan gives a <strong>Clarity Score from 0.00 to 1.00</strong> — how transparently the content is constructed. Higher = clearer; lower = more manipulation, weaker sourcing, or persuasive intent.</P>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 8, margin: '6px 0 12px' }}>
            {[
              { n: 'High', r: '0.65–1.00', d: 'Transparently constructed', c: '#16a34a' },
              { n: 'Moderate', r: '0.35–0.64', d: 'Mixed signals', c: '#d97706' },
              { n: 'Low', r: '0.00–0.34', d: 'Heavily constructed', c: '#dc2626' },
            ].map(b => (
              <div key={b.n} style={{ background: b.c, color: '#fff', borderRadius: 8, padding: '9px 12px' }}>
                <div style={{ fontWeight: 700, fontSize: 14 }}>{b.n} <span style={{ fontSize: 11, fontWeight: 400, opacity: 0.9 }}>{b.r}</span></div>
                <div style={{ fontSize: 11, marginTop: 2, opacity: 0.95 }}>{b.d}</div>
              </div>
            ))}
          </div>
          <Tip>A high score is not an endorsement and a low score is not a debunk. Read the dimensions — a low score from Intent (manipulation) means something different than one from Verification (weak sourcing).</Tip>

          {/* ── HOW THE SCORE IS CALCULATED ── */}
          <H id="howscore">How the score is calculated</H>
          <P>The Clarity Score is the <strong>geometric mean of three dimensions</strong>. Geometric mean (rather than a plain average) means a serious weakness in any one dimension pulls the whole score down — you can&apos;t average a red flag away.</P>
          <div style={{ textAlign: 'center', background: '#1a1a1a', color: '#5eead4', borderRadius: 8, padding: '12px 14px', fontFamily: 'monospace', fontSize: 13, margin: '6px 0 14px' }}>
            Clarity = ( Construction × Verification × Intent ) <sup>1/3</sup>
          </div>
          <P>Each dimension is itself built from several metrics, also combined as a weighted geometric mean:</P>

          <div style={grid3}>
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, borderTop: '3px solid #dc2626', padding: 14 }}>
              <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#dc2626', marginBottom: 2 }}>How is it built?</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', marginBottom: 8 }}>Construction</div>
              <Metric name="Rhetoric">manipulation techniques detected, weighted by severity (a straw man counts more than loaded language) and confidence.</Metric>
              <Metric name="Argumentation">are claims backed by evidence, is the reasoning coherent (few fallacies), is there a real conclusion.</Metric>
              <Metric name="Completeness">does it cover who / what / when, cite sources, and include a counter-view.</Metric>
            </div>
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, borderTop: '3px solid #2563eb', padding: 14 }}>
              <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#2563eb', marginBottom: 2 }}>How supported?</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', marginBottom: 8 }}>Verification</div>
              <Metric name="Evidence">existing fact-checks (Lens), weighted by the checker&apos;s tier and verdict.</Metric>
              <Metric name="Source">credibility / factuality of the outlet, from the media database (Spectrum).</Metric>
              <Metric name="Diversity">range of sources cited — named vs. anonymous, how many distinct types.</Metric>
              <Metric name="Temporal">consistency over time (builds as your scan history grows).</Metric>
            </div>
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10, borderTop: '3px solid #d97706', padding: 14 }}>
              <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#d97706', marginBottom: 2 }}>What does it want?</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', marginBottom: 8 }}>Intent</div>
              <Metric name="Tone">toxicity &amp; hostility, adjusted for genre and discounting hostile words inside quotes.</Metric>
              <Metric name="Manipulation">urgency, calls to action, emotional escalation, us-vs-them framing.</Metric>
              <Metric name="Narrative">how hard it pushes a hopeful/fearful or trusting/skeptical frame.</Metric>
            </div>
          </div>

          <div style={{ background: '#eff6ff', border: '0.5px solid #c7ddff', borderRadius: 8, padding: '11px 15px', margin: '6px 0 12px', fontSize: 13, lineHeight: 1.7, color: '#1e477e' }}>
            <strong>Coverage / confidence.</strong> The score also reports how much <em>real evidence</em> backed it. When there are no fact-checks, no known source rating, no techniques, or very little text, the result leans mostly on text-pattern heuristics — it&apos;s flagged as <strong>limited signal</strong>. A confident-looking number isn&apos;t the same as a well-evidenced one, so weight low-coverage scores accordingly. <strong>Missing signals are excluded, not guessed at</strong> — an unknown source doesn&apos;t quietly drag the score to neutral; that axis simply drops out and the rest are reweighted.
          </div>
          <Tip><strong>What we&apos;d love you to test:</strong> scan content you know well and tell us where the score disagrees with your own read. Those disagreements are how we calibrate the weights — your judgment is the ground truth we don&apos;t have yet.</Tip>

          <H id="result">What&apos;s in a result</H>
          <div style={grid2}>
            <Card title="Prism" sub="Techniques">Manipulation techniques, each with confidence and the triggering text.</Card>
            <Card title="Lens" sub="Cross-references">Existing fact-checks + where the content appeared. Verdicts link to the checker.</Card>
            <Card title="Spectrum" sub="Source & tone">Credibility / bias (231-source database), toxicity, sentiment.</Card>
            <Card title="Facet" sub="Claims">Extracts individual verifiable claims for separate checking.</Card>
            <Card title="Meridian" sub="Political context">Surfaces political / accountability context where relevant.</Card>
            <Card title="Metadata">Time, model, cache status, content hash — identifiable & tamper-evident.</Card>
          </div>

          <H id="more">Other features to try</H>
          <P><strong>Keyword topic analysis</strong> — analyze how a whole topic is covered now. Add 2–3 related keywords → recent articles are fetched, analyzed, and aggregated, with each source linking to the original.</P>
          <div style={grid2}>
            <Card title="📊 Dashboard">Reading profile + decision stats, Reflect, Ledger (logged Trust/Unsure/Reject), and past scans — each with a Rescan action. Plus API keys.</Card>
            <Card title="✦ Observatory">Patterns across everything you&apos;ve analyzed, centered on Constellation — a knowledge graph of entities and how they connect.</Card>
          </div>

          <H id="limits">Known limitations</H>
          <Tip><strong>Already known — skip these unless you feel strongly:</strong> some sites block fetching (noted &amp; excluded) · toxicity is usually ~0% for professional news (expected) · fact-checks appear only if checkers covered the claim · the text-pattern metrics are tuned for English, so non-English scans lean lower-confidence · graph/history features need a few scans to fill in.</Tip>
          <P>What we want your eyes on: <strong>does the core analysis land?</strong> Is the Clarity Score believable? Are detected techniques fair and useful? Anything confusing, mislabeled, or missing for your work?</P>
        </div>

        {/* ── CHECKLIST ── */}
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: '20px 24px', marginTop: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10, marginBottom: 6 }}>
            <h2 style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', margin: 0, fontFamily: 'Charter, Georgia, serif' }}>Review checklist</h2>
            {mounted && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 12, color: '#888' }}>{doneItems}/{totalItems} · {pct}%</span>
                <div style={{ width: 90, height: 6, background: '#f0f0ee', borderRadius: 3, overflow: 'hidden' }}>
                  <div style={{ width: `${pct}%`, height: '100%', background: teal }} />
                </div>
                <button onClick={reset} style={{ fontSize: 11, color: '#888', background: '#f0f0ee', border: 'none', borderRadius: 5, padding: '4px 10px', cursor: 'pointer' }}>Reset</button>
              </div>
            )}
          </div>
          <p style={{ fontSize: 12.5, color: '#888', margin: '0 0 14px' }}>Tick as you go — your progress is saved on this device, just for your own tracking. To actually send notes, use the feedback form below.</p>

          {CHECKLIST.map(group => (
            <div key={group.section} style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#0f6e56', marginBottom: 6 }}>{group.section}</div>
              {group.items.map(it => {
                const on = !!checked[it.id];
                return (
                  <div key={it.id} onClick={() => toggle(it.id)} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '7px 10px', borderRadius: 8, cursor: 'pointer', background: on ? '#f0fdfa' : 'transparent' }}>
                    <div style={{ width: 16, height: 16, borderRadius: 4, border: `1.5px solid ${on ? teal : '#cdd2d0'}`, background: on ? teal : '#fff', flexShrink: 0, marginTop: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {on && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="3.5" strokeLinecap="round"><path d="M5 12l5 5L20 7" /></svg>}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 13, color: on ? '#0f6e56' : '#404040', textDecoration: on ? 'line-through' : 'none', lineHeight: 1.5 }}>{it.label}</div>
                      {it.note && <div style={{ fontSize: 11, color: '#aaa', marginTop: 1 }}>{it.note}</div>}
                    </div>
                  </div>
                );
              })}
            </div>
          ))}

          <div style={{ fontSize: 13, fontWeight: 700, color: '#0f6e56', margin: '4px 0 8px' }}>H · Open questions — answer these in your feedback</div>
          <ul style={{ margin: 0, paddingLeft: 18 }}>
            {OPEN_QUESTIONS.map((q, i) => (
              <li key={i} style={{ fontSize: 13, color: '#404040', lineHeight: 1.7, marginBottom: 3 }}>{q}</li>
            ))}
          </ul>
        </div>

        {/* ── FEEDBACK ── */}
        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: '20px 24px', marginTop: 20 }}>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', margin: '0 0 4px', fontFamily: 'Charter, Georgia, serif' }}>How to send feedback</h2>
          <p style={{ fontSize: 13, color: '#888', margin: '0 0 14px' }}>Use whichever is easiest. We read every submission and use it to decide what we build, fix, and cut.</p>
          <div style={grid2}>
            <Card title="Feedback form" sub="In the portal">Pick a type and the component it&apos;s about. Best for quick, in-context reactions and bugs.</Card>
            <Card title="Contact form" sub="In the portal">Questions, partnership, or anything not tied to a specific feature.</Card>
            <Card title="Discord" sub="Dissekt channel">Join via the link in your Dashboard. Best for open discussion.</Card>
            <Card title="Email" sub="Direct">Reply to our email, or the address in the footer. Best for longer write-ups & screenshots.</Card>
          </div>
          <Tip><strong>What helps most:</strong> tell us what you were trying to do, what you expected, and what happened — a screenshot and the URL/text you scanned make a report far more actionable.</Tip>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginTop: 14 }}>
            <a href="/contact?mode=feedback" style={{ padding: '11px 24px', background: teal, color: '#fff', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>Open the feedback form →</a>
            <a href="/analyze" style={{ padding: '11px 24px', background: '#f0f0ee', color: '#555', borderRadius: 8, fontSize: 14, fontWeight: 500, textDecoration: 'none' }}>Back to scanning</a>
          </div>
        </div>

      </div>
      <SiteFooter />
    </main>
  );
}
