'use client';
import SiteHeader from './SiteHeader';
import SiteFooter from './SiteFooter';

export default function LandingPage({ onSignIn, onTryFree }: { onSignIn: () => void; onTryFree: () => void; onShowFeedback?: () => void }) {
  return (
    <>
      <SiteHeader />

      {/* Hero */}
      <section style={{ background: '#fff', borderBottom: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '60px 24px', textAlign: 'center' }}>
          <h1 style={{ fontSize: 36, fontWeight: 700, color: '#1a1a1a', lineHeight: 1.3, marginBottom: 12 }}>
            See how information<br />is constructed
          </h1>
          <p style={{ fontSize: 16, color: '#888', maxWidth: 520, margin: '0 auto 24px', lineHeight: 1.6 }}>
            Every article frames information differently. Dissekt makes that framing visible — so you can think for yourself.
          </p>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 12, marginBottom: 16 }}>
            <button onClick={onTryFree} style={{ padding: '12px 28px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>
              Inspect any content
            </button>
            <button onClick={onSignIn} style={{ padding: '12px 28px', background: '#fff', color: '#0d9488', border: '1px solid #0d9488', borderRadius: 10, fontSize: 15, fontWeight: 600, cursor: 'pointer' }}>
              Get access
            </button>
          </div>
          <p style={{ fontSize: 12, color: '#aaa' }}>Free · 3 brief + 1 detailed scan/day · Resets 00:00 GMT · No signup required</p>
        </div>
      </section>

      {/* How it works */}
      <section style={{ background: '#fafaf8' }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '48px 24px' }}>
          <h2 style={{ fontSize: 22, fontWeight: 700, textAlign: 'center', marginBottom: 8, color: '#1a1a1a' }}>How Dissekt works</h2>
          <p style={{ fontSize: 14, color: '#888', textAlign: 'center', marginBottom: 32 }}>Not a fact-checker. Not an AI detector. An information debugger.</p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
            {[
              { n: '1', t: 'You paste content', d: 'A URL, article text, screenshot, or claim. Dissekt accepts any format.' },
              { n: '2', t: 'Engines analyze it', d: 'Prism identifies techniques. Lens finds cross-references. Spectrum scores evidence. Meridian checks political context.' },
              { n: '3', t: 'You see the framing', d: 'Transparency score, alternative framings, extracted claims — everything you need to think critically.' },
            ].map(s => (
              <div key={s.n} style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12, padding: '20px' }}>
                <div style={{ width: 32, height: 32, borderRadius: 8, background: '#f0fdfa', color: '#0d9488', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 14, marginBottom: 10 }}>{s.n}</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 4 }}>{s.t}</div>
                <div style={{ fontSize: 12, color: '#888', lineHeight: 1.6 }}>{s.d}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Engines */}
      <section style={{ background: '#fff', borderTop: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '48px 24px' }}>
          <h2 style={{ fontSize: 22, fontWeight: 700, textAlign: 'center', marginBottom: 32, color: '#1a1a1a' }}>10 analysis engines</h2>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
            {[
              { icon: '🔍', name: 'Prism', desc: '20 manipulation techniques detected with confidence scores — loaded language, cherry-picking, appeal to fear, and more.' },
              { icon: '🌐', name: 'Lens', desc: 'Focuses on cross-references 100+ fact-checking organizations automatically. Shows what others have verified.' },
              { icon: '📊', name: 'Spectrum', desc: 'Evidence provenance — toxicity, sentiment, source credibility from 231 outlets.' },
              { icon: '🏛️', name: 'Meridian', desc: 'Political context for 30+ Indian and 10+ US politicians. Voting records, promises, accountability.' },
              { icon: '📡', name: 'Scope', desc: '16 RSS feeds across India, US, Germany, UK. Risk-scored headlines updated every 6 hours.' },
              { icon: '🔗', name: 'Lattice', desc: 'Every analysis builds a knowledge graph. Find similar claims across your analysis history.' },
              { icon: '🔄', name: 'Mirror', desc: 'Shows alternative framings — "as stated" vs "with more context" vs "what\'s omitted".' },
              { icon: '⚡', name: 'Flare', desc: 'Coordination detection — volume spikes, near-duplicates, temporal bursts, technique patterns.' },
              { icon: '📝', name: 'Facet', desc: 'Extracts individual verifiable claims with types (statistic, quote, event, prediction, causal).' },
              { icon: '🔒', name: 'Crystal', desc: 'SHA-256 + OpenTimestamps blockchain proof. Immutable record of what was analyzed and when.' },
            ].map(e => (
              <div key={e.name} style={{ display: 'flex', gap: 12, padding: '12px 14px', borderRadius: 10, border: '0.5px solid #e5eaea' }}>
                <span style={{ fontSize: 20, flexShrink: 0 }}>{e.icon}</span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{e.name}</div>
                  <div style={{ fontSize: 11, color: '#888', lineHeight: 1.5 }}>{e.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Access tiers */}
      <section style={{ background: '#fafaf8', borderTop: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '48px 24px' }}>
          <h2 style={{ fontSize: 22, fontWeight: 700, textAlign: 'center', marginBottom: 32, color: '#1a1a1a' }}>Access tiers</h2>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, maxWidth: 640, margin: '0 auto' }}>
            <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12, padding: '24px 20px' }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>🆓 Free</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>
                3 brief scans/day<br />
                1 detailed scan/day<br />
                Single analysis<br />
                Scope feeds<br />
                Resets 00:00 GMT
              </div>
              <button onClick={onTryFree} style={{ marginTop: 16, width: '100%', padding: '8px 0', background: '#f0fdfa', color: '#0d9488', border: '0.5px solid #ccfbf1', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
                Start free
              </button>
            </div>
            <div style={{ background: '#fff', border: '2px solid #0d9488', borderRadius: 12, padding: '24px 20px', position: 'relative' }}>
              <div style={{ position: 'absolute', top: -10, right: 16, background: '#0d9488', color: '#fff', fontSize: 10, fontWeight: 600, padding: '2px 10px', borderRadius: 4 }}>RECOMMENDED</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>🎫 Invited</div>
              <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>
                25 brief scans/day<br />
                10 detailed scans/day<br />
                Bulk CSV analysis<br />
                Compare sources<br />
                Topic tracking<br />
                All engines unlocked
              </div>
              <button onClick={onSignIn} style={{ marginTop: 16, width: '100%', padding: '8px 0', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
                Request access
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* For organizations */}
      <section style={{ background: '#fff', borderTop: '0.5px solid #e5eaea' }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '48px 24px', textAlign: 'center' }}>
          <h2 style={{ fontSize: 22, fontWeight: 700, marginBottom: 8, color: '#1a1a1a' }}>For organizations</h2>
          <p style={{ fontSize: 14, color: '#888', marginBottom: 24 }}>Newsrooms, research teams, and analysts can integrate Dissekt via API.</p>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 32 }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>10</div>
              <div style={{ fontSize: 11, color: '#888' }}>Engines</div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>20</div>
              <div style={{ fontSize: 11, color: '#888' }}>Techniques</div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>4</div>
              <div style={{ fontSize: 11, color: '#888' }}>Markets</div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>100+</div>
              <div style={{ fontSize: 11, color: '#888' }}>Fact-check orgs</div>
            </div>
          </div>
          <a href="/docs" style={{ display: 'inline-block', marginTop: 20, fontSize: 13, color: '#0d9488', textDecoration: 'none', fontWeight: 600 }}>View API documentation →</a>
        </div>
      </section>

      <SiteFooter />
    </>
  );
}
