'use client';

export default function LandingPage({ onSignIn, onTryFree, onShowFeedback }: { onSignIn: () => void; onTryFree: () => void; onShowFeedback?: () => void }) {
  return (
    <div style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      {/* Nav */}
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div className="nav-inner" style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
          </div>
          <div className="nav-links" style={{ display: 'flex', gap: 14, fontSize: 13, color: '#737373', alignItems: 'center' }}>
            <a href="#features" style={{ color: '#737373', textDecoration: 'none' }}>Features</a>
            <a href="/docs" style={{ color: '#737373', textDecoration: 'none' }}>API</a>
            <a href="#how" style={{ color: '#737373', textDecoration: 'none' }}>How it works</a>
            {onShowFeedback && <button onClick={onShowFeedback} style={{ color: '#737373', background: 'none', border: 'none', cursor: 'pointer', fontSize: 13 }}>Feedback</button>}
            <button onClick={() => window.location.href="/invite"} style={{ padding: "5px 14px", background: "transparent", color: "#7c3aed", border: "1px solid #e5e5e5", borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: "pointer" }}>Get access</button>
            <button onClick={onTryFree} style={{ padding: '5px 14px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Try free</button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <div style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', textAlign: 'center', padding: '48px 20px 40px' }}>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 10, maxWidth: 500, margin: '0 auto 10px' }}>Every article frames information differently. Dissekt makes that framing visible.</p>
        <h1 className="hero-title" style={{ fontSize: 34, fontWeight: 700, lineHeight: 1.2, letterSpacing: '-0.02em', maxWidth: 640, margin: '0 auto 14px' }}>See how information is constructed. Understand what content says — and what it leaves out.</h1>
        <p className="hero-sub" style={{ fontSize: 15, color: '#555', lineHeight: 1.6, maxWidth: 540, margin: '0 auto 12px' }}>
          Dissekt shows you exactly how — loaded language, missing context, emotional framing, and 17 more techniques.
          Paste any URL, text, or screenshot and see the playbook behind the content.
        </p>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, flexWrap: 'wrap', marginBottom: 10 }}>
          {['📰 Journalists', '🔍 Researchers', '📱 Social media users', '📰 News readers'].map((t, i) => (
            <span key={i} style={{ fontSize: 12, padding: '4px 12px', borderRadius: 20, background: '#f5f5f4', border: '1px solid #e5e5e5', color: '#555' }}>{t}</span>
          ))}
        </div>
        <div className="hero-buttons" style={{ display: 'flex', justifyContent: 'center', gap: 10, flexWrap: 'wrap', marginTop: 16 }}>
          <button onClick={onTryFree} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 24px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Inspect any content
          </button>
          <button onClick={onSignIn} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '12px 24px', background: '#fff', color: '#7c3aed', border: '1px solid #e5e5e5', borderRadius: 10, fontSize: 15, fontWeight: 500, cursor: 'pointer' }}>Sign in</button>
        </div>
        <p style={{ fontSize: 12, color: '#aaa', marginTop: 10 }}>Free · 10 scans/day · No signup required</p>
      </div>

      {/* Live demo */}
      <div id="demo" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#888', textAlign: 'center', marginBottom: 4 }}>See it in action</div>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 4 }}>What Dissekt reveals in 3 seconds</div>
        <p style={{ fontSize: 13, color: '#888', textAlign: 'center', marginBottom: 20 }}>Real scan of: "COVID-19 vaccines contain microchips for tracking people"</p>
        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' }}>
          <div style={{ padding: '10px 14px', borderBottom: '1px solid #e5e5e5', fontSize: 12, color: '#888', display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 4 }}>
            <span>Threat score: <strong style={{ color: '#dc2626' }}>76/100 High risk</strong></span>
            <span>3.1s · GPT-4o mini</span>
          </div>
          <div className="demo-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <div className="demo-panel" style={{ padding: 14, borderRight: '1px solid #e5e5e5' }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#7c3aed', marginBottom: 8 }}>👁 Prism — Techniques</div>
              <div style={{ border: '1px solid #e5e5e5', borderRadius: 8, padding: 8, marginBottom: 6 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, marginBottom: 3 }}><span style={{ fontWeight: 600 }}>Loaded language</span><span style={{ fontWeight: 700, color: '#dc2626' }}>90%</span></div>
                <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: '90%', background: '#dc2626', borderRadius: 2 }}></div></div>
              </div>
              <p style={{ fontSize: 10, color: '#555', lineHeight: 1.5, margin: 0 }}>Uses "microchips" to provoke fear about surveillance without evidence.</p>
            </div>
            <div className="demo-panel" style={{ padding: 14, borderRight: '1px solid #e5e5e5' }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#2563eb', marginBottom: 8 }}>🌐 Trace — 10 fact-checks</div>
              {['FactCheck.org', 'Full Fact', 'AP News'].map((p,i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 6px', border: '1px solid #e5e5e5', borderRadius: 6, marginBottom: 3, fontSize: 11 }}>
                  <span style={{ fontWeight: 600 }}>{p}</span>
                  <span style={{ fontSize: 9, fontWeight: 600, padding: '1px 5px', borderRadius: 4, background: '#fef2f2', color: '#b91c1c' }}>False</span>
                </div>
              ))}
            </div>
            <div className="demo-panel" style={{ padding: 14 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#d97706', marginBottom: 8 }}>📊 Signal — Credibility</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4 }}>
                {[{l:'Toxicity',v:'0.1%',c:'#059669'},{l:'Sentiment',v:'Neutral',c:'#404040'},{l:'Bias',v:'N/A',c:'#888'},{l:'Factuality',v:'N/A',c:'#888'}].map((s,i) => (
                  <div key={i} style={{ background: '#f8f8f6', borderRadius: 6, padding: 6, fontSize: 10 }}>
                    <div style={{ color: '#888', textTransform: 'uppercase', fontSize: 8, marginBottom: 1 }}>{s.l}</div>
                    <div style={{ fontWeight: 600, color: s.c }}>{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button onClick={onTryFree} style={{ padding: '10px 20px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Try it yourself →</button>
        </div>
      </div>

      {/* How it works */}
      <div id="how" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div style={{ fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#888', textAlign: 'center', marginBottom: 4 }}>How it works</div>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>Paste anything. Get the full picture.</div>
        <div className="how-steps" style={{ maxWidth: 560, margin: '0 auto' }}>
          {[
            { n: '1', t: 'Paste or upload', d: 'Drop any URL, article, WhatsApp forward, screenshot, tweet, or social media post.' },
            { n: '2', t: 'Prism scans', d: 'AI identifies manipulation techniques — loaded language, cherry-picking, appeal to fear, and 17 more — with confidence scores.' },
            { n: '3', t: 'Trace checks', d: 'Searches 100+ fact-checking organizations and traces the claim to its earliest online appearance.' },
            { n: '4', t: 'Signal scores', d: 'Rates source bias, factuality, toxicity, and sentiment — all running locally, zero external data.' },
          ].map(s => (
            <div key={s.n} style={{ display: 'flex', alignItems: 'start', gap: 14, marginBottom: 16 }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: '#f3e8ff', color: '#7c3aed', fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{s.n}</div>
              <div><div style={{ fontSize: 14, fontWeight: 600, marginBottom: 2 }}>{s.t}</div><div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>{s.d}</div></div>
            </div>
          ))}
        </div>
      </div>

      {/* Features */}
      <div id="features" className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>What's under the hood</div>
        <div className="landing-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          {[
            { icon: '👁', title: 'Prism', desc: '20 manipulation techniques across framing, logical fallacies, credibility tricks, and deflection tactics.' },
            { icon: '🌐', title: 'Trace', desc: '100+ fact-checker organizations. Spread timeline showing where the claim traveled across platforms.' },
            { icon: '📊', title: 'Signal', desc: '231 rated sources. Toxicity scoring. Sentiment analysis. All local, all private, zero API cost.' },
            { icon: '🔒', title: 'Anchor', desc: 'SHA-256 hash + blockchain proof for every analysis. Tamper-proof evidence you can cite.' },
            { icon: '📡', title: 'Radar', desc: 'Live RSS feeds from 16 sources across India, Germany, US, UK. Spot suspicious content before it spreads.' },
            { icon: '📷', title: 'Image scan', desc: 'Upload screenshots, WhatsApp forwards, or use your camera. AI extracts text and detects visual manipulation.' },
          ].map((f, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
              <div style={{ fontSize: 22, marginBottom: 8 }}>{f.icon}</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{f.title}</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5 }}>{f.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px' }}>
        <div className="stats-grid landing-grid-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { num: '20', label: 'Manipulation techniques', color: '#7c3aed' },
            { num: '100+', label: 'Fact-checker organizations', color: '#2563eb' },
            { num: '231', label: 'Rated news sources', color: '#d97706' },
            { num: '~3s', label: 'Average scan time', color: '#059669' },
          ].map((s, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '18px 14px', textAlign: 'center' }}>
              <div style={{ fontSize: 26, fontWeight: 700, color: s.color }}>{s.num}</div>
              <div style={{ fontSize: 12, color: '#888', marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Markets */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px', borderBottom: '1px solid #e5e5e5' }}>
        <div className="section-title" style={{ fontSize: 20, fontWeight: 600, textAlign: 'center', marginBottom: 20 }}>Works across 4 markets</div>
        <div className="landing-grid-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { flag: '🇮🇳', name: 'India', checkers: 'Alt News, BOOM Live, Vishvas News' },
            { flag: '🇩🇪', name: 'Germany', checkers: 'Correctiv, dpa-Faktencheck' },
            { flag: '🇺🇸', name: 'US', checkers: 'PolitiFact, Snopes, FactCheck.org' },
            { flag: '🇬🇧', name: 'UK', checkers: 'Full Fact, BBC Reality Check' },
          ].map((m, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 16 }}>
              <div style={{ fontSize: 26, marginBottom: 4 }}>{m.flag}</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{m.name}</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{m.checkers}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Trust */}
      <div className="section" style={{ maxWidth: 1100, margin: '0 auto', padding: '36px 20px' }}>
        <div className="trust-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
          {[
            { icon: '🔒', title: 'Privacy first', desc: 'Toxicity and bias analysis runs entirely on our servers. No content sent to third parties.' },
            { icon: '⛓️', title: 'Blockchain verified', desc: 'Every scan timestamped with SHA-256 hash. Tamper-proof evidence.' },
            { icon: '🚫', title: 'No verdicts', desc: 'Dissekt never says "true" or "false." It shows you HOW content is constructed — you decide.' },
          ].map((t, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 20, textAlign: 'center' }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>{t.icon}</div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{t.title}</div>
              <div style={{ fontSize: 13, color: '#555', lineHeight: 1.6 }}>{t.desc}</div>
            </div>
          ))}
        </div>
      </div>


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

      {/* CTA */}
      <div style={{ padding: '0 20px' }}>
        <div className="cta-section" style={{ background: '#7c3aed', borderRadius: 14, padding: '36px 20px', textAlign: 'center', margin: '36px auto', maxWidth: 800 }}>
          <div style={{ fontSize: 22, fontWeight: 700, color: '#fff', marginBottom: 6 }}>Information transparency for everyone.</div>
          <div style={{ fontSize: 13, color: '#d4bfff', marginBottom: 16 }}>Free · No signup · 10 scans per day</div>
          <button onClick={onTryFree} style={{ padding: '12px 24px', background: '#fff', color: '#7c3aed', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>Inspect any content →</button>
        </div>
      </div>

      {/* Footer */}
      <div style={{ borderTop: '1px solid #e5e5e5', padding: '16px 20px', textAlign: 'center', fontSize: 12, color: '#aaa' }}>
        <span style={{ fontWeight: 600, color: '#555' }}>Dissekt</span>
        <span style={{ margin: '0 6px' }}>·</span>Information transparency and argument inspection
        <span style={{ margin: '0 6px' }}>·</span><a href="mailto:sambitmallick123@gmail.com" style={{ color: '#7c3aed', textDecoration: 'none' }}>sambitmallick123@gmail.com</a>
        <span style={{ margin: '0 6px' }}>·</span>Munich, Germany · 2026
        <span style={{ margin: "0 6px" }}>·</span><a href="/privacy" style={{ color: "#7c3aed", textDecoration: "none" }}>Privacy Policy</a>
      </div>
    </div>
  );
}
