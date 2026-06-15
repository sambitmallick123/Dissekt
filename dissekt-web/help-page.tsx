'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const SECTIONS = [
  { id: 'overview', label: 'Overview' },
  { id: 'clarity', label: 'Clarity Score' },
  { id: 'engines', label: 'Engines' },
  { id: 'features', label: 'Features' },
  { id: 'access', label: 'Access & limits' },
  { id: 'methodology', label: 'Methodology' },
  { id: 'references', label: 'References' },
  { id: 'privacy', label: 'Privacy' },
  { id: 'faq', label: 'FAQ' },
];

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: 36 }}>
      <h2 style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', marginBottom: 12 }}>{title}</h2>
      <div style={{ fontSize: 14, color: '#444', lineHeight: 1.8 }}>{children}</div>
    </div>
  );
}

function H3({ children }: { children: React.ReactNode }) {
  return <h3 style={{ fontSize: 15, fontWeight: 600, color: '#1a1a1a', margin: '16px 0 6px' }}>{children}</h3>;
}

function Ref({ href, children }: { href: string; children: React.ReactNode }) {
  return <a href={href} target="_blank" rel="noopener" style={{ color: '#0d9488', textDecoration: 'none' }}>{children}</a>;
}

function EngineCard({ icon, name, children }: { icon: string; name: string; children: React.ReactNode }) {
  return (
    <div style={{ padding: '12px 14px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, marginBottom: 8 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
        <span style={{ fontSize: 15 }}>{icon}</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#0d9488' }}>{name}</span>
      </div>
      <div style={{ fontSize: 13, color: '#555', lineHeight: 1.6 }}>{children}</div>
    </div>
  );
}

export default function HelpPage() {
  const [active, setActive] = useState('overview');

  const scrollTo = (id: string) => {
    setActive(id);
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader active="Help" />
      <div style={{ maxWidth: 1000, margin: '0 auto', padding: '32px 16px', display: 'flex', gap: 32 }}>
        {/* Sidebar nav */}
        <aside style={{ width: 180, flexShrink: 0, position: 'sticky', top: 70, alignSelf: 'flex-start', display: 'none' }} className="help-sidebar">
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Contents</div>
          {SECTIONS.map(s => (
            <button key={s.id} onClick={() => scrollTo(s.id)} style={{ display: 'block', width: '100%', textAlign: 'left', padding: '5px 8px', fontSize: 13, color: active === s.id ? '#0d9488' : '#666', background: active === s.id ? '#f0fdfa' : 'transparent', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: active === s.id ? 600 : 400, marginBottom: 1 }}>
              {s.label}
            </button>
          ))}
        </aside>

        {/* Content */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: '#1a1a1a', marginBottom: 6 }}>Help & Methodology</h1>
          <p style={{ fontSize: 14, color: '#888', marginBottom: 28 }}>How Dissekt works, how the Clarity Score is calculated, and the research behind it.</p>

          {/* OVERVIEW */}
          <div id="overview">
            <Section title="👁️ What Dissekt does">
              <p>Dissekt analyzes how information is constructed. It does <strong>not</strong> tell you what is true or false — it shows you the techniques used, the evidence available, the context present or missing, and how the content is framed. You stay the judge; Dissekt gives you the tools to see clearly.</p>
              <p>Paste any article URL, social media post, or raw text. In seconds, 12 engines analyze it in parallel and return a transparency report with a single headline score and a full breakdown.</p>
              <div style={{ padding: '12px 16px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, marginTop: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>Transparent scoring</div>
                <div style={{ fontSize: 13, color: '#555', lineHeight: 1.6 }}>Every score is fully decomposed. You see exactly how each dimension and metric contributes — no black boxes. Click "How is this calculated?" on any analysis to see the breakdown.</div>
              </div>
            </Section>
          </div>

          {/* CLARITY SCORE */}
          <div id="clarity">
            <Section title="📊 Clarity Score — how it is calculated">
              <p>The Clarity Score runs from <strong>0.00 (opaque)</strong> to <strong>1.00 (transparent)</strong>. It measures how clearly information is constructed, verified, and intended — not whether it is true or false. The score combines three independent dimensions using a geometric mean, so one weak dimension cannot be hidden by strong ones.</p>

              <H3>Headline formula</H3>
              <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 8, fontFamily: 'monospace', fontSize: 12, marginBottom: 12 }}>
                Clarity = (Construction × Verification × Intent) ^ ⅓
              </div>

              <H3>Color legend</H3>
              <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginBottom: 12 }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13 }}><span style={{ width: 10, height: 10, borderRadius: 3, background: '#16a34a' }} /> 0.65–1.00 High transparency</span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13 }}><span style={{ width: 10, height: 10, borderRadius: 3, background: '#d97706' }} /> 0.35–0.64 Moderate</span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13 }}><span style={{ width: 10, height: 10, borderRadius: 3, background: '#dc2626' }} /> 0.00–0.34 Low transparency</span>
              </div>

              <H3>🏗️ Construction — &quot;How is it built?&quot;</H3>
              <p>Measures the structural quality of the content, independent of whether it is true. Weighted geometric mean of three metrics:</p>
              <p><strong>Rhetoric (×0.40):</strong> 1 − severity-weighted technique penalties. Each detected technique is weighted by how manipulative it is — a straw man (severity 10) hurts more than loaded language (severity 3). Severity weights derived from the SemEval propaganda corpus (Da San Martino et al., EMNLP 2019).</p>
              <p><strong>Argumentation (×0.35):</strong> Logical structure quality — are claims supported, are arguments coherent, does the conclusion follow? Based on computational argumentation research (Wachsmuth et al., ACL 2017).</p>
              <p><strong>Completeness (×0.25):</strong> Whether the content answers who, what, when, cites sources, and presents a counter-view. Manipulation by omission is invisible to technique detection — this catches it.</p>

              <H3>✅ Verification — &quot;How verified is it?&quot;</H3>
              <p>Measures external validation. Only metrics that have real data are counted — missing signals do not drag the score toward neutral.</p>
              <p><strong>Evidence (×0.40):</strong> Fact-checker consensus, weighted by organization tier (Gold/IFCN = 1.0, Established = 0.7, Emerging = 0.4). A claim disputed by multiple Gold-tier checkers scores low; one confirmed scores high.</p>
              <p><strong>Source (×0.25):</strong> Media Bias/Fact Check factuality rating of the source domain, across 231 rated outlets.</p>
              <p><strong>Diversity (×0.20):</strong> How many independent, named source categories are cited. &quot;Sources say&quot; scores low; &quot;WHO data confirmed by a Lancet study and the health ministry&quot; scores high.</p>
              <p><strong>Temporal (×0.20):</strong> Whether claims have held up over time, drawn from our accumulated analysis history. Improves as the knowledge graph grows.</p>

              <H3>🎯 Intent — &quot;What does it want me to do?&quot;</H3>
              <p>Measures persuasion pressure and emotional direction.</p>
              <p><strong>Manipulation (×0.40):</strong> Cumulative persuasion pressure — urgency phrases, calls to action, emotional escalation, binary framing, and aggression density. Grounded in persuasion research (Cialdini, 2007).</p>
              <p><strong>Tone (×0.35):</strong> Context-aware hostility. Quoted speech is separated from the author&apos;s own voice, toxicity is adjusted for genre (an editorial is naturally more charged than a wire report), and rhetorical hostility is measured separately from profanity (Pavlopoulos et al., EACL 2021; Sap et al., ALW 2020).</p>
              <p><strong>Narrative direction (×0.25):</strong> How far the framing leans from neutral on two axes — skepticism↔trust and fear↔hope (Card et al., ACL 2018). Neutral framing scores high; strongly directional framing scores lower.</p>

              <H3>Why a geometric mean?</H3>
              <p>An arithmetic average lets a great score in one area mask a terrible score in another. The geometric mean does not — an article with excellent rhetoric but disputed evidence cannot hide behind its writing quality. This is the same reason the UN Human Development Index switched to a geometric mean in 2010.</p>

              <H3>Confidence band</H3>
              <p><strong>High</strong> (average technique confidence 0.8+): strong signals detected with certainty.</p>
              <p><strong>Medium</strong> (0.5–0.8): moderate signals; Detailed mode may add clarity.</p>
              <p><strong>Low</strong> (below 0.5): signals present but not definitive — interpret with caution.</p>

              <H3>Limitations</H3>
              <p>The Clarity Score is a composite signal, not ground truth. It does not determine truth or falsehood. Satire, opinion, and persuasive essays score lower by design without being misinformation — a low score means the content <em>uses techniques that can be manipulative</em>, not that it necessarily is. Where a dimension has no data (for example, no fact-checks exist yet), that dimension is excluded rather than guessed, so absence of evidence is not treated as evidence.</p>
            </Section>
          </div>

          {/* ENGINES */}
          <div id="engines">
            <Section title="🔭 The 12 engines">
              <p>Every scan runs through 12 specialized engines in parallel, each named after an optical instrument.</p>
              <EngineCard icon="🔦" name="Beacon">Orchestrator. Extracts content (3-method fallback: Trafilatura → httpx → Playwright), auto-detects social platforms, and runs all engines in parallel via asyncio.</EngineCard>
              <EngineCard icon="🔺" name="Prism">Detects 20 manipulation techniques (loaded language, cherry-picking, straw man, appeal to fear, etc.) with confidence scores. Heuristic-first, escalates to GPT-4o mini or Claude for detailed mode.</EngineCard>
              <EngineCard icon="🔎" name="Lens">Cross-references claims against 100+ fact-checking organizations via Google Fact Check API and SerpAPI.</EngineCard>
              <EngineCard icon="🌈" name="Spectrum">Toxicity (Detoxify), source credibility (231-source MBFC database), and sentiment (VADER).</EngineCard>
              <EngineCard icon="💎" name="Crystal">Blockchain evidence — SHA-256 hash + OpenTimestamps proof, so an analysis can be verified as unaltered.</EngineCard>
              <EngineCard icon="🔗" name="Lattice">Knowledge graph in Qdrant. Stores claims as embeddings to find similar past analyses and track claims over time.</EngineCard>
              <EngineCard icon="🔭" name="Scope">Monitors 29 RSS feeds across 5 markets, surfacing fresh articles to analyze.</EngineCard>
              <EngineCard icon="💠" name="Facet">Extracts individual verifiable claims and types them (statistic, quote, event).</EngineCard>
              <EngineCard icon="👁" name="Iris">Detects input language (English, Hindi, German).</EngineCard>
              <EngineCard icon="🧭" name="Meridian">Political accountability — recognizes 69 politicians across India, US, Germany, and the UK, surfacing relevant context.</EngineCard>
              <EngineCard icon="🔥" name="Flare">Coordination detection — flags signs of coordinated inauthentic behavior (volume spikes, duplicate phrasing, temporal patterns).</EngineCard>
              <EngineCard icon="🪞" name="Mirror">Generates alternative framings of key claims — as stated, with context, and what is omitted.</EngineCard>
            </Section>
          </div>

          {/* FEATURES */}
          <div id="features">
            <Section title="🛠️ Features — what you can do">
              <EngineCard icon="🔍" name="Loupe">Inline annotations — highlights detected techniques directly in the text with hover tooltips.</EngineCard>
              <EngineCard icon="✍️" name="Polish">Pre-publish check for writers — shows which techniques your draft uses, with rewrite suggestions.</EngineCard>
              <EngineCard icon="🔮" name="Kaleidoscope">Analyze one claim from 5 editorial perspectives at once.</EngineCard>
              <EngineCard icon="🪞" name="Reflect">Personal bias profile — discover your own reading patterns over time.</EngineCard>
              <EngineCard icon="📒" name="Ledger">Decision journal — mark content Trust / Unsure / Reject and track your judgments.</EngineCard>
              <EngineCard icon="🕸️" name="Trust Graph">Visualize your trust patterns per source.</EngineCard>
              <EngineCard icon="🧵" name="Thread">Track how a claim evolved from first appearance to fact-check response.</EngineCard>
              <EngineCard icon="🔬" name="Imprint">Source fingerprinting — which techniques each outlet uses most.</EngineCard>
              <EngineCard icon="🏷️" name="Seal">Embeddable transparency badge for news sites. One script tag shows a live Clarity Score on any article; click opens the full analysis.</EngineCard>
              <EngineCard icon="📧" name="Dispatch">Weekly digest with auto-scanned articles and trending techniques.</EngineCard>
            </Section>
          </div>

          {/* ACCESS */}
          <div id="access">
            <Section title="🎫 Access & limits">
              <p>Dissekt is free to use with no signup. Invited users get higher limits and all features.</p>
              <H3>Free</H3>
              <p>3 brief scans and 1 detailed scan per day. Resets at 00:00 GMT. Help and Feedback are always available.</p>
              <H3>Invited</H3>
              <p>25 brief and 10 detailed scans per day, all features unlocked (Bulk CSV, Compare, API, personal dashboard), valid for 6 months. Request access via the Get access button.</p>
              <H3>Brief vs Detailed</H3>
              <p><strong>Brief</strong> uses heuristics and GPT-4o mini for fast analysis. <strong>Detailed</strong> escalates to Claude for deeper technique detection and richer explanations.</p>
            </Section>
          </div>

          {/* METHODOLOGY */}
          <div id="methodology">
            <Section title="🔬 Methodology">
              <p>Dissekt combines rule-based heuristics, fine-tuned classifiers, and large language models. Technique detection is heuristic-first for speed and consistency, escalating to LLMs only when needed. Toxicity uses a local Detoxify model adjusted for news context. Source credibility draws on the Media Bias/Fact Check database. Fact-checks come from IFCN-accredited organizations, tiered by credibility.</p>
              <p>The scoring model is deliberately transparent: every metric is decomposable and every weight is documented above. We favor explainability over a black-box model so you can audit and disagree with any individual signal.</p>
            </Section>
          </div>

          {/* REFERENCES */}
          <div id="references">
            <Section title="📚 References">
              <p><Ref href="https://aclanthology.org/D19-1565/">Da San Martino et al., EMNLP 2019</Ref> — Fine-grained analysis of propaganda in news articles. Basis for technique severity weights.</p>
              <p><Ref href="https://aclanthology.org/D18-1389/">Baly et al., EMNLP 2018</Ref> — Predicting factuality and bias of news media (multi-dimensional credibility).</p>
              <p><Ref href="https://aclanthology.org/P17-1002/">Wachsmuth et al., ACL 2017</Ref> — Computational argumentation quality assessment.</p>
              <p><Ref href="https://aclanthology.org/P18-1017/">Card et al., ACL 2018</Ref> — The Media Frames Corpus; framing direction.</p>
              <p><Ref href="https://aclanthology.org/2021.eacl-main.114/">Pavlopoulos et al., EACL 2021</Ref> — Toxicity detection: does context matter?</p>
              <p><Ref href="https://aclanthology.org/2020.alw-1.18/">Sap et al., ALW 2020</Ref> — Social bias frames; hostile framing vs explicit toxicity.</p>
              <p><Ref href="https://www.nltk.org/">Hutto & Gilbert, ICWSM 2014</Ref> — VADER sentiment analysis for social media text.</p>
              <p>Cialdini, 2007 — Influence: The Psychology of Persuasion. Foundation for the manipulation-pressure model.</p>
              <p><Ref href="https://hdr.undp.org/data-center/human-development-index">UNDP Human Development Index</Ref> — Geometric mean for composite indices.</p>
              <p><Ref href="https://mediabiasfactcheck.com/methodology/">Media Bias/Fact Check</Ref> — Source credibility methodology and 231-source database.</p>
              <p><Ref href="https://ifcncodeofprinciples.poynter.org/">IFCN Code of Principles</Ref> — Fact-checker accreditation standard.</p>
              <p>Hartung & Mallick, TSD 2024 — Evaluation metrics in LLM code generation.</p>
            </Section>
          </div>

          {/* PRIVACY */}
          <div id="privacy">
            <Section title="🔒 Privacy">
              <p>Analyses are stored to power features like Thread, Lattice, and your personal dashboard. We do not sell data. Free usage is tracked locally in your browser. See the <a href="/privacy" style={{ color: '#0d9488', textDecoration: 'none' }}>Privacy Policy</a> for full detail.</p>
            </Section>
          </div>

          {/* FAQ */}
          <div id="faq">
            <Section title="❓ FAQ">
              <H3>Does a low score mean the content is false?</H3>
              <p>No. A low Clarity Score means the content uses techniques that can be manipulative, is disputed by fact-checkers, or is framed to provoke — not that it is necessarily false. Satire and opinion score lower by design.</p>
              <H3>Why did my article score in the middle?</H3>
              <p>A moderate score (0.35–0.64) usually means mixed signals — for example, sound rhetoric but no external verification available, or good sourcing with charged framing. Expand each dimension to see which metric is responsible.</p>
              <H3>Can I analyze social media?</H3>
              <p>Yes — paste a URL from news sites, Reddit, YouTube, Bluesky, Mastodon, or Substack. Dissekt auto-detects the platform and extracts the full content.</p>
              <H3>Is there an API?</H3>
              <p>Yes, for invited users. See the <a href="/docs" style={{ color: '#0d9488', textDecoration: 'none' }}>API documentation</a>.</p>
            </Section>
          </div>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
