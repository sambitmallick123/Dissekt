'use client';
import { useState, useEffect } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const SECTIONS = [
  { id: 'overview', label: 'Overview', icon: '👁️' },
  { id: 'quickstart', label: 'Quick start', icon: '⚡' },
  { id: 'clarity', label: 'Clarity Score', icon: '📊' },
  { id: 'dimensions', label: '3 Dimensions', icon: '🎯' },
  { id: 'engines', label: '12 Engines', icon: '🔭' },
  { id: 'features', label: 'Features', icon: '🛠️' },
  { id: 'access', label: 'Access & limits', icon: '🎫' },
  { id: 'community', label: 'Community & Access', icon: '💬' },
  { id: 'references', label: 'References', icon: '📚' },
  { id: 'faq', label: 'FAQ', icon: '❓' },
];

// ─── Reusable bits ───
function Collapsible({ title, subtitle, children, defaultOpen = false }: { title: string; subtitle?: string; children: React.ReactNode; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div style={{ border: '0.5px solid #e5eaea', borderRadius: 10, marginBottom: 8, background: '#fff', overflow: 'hidden' }}>
      <button onClick={() => setOpen(!open)} style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '13px 16px', background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left' }}>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>{title}</div>
          {subtitle && <div style={{ fontSize: 12, color: '#888', marginTop: 1 }}>{subtitle}</div>}
        </div>
        <span style={{ fontSize: 12, color: '#888', transform: open ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}>▾</span>
      </button>
      {open && <div style={{ padding: '0 16px 16px', fontSize: 13.5, color: '#444', lineHeight: 1.75 }}>{children}</div>}
    </div>
  );
}

function SectionHead({ icon, title, sub }: { icon: string; title: string; sub?: string }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <h2 style={{ fontSize: 21, fontWeight: 700, color: '#1a1a1a', margin: 0 }}>{icon} {title}</h2>
      {sub && <p style={{ fontSize: 13.5, color: '#888', margin: '4px 0 0' }}>{sub}</p>}
    </div>
  );
}

function Ref({ href, children }: { href: string; children: React.ReactNode }) {
  return <a href={href} target="_blank" rel="noopener" style={{ color: '#0d9488', textDecoration: 'none' }}>{children}</a>;
}

// ─── Interactive score demo ───
function ScoreDemo() {
  const [val, setVal] = useState(0.5);
  const band = val >= 0.65 ? { label: 'High transparency', color: '#16a34a', bg: '#f0fdf4' }
    : val >= 0.35 ? { label: 'Moderate', color: '#d97706', bg: '#fffbeb' }
    : { label: 'Low transparency', color: '#dc2626', bg: '#fef2f2' };
  const circ = 2 * Math.PI * 42;
  return (
    <div style={{ display: 'flex', gap: 20, alignItems: 'center', padding: 18, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12, flexWrap: 'wrap' }}>
      <div style={{ position: 'relative', width: 110, height: 110, flexShrink: 0 }}>
        <svg width="110" height="110" viewBox="0 0 110 110">
          <circle cx="55" cy="55" r="42" fill="none" stroke="#f0f0ee" strokeWidth="7" />
          <circle cx="55" cy="55" r="42" fill="none" stroke={band.color} strokeWidth="7" strokeLinecap="round"
            strokeDasharray={circ} strokeDashoffset={circ * (1 - val)} transform="rotate(-90 55 55)" style={{ transition: 'stroke-dashoffset 0.2s, stroke 0.2s' }} />
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 24, fontWeight: 700, color: band.color }}>{val.toFixed(2)}</span>
        </div>
      </div>
      <div style={{ flex: 1, minWidth: 200 }}>
        <div style={{ display: 'inline-block', padding: '3px 12px', borderRadius: 20, fontSize: 12, fontWeight: 600, color: band.color, background: band.bg, marginBottom: 10 }}>{band.label}</div>
        <input type="range" min={0} max={1} step={0.01} value={val} onChange={e => setVal(parseFloat(e.target.value))}
          style={{ width: '100%', accentColor: band.color, marginBottom: 6 }} />
        <div style={{ fontSize: 11, color: '#888' }}>Drag to see how the score maps to transparency bands. 0.0 = opaque, 1.0 = transparent.</div>
      </div>
    </div>
  );
}

// ─── Dimension explorer ───
function DimensionExplorer() {
  const [active, setActive] = useState('construction');
  const dims: Record<string, any> = {
    construction: { icon: '🏗️', color: '#dc2626', q: 'How is it built?', metrics: [
      ['Rhetoric', '×0.40', 'Severity-weighted technique penalties (Da San Martino 2019)'],
      ['Argumentation', '×0.35', 'Logical structure & claim support (Wachsmuth 2017)'],
      ['Completeness', '×0.25', 'Who/what/when, sources, counter-view present?'],
    ]},
    verification: { icon: '✅', color: '#2563eb', q: 'How verified is it?', metrics: [
      ['Evidence', '×0.40', 'Fact-checker consensus, tier-weighted'],
      ['Source', '×0.25', 'MBFC factuality rating (231 outlets)'],
      ['Diversity', '×0.20', 'Independent named-source count'],
      ['Temporal', '×0.20', 'Has the claim held up over time?'],
    ]},
    intent: { icon: '🎯', color: '#d97706', q: 'What does it want?', metrics: [
      ['Manipulation', '×0.40', 'Urgency, CTA, escalation, aggression (Cialdini 2007)'],
      ['Tone', '×0.35', 'Context-aware toxicity (Pavlopoulos 2021)'],
      ['Narrative', '×0.25', 'Framing direction: fear↔hope, skepticism↔trust (Card 2018)'],
    ]},
  };
  const d = dims[active];
  return (
    <div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
        {Object.keys(dims).map(k => (
          <button key={k} onClick={() => setActive(k)} style={{ flex: 1, padding: '10px 8px', borderRadius: 8, border: active === k ? `2px solid ${dims[k].color}` : '0.5px solid #e5eaea', background: active === k ? dims[k].color + '0d' : '#fff', cursor: 'pointer', textAlign: 'center' }}>
            <div style={{ fontSize: 18 }}>{dims[k].icon}</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: active === k ? dims[k].color : '#888', textTransform: 'capitalize' }}>{k}</div>
          </button>
        ))}
      </div>
      <div style={{ padding: 16, background: d.color + '08', borderRadius: 10, borderLeft: `3px solid ${d.color}` }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: d.color, marginBottom: 10 }}>{d.icon} {d.q}</div>
        {d.metrics.map((m: string[]) => (
          <div key={m[0]} style={{ display: 'flex', gap: 10, padding: '7px 0', borderBottom: '0.5px solid rgba(0,0,0,0.05)' }}>
            <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a', minWidth: 100 }}>{m[0]}</span>
            <span style={{ fontSize: 11, fontWeight: 600, color: d.color, minWidth: 36 }}>{m[1]}</span>
            <span style={{ fontSize: 12, color: '#666', flex: 1 }}>{m[2]}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function HelpPage() {
  const [active, setActive] = useState('overview');
  const [isInvited, setIsInvited] = useState(false);
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const invited = localStorage.getItem('dissekt_tier') === 'invited';
      const admin = localStorage.getItem('dissekt_admin') === 'true';
      setIsInvited(invited || admin);
    }
  }, []);

  useEffect(() => {
    const onScroll = () => {
      for (const s of SECTIONS) {
        const el = document.getElementById(s.id);
        if (el) {
          const r = el.getBoundingClientRect();
          if (r.top <= 120 && r.bottom >= 120) { setActive(s.id); break; }
        }
      }
    };
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const go = (id: string) => document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div className="help-container" style={{ maxWidth: 1000, margin: '0 auto', padding: '28px 16px', display: 'flex', gap: 28 }}>

        {/* Sticky sidebar */}
        <aside className="help-nav" style={{ width: 190, flexShrink: 0, position: 'sticky', top: 80, alignSelf: 'flex-start', maxHeight: 'calc(100vh - 100px)', overflowY: 'auto' }}>
          <div style={{ fontSize: 10, fontWeight: 600, color: '#aaa', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: 8, paddingLeft: 8 }}>Contents</div>
          {SECTIONS.map(s => (
            <button key={s.id} onClick={() => go(s.id)} style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', textAlign: 'left', padding: '7px 10px', fontSize: 13, color: active === s.id ? '#0d9488' : '#666', background: active === s.id ? '#f0fdfa' : 'transparent', border: 'none', borderRadius: 7, cursor: 'pointer', fontWeight: active === s.id ? 600 : 400, marginBottom: 1 }}>
              <span style={{ fontSize: 13 }}>{s.icon}</span>{s.label}
            </button>
          ))}
        </aside>

        {/* Content */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: 30, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Help & Methodology</h1>
          <p style={{ fontSize: 14, color: '#888', marginBottom: 32 }}>Everything about how Dissekt works — click through the sections, or explore the interactive demos.</p>

          {/* OVERVIEW */}
          <div id="overview" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="👁️" title="What Dissekt does" />
            <p style={{ fontSize: 14, color: '#444', lineHeight: 1.8 }}>
              Dissekt analyzes <strong>how</strong> information is constructed — not whether it&apos;s true or false. It surfaces the techniques used, the evidence available, the context present or missing, and how content is framed. You stay the judge; Dissekt gives you the lens.
            </p>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 10, marginTop: 14 }}>
              {[['🔭', 'Paste anything', 'URL, text, or social post'], ['⚡', '12 engines', 'Run in parallel, under 4s'], ['📊', 'One clear score', 'Fully decomposed, no black box']].map(c => (
                <div key={c[1]} style={{ padding: 14, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
                  <div style={{ fontSize: 22, marginBottom: 4 }}>{c[0]}</div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{c[1]}</div>
                  <div style={{ fontSize: 11, color: '#888' }}>{c[2]}</div>
                </div>
              ))}
            </div>
          </div>

          {/* QUICK START */}
          <div id="quickstart" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="⚡" title="Quick start" sub="Three steps to your first analysis." />
            {[['1', 'Paste a URL or text', 'Drop any article link, social post, or raw text into the scanner on the Analyze page.'], ['2', 'Pick Brief or Detailed', 'Brief is fast (heuristics + GPT-4o mini). Detailed escalates to Claude for deeper analysis.'], ['3', 'Read the breakdown', 'See the Clarity Score, then expand any dimension to see exactly which signals drove it.']].map(s => (
              <div key={s[0]} style={{ display: 'flex', gap: 12, marginBottom: 10, alignItems: 'flex-start' }}>
                <div style={{ width: 28, height: 28, borderRadius: 14, background: '#0d9488', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, flexShrink: 0 }}>{s[0]}</div>
                <div><div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>{s[1]}</div><div style={{ fontSize: 13, color: '#666', lineHeight: 1.6 }}>{s[2]}</div></div>
              </div>
            ))}
          </div>

          {/* CLARITY SCORE */}
          <div id="clarity" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="📊" title="The Clarity Score" sub="0.00 (opaque) → 1.00 (transparent). Drag the slider to explore." />
            <ScoreDemo />
            <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 8, fontFamily: 'monospace', fontSize: 12, margin: '12px 0' }}>
              Clarity = (Construction × Verification × Intent) ^ ⅓
            </div>
            <Collapsible title="Why a geometric mean?" subtitle="Not an average — and that matters">
              An arithmetic average lets a great score in one area mask a terrible score in another. The geometric mean doesn&apos;t — an article with excellent rhetoric but disputed evidence can&apos;t hide behind its writing quality. Same reason the UN Human Development Index switched to a geometric mean in 2010.
            </Collapsible>
            <Collapsible title="What about missing data?" subtitle="No fact-checks ≠ low score">
              Where a dimension has no data (e.g. no fact-checks exist yet), it&apos;s excluded rather than guessed. Absence of evidence is never treated as evidence. Only the signals we can actually measure contribute to the score.
            </Collapsible>
            <Collapsible title="Confidence band" subtitle="How sure are the signals?">
              <strong>High</strong> (technique confidence 0.8+): strong signals, detected with certainty.<br />
              <strong>Medium</strong> (0.5–0.8): moderate signals; Detailed mode may help.<br />
              <strong>Low</strong> (below 0.5): present but not definitive — interpret with caution.
            </Collapsible>
          </div>

          {/* DIMENSIONS */}
          <div id="dimensions" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="🎯" title="The three dimensions" sub="Every analysis answers three different questions. Tap each to explore its metrics." />
            <DimensionExplorer />
          </div>

          {/* ENGINES */}
          <div id="engines" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="🔭" title="12 analysis engines" sub="Each named after an optical instrument. All run in parallel." />
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 8 }}>
              {[['🔦', 'Beacon', 'Orchestrator — parallel pipeline + extraction'], ['🔺', 'Prism', '20 manipulation techniques'], ['🔎', 'Lens', '100+ fact-checker cross-refs'], ['🌈', 'Spectrum', 'Toxicity + credibility + sentiment'], ['💎', 'Crystal', 'Blockchain evidence proof'], ['🔗', 'Lattice', 'Knowledge graph (Qdrant)'], ['🔭', 'Scope', 'News feeds, 5 markets'], ['💠', 'Facet', 'Claim extraction + typing'], ['👁', 'Iris', 'Language detection'], ['🧭', 'Meridian', '69 politicians, 4 countries'], ['🔥', 'Flare', 'Coordination detection'], ['🪞', 'Mirror', 'Alternative framings']].map(e => (
                <div key={e[1]} style={{ padding: '11px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ fontSize: 15 }}>{e[0]}</span><span style={{ fontSize: 13, fontWeight: 600, color: '#0d9488' }}>{e[1]}</span></div>
                  <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>{e[2]}</div>
                </div>
              ))}
            </div>
          </div>

          {/* FEATURES */}
          <div id="features" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="🛠️" title="Features" sub="Tools for reading more clearly." />
            {[['🔍 Loupe', 'Inline annotations — highlights techniques directly in the text'], ['✍️ Polish', 'Pre-publish check for writers, with rewrite suggestions'], ['🔮 Kaleidoscope', 'One claim from 5 editorial perspectives'], ['🪞 Reflect', 'Your personal bias profile over time'], ['📒 Ledger', 'Decision journal — Trust / Unsure / Reject'], ['🕸️ Trust Graph', 'Per-source trust visualization'], ['🧵 Thread', 'Track how a claim evolved over time'], ['🔬 Imprint', 'Source fingerprinting']].map(f => (
              <Collapsible key={f[0]} title={f[0]} subtitle={f[1]}><span style={{ fontSize: 12, color: '#888' }}>Available on the Analyze page and dashboard for invited users.</span></Collapsible>
            ))}
          </div>

          {/* ACCESS */}
          <div id="access" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="🎫" title="Access & limits" />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              <div style={{ padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>🆓 Free</div>
                <div style={{ fontSize: 11, color: '#888', marginBottom: 8 }}>No signup</div>
                <div style={{ fontSize: 12, color: '#555', lineHeight: 1.9 }}>3 brief / day<br />1 detailed / day<br />Resets 00:00 GMT</div>
              </div>
              <div style={{ padding: 16, background: '#fff', border: '2px solid #0d9488', borderRadius: 10 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>🎫 Invited</div>
                <div style={{ fontSize: 11, color: '#0d9488', marginBottom: 8 }}>6 months</div>
                <div style={{ fontSize: 12, color: '#555', lineHeight: 1.9 }}>25 brief / day<br />10 detailed / day<br />All features + API</div>
              </div>
            </div>
          </div>

          {/* REFERENCES */}
          {/* COMMUNITY & ACCESS */}
          <div id="community" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="💬" title="Community & access" sub="Join the conversation and get full access." />
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10, marginBottom: 16 }}>
              <div style={{ padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
                <div style={{ fontSize: 22, marginBottom: 4 }}>💬</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#5865F2' }}>Discord</div>
                <div style={{ fontSize: 12, color: '#888' }}>Report bugs, share ideas, follow updates</div>
                <div style={{ fontSize: 11, color: '#aaa', marginTop: 6 }}>Available to invited members</div>
              </div>
              <div style={{ padding: 16, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
                <div style={{ fontSize: 22, marginBottom: 4 }}>⌨️</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>GitHub</div>
                <div style={{ fontSize: 12, color: '#888' }}>Open issues, discussions, contribute</div>
                <div style={{ fontSize: 11, color: '#aaa', marginTop: 6 }}>Available to invited members</div>
              </div>
            </div>
            <Collapsible title="How does invite access work?" subtitle="Getting full features">
              Dissekt is in beta. Anyone can run single scans for free. <strong>Invited members</strong> get higher limits, all features (Bulk, Compare, Dashboard, API), and access to the community channels. Request an invite from the landing page, or ask in our Discord. Invite access currently runs for 6 months.
            </Collapsible>
            <Collapsible title="What can I do in the community?" subtitle="Discord & GitHub">
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


          <div id="references" style={{ marginBottom: 40, scrollMarginTop: 80 }}>
            <SectionHead icon="📚" title="References" sub="Every scoring decision is backed by peer-reviewed work." />
            {[['Da San Martino et al., EMNLP 2019', 'https://aclanthology.org/D19-1565/', 'Technique severity weights'], ['Baly et al., EMNLP 2018', 'https://aclanthology.org/D18-1389/', 'Multi-dimensional credibility'], ['Wachsmuth et al., ACL 2017', 'https://aclanthology.org/P17-1002/', 'Argumentation quality'], ['Card et al., ACL 2018', 'https://aclanthology.org/P18-1017/', 'Media framing direction'], ['Pavlopoulos et al., EACL 2021', 'https://aclanthology.org/2021.eacl-main.114/', 'Context-aware toxicity'], ['UNDP HDI', 'https://hdr.undp.org/data-center/human-development-index', 'Geometric mean for indices'], ['Media Bias/Fact Check', 'https://mediabiasfactcheck.com/methodology/', 'Source credibility database']].map(r => (
              <div key={r[0]} style={{ display: 'flex', gap: 8, padding: '8px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, marginBottom: 6 }}>
                <span style={{ fontSize: 13 }}>📄</span>
                <div><Ref href={r[1]}>{r[0]}</Ref><div style={{ fontSize: 11, color: '#888' }}>{r[2]}</div></div>
              </div>
            ))}
          </div>

          {/* FAQ */}
          <div id="faq" style={{ marginBottom: 20, scrollMarginTop: 80 }}>
            <SectionHead icon="❓" title="FAQ" />
            <Collapsible title="Does a low score mean the content is false?" defaultOpen>
              No. A low Clarity Score means the content uses techniques that can be manipulative, is disputed by fact-checkers, or is framed to provoke — not that it&apos;s necessarily false. Satire and opinion score lower by design.
            </Collapsible>
            <Collapsible title="Why did my article score in the middle?">
              A moderate score (0.35–0.64) usually means mixed signals — sound rhetoric but no external verification, or good sourcing with charged framing. Expand each dimension to see which metric is responsible.
            </Collapsible>
            <Collapsible title="Can I analyze social media?">
              Yes — paste a URL from news sites, Reddit, YouTube, Bluesky, Mastodon, or Substack. Dissekt auto-detects the platform and extracts the full content.
            </Collapsible>
            <Collapsible title="Is there an API?">
              Yes, for invited users. See the <a href="/docs" style={{ color: '#0d9488', textDecoration: 'none' }}>API documentation</a>.
            </Collapsible>
          </div>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
