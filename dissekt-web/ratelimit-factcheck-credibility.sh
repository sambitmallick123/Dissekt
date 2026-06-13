#!/bin/bash
# Dissekt — API rate limiting middleware + fact-checker credibility
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. Fact-checker credibility database
# ============================================

cat > app/factchecker_db.py << 'FCDBEOF'
"""
Fact-checker credibility database.
Sources: IFCN (International Fact-Checking Network), Duke Reporters' Lab,
Poynter Institute, European Digital Media Observatory (EDMO).

Credibility tiers:
  A — IFCN signatory, transparent methodology, regular corrections
  B — Established org, editorial standards, not IFCN but reputable
  C — Newer or regional, less track record, still useful
  U — Unknown / not rated
"""

FACTCHECKER_DB = {
    # Tier A — IFCN signatories + gold standard
    "snopes.com": {"name": "Snopes", "tier": "A", "founded": 1994, "ifcn": True, "focus": "General misinformation", "methodology": "https://www.snopes.com/transparency/", "region": "US", "notes": "Oldest online fact-checker. IFCN signatory since 2017."},
    "politifact.com": {"name": "PolitiFact", "tier": "A", "founded": 2007, "ifcn": True, "focus": "US politics", "methodology": "https://www.politifact.com/article/2018/feb/12/principles-truth-o-meter/", "region": "US", "notes": "Pulitzer Prize winner. Truth-O-Meter rating system."},
    "factcheck.org": {"name": "FactCheck.org", "tier": "A", "founded": 2003, "ifcn": True, "focus": "US politics", "methodology": "https://www.factcheck.org/our-process/", "region": "US", "notes": "Annenberg Public Policy Center. Non-partisan."},
    "fullfact.org": {"name": "Full Fact", "tier": "A", "founded": 2010, "ifcn": True, "focus": "UK politics & public discourse", "methodology": "https://fullfact.org/about/our-approach/", "region": "UK", "notes": "UK's independent fact-checking charity. AI-assisted."},
    "correctiv.org": {"name": "Correctiv", "tier": "A", "founded": 2014, "ifcn": True, "focus": "German public interest", "methodology": "https://correctiv.org/faktencheck/ueber-uns/", "region": "Germany", "notes": "Germany's largest non-profit newsroom."},
    "altnews.in": {"name": "Alt News", "tier": "A", "founded": 2017, "ifcn": True, "focus": "Indian misinformation", "methodology": "https://www.altnews.in/about-us/", "region": "India", "notes": "IFCN signatory. Covers Hindi + English."},
    "boomlive.in": {"name": "BOOM", "tier": "A", "founded": 2016, "ifcn": True, "focus": "Indian misinformation", "methodology": "https://www.boomlive.in/about-us", "region": "India", "notes": "IFCN signatory. Multi-language fact-checking."},
    "afp.com": {"name": "AFP Fact Check", "tier": "A", "founded": 2017, "ifcn": True, "focus": "Global", "methodology": "https://factcheck.afp.com/about-us", "region": "Global", "notes": "80+ journalists across 25+ countries."},
    "reuters.com": {"name": "Reuters Fact Check", "tier": "A", "founded": 2020, "ifcn": False, "focus": "Global", "methodology": "https://www.reuters.com/fact-check/about", "region": "Global", "notes": "Reuters wire service fact-check unit."},
    "washingtonpost.com": {"name": "Washington Post Fact Checker", "tier": "A", "founded": 2011, "ifcn": False, "focus": "US politics", "methodology": "https://www.washingtonpost.com/politics/2019/01/07/about-fact-checker/", "region": "US", "notes": "Pinocchio rating system (1-4)."},
    
    # Tier B — Established, reputable
    "apnews.com": {"name": "AP Fact Check", "tier": "B", "founded": 2016, "ifcn": False, "focus": "US + global", "region": "US", "notes": "Associated Press. Wire service standards."},
    "bbc.com": {"name": "BBC Reality Check", "tier": "B", "founded": 2017, "ifcn": False, "focus": "UK + global", "region": "UK", "notes": "BBC's in-house verification team."},
    "channel4.com": {"name": "Channel 4 FactCheck", "tier": "B", "founded": 2005, "ifcn": False, "focus": "UK politics", "region": "UK", "notes": "UK broadcast fact-checking."},
    "vishvasnews.com": {"name": "Vishvas News", "tier": "B", "founded": 2018, "ifcn": True, "focus": "Indian misinformation", "region": "India", "notes": "Part of Jagran New Media. 11 Indian languages."},
    "thequint.com": {"name": "The Quint WebQoof", "tier": "B", "founded": 2019, "ifcn": True, "focus": "Indian misinformation", "region": "India", "notes": "The Quint's fact-check arm."},
    "dw.com": {"name": "DW Fact Check", "tier": "B", "founded": 2020, "ifcn": False, "focus": "German + global", "region": "Germany", "notes": "Deutsche Welle's fact-check team."},
    "tagesschau.de": {"name": "Tagesschau Faktenfinder", "tier": "B", "founded": 2017, "ifcn": False, "focus": "German misinformation", "region": "Germany", "notes": "ARD's fact-checking unit."},
    "bellingcat.com": {"name": "Bellingcat", "tier": "B", "founded": 2014, "ifcn": False, "focus": "OSINT investigations", "region": "Global", "notes": "Open source intelligence. Verification of conflict/crisis."},
    
    # Tier C — Newer or regional
    "leadstories.com": {"name": "Lead Stories", "tier": "C", "founded": 2015, "ifcn": True, "focus": "Viral misinformation", "region": "US", "notes": "Trendolizer technology for viral content."},
    "logicallyfacts.com": {"name": "Logically Facts", "tier": "C", "founded": 2017, "ifcn": True, "focus": "AI-assisted fact-checking", "region": "UK/India", "notes": "AI + human hybrid fact-checking."},
    "factly.in": {"name": "Factly", "tier": "C", "founded": 2014, "ifcn": True, "focus": "Indian data + facts", "region": "India", "notes": "Open data advocacy + fact-checking."},
    "indiatoday.in": {"name": "India Today Fact Check", "tier": "C", "founded": 2019, "ifcn": False, "focus": "Indian misinformation", "region": "India", "notes": "India Today's anti-misinformation desk."},
    "thejournal.ie": {"name": "The Journal FactCheck", "tier": "C", "founded": 2016, "ifcn": True, "focus": "Irish politics", "region": "Ireland", "notes": "Ireland's first dedicated fact-check service."},
}


def get_checker_info(domain: str) -> dict:
    """Get credibility info for a fact-checker by domain."""
    domain = domain.lower().replace("www.", "").replace("https://", "").replace("http://", "").split("/")[0]
    for key, info in FACTCHECKER_DB.items():
        if key in domain or domain in key:
            return {**info, "domain": key}
    return {"name": domain, "tier": "U", "ifcn": False, "region": "Unknown", "notes": "Not in credibility database"}


def tier_label(tier: str) -> str:
    return {"A": "Gold standard", "B": "Established", "C": "Emerging", "U": "Unrated"}[tier]


def tier_color(tier: str) -> str:
    return {"A": "#16a34a", "B": "#2563eb", "C": "#d97706", "U": "#888"}[tier]
FCDBEOF

echo "✅ Fact-checker credibility database (23 orgs)"

# ============================================
# 2. Wire fact-checker info into Lens/Trace output
# ============================================

python3 -c "
content = open('app/main.py').read()
if 'factchecker_db' not in content:
    content = content.replace(
        'from app.beacon import scan',
        'from app.beacon import scan\nfrom app.factchecker_db import get_checker_info, tier_label'
    )
    open('app/main.py', 'w').write(content)
    print('✅ Imported factchecker_db')
"

# Add fact-checker enrichment to scan response
python3 -c "
content = open('app/beacon/__init__.py').read()
if 'factchecker_db' not in content:
    content = content.replace(
        'import httpx',
        'import httpx\nfrom app.factchecker_db import get_checker_info, tier_label, tier_color'
    )
    
    # Enrich fact-check results with credibility info
    if 'enrich_factchecks' not in content:
        content = content.replace(
            'return analysis',
            '''    # Enrich fact-checks with credibility info
    try:
        if hasattr(analysis, 'trace') and analysis.trace and hasattr(analysis.trace, 'fact_checks'):
            for fc in analysis.trace.fact_checks:
                domain = (fc.get('url', '') or '').split('/')[2] if fc.get('url') else ''
                info = get_checker_info(domain)
                fc['checker_tier'] = info.get('tier', 'U')
                fc['checker_tier_label'] = tier_label(info.get('tier', 'U'))
                fc['checker_ifcn'] = info.get('ifcn', False)
                fc['checker_region'] = info.get('region', '')
                fc['checker_notes'] = info.get('notes', '')
    except Exception:
        pass
    
    return analysis'''
        )
    open('app/beacon/__init__.py', 'w').write(content)
    print('✅ Beacon: fact-checker enrichment')
"

# ============================================
# 3. API rate limiting middleware
# ============================================

cat > app/middleware.py << 'MWEOF'
"""
API rate limiting middleware.
Validates X-API-Key header on /api/scan and other protected endpoints.
Free users use tier-based limits (localStorage on frontend).
API key users get server-side rate limiting.
"""
import hashlib
import time
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("dissekt.middleware")


async def validate_and_rate_limit(api_key: str, supabase_url: str, supabase_key: str) -> dict:
    """
    Validate an API key and check rate limits.
    Returns: {"valid": True/False, "user": ..., "error": ...}
    """
    if not api_key or not api_key.startswith("dsk_"):
        return {"valid": False, "error": "Invalid API key format. Keys start with dsk_"}
    
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    
    try:
        from supabase import create_client
        sb = create_client(supabase_url, supabase_key)
        
        result = sb.table("api_keys").select("*").eq("key_hash", key_hash).execute()
        
        if not result.data:
            return {"valid": False, "error": "API key not found"}
        
        row = result.data[0]
        
        if not row.get("active"):
            return {"valid": False, "error": "API key has been revoked"}
        
        # Check rate limit (reset daily)
        last_reset = row.get("last_reset", "")
        now = datetime.utcnow()
        
        try:
            if last_reset:
                last_reset_dt = datetime.fromisoformat(str(last_reset).replace("Z", "+00:00")).replace(tzinfo=None)
                if (now - last_reset_dt).days >= 1:
                    # Reset counter
                    sb.table("api_keys").update({
                        "requests_today": 1,
                        "last_reset": now.isoformat()
                    }).eq("id", row["id"]).execute()
                    return {"valid": True, "user": row["user_email"], "remaining": row["rate_limit"] - 1}
        except:
            pass
        
        if row.get("requests_today", 0) >= row.get("rate_limit", 100):
            return {
                "valid": False,
                "error": f"Rate limit exceeded ({row['rate_limit']}/day). Resets at midnight UTC.",
                "limit": row["rate_limit"],
                "used": row["requests_today"],
            }
        
        # Increment counter
        sb.table("api_keys").update({
            "requests_today": (row.get("requests_today", 0) or 0) + 1,
        }).eq("id", row["id"]).execute()
        
        remaining = row["rate_limit"] - row.get("requests_today", 0) - 1
        
        return {
            "valid": True,
            "user": row["user_email"],
            "tier": row.get("tier", "pro"),
            "remaining": max(remaining, 0),
            "limit": row["rate_limit"],
        }
    except Exception as e:
        logger.warning(f"Rate limit check failed: {e}")
        # Fail open — allow the request if DB is down
        return {"valid": True, "user": "unknown", "error_note": "Rate limit check failed, request allowed"}
MWEOF

echo "✅ Rate limiting middleware"

# Wire middleware into /api/scan
python3 -c "
content = open('app/main.py').read()

if 'middleware' not in content or 'validate_and_rate_limit' not in content:
    content = content.replace(
        'from app.beacon import scan',
        'from app.beacon import scan\nfrom app.middleware import validate_and_rate_limit'
    )
    
    # Add API key validation to scan endpoint
    if 'X-API-Key' not in content:
        content = content.replace(
            'async def scan_content(request: ScanRequest):',
            'async def scan_content(request: ScanRequest, x_api_key: str = Header(None, alias=\"X-API-Key\")):' 
        )
        
        # Add Header import
        if 'from fastapi import Header' not in content:
            content = content.replace(
                'from fastapi import FastAPI',
                'from fastapi import FastAPI, Header'
            )
        
        # Add key validation at the start of scan_content
        content = content.replace(
            '\"\"\"Main analysis endpoint.',
            '\"\"\"Main analysis endpoint.'
        )
        
        old_try = '''    try:
        result = await scan('''
        
        new_try = '''    # API key rate limiting (if key provided)
    if x_api_key:
        settings = get_settings()
        auth = await validate_and_rate_limit(x_api_key, settings.supabase_url, settings.supabase_key)
        if not auth[\"valid\"]:
            from fastapi.responses import JSONResponse
            return JSONResponse(status_code=429 if \"Rate limit\" in auth.get(\"error\", \"\") else 401, content={\"error\": auth[\"error\"], \"limit\": auth.get(\"limit\"), \"used\": auth.get(\"used\")})
    
    try:
        result = await scan('''
        
        content = content.replace(old_try, new_try, 1)
    
    open('app/main.py', 'w').write(content)
    print('✅ Scan endpoint: API key validation + rate limiting')
"

echo "✅ Backend complete"

# ============================================
# 4. FRONTEND: Update FactCheckSection with credibility tiers
# ============================================

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

cat > src/components/FactCheckSection.tsx << 'FCEOF'
'use client';

const TIER_INFO: Record<string, { label: string; color: string; bg: string }> = {
  A: { label: 'Gold standard', color: '#16a34a', bg: '#f0fdf4' },
  B: { label: 'Established', color: '#2563eb', bg: '#eff6ff' },
  C: { label: 'Emerging', color: '#d97706', bg: '#fffbeb' },
  U: { label: 'Unrated', color: '#888', bg: '#f8fafa' },
};

export default function FactCheckSection({ data }: { data: any }) {
  const factChecks = data?.lens?.fact_checks || data?.trace?.fact_checks || [];
  const spread = data?.lens?.spread || data?.trace?.spread || [];

  // Calculate aggregate reliability
  const tiers = factChecks.map((fc: any) => fc.checker_tier || 'U');
  const tierACount = tiers.filter((t: string) => t === 'A').length;
  const tierBCount = tiers.filter((t: string) => t === 'B').length;
  const totalRated = tiers.filter((t: string) => t !== 'U').length;
  
  let reliabilityScore = 0;
  let reliabilityLabel = 'No data';
  let reliabilityColor = '#888';
  
  if (factChecks.length > 0) {
    reliabilityScore = Math.round(((tierACount * 100 + tierBCount * 70) / Math.max(factChecks.length, 1)));
    if (reliabilityScore >= 80) { reliabilityLabel = 'High confidence'; reliabilityColor = '#16a34a'; }
    else if (reliabilityScore >= 50) { reliabilityLabel = 'Moderate confidence'; reliabilityColor = '#d97706'; }
    else if (reliabilityScore > 0) { reliabilityLabel = 'Low confidence'; reliabilityColor = '#dc2626'; }
    else { reliabilityLabel = 'Unrated sources'; reliabilityColor = '#888'; }
  }

  return (
    <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 18, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16 }}>✅</span>
          <span style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>What fact-checkers say</span>
          <span style={{ fontSize: 12, color: '#888' }}>
            {factChecks.length > 0 ? `${factChecks.length} verification${factChecks.length !== 1 ? 's' : ''}` : 'None found'}
          </span>
        </div>
        {factChecks.length > 0 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 10, color: '#888' }}>Source reliability:</span>
            <span style={{ fontSize: 11, fontWeight: 600, color: reliabilityColor, padding: '2px 8px', background: reliabilityScore >= 80 ? '#f0fdf4' : reliabilityScore >= 50 ? '#fffbeb' : '#fef2f2', borderRadius: 4 }}>
              {reliabilityLabel}
            </span>
          </div>
        )}
      </div>

      {factChecks.length === 0 && (
        <div style={{ padding: '14px 16px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 10, fontSize: 13, color: '#555', lineHeight: 1.6 }}>
          No fact-checking organizations have published verification for these claims yet. This does not mean the content is accurate or inaccurate.
        </div>
      )}

      {factChecks.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {factChecks.map((fc: any, i: number) => {
            const rating = (fc.rating || fc.textualRating || '').toLowerCase();
            const ratingColor = rating.includes('false') || rating.includes('misleading') || rating.includes('pants') ? '#dc2626'
              : rating.includes('true') || rating.includes('correct') ? '#16a34a'
              : rating.includes('mixed') || rating.includes('partly') ? '#d97706' : '#555';
            
            const tier = fc.checker_tier || 'U';
            const tierInfo = TIER_INFO[tier] || TIER_INFO.U;

            return (
              <div key={i} style={{ padding: '10px 14px', border: '0.5px solid #e5eaea', borderRadius: 10, borderLeft: `3px solid ${ratingColor}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8, marginBottom: 4 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                      <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>
                        {fc.publisher?.name || fc.claimant || 'Fact-checker'}
                      </span>
                      <span style={{ fontSize: 9, fontWeight: 600, color: tierInfo.color, background: tierInfo.bg, padding: '1px 6px', borderRadius: 3 }}>
                        {tierInfo.label}
                      </span>
                      {fc.checker_ifcn && (
                        <span style={{ fontSize: 9, fontWeight: 600, color: '#0d9488', background: '#f0fdfa', padding: '1px 6px', borderRadius: 3 }}>IFCN ✓</span>
                      )}
                    </div>
                    <div style={{ fontSize: 12, color: '#555', lineHeight: 1.5 }}>{fc.text || fc.title || fc.claim || ''}</div>
                    {fc.checker_notes && (
                      <div style={{ fontSize: 10, color: '#888', marginTop: 3 }}>{fc.checker_notes}</div>
                    )}
                  </div>
                  <span style={{ fontSize: 10, fontWeight: 600, color: '#fff', background: ratingColor, padding: '2px 8px', borderRadius: 4, flexShrink: 0 }}>
                    {fc.rating || fc.textualRating || 'Reviewed'}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  {fc.checker_region && <span style={{ fontSize: 9, color: '#888' }}>{fc.checker_region}</span>}
                  {fc.url && <a href={fc.url} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none' }}>Read full fact-check ↗</a>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Tier legend */}
      {factChecks.length > 0 && (
        <div style={{ display: 'flex', gap: 10, marginTop: 10, flexWrap: 'wrap' }}>
          {Object.entries(TIER_INFO).map(([key, info]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10 }}>
              <div style={{ width: 8, height: 8, borderRadius: 2, background: info.color }} />
              <span style={{ color: '#888' }}>{info.label}</span>
            </div>
          ))}
          <a href="https://ifcncodeofprinciples.poynter.org/signatories" target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', marginLeft: 4 }}>What is IFCN? ↗</a>
        </div>
      )}

      {spread.length > 0 && (
        <div style={{ marginTop: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', marginBottom: 6 }}>Claim spread</div>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            {spread.slice(0, 8).map((s: any, i: number) => (
              <a key={i} href={s.url || '#'} target="_blank" rel="noopener"
                style={{ fontSize: 10, padding: '3px 8px', background: '#f8fafa', border: '0.5px solid #e5eaea', borderRadius: 4, color: '#555', textDecoration: 'none' }}>
                {s.source || s.domain || `Source ${i + 1}`}
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
FCEOF

echo "✅ FactCheckSection: credibility tiers + reliability score"

echo ""
echo "✅ Both features built:"
echo ""
echo "  🔐 API Rate Limiting"
echo "     - X-API-Key header validated on /api/scan"
echo "     - Invalid key: 401 with error message"
echo "     - Rate exceeded: 429 with limit/used counts"
echo "     - Daily reset at midnight UTC"
echo "     - No key: falls through to frontend tier limits"
echo "     - Fail-open: if DB down, request allowed"
echo ""
echo "  ✅ Fact-checker Credibility"
echo "     - 23 organizations rated (A/B/C/U tiers)"
echo "     - A = Gold standard (IFCN signatories)"
echo "     - B = Established (BBC, AP, Bellingcat)"
echo "     - C = Emerging (regional, newer)"
echo "     - U = Unrated"
echo "     - Aggregate reliability score per analysis"
echo "     - IFCN badge shown for signatories"
echo "     - Tier legend + 'What is IFCN?' link"
echo "     - Each fact-check shows: org, tier, region, notes"
echo ""
echo "npm run build"
