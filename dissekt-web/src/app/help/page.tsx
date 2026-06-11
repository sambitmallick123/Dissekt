'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const components = [
  {
    icon: '🎯',
    name: 'Threat Score',
    color: '#dc2626',
    desc: 'An overall risk score from 0 to 100 based on the combination of manipulation techniques found, existing cross-references, and toxicity level.',
    details: [
      'Score 0-39: Low risk — few or no manipulation signals detected',
      'Score 40-69: Medium risk — some manipulation techniques or disputed claims found',
      'Score 70-100: High risk — strong manipulation signals with multiple cross-references flagging the content',
      'The score is calculated from: technique confidence (40%), fact-check count (30%), toxicity (20%), and cross-referencing bonus (10%)',
    ]
  },
  {
    icon: '👁',
    name: 'Prism — Manipulation Techniques',
    color: '#0d9488',
    desc: 'Identifies specific manipulation techniques used in the content. Dissekt detects 20 techniques across 4 categories.',
    details: [
      'Framing: loaded language, emotional framing, cherry picking, misleading headlines',
      'Logical fallacies: hasty generalization, false equivalence, straw man, slippery slope',
      'Credibility manipulation: appeal to authority, bandwagon, testimonial, transfer',
      'Deflection: whataboutism, red herring, ad hominem, scapegoating',
      'Each technique shows: confidence score (0-100%), category badge, explanation, and evidence quote from the text',
      'Brief mode uses GPT-4o mini (~3s), Detailed mode uses Claude Sonnet 4 (~15s)',
    ]
  },
  {
    icon: '🌐',
    name: 'Trace — Fact-Checks & Sources',
    color: '#2563eb',
    desc: 'Searches 100+ fact-checking organizations worldwide for existing cross-references on the claim, and traces the spread timeline.',
    details: [
      'Searches: FactCheck.org, Full Fact, PolitiFact, AP Fact Check, Snopes, Alt News, BOOM Live, Correctiv, and 90+ more',
      'Each fact-check shows: publisher, title, rating (True/False/Misleading/Mixed), and link to original',
      'Spread timeline shows where the claim appeared across platforms with dates',
      'Covers 4 markets: India, Germany, US, UK — with local fact-checkers for each',
    ]
  },
  {
    icon: '📊',
    name: 'Signal — Source Credibility',
    color: '#d97706',
    desc: 'Scores the source\'s credibility using bias ratings, factuality scores, toxicity analysis, and sentiment detection.',
    details: [
      'Source bias: rated from Left to Right using the MBFC database (231 news sources)',
      'Factuality: rated from Very Low to Very High based on the source\'s track record',
      'Toxicity: Detoxify model scores 6 categories — toxicity, severe toxicity, obscenity, threat, insult, identity attack',
      'Sentiment: VADER compound score (-1 to +1) classified as positive, negative, or neutral',
      'All Signal models run locally on the server — zero data sent to external services',
    ]
  },
  {
    icon: '🔒',
    name: 'Meta — Evidence & Blockchain',
    color: '#059669',
    desc: 'Shows analysis metadata and generates a tamper-proof evidence hash for every scan.',
    details: [
      'Analysis time: how long the scan took (typically 3-5 seconds for Brief, 10-15s for Detailed)',
      'Model: which AI model was used — GPT-4o mini (Brief) or Claude Sonnet 4 (Detailed)',
      'Cache: whether the result was served from Redis cache (instant) or freshly analyzed',
      'SHA-256 hash: a unique fingerprint of the analyzed content for evidence integrity',
      'OpenTimestamps: blockchain anchoring for court-admissible proof of existence',
    ]
  },
  {
    icon: '📋',
    name: 'Extracted Claims',
    color: '#6366f1',
    desc: 'AI extracts individual verifiable factual claims from the content, each tagged by type.',
    details: [
      'Statistic: numerical claims that can be verified against data sources',
      'Quote: attributed statements that can be checked against the original',
      'Event: claims about things that happened which can be verified',
      'Prediction: forward-looking claims about future events',
      'Causal: claims that X causes Y, which can be evaluated against evidence',
      'Up to 7 claims extracted per analysis using GPT-4o mini',
    ]
  },
  {
    icon: '🔍',
    name: 'Similar Claims',
    color: '#8b5cf6',
    desc: 'Shows previously analyzed claims that are similar to the current one, building a knowledge graph over time.',
    details: [
      'Every analysis is stored as a vector embedding in Qdrant',
      'When you scan something, Dissekt searches for similar past analyses',
      'Similarity score (0-100%) shows how closely related the claims are',
      'The more people use Dissekt, the more connections it finds — this is the knowledge moat',
    ]
  },
  {
    icon: '🏛',
    name: 'Compass — Political Accountability',
    color: '#d97706',
    desc: 'Detects politician names in content and cross-references claims against their voting records, promises, and factual data.',
    details: [
      'Detects mentions of Indian politicians using name recognition',
      'Shows politician profile: party, position, constituency, terms served',
      'Displays key votes and key promises for context',
      'Flags when controversies or promises are referenced in the content',
      'Provides factual context notes from verified sources',
      'Currently covers India — US, Germany, UK coming in future updates',
    ]
  },
  {
    icon: '📡',
    name: 'Pulse — Coordination Detection',
    color: '#dc2626',
    desc: 'Detects signs of coordinated amplification — when multiple similar claims appear in patterns suggesting organized pushing.',
    details: [
      'Volume spike: flags when many similar claims exist in the knowledge base',
      'Near-duplicate detection: finds claims with >85% text similarity',
      'Temporal burst: detects multiple similar claims within 24 hours',
      'Technique pattern: flags when similar claims all use the same manipulation technique',
      'Risk levels: High (likely coordinated), Medium (suspicious patterns), Low (notable but inconclusive)',
      'Note: coordination signals suggest organized amplification, not necessarily falsehood',
    ]
  },
  {
    icon: '📡',
    name: 'Radar',
    color: '#ea580c',
    desc: 'Live RSS feeds from fact-checkers and news sources across 4 markets, with risk badges.',
    details: [
      '16 RSS feeds from India, Germany, US, UK',
      '🔴 High risk: headlines with words like "shocking", "conspiracy", "exposed"',
      '🟡 Medium risk: headlines with "fact-check", "debunk", "misleading"',
      '🟢 Low risk: standard news headlines',
      'Cached in Redis for 6 hours, with manual refresh option',
      'Click "Analyze" on any Radar item to scan it instantly',
    ]
  },
];

export default function HelpPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <SiteHeader />

      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>How Dissekt works</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 28 }}>Every component explained — what it does, how it works, and what the numbers mean.</p>

        
        <div style={{ background: '#0d9488', borderRadius: 14, padding: '24px 20px', marginBottom: 24, color: '#fff' }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>Our approach</h2>
          <p style={{ fontSize: 13, lineHeight: 1.7, opacity: 0.9, marginBottom: 12 }}>
            Dissekt is interpretation infrastructure for the information age. It never tells you what's true or false. Instead, it shows you <em>how</em> content is constructed to influence you — the techniques, the framing, the missing context.
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Heuristics first, AI second</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>9 statistical models run instantly at zero cost. LLMs are only called when heuristics need confirmation — saving money and reducing hallucination risk.</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Transparent scoring</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>Every score is decomposed. You see exactly how much each factor contributes — technique confidence, cross-references, toxicity. No black boxes.</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>You correct us</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>Every technique has a 👍/👎 button. Your corrections train future models. The more you use Dissekt, the better it gets — for everyone.</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Multiple sources, one view</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>We check 100+ fact-checkers, 231 media sources, and our own growing knowledge base. Cross-referencing beats any single source.</div>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {components.map((c, i) => (
            <div key={i} style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, overflow: 'hidden' }}>
              <div style={{ padding: '16px 20px', borderBottom: '1px solid #f0f0ee', display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ fontSize: 24 }}>{c.icon}</span>
                <div>
                  <div style={{ fontSize: 16, fontWeight: 600, color: c.color }}>{c.name}</div>
                  <div style={{ fontSize: 13, color: '#555', lineHeight: 1.5, marginTop: 2 }}>{c.desc}</div>
                </div>
              </div>
              <div style={{ padding: '14px 20px' }}>
                {c.details.map((d, j) => (
                  <div key={j} style={{ display: 'flex', gap: 8, marginBottom: 8, fontSize: 13, color: '#404040', lineHeight: 1.6 }}>
                    <span style={{ color: c.color, flexShrink: 0, marginTop: 2 }}>•</span>
                    <span>{d}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div style={{ textAlign: 'center', marginTop: 32, paddingTop: 20, borderTop: '1px solid #e5e5e5' }}>
          <a href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '10px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>
            Try Dissekt now →
          </a>
          <p style={{ fontSize: 12, color: '#aaa', marginTop: 8 }}>Free · 3 brief + 1 detailed scan/day · No signup required</p>
        </div>
      </div>
    <SiteFooter />
    </main>
  );
}
