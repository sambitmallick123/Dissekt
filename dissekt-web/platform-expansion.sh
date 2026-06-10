#!/bin/bash
# Dissekt — Platform Expansion
# 1. Longitudinal tracking (topic trends over time)
# 2. Embeddable widget for news sites
# 3. Expand Compass India (50+ politicians)
# 4. Compass US (major politicians)
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. BACKEND: Longitudinal tracking endpoint
# ============================================

python3 << 'PYEOF'
content = open('app/main.py').read()

if '/api/topics' not in content:
    topics_endpoint = '''

@app.get("/api/topics")
async def topic_tracking(q: str = "", limit: int = 20):
    """Track how a topic has been analyzed over time."""
    if len(q) < 3:
        return {"topic": q, "analyses": [], "trends": {}}
    
    try:
        from app.claim_graph import find_similar
        results = await find_similar(q, limit=limit)
        
        # Build temporal data
        analyses = []
        technique_freq = {}
        timestamps = []
        
        for r in results:
            ts = r.get("timestamp") or ""
            analyses.append({
                "text_preview": r.get("text_preview", ""),
                "similarity": r.get("similarity", 0),
                "techniques": r.get("techniques", []),
                "timestamp": ts,
            })
            
            for t in r.get("techniques", []):
                technique_freq[t] = technique_freq.get(t, 0) + 1
            
            if ts:
                try: timestamps.append(float(ts))
                except: pass
        
        # Sort by timestamp
        analyses.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        
        # Build trends
        trends = {
            "total_analyses": len(analyses),
            "technique_frequency": dict(sorted(technique_freq.items(), key=lambda x: -x[1])),
            "time_span_days": round((max(timestamps) - min(timestamps)) / 86400, 1) if len(timestamps) >= 2 else 0,
            "avg_similarity": round(sum(r.get("similarity", 0) for r in results) / max(len(results), 1), 3),
        }
        
        return {"topic": q, "analyses": analyses, "trends": trends, "count": len(analyses)}
    except Exception as e:
        logger.warning(f"Topic tracking failed: {e}")
        return {"topic": q, "analyses": [], "trends": {}, "error": str(e)}

'''
    content = content.replace(
        '# ============================================\n# Run with: uvicorn app.main:app --reload',
        topics_endpoint + '# ============================================\n# Run with: uvicorn app.main:app --reload'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Topics endpoint added')
else:
    print('Already exists')
PYEOF

echo "✅ Backend: Longitudinal tracking"

# ============================================
# 2. FRONTEND: Topics/Trends page
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

mkdir -p src/app/topics

cat > src/app/topics/page.tsx << 'TOPEOF'
'use client';
import { useState } from 'react';

export default function TopicsPage() {
  const [query, setQuery] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    if (query.length < 3) return;
    setLoading(true);
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const res = await fetch(`${apiUrl}/api/topics?q=${encodeURIComponent(query)}&limit=20`);
      setData(await res.json());
    } catch {}
    finally { setLoading(false); }
  };

  const techColor = (name: string) => {
    const colors: Record<string, string> = {
      loaded_language: '#dc2626', cherry_picking: '#d97706', missing_context: '#2563eb',
      appeal_to_authority: '#7c3aed', emotional_framing: '#ec4899', hasty_generalization: '#f59e0b',
    };
    return colors[name] || '#888';
  };

  return (
    <main style={{ minHeight: '100vh', background: '#f5f5f4' }}>
      <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 20 }}>
        <div style={{ maxWidth: 900, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
            <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Dissekt</span>
            <span style={{ fontSize: 13, color: '#888' }}>Topics</span>
          </a>
          <a href="/" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', fontWeight: 500 }}>← Back</a>
        </div>
      </nav>

      <div style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>📈 Topic Tracking</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 20 }}>See how a topic has been analyzed over time — techniques used, frequency, evolution.</p>

        <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
          <input type="text" value={query} onChange={e => setQuery(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleSearch()}
            placeholder="Search a topic: vaccines, Modi, climate, 5G..."
            style={{ flex: 1, padding: '12px 16px', border: '1px solid #e5e5e5', borderRadius: 10, fontSize: 14, outline: 'none', background: '#fff' }} />
          <button onClick={handleSearch} disabled={loading || query.length < 3}
            style={{ padding: '12px 24px', background: query.length >= 3 ? '#7c3aed' : '#d4d4d4', color: '#fff', border: 'none', borderRadius: 10, fontSize: 14, fontWeight: 600, cursor: query.length >= 3 ? 'pointer' : 'not-allowed' }}>
            {loading ? 'Searching...' : 'Track'}
          </button>
        </div>

        {data && (
          <>
            {/* Summary */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#7c3aed' }}>{data.trends?.total_analyses || 0}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Analyses found</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#2563eb' }}>{Object.keys(data.trends?.technique_frequency || {}).length}</div>
                <div style={{ fontSize: 11, color: '#888' }}>Unique techniques</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#d97706' }}>{data.trends?.time_span_days || 0}d</div>
                <div style={{ fontSize: 11, color: '#888' }}>Time span</div>
              </div>
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, padding: '14px 16px', textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: '#16a34a' }}>{((data.trends?.avg_similarity || 0) * 100).toFixed(0)}%</div>
                <div style={{ fontSize: 11, color: '#888' }}>Avg similarity</div>
              </div>
            </div>

            {/* Technique frequency */}
            {Object.keys(data.trends?.technique_frequency || {}).length > 0 && (
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18, marginBottom: 16 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Technique frequency</div>
                {Object.entries(data.trends.technique_frequency).map(([name, count]: [string, any]) => (
                  <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                    <span style={{ fontSize: 12, fontWeight: 500, width: 140, flexShrink: 0 }}>{name.replace(/_/g, ' ')}</span>
                    <div style={{ flex: 1, height: 6, background: '#f0f0ee', borderRadius: 3 }}>
                      <div style={{ height: '100%', width: `${Math.min((count / data.trends.total_analyses) * 100, 100)}%`, background: techColor(name), borderRadius: 3 }} />
                    </div>
                    <span style={{ fontSize: 11, fontWeight: 600, color: '#555', width: 24, textAlign: 'right' }}>{count}</span>
                  </div>
                ))}
              </div>
            )}

            {/* Timeline */}
            {data.analyses?.length > 0 && (
              <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 18 }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>Analysis timeline</div>
                {data.analyses.map((a: any, i: number) => (
                  <div key={i} style={{ display: 'flex', gap: 10, padding: '8px 0', borderBottom: i < data.analyses.length - 1 ? '1px solid #f0f0ee' : 'none' }}>
                    <div style={{ width: 36, height: 36, borderRadius: 8, background: '#f3e8ff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <span style={{ fontSize: 11, fontWeight: 700, color: '#7c3aed' }}>{Math.round(a.similarity * 100)}%</span>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.5 }}>{a.text_preview}</div>
                      <div style={{ display: 'flex', gap: 4, marginTop: 3, flexWrap: 'wrap' }}>
                        {(a.techniques || []).map((t: string, j: number) => (
                          <span key={j} style={{ fontSize: 9, padding: '1px 6px', borderRadius: 3, background: '#f0f0ee', color: '#555' }}>{t.replace(/_/g, ' ')}</span>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {data.count === 0 && (
              <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>
                No analyses found for "{query}". The knowledge base grows with every scan.
              </div>
            )}
          </>
        )}
      </div>
    </main>
  );
}
TOPEOF

echo "✅ Topics tracking page created"

# ============================================
# 3. FRONTEND: Embeddable widget
# ============================================

mkdir -p "src/app/embed/[id]"

cat > "src/app/embed/[id]/page.tsx" << 'EMBEDEOF'
'use client';
import { useState, useEffect, use } from 'react';

export default function EmbedPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/report?id=${id}`)
      .then(r => r.json())
      .then(d => { if (!d.error) setData(d); setLoading(false); })
      .catch(() => setLoading(false));
  }, [id]);

  if (loading) return <div style={{ padding: 20, textAlign: 'center', fontSize: 13, color: '#888' }}>Loading analysis...</div>;
  if (!data?.analysis) return <div style={{ padding: 20, textAlign: 'center', fontSize: 13, color: '#888' }}>Report not found</div>;

  const a = data.analysis;
  const techs = a.prism?.techniques || [];
  const fcs = a.trace?.fact_checks || [];
  const tox = a.signal?.toxicity_score || 0;
  const maxConf = techs.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  const raw = Math.min((techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs.length * 4, 30) + Math.round(tox * 20) + (fcs.length >= 3 ? 10 : 0), 100);
  const score = 100 - raw;
  const scoreColor = score <= 30 ? '#dc2626' : score <= 60 ? '#d97706' : '#16a34a';
  const label = score <= 30 ? 'Low transparency' : score <= 60 ? 'Moderate' : 'High transparency';

  return (
    <div style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', maxWidth: 400, margin: '0 auto', padding: 16 }}>
      {/* Score bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 10, marginBottom: 10 }}>
        <div style={{ width: 44, height: 44, borderRadius: 22, border: `3px solid ${scoreColor}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 16, fontWeight: 700, color: scoreColor }}>{score}</span>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: scoreColor }}>{label}</div>
          <div style={{ fontSize: 10, color: '#888' }}>{techs.length} techniques · {fcs.length} cross-refs · {(tox * 100).toFixed(1)}% toxicity</div>
        </div>
      </div>

      {/* Techniques */}
      {techs.length > 0 && (
        <div style={{ marginBottom: 10 }}>
          {techs.slice(0, 3).map((t: any, i: number) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', fontSize: 11, borderBottom: '1px solid #f0f0ee' }}>
              <span style={{ fontWeight: 500 }}>{(t.name || '').replace(/_/g, ' ')}</span>
              <span style={{ fontWeight: 700, color: t.confidence >= 0.8 ? '#dc2626' : '#d97706' }}>{Math.round(t.confidence * 100)}%</span>
            </div>
          ))}
        </div>
      )}

      {/* Brief */}
      {a.prism?.brief && (
        <div style={{ fontSize: 11, color: '#555', lineHeight: 1.6, marginBottom: 10 }}>
          {a.prism.brief.slice(0, 200)}
        </div>
      )}

      {/* Footer */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 8, borderTop: '1px solid #e5e5e5' }}>
        <a href={`https://dissekt.info/report/${id}`} target="_blank" rel="noopener"
          style={{ fontSize: 11, color: '#7c3aed', textDecoration: 'none', fontWeight: 600 }}>
          Full analysis →
        </a>
        <a href="https://dissekt.info" target="_blank" rel="noopener"
          style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: '#888', textDecoration: 'none' }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          Powered by Dissekt
        </a>
      </div>
    </div>
  );
}
EMBEDEOF

echo "✅ Embeddable widget at /embed/[id]"

# ============================================
# 4. EXPAND: Compass India (50+ politicians)
# ============================================

cat > app/compass/india_db.json << 'INDIAEOF'
{
  "narendra modi": {"name": "Narendra Modi", "party": "BJP", "position": "Prime Minister", "constituency": "Varanasi, UP", "state": "Gujarat", "terms": "PM since 2014", "key_votes": ["CAA 2019", "Farm Laws 2020", "Article 370 abrogation"], "key_promises": ["Achhe Din", "Make in India", "Digital India", "2 crore jobs/year", "₹15 lakh"], "controversies": ["Demonetisation", "Electoral Bonds", "Adani row"], "factual_notes": ["GDP growth avg ~6.5% 2014-24", "Unemployment ~7-8% CMIE"]},
  "rahul gandhi": {"name": "Rahul Gandhi", "party": "INC", "position": "Leader of Opposition, Lok Sabha", "constituency": "Rae Bareli, UP", "state": "Delhi", "terms": "MP since 2004", "key_votes": ["Opposed CAA", "Opposed Farm Laws", "Opposed Art 370"], "key_promises": ["NYAY ₹72K/year", "Caste census", "MSP guarantee"], "controversies": ["National Herald case", "Defamation case"], "factual_notes": ["INC won 99 seats 2024 (up from 52)"]},
  "amit shah": {"name": "Amit Shah", "party": "BJP", "position": "Home Minister", "constituency": "Gandhinagar, Gujarat", "state": "Gujarat", "terms": "MP since 2017, BJP Pres 2014-20", "key_votes": ["CAA author", "Article 370", "NRC push"], "key_promises": ["NRC nationwide", "Zero terrorism"], "controversies": ["Snoopgate", "Fake encounter cases (acquitted)"], "factual_notes": ["CAA+NRC triggered nationwide protests"]},
  "arvind kejriwal": {"name": "Arvind Kejriwal", "party": "AAP", "position": "Former CM Delhi", "constituency": "New Delhi", "state": "Delhi", "terms": "CM 2013, 2015-2024", "key_votes": ["Free water 20kL", "Free electricity <200 units"], "key_promises": ["Free electricity", "Improved schools", "Anti-corruption"], "controversies": ["Excise policy case", "Liquor scam allegations"], "factual_notes": ["Delhi govt schools improved pass rates", "AAP won Punjab 2022"]},
  "mamata banerjee": {"name": "Mamata Banerjee", "party": "TMC", "position": "CM West Bengal", "constituency": "Bhawanipur, WB", "state": "West Bengal", "terms": "CM since 2011", "key_votes": ["Opposed CAA/NRC", "Opposed farm laws"], "key_promises": ["Kanyashree", "Duare Sarkar"], "controversies": ["Sandeshkhali 2024", "Post-election violence 2021"], "factual_notes": ["TMC won 215/294 seats 2021"]},
  "yogi adityanath": {"name": "Yogi Adityanath", "party": "BJP", "position": "CM Uttar Pradesh", "constituency": "Gorakhpur, UP", "state": "UP", "terms": "CM since 2017", "key_votes": ["Anti-conversion law", "Bulldozer policy"], "key_promises": ["Zero crime tolerance", "Expressways", "Industrial growth"], "controversies": ["Bulldozer justice", "Hathras case"], "factual_notes": ["UP GDP grew but unemployment high"]},
  "sonia gandhi": {"name": "Sonia Gandhi", "party": "INC", "position": "Rajya Sabha MP", "constituency": "Rajya Sabha", "state": "Delhi", "terms": "INC President 1998-2017, 2019-2024", "key_votes": ["RTI Act 2005", "MGNREGA", "Food Security Act"], "key_promises": ["Inclusive growth", "Secular governance"], "controversies": ["National Herald case", "AgustaWestland allegations"], "factual_notes": ["Led UPA to two consecutive wins 2004, 2009"]},
  "nitin gadkari": {"name": "Nitin Gadkari", "party": "BJP", "position": "MP (formerly Road Transport Minister)", "constituency": "Nagpur, Maharashtra", "state": "Maharashtra", "terms": "MP since 2014", "key_votes": ["National highway expansion", "Green energy push"], "key_promises": ["World-class highways", "Electric vehicles"], "controversies": ["Purti Group allegations"], "factual_notes": ["Highway construction doubled to ~12,000km/year under tenure"]},
  "rajnath singh": {"name": "Rajnath Singh", "party": "BJP", "position": "Defence Minister", "constituency": "Lucknow, UP", "state": "UP", "terms": "MP since 2004", "key_votes": ["Rafale deal", "Defence procurement reforms"], "key_promises": ["Modernized armed forces", "Atmanirbhar defence"], "controversies": ["Rafale deal questions"], "factual_notes": ["India became 4th largest defence spender"]},
  "nirmala sitharaman": {"name": "Nirmala Sitharaman", "party": "BJP", "position": "Finance Minister", "constituency": "Rajya Sabha", "state": "Karnataka", "terms": "FM since 2019", "key_votes": ["GST implementation", "PLI schemes", "Budget presentations"], "key_promises": ["$5T economy", "Tax reform", "Digital payments"], "controversies": ["Rising inflation", "Fiscal deficit"], "factual_notes": ["GST collection crossed ₹2L crore/month in 2024"]},
  "s jaishankar": {"name": "S Jaishankar", "party": "BJP", "position": "External Affairs Minister", "constituency": "Rajya Sabha", "state": "Gujarat", "terms": "Minister since 2019", "key_votes": ["Multi-alignment foreign policy", "Quad participation"], "key_promises": ["India's voice globally"], "controversies": ["China border response criticism"], "factual_notes": ["Former Foreign Secretary, career diplomat"]},
  "m k stalin": {"name": "M K Stalin", "party": "DMK", "position": "CM Tamil Nadu", "constituency": "Kolathur, Chennai", "state": "Tamil Nadu", "terms": "CM since 2021", "key_votes": ["Opposed NEET", "Social justice bills"], "key_promises": ["Dravidian model governance", "₹1000/month for women"], "controversies": ["Corruption allegations against DMK"], "factual_notes": ["DMK won 133/234 seats in 2021 TN election"]},
  "pinarayi vijayan": {"name": "Pinarayi Vijayan", "party": "CPI(M)", "position": "CM Kerala", "constituency": "Dharmadom, Kerala", "state": "Kerala", "terms": "CM since 2016", "key_votes": ["Kerala model development", "Digital literacy"], "key_promises": ["Knowledge economy", "Life Mission housing"], "controversies": ["Gold smuggling case", "SilverLine project"], "factual_notes": ["First LDF govt to win consecutive terms in Kerala"]},
  "nitish kumar": {"name": "Nitish Kumar", "party": "JD(U)", "position": "CM Bihar", "constituency": "Bihar", "state": "Bihar", "terms": "CM multiple terms since 2005", "key_votes": ["Prohibition in Bihar", "Caste census support"], "key_promises": ["Development of Bihar", "Women empowerment"], "controversies": ["Multiple alliance switches", "Prohibition failures"], "factual_notes": ["Switched between NDA and INDIA alliance multiple times"]},
  "k chandrashekar rao": {"name": "K Chandrashekar Rao", "party": "BRS", "position": "Former CM Telangana", "constituency": "Gajwel, Telangana", "state": "Telangana", "terms": "CM 2014-2023", "key_votes": ["Telangana formation", "Rythu Bandhu farmer scheme"], "key_promises": ["Dalit Bandhu", "IT hub"], "controversies": ["Kaleshwaram project costs", "Dynasty politics"], "factual_notes": ["BRS lost power to Congress in 2023"]},
  "uddhav thackeray": {"name": "Uddhav Thackeray", "party": "Shiv Sena (UBT)", "position": "Party leader", "constituency": "Mumbai", "state": "Maharashtra", "terms": "CM 2019-2022", "key_votes": ["MVA alliance with NCP+Congress"], "key_promises": ["Hindutva + development"], "controversies": ["Party split by Eknath Shinde 2022"], "factual_notes": ["Lost CM post after Shinde faction split"]},
  "eknath shinde": {"name": "Eknath Shinde", "party": "Shiv Sena", "position": "CM Maharashtra", "constituency": "Thane, Maharashtra", "state": "Maharashtra", "terms": "CM since 2022", "key_votes": ["Alliance with BJP"], "key_promises": ["Development of Maharashtra"], "controversies": ["Party split legality", "SC verdict on Shiv Sena"], "factual_notes": ["Supreme Court upheld his faction as legitimate"]},
  "sharad pawar": {"name": "Sharad Pawar", "party": "NCP (SP)", "position": "Party President", "constituency": "Maharashtra", "state": "Maharashtra", "terms": "Multiple terms since 1970s", "key_votes": ["RTI support", "Farm policies"], "key_promises": ["Maharashtra development", "Farmer welfare"], "controversies": ["NCP split 2023", "Corruption allegations"], "factual_notes": ["One of longest-serving Indian politicians"]},
  "akhilesh yadav": {"name": "Akhilesh Yadav", "party": "SP", "position": "SP President", "constituency": "Kannauj, UP", "state": "UP", "terms": "CM 2012-2017, MP", "key_votes": ["Expressway projects in UP", "Social justice"], "key_promises": ["Development + social justice"], "controversies": ["Family feud with Mulayam Singh"], "factual_notes": ["SP won 37 seats in 2024 LS election (up from 5)"]},
  "mayawati": {"name": "Mayawati", "party": "BSP", "position": "BSP President", "constituency": "UP", "state": "UP", "terms": "CM 4 times", "key_votes": ["Dalit empowerment", "Ambedkar parks"], "key_promises": ["Dalit rights", "Social equality"], "controversies": ["Statues spending", "Alliance flip-flops"], "factual_notes": ["First Dalit woman CM in India", "BSP won 0 seats in 2024"]},
  "tejashwi yadav": {"name": "Tejashwi Yadav", "party": "RJD", "position": "RJD leader", "constituency": "Bihar", "state": "Bihar", "terms": "Deputy CM 2022-2024", "key_votes": ["Caste census", "INDIA alliance"], "key_promises": ["10 lakh jobs", "Youth empowerment"], "controversies": ["IRCTC scam case (family)"], "factual_notes": ["Son of Lalu Prasad Yadav"]},
  "asaduddin owaisi": {"name": "Asaduddin Owaisi", "party": "AIMIM", "position": "MP", "constituency": "Hyderabad", "state": "Telangana", "terms": "MP since 2004", "key_votes": ["Opposed CAA", "Triple Talaq bill opposition"], "key_promises": ["Muslim community rights", "Minority welfare"], "controversies": ["Divisive politics allegations"], "factual_notes": ["Won Hyderabad seat 5 consecutive times"]},
  "smriti irani": {"name": "Smriti Irani", "party": "BJP", "position": "Former Minister", "constituency": "Amethi (lost 2024)", "state": "Delhi", "terms": "Minister 2014-2024", "key_votes": ["New Education Policy support"], "key_promises": ["Education reform", "Women empowerment"], "controversies": ["Degree controversy", "Goa restaurant allegations"], "factual_notes": ["Defeated Rahul Gandhi in Amethi 2019, lost in 2024"]},
  "priyanka gandhi": {"name": "Priyanka Gandhi", "party": "INC", "position": "MP Wayanad", "constituency": "Wayanad, Kerala", "state": "UP/Delhi", "terms": "MP since 2024", "key_votes": ["First electoral win 2024 bypoll"], "key_promises": ["Congress revival in UP"], "controversies": ["Dynasty politics criticism"], "factual_notes": ["Won Wayanad bypoll with large margin"]},
  "devendra fadnavis": {"name": "Devendra Fadnavis", "party": "BJP", "position": "Deputy CM Maharashtra", "constituency": "Nagpur South West", "state": "Maharashtra", "terms": "CM 2014-2019, Dy CM since 2022", "key_votes": ["Mumbai metro expansion", "Bullet train support"], "key_promises": ["Mumbai transformation", "Industrial growth"], "controversies": ["Government formation drama 2019"], "factual_notes": ["BJP's key strategist in Maharashtra"]},
  "siddaramaiah": {"name": "Siddaramaiah", "party": "INC", "position": "CM Karnataka", "constituency": "Varuna, Karnataka", "state": "Karnataka", "terms": "CM 2013-2018, 2023-present", "key_votes": ["5 guarantees scheme", "Caste census"], "key_promises": ["Free bus for women", "Free rice", "₹2000 cash transfer"], "controversies": ["MUDA land scam allegations"], "factual_notes": ["Congress won 135/224 seats in 2023 Karnataka election"]},
  "chandrababu naidu": {"name": "Chandrababu Naidu", "party": "TDP", "position": "CM Andhra Pradesh", "constituency": "Kuppam, AP", "state": "AP", "terms": "CM 1995-2004, 2014-2019, 2024-present", "key_votes": ["Amaravati capital", "Tech hub development"], "key_promises": ["Andhra development", "Amaravati completion"], "controversies": ["Skill Development scam case (acquitted)"], "factual_notes": ["TDP won 135/175 seats in 2024 AP election"]},
  "jagan mohan reddy": {"name": "Jagan Mohan Reddy", "party": "YSRCP", "position": "Former CM AP", "constituency": "Pulivendula, AP", "state": "AP", "terms": "CM 2019-2024", "key_votes": ["Navaratnalu welfare schemes", "3 capitals plan"], "key_promises": ["Welfare for poor", "English medium education"], "controversies": ["CBI cases", "Assets case"], "factual_notes": ["YSRCP won only 11/175 seats in 2024 (down from 151)"]},
  "hemant soren": {"name": "Hemant Soren", "party": "JMM", "position": "CM Jharkhand", "constituency": "Jharkhand", "state": "Jharkhand", "terms": "CM 2019-present (interrupted)", "key_votes": ["Tribal land rights", "Mining regulation"], "key_promises": ["Tribal welfare", "Anti-displacement"], "controversies": ["Land scam case (arrested 2024, bail)"], "factual_notes": ["JMM-Congress alliance retained Jharkhand in 2024"]},
  "naveen patnaik": {"name": "Naveen Patnaik", "party": "BJD", "position": "Former CM Odisha", "constituency": "Hinjili, Odisha", "state": "Odisha", "terms": "CM 2000-2024 (5 terms)", "key_votes": ["KALIA scheme", "Disaster management"], "key_promises": ["5T governance", "Zero tolerance corruption"], "controversies": ["VK Pandian influence allegations"], "factual_notes": ["Lost power after 24 years in 2024, BJP won Odisha"]}
}
INDIAEOF

echo "✅ Compass India expanded to 30 politicians"

# ============================================
# 5. NEW: Compass US database
# ============================================

cat > app/compass/us_db.json << 'USEOF'
{
  "joe biden": {"name": "Joe Biden", "party": "Democrat", "position": "46th President (ended Jan 2025)", "constituency": "National", "state": "Delaware", "terms": "President 2021-2025, VP 2009-2017, Senator 1973-2009", "key_votes": ["Infrastructure Investment Act", "CHIPS Act", "Inflation Reduction Act"], "key_promises": ["Build Back Better", "Student loan forgiveness", "Climate action"], "controversies": ["Age concerns", "Afghanistan withdrawal", "Hunter Biden case"], "factual_notes": ["Chose not to run for re-election 2024", "Inflation peaked at 9.1% June 2022"]},
  "donald trump": {"name": "Donald Trump", "party": "Republican", "position": "47th President", "constituency": "National", "state": "Florida", "terms": "President 2017-2021, 2025-present", "key_votes": ["Tax Cuts and Jobs Act 2017", "USMCA trade deal", "Tariffs on China"], "key_promises": ["Build the wall", "Drain the swamp", "America First"], "controversies": ["Jan 6 indictment", "Classified documents case", "34 felony convictions"], "factual_notes": ["Won 2024 election with 312 electoral votes", "First president to be criminally convicted"]},
  "kamala harris": {"name": "Kamala Harris", "party": "Democrat", "position": "Former Vice President", "constituency": "National", "state": "California", "terms": "VP 2021-2025, Senator 2017-2021", "key_votes": ["Tie-breaking Senate votes", "Inflation Reduction Act"], "key_promises": ["Opportunity economy", "Reproductive rights"], "controversies": ["Border crisis response", "Staff turnover"], "factual_notes": ["First woman, Black, and Asian VP", "Lost 2024 presidential race"]},
  "mitch mcconnell": {"name": "Mitch McConnell", "party": "Republican", "position": "Senator Kentucky", "constituency": "Kentucky", "state": "Kentucky", "terms": "Senator since 1985", "key_votes": ["Blocked Merrick Garland", "3 SCOTUS confirmations", "Infrastructure bill"], "key_promises": ["Conservative judiciary", "Republican majority"], "controversies": ["Health concerns", "Corporate donations"], "factual_notes": ["Longest-serving Senate leader in history", "Stepped down as leader 2025"]},
  "chuck schumer": {"name": "Chuck Schumer", "party": "Democrat", "position": "Senate Minority Leader", "constituency": "New York", "state": "New York", "terms": "Senator since 1999", "key_votes": ["Infrastructure bill", "CHIPS Act", "Debt ceiling deals"], "key_promises": ["Democratic agenda", "Climate action"], "controversies": ["Pro-Israel stance criticism"], "factual_notes": ["Senate Majority Leader 2021-2025"]},
  "nancy pelosi": {"name": "Nancy Pelosi", "party": "Democrat", "position": "Representative California", "constituency": "CA-11, San Francisco", "state": "California", "terms": "Representative since 1987", "key_votes": ["ACA passage", "Both Trump impeachments", "Jan 6 committee"], "key_promises": ["Democratic unity", "Progressive legislation"], "controversies": ["Stock trading", "Taiwan visit 2022"], "factual_notes": ["First woman Speaker of the House (2007, 2019)"]},
  "ron desantis": {"name": "Ron DeSantis", "party": "Republican", "position": "Governor Florida", "constituency": "Florida", "state": "Florida", "terms": "Governor since 2019", "key_votes": ["Don't Say Gay bill", "Anti-ESG legislation", "Disney feud"], "key_promises": ["Freedom agenda", "Anti-woke"], "controversies": ["COVID response", "Migrant flights", "Failed presidential bid 2024"], "factual_notes": ["Won 2022 re-election by 19 points"]},
  "gavin newsom": {"name": "Gavin Newsom", "party": "Democrat", "position": "Governor California", "constituency": "California", "state": "California", "terms": "Governor since 2019", "key_votes": ["Climate legislation", "Gun control", "Reparations task force"], "key_promises": ["Climate leadership", "Housing reform"], "controversies": ["French Laundry dinner during COVID", "Homelessness crisis"], "factual_notes": ["Survived 2021 recall election"]},
  "bernie sanders": {"name": "Bernie Sanders", "party": "Independent", "position": "Senator Vermont", "constituency": "Vermont", "state": "Vermont", "terms": "Senator since 2007, Rep 1991-2007", "key_votes": ["Medicare for All advocacy", "Opposed Iraq War", "Budget Committee chair"], "key_promises": ["Medicare for All", "Free college", "$15 minimum wage"], "controversies": ["2016/2020 primary losses"], "factual_notes": ["Longest-serving independent in Congressional history"]},
  "aoc": {"name": "Alexandria Ocasio-Cortez", "party": "Democrat", "position": "Representative NY-14", "constituency": "NY-14, Bronx/Queens", "state": "New York", "terms": "Representative since 2019", "key_votes": ["Green New Deal", "Progressive caucus"], "key_promises": ["Green New Deal", "Medicare for All", "Housing justice"], "controversies": ["Met Gala 'Tax the Rich' dress"], "factual_notes": ["Youngest woman elected to Congress at 29"]},
  "elon musk": {"name": "Elon Musk", "party": "Independent/Republican-aligned", "position": "DOGE advisor", "constituency": "National", "state": "Texas", "terms": "DOGE advisory role 2025", "key_votes": ["Government efficiency recommendations"], "key_promises": ["Cut $2T in government spending", "Reduce bureaucracy"], "controversies": ["Twitter/X acquisition", "Political spending", "SEC battles"], "factual_notes": ["World's richest person", "CEO Tesla + SpaceX", "DOGE disbanded after initial period"]},
  "vivek ramaswamy": {"name": "Vivek Ramaswamy", "party": "Republican", "position": "Former DOGE co-lead", "constituency": "Ohio", "state": "Ohio", "terms": "2024 presidential candidate", "key_votes": ["Anti-ESG advocacy"], "key_promises": ["Dismantle administrative state", "National identity"], "controversies": ["Business record questions", "Left DOGE early"], "factual_notes": ["Biotech entrepreneur, youngest 2024 GOP primary candidate"]}
}
USEOF

echo "✅ Compass US database created (12 politicians)"

# ============================================
# 6. Update NER to support US
# ============================================

python3 << 'PYEOF'
content = open('app/compass/ner.py').read()

# Add US database loading
content = content.replace(
    '''def _load_db():
    global _db
    if _db is None:
        db_path = os.path.join(os.path.dirname(__file__), 'india_db.json')
        with open(db_path) as f:
            _db = json.load(f)
    return _db''',
    '''_dbs = {}

def _load_db(country: str = "india"):
    if country not in _dbs:
        filename = f"{country}_db.json"
        db_path = os.path.join(os.path.dirname(__file__), filename)
        if os.path.exists(db_path):
            with open(db_path) as f:
                _dbs[country] = json.load(f)
        else:
            _dbs[country] = {}
    return _dbs[country]'''
)

# Update detect_politicians to search all databases
content = content.replace(
    '''def detect_politicians(text: str, country: str = "india") -> list[dict]:
    """Find politician mentions in text."""
    if country != "india":
        return []
    
    db = _load_db()''',
    '''def detect_politicians(text: str, country: str = "all") -> list[dict]:
    """Find politician mentions in text. Searches all country databases."""
    countries = ["india", "us"] if country == "all" else [country]
    
    found = []
    seen = set()
    
    for c in countries:
        db = _load_db(c)
        matches = _match_names(text, db)
        for m in matches:
            if m["name"] not in seen:
                m["country"] = c
                found.append(m)
                seen.add(m["name"])
    
    return found


def _match_names(text: str, db: dict) -> list[dict]:
    """Match politician names from a single database."""'''
)

# Fix the rest of the function
content = content.replace(
    '''    found = []
    seen = set()
    
    for key, profile in db.items():
        if key in seen:
            continue
        
        name = profile["name"]
        name_parts = name.split()
        
        # Match full name (case insensitive)
        if re.search(rf'\\b{re.escape(name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        
        # Match last name alone (e.g. "Modi", "Shah", "Kejriwal")
        last_name = name_parts[-1]
        if re.search(rf'\\b{re.escape(last_name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        
        # Match first name if unique enough (>5 chars)
        first_name = name_parts[0]
        if len(first_name) > 5 and re.search(rf'\\b{re.escape(first_name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
    
    return found''',
    '''    found = []
    seen = set()
    
    for key, profile in db.items():
        if key in seen:
            continue
        name = profile["name"]
        name_parts = name.split()
        if re.search(rf'\\b{re.escape(name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        last_name = name_parts[-1]
        if re.search(rf'\\b{re.escape(last_name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
            continue
        first_name = name_parts[0]
        if len(first_name) > 5 and re.search(rf'\\b{re.escape(first_name)}\\b', text, re.IGNORECASE):
            found.append(profile)
            seen.add(key)
    return found'''
)

open('app/compass/ner.py', 'w').write(content)
print('✅ NER updated: searches India + US databases')
PYEOF

# Update compass __init__.py to pass country="all"
python3 -c "
content = open('app/compass/__init__.py').read()
content = content.replace(
    'detect_politicians(text, country)',
    'detect_politicians(text, country=\"all\")'
)
open('app/compass/__init__.py', 'w').write(content)
print('✅ Compass: searches all countries by default')
"

# ============================================
# 7. Add Topics link to nav
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

python3 -c "
content = open('src/app/page.tsx').read()
if \"'/topics'\" not in content:
    content = content.replace(
        \"<a href='/docs' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>API</a>\",
        \"<a href='/topics' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>Topics</a>\n            <a href='/docs' style={{ fontSize: 12, color: '#404040', textDecoration: 'none', fontWeight: 500 }}>API</a>\"
    )
    open('src/app/page.tsx', 'w').write(content)
    print('✅ Topics link added to nav')
"

echo ""
echo "✅ All 4 features built:"
echo ""
echo "  📈 Longitudinal Tracking (/topics)"
echo "     - Search any topic → see all past analyses"
echo "     - Technique frequency chart"
echo "     - Time span + similarity stats"
echo "     - Analysis timeline"
echo ""
echo "  🖼️ Embeddable Widget (/embed/[id])"
echo "     - Minimal chrome, iframeable"
echo "     - Shows: score, top techniques, brief, links"
echo "     - 'Powered by Dissekt' footer"
echo "     - Usage: <iframe src=\"dissekt.info/embed/REPORT_ID\">"
echo ""
echo "  🇮🇳 Compass India — 30 politicians"
echo "     - Major national + state leaders"
echo "     - Modi, Gandhi, Shah, Kejriwal, Mamata, Yogi + 24 more"
echo ""
echo "  🇺🇸 Compass US — 12 politicians"  
echo "     - Biden, Trump, Harris, McConnell, Schumer, Pelosi"
echo "     - DeSantis, Newsom, Sanders, AOC, Musk, Ramaswamy"
echo "     - Auto-detected alongside Indian politicians"
echo ""
echo "Test: npm run build && npm run dev"
echo "  - /topics → search 'vaccines' or 'Modi'"
echo "  - Scan 'Trump tariffs on China hurt American consumers' → Compass shows Trump profile"
echo "  - /embed/REPORT_ID → minimal widget"
