'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';
import { useState } from 'react';

const sections = [
  { id: 'approach', label: 'Our approach' },
  { id: 'engines', label: '12 Engines' },
  { id: 'clarity', label: 'Clarity Score' },
  { id: 'features', label: 'Features' },
  { id: 'techniques', label: '20 Techniques' },
  { id: 'heuristics', label: '9 Heuristics' },
  { id: 'methodology', label: 'Methodology' },
  { id: 'references', label: 'References' },
  { id: 'tiers', label: 'Access tiers' },
];

function Ref({ href, children }: { href: string; children: React.ReactNode }) {
  return <a href={href} target="_blank" rel="noopener" style={{ color: '#0d9488', textDecoration: 'none' }}>{children} ↗</a>;
}

function Section({ title, children, defaultOpen }: { title: string; children: React.ReactNode; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(!!defaultOpen);
  return (
    <div style={{ marginBottom: 8 }}>
      <button onClick={() => setOpen(!open)}
        style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 18px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: open ? '12px 12px 0 0' : 12, cursor: 'pointer', fontSize: 15, fontWeight: 600, color: '#1a1a1a', textAlign: 'left' }}>
        {title}
        <span style={{ fontSize: 18, color: '#0d9488', transition: 'transform 0.2s', transform: open ? 'rotate(180deg)' : 'none' }}>▾</span>
      </button>
      {open && (
        <div style={{ padding: '18px 20px', background: '#fff', border: '0.5px solid #e5eaea', borderTop: 'none', borderRadius: '0 0 12px 12px', fontSize: 13, color: '#404040', lineHeight: 1.8 }}>
          {children}
        </div>
      )}
    </div>
  );
}

function H3({ children }: { children: React.ReactNode }) {
  return <div style={{ fontSize: 14, fontWeight: 600, color: '#0d9488', margin: '16px 0 6px' }}>{children}</div>;
}

function Tag({ children }: { children: React.ReactNode }) {
  return <span style={{ fontSize: 10, padding: '2px 6px', borderRadius: 4, background: '#f0fdfa', color: '#0d9488', fontWeight: 600, marginLeft: 6 }}>{children}</span>;
}

function EngineCard({ icon, name, tag, children }: { icon: string; name: string; tag?: string; children: React.ReactNode }) {
  return (
    <div style={{ padding: '12px 0', borderBottom: '0.5px solid #f0f0ee' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
        <span style={{ fontSize: 16 }}>{icon}</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>{name}</span>
        {tag && <Tag>{tag}</Tag>}
      </div>
      <div style={{ paddingLeft: 28, fontSize: 13, color: '#555', lineHeight: 1.8 }}>{children}</div>
    </div>
  );
}

export default function HelpPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader active="Help" />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4, color: '#1a1a1a' }}>How Dissekt works</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 24 }}>Every engine, feature, and score explained — with the science behind it.</p>

        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 20 }}>
          {sections.map(s => (
            <a key={s.id} href={`#${s.id}`}
              style={{ padding: '4px 12px', borderRadius: 6, fontSize: 11, fontWeight: 600, background: '#fff', color: '#555', boxShadow: '0 0 0 0.5px #e5eaea', textDecoration: 'none' }}>
              {s.label}
            </a>
          ))}
        </div>

        {/* =========== OUR APPROACH =========== */}
        <div id="approach">
          <Section title="🔍 Our approach — what Dissekt is" defaultOpen>
            <p>Dissekt is an information transparency platform. It does not tell you what is true or false. Instead, it shows you <strong>how</strong> information is constructed — what techniques are used, what evidence exists, what context is missing, and how different sources frame the same story.</p>
            <p style={{ marginTop: 10 }}>Think of it as an X-ray for content. A doctor does not tell you whether to have surgery — they show you the scan. Dissekt shows you the scan of any article, claim, or URL.</p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, margin: '16px 0' }}>
              <div style={{ background: '#f0fdfa', borderRadius: 8, padding: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>Heuristics first, AI second</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6 }}>9 statistical heuristics run instantly at zero cost. LLMs are only called when heuristics need confirmation — saving money and reducing hallucination risk.</div>
              </div>
              <div style={{ background: '#f0fdfa', borderRadius: 8, padding: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>Transparent scoring</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6 }}>Every score is decomposed. You see exactly how each factor contributes — technique confidence, cross-references, toxicity. No black boxes.</div>
              </div>
              <div style={{ background: '#f0fdfa', borderRadius: 8, padding: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>You correct us</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6 }}>Every technique has a correction button. Your feedback trains future models. The more you use Dissekt, the better it gets — for everyone.</div>
              </div>
              <div style={{ background: '#f0fdfa', borderRadius: 8, padding: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#0d9488', marginBottom: 4 }}>The optics metaphor</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6 }}>Every component is named after optical instruments — Prism, Lens, Spectrum, Crystal — because information transparency is about seeing clearly.</div>
              </div>
            </div>

            <H3>What Dissekt is NOT</H3>
            <p>Not a fact-checker (we surface existing fact-checks, we do not create new ones). Not an AI detector. Not a bias rater. Not a censor. We never block, filter, or remove content.</p>
          </Section>
        </div>

        {/* =========== 12 ENGINES =========== */}
        <div id="engines">
          <Section title="⚙️ 12 Engines — the analysis pipeline">
            <EngineCard icon="🔦" name="Beacon" tag="Orchestrator">
              The master pipeline. Receives your input (URL, text, or image), extracts content using Trafilatura, httpx, or Playwright (3-method fallback), and dispatches to all engines in parallel using asyncio.gather for ~50% latency reduction.
            </EngineCard>

            <EngineCard icon="🔺" name="Prism" tag="GPT-4o mini / Claude Sonnet 4">
              Identifies 20 manipulation techniques with confidence scores. Three modes: heuristic-only (free, instant), Brief (GPT-4o mini, ~3s), and Detailed (Claude Sonnet 4, ~8s). The heuristic-first architecture detects basic techniques at zero cost and escalates to LLMs only for nuanced detection.
            </EngineCard>

            <EngineCard icon="🔎" name="Lens" tag="Google Fact Check API + SerpAPI">
              Searches 100+ fact-checking organizations (FactCheck.org, PolitiFact, Snopes, Full Fact, Alt News, BOOM, and others) for existing verification. Does not create fact-checks — surfaces what professionals have already published. Also tracks claim spread timeline across news sources.
            </EngineCard>

            <EngineCard icon="🌈" name="Spectrum" tag="Detoxify + VADER + MBFC">
              Three sub-signals: <strong>Toxicity</strong> (Detoxify BERT model, Jigsaw dataset, 1.8M+ comments). <strong>Sentiment</strong> (VADER rule-based, compound score -1 to +1). <strong>Source credibility</strong> (MBFC database, 231 outlets rated for factuality and bias). All run locally — no external API calls.
            </EngineCard>

            <EngineCard icon="💎" name="Crystal" tag="SHA-256 + OpenTimestamps">
              Creates immutable, timestamped records. SHA-256 hash of input submitted to Bitcoin blockchain via OpenTimestamps. Proves what was analyzed and when, without revealing content. Use case: proving a now-deleted article existed.
            </EngineCard>

            <EngineCard icon="🔗" name="Lattice" tag="Qdrant + OpenAI embeddings">
              Every analysis stored as a 1536-dimension vector embedding (text-embedding-3-small). New content is matched against past analyses using cosine similarity, building a growing knowledge graph. The more people analyze, the more connections emerge.
            </EngineCard>

            <EngineCard icon="🔭" name="Scope" tag="16 RSS feeds">
              Monitors 16 feeds across India (The Hindu, NDTV, India Today, Times of India), US (CNN, Fox, AP, Reuters), Germany (Tagesschau, Spiegel), and UK (BBC, Guardian). Headlines risk-scored with keyword analysis. 6-hour Redis cache.
            </EngineCard>

            <EngineCard icon="💠" name="Facet" tag="GPT-4o mini">
              Extracts individual verifiable claims, each tagged: statistic, quote, event, prediction, or causal claim. Each links to search on Google, Snopes, PolitiFact, and Alt News.
            </EngineCard>

            <EngineCard icon="👁" name="Iris">
              Auto-detects language (English, Hindi, German) and adjusts LLM prompts accordingly. Ensures culturally-aware technique detection across languages.
            </EngineCard>

            <EngineCard icon="🧭" name="Meridian" tag="30 India + 10 US politicians">
              NER identifies politician mentions and surfaces profiles: party, position, key votes, promises, controversies. Alias detection ("NaMo" → Modi, "AOC" → Ocasio-Cortez). Sources: MyNeta.info, PRS Legislative Research, Congress.gov, ProPublica.
            </EngineCard>

            <EngineCard icon="🔥" name="Flare">
              Detects coordination patterns: volume spikes (abnormal claim frequency), near-duplicates (suspiciously similar phrasing), temporal bursts (simultaneous appearance), and technique patterns (same techniques across sources on same topic).
            </EngineCard>

            <EngineCard icon="🪞" name="Mirror" tag="GPT-4o mini">
              For each major claim, generates three views: <strong>As stated</strong> (the original), <strong>With more context</strong> (reframed with added information), <strong>What is omitted</strong> (what the framing leaves out). Never says a claim is wrong — shows how framing shapes perception.
            </EngineCard>
          </Section>
        </div>

        {/* =========== CLARITY SCORE =========== */}
        <div id="clarity">
          <Section title="📊 Clarity Score — how it is calculated">
            <p>The Clarity Score (0-100) measures how transparent and well-evidenced content is. <strong>Higher = more transparent.</strong> The score is inverted: manipulation signals are subtracted from 100.</p>

            <H3>Formula</H3>
            <div style={{ padding: '12px 16px', background: '#f0fdfa', border: '0.5px solid #ccfbf1', borderRadius: 8, fontFamily: 'monospace', fontSize: 12, marginBottom: 12 }}>
              Clarity = 100 − (technique_signal + crossref_signal + toxicity_signal + disputed_bonus)
            </div>

            <H3>Components</H3>
            <p><strong>Technique signal (0-40):</strong> Maximum confidence across detected techniques × 40. If Prism finds "loaded language" at 85% confidence, this contributes 34 points.</p>
            <p><strong>Cross-reference signal (0-30):</strong> Number of existing fact-checks × 4, capped at 30. More fact-checks = more disputed = lower clarity.</p>
            <p><strong>Toxicity signal (0-20):</strong> Detoxify score × 20. Highly toxic language reduces clarity.</p>
            <p><strong>Disputed bonus (0-10):</strong> +10 if 3 or more fact-checking organizations have flagged claims in the content.</p>

            <H3>Interpretation</H3>
            <p><strong>80-100:</strong> High clarity — transparent, well-evidenced, minimal rhetorical techniques.</p>
            <p><strong>60-79:</strong> Moderate — some techniques present, content may still be accurate.</p>
            <p><strong>40-59:</strong> Low-moderate — significant framing, disputed claims.</p>
            <p><strong>0-39:</strong> Low clarity — heavy manipulation techniques, disputed content, or high toxicity.</p>

            <H3>Confidence band</H3>
            <p><strong>High</strong> (average technique confidence 0.8+): strong signals detected with certainty.</p>
            <p><strong>Medium</strong> (0.5-0.8): moderate signals, Detailed mode may help.</p>
            <p><strong>Low</strong> (below 0.5): signals present but not definitive — interpret with caution.</p>

            <H3>Limitations</H3>
            <p>The Clarity Score is a heuristic composite, not ground truth. It does not determine truth or falsehood. Satire, opinion pieces, and persuasive essays will naturally score lower without being misinformation. A low score means the content <em>uses techniques that can be manipulative</em> — not that it necessarily is.</p>
          </Section>
        </div>

        {/* =========== FEATURES =========== */}
        <div id="features">
          <Section title="🛠️ Features — what you can do">
            <EngineCard icon="🔍" name="Loupe">Inline text annotations. Toggle on any analysis to see the original text with color-coded highlights — red for emotional/loaded, yellow for logical fallacy, blue for missing context, purple for authority. Hover for explanation and confidence.</EngineCard>
            <EngineCard icon="✍️" name="Polish">Pre-publish check for writers. Shows which techniques your draft uses and provides concrete rewrite suggestions. Clean draft? You get a green confirmation.</EngineCard>
            <EngineCard icon="🔮" name="Kaleidoscope">Enter a claim, see it analyzed from 5 perspectives: original, conservative framing, liberal framing, international view, and fact-checker view. Reveals how framing changes meaning.</EngineCard>
            <EngineCard icon="🔬" name="Imprint">Source fingerprinting. Enter outlet names (bbc, fox, ndtv) to see their technique patterns across all past analyses. Builds over time as the knowledge base grows.</EngineCard>
            <EngineCard icon="🧵" name="Thread">Claim lifecycle tracking. Follow a claim from first appearance through spread across sources, technique evolution (did framing change?), to current status.</EngineCard>
            <EngineCard icon="🎵" name="Chorus">Aggregate anonymous community signal. Shows what percentage of users marked content as Trust, Unsure, or Reject, plus common concerns.</EngineCard>
            <EngineCard icon="🪞" name="Reflect">Personal bias profile based on your Ledger. Shows your reading patterns: what you tend to trust vs reject, your profile type (Trusting/Skeptical/Careful/Balanced), and potential blind spots.</EngineCard>
            <EngineCard icon="📒" name="Ledger">Decision journal. Mark any analysis as Trust, Unsure, or Reject with optional notes. Revisit past decisions. Feeds into Chorus (anonymously) and Reflect (privately).</EngineCard>
            <EngineCard icon="🧠" name="Recall">Reader memory. Search past analyses by topic using semantic similarity. Find related content you have analyzed before.</EngineCard>
            <EngineCard icon="📝" name="Marginalia">Collaborative annotations. Add notes to any analysis visible to all users. Build collective knowledge: "I verified this claim," "Additional context," etc.</EngineCard>
            <EngineCard icon="🔭" name="Observatory">Topic tracking. Search any topic to see all past analyses, technique frequency, and narrative evolution (Arc visualization) over time.</EngineCard>
            <EngineCard icon="🏷️" name="Seal">Embeddable transparency badge for news sites. One script tag shows a live Clarity Score on any article. Click opens full analysis.</EngineCard>
            <EngineCard icon="📷" name="Aperture">One-click bookmarklet. Drag to your bookmarks bar, click on any article to instantly analyze it in Dissekt.</EngineCard>
            <EngineCard icon="📨" name="Dispatch">Weekly digest email. Trending topics, most-used techniques, and highlights from the knowledge base.</EngineCard>
          </Section>
        </div>

        {/* =========== 20 TECHNIQUES =========== */}
        <div id="techniques">
          <Section title="🎯 20 Detection techniques">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
              {[
                ['Loaded language', 'Emotionally charged words to influence beyond rational argument'],
                ['Emotional framing', 'Structuring content to trigger specific emotional responses'],
                ['Cherry picking', 'Selecting data that supports a conclusion while ignoring contradicting data'],
                ['Missing context', 'Omitting relevant information that would change interpretation'],
                ['Appeal to authority', 'Using authority figures rather than evidence to support claims'],
                ['Appeal to fear', 'Using fear to persuade rather than evidence or reasoning'],
                ['Appeal to emotion', 'Substituting emotional reactions for rational argument'],
                ['Hasty generalization', 'Drawing broad conclusions from limited examples'],
                ['False equivalence', 'Treating fundamentally different things as comparable'],
                ['False dilemma', 'Presenting only two options when more exist'],
                ['Straw man', 'Misrepresenting an argument to make it easier to attack'],
                ['Ad hominem', 'Attacking the person instead of addressing their argument'],
                ['Whataboutism', 'Deflecting criticism by pointing to someone else'],
                ['Red herring', 'Introducing irrelevant information to divert from the issue'],
                ['Bandwagon', 'Arguing that popularity equals validity'],
                ['Slippery slope', 'Claiming one event will inevitably lead to extremes'],
                ['Circular reasoning', 'Using the conclusion as a premise in the argument'],
                ['Anecdotal evidence', 'Using individual stories as proof of a general claim'],
                ['False causation', 'Assuming correlation implies causation'],
                ['Oversimplification', 'Reducing complex issues to simple narratives'],
              ].map(([name, desc], i) => (
                <div key={i} style={{ padding: '6px 10px', background: '#f8fafa', borderRadius: 6 }}>
                  <strong style={{ fontSize: 12, color: '#1a1a1a' }}>{name}</strong>
                  <div style={{ fontSize: 11, color: '#888', marginTop: 1 }}>{desc}</div>
                </div>
              ))}
            </div>
            <p style={{ marginTop: 12, fontSize: 12, color: '#888' }}>Taxonomy informed by: Da San Martino et al., "Fine-Grained Analysis of Propaganda in News Articles," EMNLP 2019 (18 techniques). Dissekt extends this to 20 with heuristic-first detection.</p>
          </Section>
        </div>

        {/* =========== 9 HEURISTICS =========== */}
        <div id="heuristics">
          <Section title="📐 9 Statistical heuristics (zero-cost, no API)">
            <p style={{ marginBottom: 12 }}>These run locally before any LLM call, providing instant baseline detection at zero cost:</p>
            {[
              ['Emotional density', 'Ratio of emotional words (NRC lexicon) to total words. High density suggests emotional manipulation.'],
              ['Authority phrases', 'Frequency of "experts say," "studies show," "officials confirm" without citing specific sources.'],
              ['Absolute language', 'Frequency of "always," "never," "everyone," "impossible" — words that eliminate nuance.'],
              ['Claim density', 'Unsubstantiated claims per paragraph. High density = low evidence quality.'],
              ['Source credibility', 'MBFC factuality rating from the 231-source database.'],
              ['Readability (Flesch-Kincaid)', 'Extremely low readability can indicate intentional obfuscation. Based on Flesch, 1948.'],
              ['VADER sentiment', 'Compound score -1 to +1. Extreme sentiment in news content is a signal.'],
              ['Semantic compression', 'Cosine similarity between sentence embeddings. Threshold 0.72. High compression (many sentences saying the same thing differently) suggests repetitive persuasion.'],
              ['Attention gradient', 'Measures how emotional intensity varies across the text. A steep gradient (calm opening, emotionally charged conclusion) is a known persuasion pattern.'],
            ].map(([name, desc], i) => (
              <div key={i} style={{ display: 'flex', gap: 8, padding: '6px 0', borderBottom: i < 8 ? '0.5px solid #f0f0ee' : 'none' }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: '#0d9488', width: 20, flexShrink: 0 }}>{i + 1}.</span>
                <div><strong style={{ fontSize: 12 }}>{name}</strong><span style={{ fontSize: 12, color: '#555' }}> — {desc}</span></div>
              </div>
            ))}
          </Section>
        </div>

        {/* =========== METHODOLOGY =========== */}
        <div id="methodology">
          <Section title="🔬 Methodology">
            <H3>Architecture</H3>
            <p>Heuristic-first, LLM-escalation. Statistical analysis runs first (free, instant). LLM analysis runs only in Brief or Detailed mode. Cost: ~€0.002 per Brief scan, ~€0.01 per Detailed scan.</p>

            <H3>Multi-model approach</H3>
            <p><strong>GPT-4o mini</strong> — Brief mode, Facet extraction, Mirror generation. Fast, cost-efficient.</p>
            <p><strong>Claude Sonnet 4</strong> — Detailed mode. Nuanced reasoning, longer context, thorough evidence extraction.</p>
            <p><strong>text-embedding-3-small</strong> — 1536-dim embeddings for Lattice. Cosine similarity.</p>
            <p><strong>Detoxify (BERT)</strong> — Toxicity. Runs locally, no external API.</p>

            <H3>Accuracy and limitations</H3>
            <p><strong>False positives:</strong> satire, opinion, and persuasive writing trigger detections. This does not mean they are misinformation.</p>
            <p><strong>False negatives:</strong> subtle manipulation without common patterns may not be detected.</p>
            <p><strong>LLM hallucination:</strong> GPT-4o mini and Claude can hallucinate detections. Confidence scores and user corrections help mitigate this.</p>
            <p><strong>Cultural context:</strong> techniques are culturally relative. Iris helps but does not fully solve this.</p>

            <H3>Benchmark position</H3>
            <p>Dissekt uses a hybrid heuristic + LLM approach rather than fine-tuned classifiers, so direct comparison with SemEval baselines is not straightforward. Key metrics:</p>
            <p>End-to-end latency: under 4 seconds (Brief). Heuristic-only: under 500ms. Technique taxonomy: 20 (superset of SemEval-2020 Task 11's 14). Cross-references: 100+ organizations. Source credibility: 231 outlets. Political entities: 40 politicians.</p>
          </Section>
        </div>

        {/* =========== REFERENCES =========== */}
        <div id="references">
          <Section title="📚 References and papers">
            <H3>Propaganda and technique detection</H3>
            <p>Da San Martino, G., et al. (2019). "Fine-Grained Analysis of Propaganda in News Articles." EMNLP. Introduced 18-technique taxonomy that influenced Dissekt. <Ref href="https://aclanthology.org/D19-1565/">Paper</Ref></p>
            <p>Da San Martino, G., et al. (2020). "SemEval-2020 Task 11: Detection of Propaganda Techniques in News Articles." Benchmark datasets for technique detection. <Ref href="https://aclanthology.org/2020.semeval-1.186/">Paper</Ref></p>
            <p>Piskorski, J., et al. (2023). "SemEval-2023 Task 3: Detecting Persuasion Techniques in Online News in a Multi-lingual Setup." <Ref href="https://aclanthology.org/2023.semeval-1.317/">Paper</Ref></p>

            <H3>Sentiment and toxicity</H3>
            <p>Hutto, C.J. and Gilbert, E.E. (2014). "VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text." ICWSM. <Ref href="https://ojs.aaai.org/index.php/ICWSM/article/view/14550">Paper</Ref></p>
            <p>Detoxify — Unitary AI. Multilingual toxic comment classification, BERT fine-tuned on Jigsaw datasets. <Ref href="https://github.com/unitaryai/detoxify">GitHub</Ref></p>

            <H3>Fact-checking and credibility</H3>
            <p>Nakov, P., et al. (2021). "Automated Fact-Checking for Assisting Human Fact-Checkers." IJCAI Survey. <Ref href="https://arxiv.org/abs/2103.07769">Paper</Ref></p>
            <p>Baly, R., et al. (2018). "Predicting Factuality of Reporting and Bias of News Media Using Multi-Task Learning." EMNLP. <Ref href="https://aclanthology.org/D18-1389/">Paper</Ref></p>
            <p>Media Bias/Fact Check — methodology and 231-source database. <Ref href="https://mediabiasfactcheck.com/methodology/">Methodology</Ref></p>

            <H3>Readability and text analysis</H3>
            <p>Flesch, R. (1948). "A New Readability Yardstick." Journal of Applied Psychology. <Ref href="https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests">Reference</Ref></p>
            <p>textstat — Python readability metrics (Flesch-Kincaid, Gunning Fog, SMOG). <Ref href="https://github.com/textstat/textstat">GitHub</Ref></p>

            <H3>Vector search</H3>
            <p>Qdrant — vector similarity search engine used for Lattice and Recall. <Ref href="https://qdrant.tech/documentation/">Docs</Ref></p>
            <p>OpenAI text-embedding-3-small — 1536-dim embeddings for semantic similarity. <Ref href="https://platform.openai.com/docs/guides/embeddings">Docs</Ref></p>

            <H3>Blockchain</H3>
            <p>OpenTimestamps — Bitcoin-backed timestamping. <Ref href="https://opentimestamps.org/">Website</Ref></p>

            <H3>Related work by the author</H3>
            <p>Hartung, K. and Mallick, S. (2024). "Evaluation Metrics in LLM Code Generation." TSD 2024. Semantic and structural metrics beyond BLEU/CodeBLEU. <Ref href="https://link.springer.com/conference/tsd">Conference</Ref></p>
          </Section>
        </div>

        {/* =========== ACCESS TIERS =========== */}
        <div id="tiers">
          <Section title="🎫 Access tiers">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div style={{ padding: 16, border: '0.5px solid #e5eaea', borderRadius: 10 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>🆓 Free</div>
                <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>
                  3 brief scans/day<br/>1 detailed scan/day<br/>Resets 00:00 GMT<br/>No signup required<br/>Help and Feedback always available<br/>Components: admin-controlled
                </div>
              </div>
              <div style={{ padding: 16, border: '2px solid #0d9488', borderRadius: 10 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>🎫 Invited</div>
                <div style={{ fontSize: 12, color: '#555', lineHeight: 2 }}>
                  25 brief scans/day<br/>10 detailed scans/day<br/>Resets 00:00 GMT<br/>Invite code required (valid 7 days)<br/>Access valid 6 months<br/>All components unlocked<br/>Bulk CSV, Compare, Observatory
                </div>
              </div>
            </div>
            <p style={{ marginTop: 12, fontSize: 12, color: '#888' }}>Request access at <a href="/invite" style={{ color: '#0d9488' }}>dissekt.info/invite</a>. All limits and features are configurable by the admin.</p>
          </Section>
        </div>

        <div style={{ textAlign: 'center', marginTop: 32, paddingTop: 20, borderTop: '0.5px solid #e5eaea' }}>
          <a href="/analyze" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '10px 20px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 600, textDecoration: 'none' }}>
            Try Dissekt now →
          </a>
          <p style={{ fontSize: 12, color: '#aaa', marginTop: 8 }}>Free · 3 brief + 1 detailed scan/day · No signup required</p>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
