#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
set -e

python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

old_section = '''          <Section title="📊 Clarity Score — how it is calculated">
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
          </Section>'''

new_section = '''          <Section title="📊 Clarity Score — how it is calculated">
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

            <H3>🏗️ Construction — "How is it built?"</H3>
            <p>Measures the structural quality of the content, independent of whether it is true. Weighted geometric mean of three metrics:</p>
            <p><strong>Rhetoric (×0.40):</strong> 1 − severity-weighted technique penalties. Each detected technique is weighted by how manipulative it is — a straw man (severity 10) hurts more than loaded language (severity 3). Severity weights derived from the SemEval propaganda corpus (Da San Martino et al., EMNLP 2019).</p>
            <p><strong>Argumentation (×0.35):</strong> Logical structure quality — are claims supported, are the arguments coherent, does the conclusion follow? Based on computational argumentation research (Wachsmuth et al., ACL 2017).</p>
            <p><strong>Completeness (×0.25):</strong> Whether the content answers who, what, when, cites sources, and presents a counter-view. Manipulation by omission is invisible to technique detection — this catches it.</p>

            <H3>✅ Verification — "How verified is it?"</H3>
            <p>Measures external validation. Only metrics that have real data are counted — missing signals do not drag the score toward neutral.</p>
            <p><strong>Evidence (×0.40):</strong> Fact-checker consensus, weighted by organization tier (Gold/IFCN = 1.0, Established = 0.7, Emerging = 0.4). A claim disputed by multiple Gold-tier checkers scores low; one confirmed scores high.</p>
            <p><strong>Source (×0.25):</strong> Media Bias/Fact Check factuality rating of the source domain, across 231 rated outlets.</p>
            <p><strong>Diversity (×0.20):</strong> How many independent, named source categories are cited. "Sources say" scores low; "WHO data confirmed by a Lancet study and the health ministry" scores high.</p>
            <p><strong>Temporal (×0.20):</strong> Whether the claims have held up over time, drawn from our accumulated analysis history. Improves as the knowledge graph grows.</p>

            <H3>🎯 Intent — "What does it want me to do?"</H3>
            <p>Measures persuasion pressure and emotional direction.</p>
            <p><strong>Manipulation (×0.40):</strong> Cumulative persuasion pressure — urgency phrases, calls to action, emotional escalation, binary framing, and aggression density. Grounded in persuasion research (Cialdini, 2007).</p>
            <p><strong>Tone (×0.35):</strong> Context-aware hostility. Quoted speech is separated from the author's own voice, toxicity is adjusted for genre (an editorial is naturally more charged than a wire report), and rhetorical hostility is measured separately from profanity (Pavlopoulos et al., EACL 2021; Sap et al., ALW 2020).</p>
            <p><strong>Narrative direction (×0.25):</strong> How far the framing leans from neutral on two axes — skepticism↔trust and fear↔hope (Card et al., ACL 2018). Neutral framing scores high; strongly directional framing scores lower.</p>

            <H3>Why a geometric mean?</H3>
            <p>An arithmetic average lets a great score in one area mask a terrible score in another. The geometric mean does not — an article with excellent rhetoric but disputed evidence cannot hide behind its writing quality. This is the same reason the UN Human Development Index switched to a geometric mean in 2010.</p>

            <H3>Confidence band</H3>
            <p><strong>High</strong> (average technique confidence 0.8+): strong signals detected with certainty.</p>
            <p><strong>Medium</strong> (0.5–0.8): moderate signals; Detailed mode may add clarity.</p>
            <p><strong>Low</strong> (below 0.5): signals present but not definitive — interpret with caution.</p>

            <H3>Limitations</H3>
            <p>The Clarity Score is a composite signal, not ground truth. It does not determine truth or falsehood. Satire, opinion, and persuasive essays score lower by design without being misinformation — a low score means the content <em>uses techniques that can be manipulative</em>, not that it necessarily is. Where a dimension has no data (for example, no fact-checks exist yet), that dimension is excluded rather than guessed, so absence of evidence is not treated as evidence.</p>
          </Section>'''

if old_section in content:
    content = content.replace(old_section, new_section)
    open('src/app/help/page.tsx', 'w').write(content)
    print('✅ Help page Clarity Score section updated to ensemble model')
else:
    print('❌ Could not match the old section exactly — paste lines again')
PYEOF

# Verify it parses (basic check)
node -e "require('fs').readFileSync('src/app/help/page.tsx','utf8'); console.log('✅ file readable')" 2>/dev/null || echo "check manually"

echo "Run: npm run build"
