#!/bin/bash
# Dissekt — Add help tooltips (?) to each analysis component
# Run from inside dissekt-web/
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# Tooltip component
# ============================================
cat > src/components/HelpTip.tsx << 'HTEOF'
'use client';
import { useState } from 'react';

export default function HelpTip({ text }: { text: string }) {
  const [show, setShow] = useState(false);

  return (
    <span style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', marginLeft: 6 }}>
      <button
        onMouseEnter={() => setShow(true)}
        onMouseLeave={() => setShow(false)}
        onClick={() => setShow(!show)}
        style={{
          width: 16, height: 16, borderRadius: 8, border: '1px solid #d4d4d4',
          background: show ? '#7c3aed' : '#f0f0ee', color: show ? '#fff' : '#888',
          fontSize: 10, fontWeight: 600, cursor: 'pointer', display: 'flex',
          alignItems: 'center', justifyContent: 'center', padding: 0, lineHeight: 1,
        }}
        aria-label="Help"
      >?</button>
      {show && (
        <div style={{
          position: 'absolute', bottom: 24, left: '50%', transform: 'translateX(-50%)',
          background: '#1a1a1a', color: '#fff', fontSize: 11, lineHeight: 1.5,
          padding: '8px 12px', borderRadius: 8, width: 240, zIndex: 50,
          boxShadow: '0 4px 16px rgba(0,0,0,0.15)', pointerEvents: 'none',
        }}>
          {text}
          <div style={{
            position: 'absolute', top: '100%', left: '50%', transform: 'translateX(-50%)',
            width: 0, height: 0, borderLeft: '6px solid transparent',
            borderRight: '6px solid transparent', borderTop: '6px solid #1a1a1a',
          }} />
        </div>
      )}
    </span>
  );
}
HTEOF

echo "✅ HelpTip component created"

# ============================================
# Update ThreatScore
# ============================================
python3 << 'PYEOF'
content = open('src/components/ThreatScore.tsx').read()

if 'HelpTip' not in content:
    content = content.replace(
        "import { useState } from 'react';",
        "import { useState } from 'react';"
    )
    # Add import if not present
    if "import HelpTip" not in content:
        content = "'use client';\nimport HelpTip from './HelpTip';\n" + content.replace("'use client';\n", "")

open('src/components/ThreatScore.tsx', 'w').write(content)
print('✅ ThreatScore prepared')
PYEOF

# ============================================
# Update PrismCard
# ============================================
python3 << 'PYEOF'
content = open('src/components/PrismCard.tsx').read()

if 'HelpTip' not in content:
    # Add import
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    # Add tooltip to header
    content = content.replace(
        '>Prism — techniques<',
        '>Prism — techniques<HelpTip text="Prism detects manipulation techniques like loaded language, cherry-picking, appeal to authority, and 17 more. Each technique shows a confidence score and evidence quote." /><'
    )
    
    # Try alternate header patterns
    if 'HelpTip text="Prism' not in content:
        content = content.replace(
            'Prism — techniques',
            'Prism — techniques</span><HelpTip text="Prism detects manipulation techniques like loaded language, cherry-picking, appeal to authority, and 17 more. Each technique shows a confidence score and evidence quote." /><span style={{display:"none"}}'
        )

open('src/components/PrismCard.tsx', 'w').write(content)
print('✅ PrismCard updated')
PYEOF

# ============================================
# Update TraceCard
# ============================================
python3 << 'PYEOF'
content = open('src/components/TraceCard.tsx').read()

if 'HelpTip' not in content:
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    content = content.replace(
        'Trace — fact-checks',
        'Trace — fact-checks</span><HelpTip text="Trace searches 100+ fact-checking organizations (FactCheck.org, Full Fact, PolitiFact, AP) for existing fact-checks on this claim, and traces the spread timeline across platforms." /><span style={{display:"none"}}'
    )

open('src/components/TraceCard.tsx', 'w').write(content)
print('✅ TraceCard updated')
PYEOF

# ============================================
# Update SignalCard
# ============================================
python3 << 'PYEOF'
content = open('src/components/SignalCard.tsx').read()

if 'HelpTip' not in content:
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    content = content.replace(
        'Signal — credibility',
        'Signal — credibility</span><HelpTip text="Signal scores source credibility using 231 rated news sources (MBFC database), Detoxify toxicity analysis (6 categories), and VADER sentiment scoring. All models run locally — zero external data." /><span style={{display:"none"}}'
    )

open('src/components/SignalCard.tsx', 'w').write(content)
print('✅ SignalCard updated')
PYEOF

# ============================================
# Update MetaCard
# ============================================
python3 << 'PYEOF'
content = open('src/components/MetaCard.tsx').read()

if 'HelpTip' not in content:
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    content = content.replace(
        'Meta',
        'Meta</span><HelpTip text="Metadata shows analysis time, which AI model was used (GPT-4o mini for Brief, Claude for Detailed), cache status, and the SHA-256 blockchain hash for tamper-proof evidence." /><span style={{display:"none"}}',
        1
    )

open('src/components/MetaCard.tsx', 'w').write(content)
print('✅ MetaCard updated')
PYEOF

# ============================================
# Update SimilarClaims
# ============================================
python3 << 'PYEOF'
content = open('src/components/SimilarClaims.tsx').read()

if 'HelpTip' not in content:
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    content = content.replace(
        'Similar claims analyzed before',
        'Similar claims analyzed before</span><HelpTip text="Dissekt remembers every analysis. When a similar claim was analyzed before, it shows up here with a similarity score. The more people use Dissekt, the smarter it gets." /><span style={{display:"none"}}'
    )

open('src/components/SimilarClaims.tsx', 'w').write(content)
print('✅ SimilarClaims updated')
PYEOF

# ============================================
# Update ExtractedClaims
# ============================================
python3 << 'PYEOF'
content = open('src/components/ExtractedClaims.tsx').read()

if 'HelpTip' not in content:
    if "import HelpTip" not in content:
        content = content.replace("'use client';", "'use client';\nimport HelpTip from './HelpTip';", 1)
    
    content = content.replace(
        'Verifiable claims extracted',
        'Verifiable claims extracted</span><HelpTip text="AI extracts individual factual claims that can be independently verified. Each claim is tagged by type: statistic, quote, event, prediction, or causal claim." /><span style={{display:"none"}}'
    )

open('src/components/ExtractedClaims.tsx', 'w').write(content)
print('✅ ExtractedClaims updated')
PYEOF

echo ""
echo "✅ Help tooltips added to all 7 components:"
echo "  - ThreatScore"
echo "  - PrismCard (manipulation techniques)"
echo "  - TraceCard (fact-checks)"
echo "  - SignalCard (credibility)"
echo "  - MetaCard (metadata + blockchain)"
echo "  - SimilarClaims"
echo "  - ExtractedClaims"
echo ""
echo "Run: npm run dev"
