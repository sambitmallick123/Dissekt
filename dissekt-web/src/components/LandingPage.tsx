'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function LandingPage() {
  return (
    <main style={{ flex: 1, minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />

      {/* HERO */}
      <section style={{ padding: '60px 24px 48px', textAlign: 'center' }}>
        <div style={{ maxWidth: 720, margin: '0 auto' }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '4px 14px', background: '#f0fdfa', borderRadius: 20, fontSize: 11, color: '#0d9488', fontWeight: 500, marginBottom: 16 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: '#0d9488' }} />
            Beta · Free to use
          </div>
          <h1 style={{ fontSize: 40, fontWeight: 700, color: '#1a1a1a', lineHeight: 1.15, margin: '0 0 14px' }}>See how information<br />is constructed</h1>
          <p style={{ fontSize: 16, color: '#888', lineHeight: 1.7, margin: '0 0 14px', maxWidth: 540, marginLeft: 'auto', marginRight: 'auto' }}>
            Dissekt does not tell you what is true or false. It shows you <em>how</em> content is built — what techniques are used, what evidence exists, what context is missing, and how different sources frame the same story.
          </p>
          <p style={{ fontSize: 14, color: '#1a1a1a', fontWeight: 500, margin: '0 0 28px', maxWidth: 540, marginLeft: 'auto', marginRight: 'auto' }}>
            Paste any article, URL, or social post — and get a transparency report in seconds.
          </p>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
            <a href="/analyze" style={{ padding: '12px 28px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 15, fontWeight: 600, textDecoration: 'none' }}>Try it now — free</a>
            <a href="/help" style={{ padding: '12px 28px', background: '#fff', color: '#555', borderRadius: 8, fontSize: 15, fontWeight: 500, textDecoration: 'none', border: '0.5px solid #e5eaea' }}>How it works</a>
          </div>
        </div>
      </section>

      {/* EXAMPLE PREVIEW */}
      <section style={{ padding: '0 24px 48px' }}>
        <div style={{ maxWidth: 700, margin: '0 auto', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 20, boxShadow: '0 4px 24px rgba(0,0,0,0.04)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
            <div style={{ position: 'relative', width: 56, height: 56 }}>
              <svg width="56" height="56" viewBox="0 0 56 56"><circle cx="28" cy="28" r="24" fill="none" stroke="#f0f0ee" strokeWidth="3" /><circle cx="28" cy="28" r="24" fill="none" stroke="#d97706" strokeWidth="3" strokeDasharray="150.8" strokeDashoffset="72" strokeLinecap="round" transform="rotate(-90 28 28)" /></svg>
              <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ fontSize: 14, fontWeight: 700, color: '#d97706' }}>0.52</span></div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>Sample: &quot;PM defends budget amid opposition criticism&quot;</div>
              <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>3 techniques · 2 fact-checks · Moderate transparency</div>
            </div>
          </div>
          <div style={{ fontSize: 11, color: '#888', marginBottom: 10, paddingBottom: 10, borderBottom: '0.5px solid #f0f0ee' }}>
            Clarity score <strong style={{ color: '#d97706' }}>0.52 · Moderate</strong> — higher means more transparently constructed, not &quot;more true.&quot;
          </div>
          <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
            {[{ label: 'Construction', desc: 'how it is built', score: '0.64', color: '#dc2626' }, { label: 'Verification', desc: 'how supported', score: '0.38', color: '#2563eb' }, { label: 'Intent', desc: 'what it wants', score: '0.58', color: '#d97706' }].map(d => (
              <div key={d.label} style={{ flex: 1, padding: '8px 10px', background: '#f8fafa', borderRadius: 8, borderLeft: `3px solid ${d.color}` }}>
                <div style={{ fontSize: 9, fontWeight: 600, color: '#555' }}>{d.label}</div>
                <div style={{ fontSize: 8, color: '#aaa', marginBottom: 2 }}>{d.desc}</div>
                <div style={{ fontSize: 16, fontWeight: 700, color: d.color }}>{d.score}</div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            {['loaded language', 'cherry picking', 'appeal to authority'].map(t => (<span key={t} style={{ fontSize: 10, padding: '2px 8px', background: '#fef2f2', color: '#dc2626', borderRadius: 4 }}>{t}</span>))}
            <span style={{ fontSize: 10, padding: '2px 8px', background: '#eff6ff', color: '#2563eb', borderRadius: 4 }}>2 fact-checks found</span>
          </div>
        </div>
      </section>

      {/* THE PROBLEM */}
      <section style={{ padding: '48px 24px', background: '#fff', borderTop: '0.5px solid #e5eaea', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 32 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>The problem with information today</h2>
            <p style={{ fontSize: 14, color: '#888', maxWidth: 520, margin: '0 auto' }}>You cannot tell how a story was constructed just by reading it.</p>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12 }}>
            {[{ icon: '🎭', title: 'Same event, different stories', desc: 'Two outlets cover the same event — one says "crisis," the other says "transition." Both use facts. Neither is lying. But the framing changes everything.' }, { icon: '🔇', title: "What's missing matters most", desc: "The most powerful manipulation is not what is said — it is what is left out. Missing context, omitted counter-arguments, selective data." }, { icon: '🧠', title: "You can't unsee patterns", desc: 'Once you see how loaded language, emotional escalation, and false equivalence work, you read everything differently. That is the point.' }].map(p => (
              <div key={p.title} style={{ padding: 18, background: '#fafaf8', borderRadius: 10 }}>
                <div style={{ fontSize: 24, marginBottom: 8 }}>{p.icon}</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 4 }}>{p.title}</div>
                <div style={{ fontSize: 12, color: '#888', lineHeight: 1.7 }}>{p.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section style={{ padding: '48px 24px' }}>
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 32 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>How Dissekt works</h2>
            <p style={{ fontSize: 14, color: '#888' }}>Paste a URL, text, or social media post. Get a full transparency report in seconds.</p>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center' }}>
            {[{ step: '1', title: 'Paste anything', desc: 'News article, social media post, YouTube video, Reddit thread, WhatsApp forward — or just raw text.', color: '#0d9488' }, { step: '2', title: 'Multiple engines analyze', desc: 'Technique detection, fact-checker cross-references, source credibility, toxicity, political context — all in parallel.', color: '#2563eb' }, { step: '3', title: 'See the construction', desc: "Three-dimensional score: how it is built (Construction), how verified it is (Verification), and what it wants you to do (Intent).", color: '#d97706' }].map(s => (
              <div key={s.step} style={{ flex: '1 1 220px', maxWidth: 260, textAlign: 'center' }}>
                <div style={{ width: 40, height: 40, borderRadius: 20, background: s.color, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: 18, fontWeight: 700 }}>{s.step}</div>
                <div style={{ fontSize: 15, fontWeight: 600, color: '#1a1a1a', marginBottom: 4 }}>{s.title}</div>
                <div style={{ fontSize: 12, color: '#888', lineHeight: 1.7 }}>{s.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 3 DIMENSIONS */}
      <section style={{ padding: '48px 24px', background: '#fff', borderTop: '0.5px solid #e5eaea', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 32 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>Three questions, one score</h2>
            <p style={{ fontSize: 14, color: '#888' }}>Every analysis answers three fundamentally different questions.</p>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12 }}>
            {[{ icon: '🏗️', dim: 'Construction', color: '#dc2626', bg: '#fef2f2', q: 'How is it built?', metrics: ['Rhetoric — severity-weighted techniques', 'Argumentation — logical structure', 'Completeness — who, what, when, sources, counter-view'] }, { icon: '✅', dim: 'Verification', color: '#2563eb', bg: '#eff6ff', q: 'How verified is it?', metrics: ['Evidence — fact-checker consensus', 'Source — MBFC credibility', 'Diversity — independent sources', 'Temporal — consistency over time'] }, { icon: '🎯', dim: 'Intent', color: '#d97706', bg: '#fffbeb', q: 'What does it want me to do?', metrics: ['Tone — context-aware toxicity', 'Manipulation — urgency, escalation', 'Narrative — framing direction'] }].map(d => (
              <div key={d.dim} style={{ padding: 18, background: d.bg, borderRadius: 10, borderLeft: `3px solid ${d.color}` }}>
                <div style={{ fontSize: 20, marginBottom: 6 }}>{d.icon}</div>
                <div style={{ fontSize: 16, fontWeight: 600, color: d.color, marginBottom: 2 }}>{d.dim}</div>
                <div style={{ fontSize: 12, fontWeight: 500, color: '#555', marginBottom: 10 }}>{d.q}</div>
                {d.metrics.map(m => (<div key={m} style={{ fontSize: 11, color: '#888', lineHeight: 1.8 }}>• {m}</div>))}
              </div>
            ))}
          </div>
          <div style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: '#888' }}>Clarity = (Construction × Verification × Intent) ^ 1/3 · Scale: 0.0 → 1.0<br />Scores reflect the evidence available — thin inputs are flagged as limited signal, not guessed.</div>
        </div>
      </section>

      {/* 12 ENGINES */}
      <section style={{ padding: '48px 24px' }}>
        <div style={{ maxWidth: 900, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 28 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>8 analysis engines</h2>
            <p style={{ fontSize: 14, color: '#888' }}>Every scan runs through 8 specialized engines in parallel.</p>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 8 }}>
            {[{ icon: '🔦', name: 'Beacon', desc: 'Orchestrator — parallel pipeline' }, { icon: '🔺', name: 'Prism', desc: '20 manipulation techniques' }, { icon: '🔎', name: 'Lens', desc: '100+ fact-checker cross-refs' }, { icon: '🌈', name: 'Spectrum', desc: 'Toxicity + credibility + sentiment' }, { icon: '💠', name: 'Facet', desc: 'Claim extraction + typing' }, { icon: '🧭', name: 'Meridian', desc: '69 politicians, 4 countries' }, { icon: '👁', name: 'Iris', desc: 'Language detection' }, { icon: '🔗', name: 'Lattice', desc: 'Similar past analyses' }].map(e => (
              <div key={e.name} style={{ padding: '12px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}><span style={{ fontSize: 16 }}>{e.icon}</span><span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{e.name}</span></div>
                <div style={{ fontSize: 11, color: '#888' }}>{e.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* PLATFORMS */}
      <section style={{ padding: '48px 24px', background: '#fff', borderTop: '0.5px solid #e5eaea', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 700, margin: '0 auto', textAlign: 'center' }}>
          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>Analyze anything from anywhere</h2>
          <p style={{ fontSize: 14, color: '#888', marginBottom: 24 }}>Paste a URL from any platform. Auto-detects and extracts the full content.</p>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
            {[{ icon: '🌐', label: 'News sites' }, { icon: '🟠', label: 'Reddit' }, { icon: '🎥', label: 'YouTube' }, { icon: '🦋', label: 'Bluesky' }, { icon: '🐘', label: 'Mastodon' }, { icon: '📰', label: 'Substack' }].map(p => (
              <div key={p.label} style={{ padding: '12px 16px', background: '#fafaf8', borderRadius: 8, minWidth: 80 }}>
                <div style={{ fontSize: 20, marginBottom: 2 }}>{p.icon}</div>
                <div style={{ fontSize: 11, fontWeight: 600, color: '#1a1a1a' }}>{p.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FEATURES */}
      <section style={{ padding: '48px 24px' }}>
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 28 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>Tools for seeing clearly</h2>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10 }}>
            {[{ icon: '📊', name: 'Dashboard', desc: 'Your scan history, reading profile, and API keys in one place' }, { icon: '📒', name: 'Ledger', desc: 'Decision journal — log Trust / Unsure / Reject on what you read' }, { icon: '🪞', name: 'Reflect', desc: 'Your reading profile — how you tend to judge what you read' }, { icon: '✦', name: 'Constellation', desc: 'Knowledge graph of the entities across your scans' }, { icon: '🔑', name: 'API access', desc: 'Scan programmatically with your own API key' }].map(f => (
              <div key={f.name} style={{ padding: 14, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}><span style={{ fontSize: 14 }}>{f.icon}</span><span style={{ fontSize: 13, fontWeight: 600, color: '#0d9488' }}>{f.name}</span></div>
                <div style={{ fontSize: 11, color: '#888', lineHeight: 1.7 }}>{f.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* NUMBERS */}
      <section style={{ padding: '48px 24px', background: '#0d9488' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', gap: 12, textAlign: 'center' }}>
          {[{ n: '8', l: 'Engines' }, { n: '20', l: 'Techniques' }, { n: '100+', l: 'Fact-checkers' }, { n: '231', l: 'Media rated' }, { n: '69', l: 'Politicians' }].map(s => (
            <div key={s.l} style={{ padding: 12 }}><div style={{ fontSize: 28, fontWeight: 700, color: '#fff' }}>{s.n}</div><div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)' }}>{s.l}</div></div>
          ))}
        </div>
      </section>

      {/* RESEARCH BACKING */}
      <section style={{ padding: '48px 24px' }}>
        <div style={{ maxWidth: 700, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 24 }}>
            <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 8px' }}>Built on research, not opinions</h2>
            <p style={{ fontSize: 14, color: '#888' }}>Our scoring metrics draw on peer-reviewed research.</p>
          </div>
          <div style={{ textAlign: 'center', fontSize: 13, color: '#888' }}>Our scoring metrics draw on peer-reviewed research in propaganda detection, media-source credibility, argumentation quality, and toxicity. <a href="/help#references" style={{ color: '#0d9488', textDecoration: 'none' }}>See the full references →</a></div>
        </div>
      </section>

      {/* WHO IT'S FOR */}
      <section style={{ padding: '48px 24px', background: '#fff', borderTop: '0.5px solid #e5eaea', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 24px', textAlign: 'center' }}>For everyone who reads</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>
            {[{ icon: '📰', who: 'Journalists', how: 'See how a story is framed, cross-check claims against existing fact-checks, and log your trust decisions.' }, { icon: '🎓', who: 'Researchers', how: 'Systematic framing analysis, source-credibility data, and API access.' }, { icon: '👨‍🏫', who: 'Educators', how: 'Show students how framing works and build media literacy.' }, { icon: '📱', who: 'Everyone', how: 'Check that forward before sharing. See if a claim was fact-checked. Know your own bias.' }].map(u => (
              <div key={u.who} style={{ padding: 16, background: '#fafaf8', borderRadius: 10 }}>
                <div style={{ fontSize: 24, marginBottom: 6 }}>{u.icon}</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 4 }}>{u.who}</div>
                <div style={{ fontSize: 11, color: '#888', lineHeight: 1.7 }}>{u.how}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* TIERS */}
      <section style={{ padding: '48px 24px' }}>
        <div style={{ maxWidth: 560, margin: '0 auto' }}>
          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 20px', textAlign: 'center' }}>Start free. Go deeper with an account.</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>
            <div style={{ padding: 20, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>🆓 Free</div>
              <div style={{ fontSize: 11, color: '#888', marginBottom: 10 }}>Start instantly</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>3 brief / day<br />1 detailed / day<br />Help + Feedback</div>
              <a href="/analyze" style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#f0f0ee', color: '#555', borderRadius: 6, fontSize: 13, textDecoration: 'none' }}>Start scanning</a>
            </div>
            <div style={{ padding: 20, background: '#fff', border: '2px solid #0d9488', borderRadius: 10 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>🔐 Account</div>
              <div style={{ fontSize: 11, color: '#0d9488', marginBottom: 10 }}>Free — sign up with email</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>25 brief / day<br />10 detailed / day<br />All features + API + Dashboard</div>
              <a href="/signup" style={{ display: 'block', textAlign: 'center', marginTop: 12, padding: '8px 0', background: '#0d9488', color: '#fff', borderRadius: 6, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>Sign up</a>
              <a href="/login" style={{ display: 'block', textAlign: 'center', marginTop: 6, fontSize: 12, color: '#0d9488', textDecoration: 'none' }}>or sign in</a>
            </div>
          </div>
        </div>
      </section>

      {/* FINAL CTA */}
      <section style={{ padding: '56px 24px', textAlign: 'center', background: '#fff', borderTop: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 520, margin: '0 auto' }}>
          <h2 style={{ fontSize: 26, fontWeight: 700, color: '#1a1a1a', margin: '0 0 10px' }}>Ready to see clearly?</h2>
          <p style={{ fontSize: 14, color: '#888', marginBottom: 20 }}>Paste any article, claim, or URL.</p>
          <a href="/analyze" style={{ display: 'inline-block', padding: '14px 36px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 16, fontWeight: 600, textDecoration: 'none' }}>Analyze something now</a>
          <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center', gap: 16, fontSize: 11, color: '#888' }}>
            <span>✓ Free to start</span><span>✓ Research-backed</span>
          </div>
        </div>
      </section>

      <SiteFooter />
    </main>
  );
}
