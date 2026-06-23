'use client';
import { useState } from 'react';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const SECTIONS = [
  { id: 'about', label: 'What is Dissekt' },
  { id: 'score', label: 'The Clarity Score' },
  { id: 'signals', label: 'Language signals' },
  { id: 'single', label: 'Single scan' },
  { id: 'keyword', label: 'Keyword topic' },
  { id: 'observatory', label: 'The Observatory' },
  { id: 'extension', label: 'Chrome extension' },
  { id: 'telegram', label: 'Telegram bot' },
  { id: 'access', label: 'Access & limits' },
  { id: 'tips', label: 'Tips' },
  { id: 'faq', label: 'FAQ' },
  { id: 'references', label: 'References' },
];

function H({ id, children }: { id: string; children: React.ReactNode }) {
  return <h2 id={id} style={{ fontSize: 20, fontWeight: 700, color: '#1a1a1a', margin: '32px 0 10px', scrollMarginTop: 80 }}>{children}</h2>;
}
function P({ children }: { children: React.ReactNode }) {
  return <p style={{ fontSize: 14, color: '#404040', lineHeight: 1.75, margin: '0 0 12px' }}>{children}</p>;
}
function Tip({ children }: { children: React.ReactNode }) {
  return <div style={{ fontSize: 13, color: '#0f6e56', background: '#f0fdfa', border: '0.5px solid #cce9e3', borderRadius: 8, padding: '10px 14px', margin: '0 0 12px' }}><strong>Tip:</strong> {children}</div>;
}
function Steps({ items }: { items: string[] }) {
  return (
    <ol style={{ fontSize: 14, color: '#404040', lineHeight: 1.7, margin: '0 0 12px', paddingLeft: 20 }}>
      {items.map((it, i) => <li key={i} style={{ marginBottom: 4 }}>{it}</li>)}
    </ol>
  );
}

export default function HelpPage() {
  const [open, setOpen] = useState<string | null>(null);
  const faqs = [
    ['Does Dissekt tell me if something is true or false?', 'No. Dissekt analyzes how content is constructed — the techniques, framing, sourcing, and tone — and cross-references existing fact-checks. It gives you the tools to think critically, not a verdict. The Clarity Score reflects transparency of construction, not truth.'],
    ['What is a "Brief" vs "Detailed" scan?', 'Brief is a fast analysis using a lightweight model — good for quick checks. Detailed runs a deeper model with fuller reasoning and more thorough cross-referencing. Detailed scans count separately against your daily limit.'],
    ['Why did my scan find no fact-checks?', 'Cross-referencing depends on whether fact-checkers have already covered the claim. Newer or niche topics often have none yet. Absence of fact-checks is not evidence either way.'],
    ['Why is toxicity usually 0%?', 'Professional news writing rarely triggers toxicity detection, which looks for insults, threats, and obscenity. A low toxicity score is normal for news and does not mean the content is unbiased.'],
    ['Is my data private?', 'Content you submit is processed but not stored in full. If you have an account, metadata about your scans (entities, techniques, scores — not the raw text) is stored to power Constellation. You can request deletion anytime. See the Privacy Policy for details.'],
    ['Can I use Dissekt without an account?', 'Yes. Free use requires no account (3 brief + 1 detailed scan per day). A free account raises limits and unlocks the Observatory, your Dashboard, and API access.'],
  ];

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 760, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 4 }}>Help &amp; Guide</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 20 }}>Everything Dissekt can do, how to use each feature, and tips to get the most out of it.</p>

        {/* Quick nav */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 24, padding: 14, background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 12 }}>
          {SECTIONS.map(s => (
            <a key={s.id} href={`#${s.id}`} style={{ fontSize: 12.5, color: '#0d9488', textDecoration: 'none', padding: '4px 10px', background: '#f0fdfa', borderRadius: 16 }}>{s.label}</a>
          ))}
        </div>

        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: '8px 28px 28px' }}>
          <H id="about">What is Dissekt</H>
          <P>Dissekt is an information transparency tool. Its purpose is to help you <em>see how information is constructed</em> — the rhetorical techniques, framing, sourcing, and tone behind a piece of content — so you can read more critically.</P>
          <P>Dissekt does <strong>not</strong> decide what is true or false. It surfaces <em>how</em> something is built and argued, cross-references existing fact-checks, and scores the credibility of sources. The judgment stays with you.</P>

          <H id="score">The Clarity Score</H>
          <P>Every analysis produces a <strong>Clarity Score</strong> from 0.00 to 1.00 — a measure of how transparently the content is constructed. Higher is clearer and more straightforward; lower means more manipulation, weaker sourcing, or persuasive intent.</P>
          <P>The bands: <strong style={{ color: '#16a34a' }}>0.65–1.00 High</strong> (transparent), <strong style={{ color: '#d97706' }}>0.35–0.64 Moderate</strong>, <strong style={{ color: '#dc2626' }}>0.00–0.34 Low</strong> (heavily constructed).</P>
          <P>The score combines three dimensions, multiplied together so a serious weakness in any one pulls the whole score down:</P>
          <P>• <strong>Construction</strong> — how it is built: rhetorical techniques, argument quality, completeness.<br />• <strong>Verification</strong> — how supported it is: fact-checker consensus, source credibility, named sources.<br />• <strong>Intent</strong> — what it wants: manipulation cues, tone, narrative framing.</P>
          <P><strong>Coverage.</strong> The score also reflects how much real evidence was available. When there are no fact-checks, no known source rating, or very little text, the result leans on text-pattern heuristics and is flagged as <em>limited signal</em> — treat those scores as rougher. Missing signals are excluded and the rest reweighted, rather than quietly pulling the score to neutral.</P>
          <Tip>A high score is not an endorsement and a low score is not a debunk. A clearly written opinion piece and a heavily sourced report can both score well; the score is about transparency of construction, not agreement.</Tip>

          <H id="single">Single scan</H>
          <P>The core feature. Paste text, a URL, or upload an image, and Dissekt analyzes that one item.</P>
          <Steps items={[
            'Go to Analyze → Single scan.',
            'Paste text or a URL, or attach an image.',
            'Choose Brief (fast) or Detailed (deeper).',
            'Read the Clarity Score, detected techniques, cross-references, and source credibility.',
          ]} />
          <P>For a URL, Dissekt fetches and extracts the article automatically. Some sites block automated access (paywalls) — if extraction fails, paste the text directly.</P>
          <Tip>Use Brief for a quick gut-check, Detailed when a piece matters and you want the fuller reasoning and cross-referencing.</Tip>

          <H id="keyword">Keyword topic</H>
          <P>Instead of one article, analyze how a <em>whole topic</em> is being covered right now. Dissekt fetches recent articles on your keywords, analyzes each, and aggregates a coverage report.</P>
          <Steps items={[
            'Go to Analyze → Keyword topic.',
            'Type a topic (e.g. "5G health risks") and press Suggest.',
            'Dissekt proposes related keywords — tap to add the ones that sharpen your search.',
            'Pick Brief (more articles) or Detailed (deeper, fewer), then Analyze topic.',
            'Read the aggregate report: average clarity, dominant techniques, and a per-source breakdown sorted least-to-most clear.',
          ]} />
          <P>Searches are limited to recent coverage (about the past month) and span general web sources — news, analysis, and blogs. Sources that block automated access are noted and excluded.</P>
          <Tip>Add 2–3 related keywords rather than one broad term. "Modi, Adani, fraud allegations" returns sharper, more relevant coverage than just "Modi".</Tip>

          <H id="observatory">The Observatory</H>
          <P>The Observatory is your member space for seeing patterns across everything you have analyzed, centered on Constellation.</P>
          <P><strong>✦ Constellation</strong> — a knowledge graph of the entities (people, places, organizations, topics) from your scans. Nodes are entities; lines connect entities that appeared together or were manipulated in similar ways. It builds up as you analyze more (it unlocks at 10 scans).</P>
          <Steps items={[
            'Open Observatory → Constellation.',
            'Drag nodes to rearrange; zoom with the +/− controls; click a node to see its details and linked scans.',
            'Toggle the color mode between manipulation level and entity type.',
            'To generate a report, pick a cluster from the dropdown — it highlights in the graph — then Generate report.',
          ]} />
          <P>The <strong>cluster report</strong> is an AI-generated brief on one cluster of related topics: what it covers, what the analyses show (dominant techniques, clarity range), and a "Watch for" takeaway. Each report links to the real scans it draws from, and can be printed, copied, or saved as .txt or PDF.</P>
          <Tip>Constellation gets more useful the more you scan. If a cluster mixes unrelated topics, the report will say so plainly rather than forcing a single story.</Tip>

          <H id="extension">Chrome extension</H>
          <P>Analyze anything as you browse. Right-click selected text, a link, or a page and choose "Analyze with Dissekt" to get an instant read in the extension popup. It activates only when you explicitly use it — no background tracking.</P>

          <H id="telegram">Telegram bot</H>
          <P>Dissekt also runs as a Telegram bot, so you can send content for analysis directly from chat. Handy for checking forwarded messages and links on the go.</P>

          <H id="access">Access &amp; limits</H>
          <P>Daily scan limits reset at 00:00 GMT.</P>
          <P><strong>Free (no account):</strong> 3 brief + 1 detailed scan per day.<br /><strong>Free member account:</strong> 25 brief + 10 detailed per day, plus the Observatory, Dashboard, and API access.</P>
          <P>Brief and detailed scans are counted separately. Keyword topic analyses count as one scan of the chosen depth.</P>
          <Tip>An account is free and unlocks the features that get better over time — especially Constellation, which needs your scan history to build.</Tip>

          <H id="tips">Tips for good results</H>
          <P>• Give Dissekt enough to work with — a full article or a substantial passage reads better than a one-line snippet.<br />• For URLs that fail to load, paste the text directly.<br />• Read the dimensions, not just the headline score — a low score driven by Intent (manipulation) tells a different story than one driven by Verification (weak sourcing).<br />• Use Keyword topic to see patterns across sources, not just single items.<br />• Treat the score as a starting point for your own judgment, never the final word.</P>

          <H id="faq">FAQ</H>
          {faqs.map(([q, a], i) => (
            <div key={i} style={{ border: '0.5px solid #e5eaea', borderRadius: 10, marginBottom: 8, overflow: 'hidden' }}>
              <button onClick={() => setOpen(open === String(i) ? null : String(i))}
                style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '13px 16px', background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left' }}>
                <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>{q}</span>
                <span style={{ fontSize: 12, color: '#888', transform: open === String(i) ? 'rotate(180deg)' : 'none' }}>▾</span>
              </button>
              {open === String(i) && <div style={{ padding: '0 16px 14px', fontSize: 13.5, color: '#444', lineHeight: 1.7 }}>{a}</div>}
            </div>
          ))}

          <H id="signals">Representation &amp; language signals</H>
          <P>Alongside the score, Dissekt tags language patterns it notices. These are <strong>descriptive observations, not verdicts</strong> — each tag shows the exact words that triggered it, and you decide whether it matters. They do <strong>not</strong> affect the Clarity Score.</P>
          <Tip>A report shows only the tags that actually fired, so a clean piece may show none — that&apos;s normal, not a failure. These patterns are detected in <strong>English only</strong>, so non-English articles may show fewer signals.</Tip>
          <P><strong>Framing &amp; credibility language</strong></P>
          <P>• <strong>Doubt-casting language</strong> — words that quietly question credibility (&ldquo;so-called&rdquo;, &ldquo;alleged&rdquo;, &ldquo;purported&rdquo;).<br />• <strong>Asserted certainty</strong> — verbs presenting contested points as settled (&ldquo;revealed&rdquo;, &ldquo;exposed&rdquo;, &ldquo;confirmed&rdquo;).<br />• <strong>Heavily hedged</strong> — frequent softeners that distance claims (&ldquo;may&rdquo;, &ldquo;possibly&rdquo;, &ldquo;arguably&rdquo;).<br />• <strong>One-sided framing</strong> — subjective intensifiers that assume agreement (&ldquo;clearly&rdquo;, &ldquo;obviously&rdquo;, &ldquo;of course&rdquo;).<br />• <strong>Sweeping generalization</strong> — broad claims about an entire group.<br />• <strong>Dehumanizing metaphor</strong> — threat/disaster language applied to people (&ldquo;flood&rdquo;, &ldquo;swarm&rdquo;, &ldquo;infestation&rdquo;).</P>
          <P><strong>Toxicity sub-types</strong> (shown when detected): Severe toxicity, Obscene language, Threat, Insult, Identity attack, Sexually explicit.</P>
          <P>Tap any tag in a report to see the specific words that triggered it.</P>

          <H id="references">References</H>
          <P>Dissekt&apos;s scoring draws on peer-reviewed research. Key sources:</P>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {[
              ['Da San Martino et al., EMNLP-IJCNLP 2019', 'Propaganda technique taxonomy', 'https://aclanthology.org/D19-1565/'],
              ['Baly et al., EMNLP 2018', 'News-source factuality & bias (MBFC basis)', 'https://aclanthology.org/D18-1389/'],
              ['Wachsmuth et al., EACL 2017', 'Computational argumentation quality', 'https://aclanthology.org/E17-1017/'],
              ['Pavlopoulos et al., ACL 2020', 'Context-aware toxicity', 'https://aclanthology.org/2020.acl-main.396/'],
              ['Hutto & Gilbert, ICWSM 2014', 'VADER sentiment analysis', 'https://doi.org/10.1609/icwsm.v8i1.14550'],
              ['Recasens et al., ACL 2013', 'Framing & epistemological bias', 'https://aclanthology.org/P13-1162/'],
              ['Borkan et al., WWW 2019', 'Toxicity sub-labels (Jigsaw/Detoxify)', 'https://arxiv.org/abs/1903.04561'],
              ['UNDP, Human Development Report 2010', 'Geometric mean for composite indices', 'https://hdr.undp.org/'],
            ].map(([p, t, u]) => (
              <a key={p} href={u} target="_blank" rel="noopener" style={{ fontSize: 13, color: '#404040', textDecoration: 'none', display: 'flex', gap: 8, padding: '7px 0', borderBottom: '0.5px solid #f0efec' }}>
                <span style={{ flexShrink: 0 }}>📄</span>
                <span><strong style={{ color: '#1a1a1a' }}>{p}</strong> — {t}</span>
              </a>
            ))}
          </div>
        </div>

        <p style={{ fontSize: 12.5, color: '#aaa', textAlign: 'center', marginTop: 16 }}>
          Still stuck? <a href="/contact" style={{ color: '#0d9488', textDecoration: 'none' }}>Contact us</a>.
        </p>
      </div>
      <SiteFooter />
    </main>
  );
}
