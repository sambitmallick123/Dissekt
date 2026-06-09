#!/bin/bash
# Dissekt — Compass (Political Engine India) + Pulse (Coordination Detection)
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# COMPASS: Political Accountability Engine
# ============================================

mkdir -p app/compass

# --- Indian politician database (curated, expandable) ---
cat > app/compass/india_db.json << 'DBEOF'
{
  "narendra modi": {
    "name": "Narendra Modi",
    "party": "BJP",
    "position": "Prime Minister of India",
    "constituency": "Varanasi, Uttar Pradesh",
    "state": "Gujarat (origin)",
    "terms": "PM since 2014 (3rd term from 2024)",
    "key_votes": ["CAA 2019", "Farm Laws 2020 (repealed 2021)", "Abrogation of Article 370 (2019)"],
    "key_promises": ["Achhe Din", "₹15 lakh in every account", "Make in India", "Digital India", "2 crore jobs/year"],
    "controversies": ["Demonetisation 2016", "Electoral Bonds scheme", "Adani-Hindenburg row"],
    "factual_notes": ["India GDP growth averaged ~6.5% 2014-2024", "Unemployment rate ~7-8% (CMIE data)", "Electoral Bonds struck down by SC in Feb 2024"]
  },
  "rahul gandhi": {
    "name": "Rahul Gandhi",
    "party": "INC",
    "position": "Leader of Opposition in Lok Sabha",
    "constituency": "Rae Bareli, Uttar Pradesh",
    "state": "Delhi",
    "terms": "MP since 2004",
    "key_votes": ["Opposed CAA", "Opposed Farm Laws", "Opposed Article 370 abrogation"],
    "key_promises": ["NYAY scheme (₹72,000/year)", "Caste census", "Legal guarantee for MSP"],
    "controversies": ["National Herald case", "Defamation conviction (overturned)", "Bharat Jodo Yatra"],
    "factual_notes": ["INC won 99 seats in 2024 general election (up from 52 in 2019)"]
  },
  "amit shah": {
    "name": "Amit Shah",
    "party": "BJP",
    "position": "Minister of Home Affairs",
    "constituency": "Gandhinagar, Gujarat",
    "state": "Gujarat",
    "terms": "MP since 2017, BJP President 2014-2020",
    "key_votes": ["Authored CAA", "Article 370 abrogation", "NRC push"],
    "key_promises": ["NRC nationwide", "Zero terrorism", "Congress-mukt Bharat"],
    "controversies": ["Snoopgate allegations", "Fake encounter cases (acquitted)"],
    "factual_notes": ["CAA + NRC triggered nationwide protests in 2019-2020"]
  },
  "arvind kejriwal": {
    "name": "Arvind Kejriwal",
    "party": "AAP",
    "position": "Former Chief Minister of Delhi",
    "constituency": "New Delhi",
    "state": "Delhi",
    "terms": "CM 2013 (49 days), 2015-2024",
    "key_votes": ["Free water 20kL/month in Delhi", "Free electricity <200 units", "Mohalla Clinics"],
    "key_promises": ["Free electricity", "Improved government schools", "Anti-corruption"],
    "controversies": ["Excise policy case (arrested 2024)", "Delhi liquor scam allegations"],
    "factual_notes": ["Delhi govt schools showed improved pass rates", "AAP won Punjab 2022"]
  },
  "mamata banerjee": {
    "name": "Mamata Banerjee",
    "party": "TMC",
    "position": "Chief Minister of West Bengal",
    "constituency": "Bhawanipur, West Bengal",
    "state": "West Bengal",
    "terms": "CM since 2011",
    "key_votes": ["Opposed CAA/NRC", "Opposed farm laws"],
    "key_promises": ["Kanyashree (girl child education)", "Duare Sarkar (doorstep governance)"],
    "controversies": ["Sandeshkhali incidents 2024", "Post-election violence allegations 2021"],
    "factual_notes": ["TMC won 215/294 seats in 2021 WB election"]
  },
  "yogi adityanath": {
    "name": "Yogi Adityanath",
    "party": "BJP",
    "position": "Chief Minister of Uttar Pradesh",
    "constituency": "Gorakhpur, UP",
    "state": "Uttar Pradesh",
    "terms": "CM since 2017",
    "key_votes": ["Anti-conversion law", "Bulldozer policy"],
    "key_promises": ["Zero tolerance for crime", "UP expressways", "Industrial development"],
    "controversies": ["Bulldozer justice criticism", "Hathras case handling", "COVID management"],
    "factual_notes": ["UP GDP grew but unemployment remained high per CMIE"]
  }
}
DBEOF

# --- NER: Politician name detection ---
cat > app/compass/ner.py << 'NEREOF'
"""Detect politician names in text using fuzzy matching against database."""
import json
import os
import re
import logging

logger = logging.getLogger("dissekt.compass.ner")

_db = None

def _load_db():
    global _db
    if _db is None:
        db_path = os.path.join(os.path.dirname(__file__), 'india_db.json')
        with open(db_path) as f:
            _db = json.load(f)
    return _db

def detect_politicians(text: str, country: str = "india") -> list[dict]:
    """Find politician mentions in text. Returns list of matched profiles."""
    if country != "india":
        return []
    
    db = _load_db()
    text_lower = text.lower()
    found = []
    seen = set()
    
    for key, profile in db.items():
        # Match full name or last name
        name_parts = key.split()
        full_name = key
        last_name = name_parts[-1] if len(name_parts) > 1 else key
        
        # Check for full name match
        if full_name in text_lower and full_name not in seen:
            found.append(profile)
            seen.add(full_name)
        # Check for "Mr./Shri/PM + last name" patterns
        elif last_name in text_lower and len(last_name) > 4:
            # Avoid false positives on short names
            patterns = [
                rf'\b{re.escape(last_name)}\b',
                rf'\b{re.escape(profile["name"])}\b',
            ]
            for p in patterns:
                if re.search(p, text, re.IGNORECASE):
                    if full_name not in seen:
                        found.append(profile)
                        seen.add(full_name)
                    break
    
    return found
NEREOF

# --- Compass main module ---
cat > app/compass/__init__.py << 'COMPEOF'
"""Dissekt Compass — Political Accountability Engine.

Detects politicians in content and cross-references claims
against voting records, promises, and factual data.
"""
import logging
from app.compass.ner import detect_politicians

logger = logging.getLogger("dissekt.compass")


async def analyze_political_context(text: str, country: str = "india") -> dict:
    """Find politicians mentioned and check claims against their record."""
    politicians = detect_politicians(text, country)
    
    if not politicians:
        return {"politicians": [], "contradictions": [], "context": []}
    
    contradictions = []
    context_notes = []
    
    text_lower = text.lower()
    
    for pol in politicians:
        # Check if any key promises are referenced
        for promise in pol.get("key_promises", []):
            promise_keywords = [w.lower() for w in promise.split() if len(w) > 3]
            if any(kw in text_lower for kw in promise_keywords[:2]):
                context_notes.append({
                    "politician": pol["name"],
                    "type": "promise_referenced",
                    "detail": f"Promise: {promise}",
                    "party": pol["party"],
                })
        
        # Check factual notes that might contradict claims
        for note in pol.get("factual_notes", []):
            context_notes.append({
                "politician": pol["name"],
                "type": "factual_context",
                "detail": note,
                "party": pol["party"],
            })
        
        # Check controversies
        for controversy in pol.get("controversies", []):
            controversy_keywords = [w.lower() for w in controversy.split() if len(w) > 3]
            if any(kw in text_lower for kw in controversy_keywords[:2]):
                context_notes.append({
                    "politician": pol["name"],
                    "type": "controversy_referenced",
                    "detail": controversy,
                    "party": pol["party"],
                })
    
    # Format politician profiles for response
    profiles = []
    for pol in politicians:
        profiles.append({
            "name": pol["name"],
            "party": pol["party"],
            "position": pol["position"],
            "constituency": pol.get("constituency", ""),
            "terms": pol.get("terms", ""),
            "key_votes": pol.get("key_votes", []),
            "key_promises": pol.get("key_promises", []),
        })
    
    return {
        "politicians": profiles,
        "contradictions": contradictions,
        "context": context_notes,
    }
COMPEOF

echo "✅ Compass India: NER + politician database + context engine"

# ============================================
# PULSE: Coordination Detection
# ============================================

mkdir -p app/pulse

cat > app/pulse/__init__.py << 'PULSEEOF'
"""Dissekt Pulse — Coordination Detection.

Detects when multiple similar claims appear in a short time window,
suggesting coordinated amplification (bot farms, astroturfing, troll armies).
"""
import logging
import time
from datetime import datetime, timezone, timedelta

logger = logging.getLogger("dissekt.pulse")


async def detect_coordination(text: str, similar_claims: list[dict]) -> dict:
    """Analyze similar claims for coordination patterns.
    
    Signals:
    - Temporal clustering: many similar claims in < 24 hours
    - Source diversity: same claim from very different source types
    - Volume spike: unusual number of similar claims
    """
    if not similar_claims or len(similar_claims) < 2:
        return {"detected": False, "signals": [], "risk_level": "none"}
    
    signals = []
    
    # 1. Volume check: how many similar claims exist?
    count = len(similar_claims)
    if count >= 5:
        signals.append({
            "type": "volume_spike",
            "detail": f"{count} similar claims detected in the knowledge base",
            "severity": "high" if count >= 10 else "medium",
        })
    elif count >= 3:
        signals.append({
            "type": "volume_notable",
            "detail": f"{count} similar claims found — this narrative is spreading",
            "severity": "low",
        })
    
    # 2. Similarity clustering: are they very similar (>85%)?
    high_similarity = [c for c in similar_claims if c.get("similarity", 0) > 0.85]
    if len(high_similarity) >= 2:
        signals.append({
            "type": "near_duplicate",
            "detail": f"{len(high_similarity)} near-identical versions of this claim detected (>85% similarity)",
            "severity": "high",
        })
    
    # 3. Temporal clustering: check timestamps
    timestamps = []
    for c in similar_claims:
        ts = c.get("timestamp") or c.get("metadata", {}).get("timestamp")
        if ts:
            try:
                timestamps.append(float(ts))
            except (ValueError, TypeError):
                pass
    
    if len(timestamps) >= 2:
        timestamps.sort()
        time_span = timestamps[-1] - timestamps[0]
        if time_span < 86400 and len(timestamps) >= 3:  # <24 hours, 3+ claims
            signals.append({
                "type": "temporal_burst",
                "detail": f"{len(timestamps)} similar claims within {time_span/3600:.1f} hours — possible coordinated push",
                "severity": "high",
            })
        elif time_span < 604800 and len(timestamps) >= 3:  # <7 days
            signals.append({
                "type": "temporal_cluster",
                "detail": f"{len(timestamps)} similar claims within {time_span/86400:.1f} days",
                "severity": "medium",
            })
    
    # 4. Technique overlap: do all similar claims use the same techniques?
    all_techniques = []
    for c in similar_claims:
        techs = c.get("techniques", [])
        all_techniques.extend(techs)
    
    if all_techniques:
        from collections import Counter
        tech_counts = Counter(all_techniques)
        dominant = tech_counts.most_common(1)[0]
        if dominant[1] >= 3:
            signals.append({
                "type": "technique_pattern",
                "detail": f"'{dominant[0].replace('_', ' ')}' appears in {dominant[1]} similar claims — consistent manipulation pattern",
                "severity": "medium",
            })
    
    # Determine overall risk
    high_count = len([s for s in signals if s["severity"] == "high"])
    med_count = len([s for s in signals if s["severity"] == "medium"])
    
    if high_count >= 2:
        risk_level = "high"
    elif high_count >= 1 or med_count >= 2:
        risk_level = "medium"
    elif signals:
        risk_level = "low"
    else:
        risk_level = "none"
    
    return {
        "detected": len(signals) > 0,
        "signals": signals,
        "risk_level": risk_level,
        "similar_count": count,
    }
PULSEEOF

echo "✅ Pulse: Coordination detection engine"

# ============================================
# Update models.py — add compass + pulse fields
# ============================================

python3 << 'PYEOF'
content = open('app/models.py').read()

if 'compass' not in content:
    content = content.replace(
        '    similar_claims: list[dict]',
        '''    compass: dict = Field(default_factory=dict, description="Political accountability data")
    pulse: dict = Field(default_factory=dict, description="Coordination detection signals")
    similar_claims: list[dict]'''
    )
    open('app/models.py', 'w').write(content)
    print('✅ models.py: added compass + pulse fields')
else:
    print('Already has compass/pulse')
PYEOF

# ============================================
# Update beacon — integrate compass + pulse
# ============================================

python3 << 'PYEOF'
content = open('app/beacon/__init__.py').read()

if 'app.compass' not in content:
    # Add compass + pulse after similar claims step
    old = '    # Step 10: Detect language'
    new = '''    # Step 10: Political context (Compass)
    try:
        from app.compass import analyze_political_context
        compass_data = await analyze_political_context(extracted_text)
        analysis.compass = compass_data
    except Exception as e:
        logger.warning(f"Compass failed: {e}")

    # Step 10b: Coordination detection (Pulse)
    try:
        from app.pulse import detect_coordination
        pulse_data = await detect_coordination(extracted_text, analysis.similar_claims)
        analysis.pulse = pulse_data
    except Exception as e:
        logger.warning(f"Pulse failed: {e}")

    # Step 11: Detect language'''
    
    content = content.replace(old, new)
    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ beacon: compass + pulse integrated')
else:
    print('Already integrated')
PYEOF

echo "✅ Backend complete: Compass India + Pulse"

# ============================================
# FRONTEND: Compass Card
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/CompassCard.tsx << 'CCEOF'
'use client';

const PARTY_COLORS: Record<string, { bg: string; color: string }> = {
  BJP: { bg: '#fff7ed', color: '#c2410c' },
  INC: { bg: '#eff6ff', color: '#1d4ed8' },
  AAP: { bg: '#ecfdf5', color: '#047857' },
  TMC: { bg: '#f0fdf4', color: '#15803d' },
};

export default function CompassCard({ compass }: { compass: any }) {
  if (!compass?.politicians?.length) return null;

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>🏛</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Compass — Political Context</span>
        <span style={{ fontSize: 12, color: '#888' }}>{compass.politicians.length} politician{compass.politicians.length > 1 ? 's' : ''} detected</span>
      </div>

      {compass.politicians.map((pol: any, i: number) => {
        const pc = PARTY_COLORS[pol.party] || { bg: '#f5f5f4', color: '#555' };
        return (
          <div key={i} style={{ border: '1px solid #e5e5e5', borderRadius: 10, padding: 14, marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: pc.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>🏛</div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{pol.name}</div>
                <div style={{ fontSize: 11, color: '#888' }}>
                  <span style={{ padding: '1px 6px', borderRadius: 4, background: pc.bg, color: pc.color, fontWeight: 600, fontSize: 10, marginRight: 4 }}>{pol.party}</span>
                  {pol.position}
                </div>
              </div>
            </div>

            <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6, marginBottom: 6 }}>
              <span style={{ fontWeight: 600 }}>Constituency:</span> {pol.constituency} · <span style={{ fontWeight: 600 }}>Terms:</span> {pol.terms}
            </div>

            {pol.key_votes?.length > 0 && (
              <div style={{ marginBottom: 6 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>Key votes</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {pol.key_votes.map((v: string, j: number) => (
                    <span key={j} style={{ fontSize: 10, padding: '2px 8px', borderRadius: 4, background: '#f0f0ee', color: '#404040' }}>{v}</span>
                  ))}
                </div>
              </div>
            )}

            {pol.key_promises?.length > 0 && (
              <div>
                <div style={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 3 }}>Key promises</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {pol.key_promises.slice(0, 4).map((p: string, j: number) => (
                    <span key={j} style={{ fontSize: 10, padding: '2px 8px', borderRadius: 4, background: '#fef3c7', color: '#92400e' }}>{p}</span>
                  ))}
                </div>
              </div>
            )}
          </div>
        );
      })}

      {compass.context?.length > 0 && (
        <div style={{ marginTop: 8 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#404040', marginBottom: 6 }}>📎 Factual Context</div>
          {compass.context.map((c: any, i: number) => (
            <div key={i} style={{ display: 'flex', gap: 8, padding: '6px 10px', border: '1px solid #e5e5e5', borderRadius: 6, marginBottom: 4, fontSize: 11 }}>
              <span style={{ fontWeight: 600, color: '#7c3aed', flexShrink: 0 }}>{c.politician}</span>
              <span style={{ color: '#555' }}>{c.detail}</span>
              <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 3, background: c.type === 'controversy_referenced' ? '#fef2f2' : '#f0f0ee', color: c.type === 'controversy_referenced' ? '#b91c1c' : '#888', flexShrink: 0 }}>
                {c.type.replace('_', ' ')}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
CCEOF

echo "✅ CompassCard component created"

# --- Pulse Card ---
cat > src/components/PulseCard.tsx << 'PCEOF'
'use client';

const SEVERITY_STYLE: Record<string, { bg: string; color: string; icon: string }> = {
  high: { bg: '#fef2f2', color: '#b91c1c', icon: '🔴' },
  medium: { bg: '#fffbeb', color: '#92400e', icon: '🟡' },
  low: { bg: '#f0fdf4', color: '#065f46', icon: '🟢' },
};

export default function PulseCard({ pulse }: { pulse: any }) {
  if (!pulse?.detected) return null;

  const riskStyle = SEVERITY_STYLE[pulse.risk_level] || SEVERITY_STYLE.low;
  const riskLabel = pulse.risk_level === 'high' ? 'HIGH COORDINATION RISK' : pulse.risk_level === 'medium' ? 'MODERATE COORDINATION SIGNALS' : 'LOW COORDINATION SIGNALS';

  return (
    <div style={{ background: '#fff', border: `1px solid ${riskStyle.color}33`, borderRadius: 14, padding: 18, marginTop: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <div style={{ width: 24, height: 24, borderRadius: 6, background: riskStyle.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>📡</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>Pulse — Coordination Detection</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', background: riskStyle.bg, borderRadius: 10, marginBottom: 12 }}>
        <span style={{ fontSize: 16 }}>{riskStyle.icon}</span>
        <div>
          <div style={{ fontSize: 12, fontWeight: 700, color: riskStyle.color }}>{riskLabel}</div>
          <div style={{ fontSize: 11, color: '#888' }}>{pulse.similar_count} similar claims in knowledge base</div>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {pulse.signals.map((s: any, i: number) => {
          const ss = SEVERITY_STYLE[s.severity] || SEVERITY_STYLE.low;
          return (
            <div key={i} style={{ display: 'flex', alignItems: 'start', gap: 8, padding: '8px 10px', border: '1px solid #e5e5e5', borderRadius: 8 }}>
              <span style={{ fontSize: 10, flexShrink: 0 }}>{ss.icon}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: '#404040' }}>{s.type.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase())}</div>
                <div style={{ fontSize: 11, color: '#555', lineHeight: 1.5 }}>{s.detail}</div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 10, padding: '8px 10px', background: '#f5f5f4', borderRadius: 6, fontSize: 11, color: '#888', lineHeight: 1.5 }}>
        ⚠️ Coordination signals suggest organized amplification, not necessarily falsehood. The same claim can be pushed coordinately and still be accurate.
      </div>
    </div>
  );
}
PCEOF

echo "✅ PulseCard component created"

# ============================================
# Update AnalysisResult to include Compass + Pulse
# ============================================

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

# Add imports
if 'CompassCard' not in content:
    content = content.replace(
        "import ExtractedClaims from './ExtractedClaims';",
        "import ExtractedClaims from './ExtractedClaims';\nimport CompassCard from './CompassCard';\nimport PulseCard from './PulseCard';"
    )

# Add compass + pulse to the render
if 'CompassCard' not in content.split('return')[1]:
    content = content.replace(
        '''      {data.similar_claims?.length > 0 && (
        <div className="anim-fade anim-d4"><SimilarClaims claims={data.similar_claims} /></div>
      )}
    </div>''',
        '''      {data.similar_claims?.length > 0 && (
        <div className="anim-fade anim-d4"><SimilarClaims claims={data.similar_claims} /></div>
      )}

      {data.compass?.politicians?.length > 0 && (
        <div className="anim-fade anim-d3"><CompassCard compass={data.compass} /></div>
      )}

      {data.pulse?.detected && (
        <div className="anim-fade anim-d4"><PulseCard pulse={data.pulse} /></div>
      )}
    </div>'''
    )

open('src/components/AnalysisResult.tsx', 'w').write(content)
print('✅ AnalysisResult: Compass + Pulse added')
PYEOF

# ============================================
# Update Help page with Compass + Pulse
# ============================================

python3 << 'PYEOF'
content = open('src/app/help/page.tsx').read()

if 'Compass' not in content:
    compass_help = """{
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
  },"""

    content = content.replace(
        """icon: '📡',
    name: 'Radar',""",
        compass_help + """
  {
    icon: '📡',
    name: 'Radar',"""
    )
    
    open('src/app/help/page.tsx', 'w').write(content)
    print('✅ Help page: Compass + Pulse added')
else:
    print('Already has Compass in help')
PYEOF

echo ""
echo "✅ All done:"
echo "  🏛 Compass India — politician detection, profiles, voting records, promises"
echo "  📡 Pulse — coordination detection (volume, duplicates, temporal, technique patterns)"
echo "  🎨 Frontend — CompassCard + PulseCard in analysis results"
echo "  📖 Help page updated with both components"
echo ""
echo "Test: npm run dev"
echo "  Scan: 'Modi promised 2 crore jobs every year but unemployment is at 8 percent'"
echo "  → Should show Compass card with Modi's profile + factual context"
echo ""
echo "  Scan the same claim 3-4 times to build up Qdrant data"
echo "  → Pulse will start detecting coordination patterns"
