#!/bin/bash
# Dissekt — Trust & Feedback Loop
# 1. 👍/👎 per technique (correction loop)
# 2. Score formula breakdown
# 3. Confidence band on threat score
# 4. "Our approach" methodology on /help
set -e

# ============================================
# 1. Supabase table for corrections
# ============================================
echo "⚠️  Run this SQL in Supabase SQL Editor:"
echo ""
echo "create table if not exists public.corrections ("
echo "  id uuid default gen_random_uuid() primary key,"
echo "  analysis_id text not null,"
echo "  technique_name text not null,"
echo "  vote text not null check (vote in ('agree', 'disagree')),"
echo "  comment text,"
echo "  created_at timestamptz default now()"
echo ");"
echo ""
echo "alter table public.corrections enable row level security;"
echo "create policy \"Anyone can insert corrections\" on public.corrections for insert with check (true);"
echo "create policy \"Anyone can read corrections\" on public.corrections for select using (true);"
echo ""

# ============================================
# 2. API endpoint for corrections (Next.js)
# ============================================
cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

mkdir -p src/app/api/corrections

cat > src/app/api/corrections/route.ts << 'COREOF'
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  try {
    const { analysis_id, technique_name, vote, comment } = await req.json();
    if (!analysis_id || !technique_name || !vote) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }
    const { error } = await supabase.from('corrections').insert({
      analysis_id, technique_name, vote, comment,
    });
    if (error) throw error;
    return NextResponse.json({ success: true });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
COREOF

echo "✅ Corrections API endpoint created"

# ============================================
# 3. Update PrismCard — add 👍/👎 per technique
# ============================================

# First check current PrismCard structure
echo "Updating PrismCard with correction buttons..."

python3 << 'PYEOF'
content = open('src/components/PrismCard.tsx').read()

# Check if it already has correction buttons
if 'vote' in content and 'disagree' in content:
    print('Already has correction buttons')
else:
    # Save current content for reference
    with open('/tmp/prism_backup.tsx', 'w') as f:
        f.write(content)
    print('Current PrismCard backed up. Will create new version.')
PYEOF

cat > src/components/PrismCard.tsx << 'PRISMEOF'
'use client';
import { useState } from 'react';

const CATEGORY_COLORS: Record<string, { bg: string; color: string }> = {
  framing: { bg: '#fff7ed', color: '#c2410c' },
  logical_fallacy: { bg: '#fef2f2', color: '#b91c1c' },
  credibility: { bg: '#f0fdf4', color: '#166534' },
  deflection: { bg: '#eff6ff', color: '#1e40af' },
};

function TechniqueVote({ analysisId, technique }: { analysisId: string; technique: any }) {
  const [voted, setVoted] = useState<'agree' | 'disagree' | null>(null);
  const [showComment, setShowComment] = useState(false);
  const [comment, setComment] = useState('');
  const [sent, setSent] = useState(false);

  const handleVote = async (vote: 'agree' | 'disagree') => {
    setVoted(vote);
    if (vote === 'disagree') {
      setShowComment(true);
      return;
    }
    try {
      await fetch('/api/corrections', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, technique_name: technique.name, vote, comment: '' }),
      });
      setSent(true);
    } catch {}
  };

  const submitDisagree = async () => {
    try {
      await fetch('/api/corrections', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ analysis_id: analysisId, technique_name: technique.name, vote: 'disagree', comment }),
      });
      setSent(true);
      setShowComment(false);
    } catch {}
  };

  if (sent) {
    return (
      <div style={{ fontSize: 10, color: '#16a34a', marginTop: 6 }}>
        ✓ Thanks for your feedback
      </div>
    );
  }

  return (
    <div style={{ marginTop: 6 }}>
      {!showComment && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 10, color: '#aaa' }}>Accurate?</span>
          <button onClick={() => handleVote('agree')}
            style={{ padding: '2px 8px', fontSize: 10, borderRadius: 4, border: '1px solid #e5e5e5', background: voted === 'agree' ? '#f0fdf4' : '#fff', color: voted === 'agree' ? '#16a34a' : '#888', cursor: 'pointer', fontWeight: 500 }}>
            👍
          </button>
          <button onClick={() => handleVote('disagree')}
            style={{ padding: '2px 8px', fontSize: 10, borderRadius: 4, border: '1px solid #e5e5e5', background: voted === 'disagree' ? '#fef2f2' : '#fff', color: voted === 'disagree' ? '#b91c1c' : '#888', cursor: 'pointer', fontWeight: 500 }}>
            👎
          </button>
        </div>
      )}
      {showComment && (
        <div style={{ display: 'flex', gap: 4, marginTop: 4 }}>
          <input
            type="text"
            placeholder="What's wrong? (optional)"
            value={comment}
            onChange={e => setComment(e.target.value)}
            style={{ flex: 1, fontSize: 10, padding: '4px 8px', border: '1px solid #e5e5e5', borderRadius: 4, outline: 'none' }}
          />
          <button onClick={submitDisagree}
            style={{ fontSize: 10, padding: '4px 10px', background: '#7c3aed', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>
            Send
          </button>
        </div>
      )}
    </div>
  );
}

export default function PrismCard({ prism, analysisId }: { prism: any; analysisId?: string }) {
  if (!prism) return null;

  const techniques = prism.techniques || [];
  const brief = prism.brief || '';

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 24, height: 24, borderRadius: 6, background: '#f3e8ff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>
          </div>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Prism — techniques</span>
        </div>
        <span style={{ fontSize: 12, color: '#888' }}>{techniques.length} found</span>
      </div>

      {techniques.length === 0 ? (
        <div style={{ padding: '12px 0', textAlign: 'center', color: '#16a34a', fontSize: 13 }}>✓ No manipulation techniques detected</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {techniques.map((t: any, i: number) => {
            const conf = Math.round((t.confidence || 0) * 100);
            const barColor = conf >= 85 ? '#dc2626' : conf >= 70 ? '#d97706' : '#eab308';
            const cat = CATEGORY_COLORS[t.category] || { bg: '#f0f0ee', color: '#555' };
            const name = (t.name || '').replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase());

            return (
              <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{name}</span>
                    <span style={{ fontSize: 9, padding: '1px 6px', borderRadius: 4, background: cat.bg, color: cat.color, fontWeight: 600 }}>
                      {(t.category || 'framing').replace(/_/g, ' ')}
                    </span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 700, color: barColor }}>{conf}%</span>
                </div>
                <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2, marginBottom: 6 }}>
                  <div style={{ height: '100%', width: `${conf}%`, background: barColor, borderRadius: 2 }} />
                </div>
                {t.explanation && <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5, marginBottom: 2 }}>{t.explanation}</div>}
                {t.evidence && <div style={{ fontSize: 11, color: '#888', fontStyle: 'italic', borderLeft: '2px solid #e5e5e5', paddingLeft: 8, marginTop: 4 }}>"{t.evidence}"</div>}
                {analysisId && <TechniqueVote analysisId={analysisId} technique={t} />}
              </div>
            );
          })}
        </div>
      )}

      {brief && (
        <div style={{ marginTop: 12, padding: '10px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, fontSize: 12, color: '#404040', lineHeight: 1.6 }}>
          {brief}
        </div>
      )}
    </div>
  );
}
PRISMEOF

echo "✅ PrismCard updated with 👍/👎 per technique"

# ============================================
# 4. Update ThreatScore — formula breakdown + confidence band
# ============================================

cat > src/components/ThreatScore.tsx << 'TSEOF'
'use client';
import { useState } from 'react';

export default function ThreatScore({ data }: { data: any }) {
  const [showFormula, setShowFormula] = useState(false);

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;

  const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  const techScore = techs.length > 0 ? Math.round(maxConf * 40) : 0;
  const fcScore = Math.min(fcs.length * 4, 30);
  const toxScore = Math.round(tox * 20);
  const bonusScore = fcs.length >= 3 ? 10 : 0;
  const score = Math.min(techScore + fcScore + toxScore + bonusScore, 100);

  const scoreColor = score >= 70 ? '#dc2626' : score >= 40 ? '#d97706' : '#16a34a';
  const scoreLabel = score >= 70 ? 'HIGH RISK' : score >= 40 ? 'MEDIUM' : 'LOW RISK';

  // Confidence band based on technique confidences
  const avgConf = techs.length > 0
    ? techs.reduce((sum: number, t: any) => sum + (t.confidence || 0), 0) / techs.length
    : 0;
  const confLabel = avgConf >= 0.8 ? 'High' : avgConf >= 0.5 ? 'Medium' : techs.length > 0 ? 'Low' : 'N/A';
  const confColor = avgConf >= 0.8 ? '#dc2626' : avgConf >= 0.5 ? '#d97706' : '#16a34a';

  const circumference = 2 * Math.PI * 54;
  const dashOffset = circumference - (score / 100) * circumference;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        {/* Score ring */}
        <div style={{ position: 'relative', width: 120, height: 120, flexShrink: 0 }}>
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="54" fill="none" stroke="#f0f0ee" strokeWidth="6" />
            <circle cx="60" cy="60" r="54" fill="none" stroke={scoreColor} strokeWidth="6"
              strokeDasharray={circumference} strokeDashoffset={dashOffset}
              strokeLinecap="round" transform="rotate(-90 60 60)"
              style={{ transition: 'stroke-dashoffset 0.8s ease' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 28, fontWeight: 700, color: scoreColor, lineHeight: 1 }}>{score}</span>
            <span style={{ fontSize: 10, fontWeight: 600, color: scoreColor }}>{scoreLabel}</span>
          </div>
        </div>

        {/* Metrics grid */}
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Techniques</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{techs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Fact-checks</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{fcs.length}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Sources</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#404040' }}>{data.signal?.source_bias ? 1 : 0}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Toxicity</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(1)}%</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Sentiment</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{data.signal?.sentiment || 'Neutral'}</div>
          </div>
          <div style={{ padding: '8px 10px', background: '#f8f8f6', borderRadius: 8 }}>
            <div style={{ fontSize: 9, fontWeight: 600, textTransform: 'uppercase', color: '#888', letterSpacing: '0.06em' }}>Model</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#404040', textTransform: 'capitalize' }}>{(data.prism?.model_used || 'gpt-4o-mini').replace(/-/g, ' ').replace('gpt 4o mini', 'GPT-4o Mini')}</div>
          </div>
        </div>
      </div>

      {/* Confidence band + formula toggle */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12, paddingTop: 10, borderTop: '1px solid #f0f0ee' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 11, color: '#888' }}>Confidence:</span>
          <span style={{ fontSize: 11, fontWeight: 600, color: confColor, padding: '2px 8px', borderRadius: 4, background: confLabel === 'High' ? '#fef2f2' : confLabel === 'Medium' ? '#fffbeb' : '#f0fdf4' }}>
            {confLabel}
          </span>
          {confLabel === 'Low' && <span style={{ fontSize: 10, color: '#aaa' }}>— signals detected but not definitive</span>}
          {confLabel === 'Medium' && <span style={{ fontSize: 10, color: '#aaa' }}>— moderate manipulation signals</span>}
          {confLabel === 'High' && <span style={{ fontSize: 10, color: '#aaa' }}>— strong manipulation signals detected</span>}
        </div>
        <button onClick={() => setShowFormula(!showFormula)}
          style={{ fontSize: 10, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
          {showFormula ? 'Hide formula' : 'How is this calculated?'}
        </button>
      </div>

      {/* Formula breakdown */}
      {showFormula && (
        <div style={{ marginTop: 8, padding: '10px 12px', background: '#faf5ff', border: '1px solid #ede9fe', borderRadius: 8, fontSize: 11, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 600, marginBottom: 4, color: '#7c3aed' }}>Score breakdown:</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: '2px 10px', alignItems: 'center' }}>
            <span style={{ color: '#888' }}>Technique confidence</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(techScore / 40 * 100, 100)}%`, background: '#7c3aed', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{techScore}/40</span>

            <span style={{ color: '#888' }}>Fact-check matches</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(fcScore / 30 * 100, 100)}%`, background: '#2563eb', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{fcScore}/30</span>

            <span style={{ color: '#888' }}>Toxicity level</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${Math.min(toxScore / 20 * 100, 100)}%`, background: '#d97706', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{toxScore}/20</span>

            <span style={{ color: '#888' }}>Cross-reference bonus</span>
            <div style={{ height: 3, background: '#f0f0ee', borderRadius: 2 }}><div style={{ height: '100%', width: `${bonusScore > 0 ? 100 : 0}%`, background: '#16a34a', borderRadius: 2 }} /></div>
            <span style={{ fontWeight: 600 }}>{bonusScore}/10</span>
          </div>
          <div style={{ marginTop: 6, fontSize: 10, color: '#888' }}>
            Total: {techScore} + {fcScore} + {toxScore} + {bonusScore} = <strong style={{ color: scoreColor }}>{score}/100</strong>
          </div>
        </div>
      )}
    </div>
  );
}
TSEOF

echo "✅ ThreatScore updated with confidence band + formula breakdown"

# ============================================
# 5. Pass analysisId to PrismCard from AnalysisResult
# ============================================

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

# Pass analysisId to PrismCard
if 'analysisId' not in content:
    content = content.replace(
        '<PrismCard prism={data.prism} />',
        '<PrismCard prism={data.prism} analysisId={data.id || data.blockchain?.content_hash?.slice(0, 12) || ""} />'
    )
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ analysisId passed to PrismCard')
else:
    print('Already passes analysisId')
PYEOF

# ============================================
# 6. Update Help page — add "Our approach" section
# ============================================

python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

if 'Our approach' not in content:
    approach_section = '''
        <div style={{ background: '#7c3aed', borderRadius: 14, padding: '24px 20px', marginBottom: 24, color: '#fff' }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>Our approach</h2>
          <p style={{ fontSize: 13, lineHeight: 1.7, opacity: 0.9, marginBottom: 12 }}>
            Dissekt never tells you what's true or false. Instead, it shows you <em>how</em> content is constructed to influence you — the techniques, the framing, the missing context.
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Heuristics first, AI second</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>9 statistical models run instantly at zero cost. LLMs are only called when heuristics need confirmation — saving money and reducing hallucination risk.</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.1)', borderRadius: 8, padding: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Transparent scoring</div>
              <div style={{ fontSize: 11, opacity: 0.8, lineHeight: 1.5 }}>Every score is decomposed. You see exactly how much each factor contributes — technique confidence, fact-checks, toxicity. No black boxes.</div>
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

'''
    # Insert after the subtitle
    content = content.replace(
        "<div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>",
        approach_section + "        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>"
    )
    open('src/app/help/page.tsx', 'w').write(content)
    print('✅ "Our approach" added to help page')
else:
    print('Already has approach section')
PYEOF

echo ""
echo "✅ All 4 trust features built:"
echo "  1. 👍/👎 per technique — corrections stored in Supabase"
echo "  2. Score formula — expandable 'How is this calculated?' with visual breakdown"
echo "  3. Confidence band — High/Medium/Low with explanation"
echo "  4. 'Our approach' — methodology section on /help page"
echo ""
echo "⚠️  Don't forget to run the SQL in Supabase to create the corrections table!"
echo ""
echo "Test: npm run build && npm run dev"
