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
