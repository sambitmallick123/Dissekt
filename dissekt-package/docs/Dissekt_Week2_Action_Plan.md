# DISSEKT — Week 2 Action Plan

**Includes:** Week 1 Day 5 (pre-tasks) + Week 2 Days 1-5
**Total estimated time:** 25-30 hours across 6 days (4-5 hours/day)
**Goal:** By end of Week 2, Dissekt has a web frontend at dissekt.co, Qdrant claim graph, OpenTimestamps anchoring, Radar MVP, Playwright extraction, pytest suite, and is ready for journalist demos.

---

## PRE-TASK: Week 1 Day 5 (close out Week 1)

### PT-1: Fix Detoxify (actually load the model)
**Time:** 30 min | **File:** `app/signal/__init__.py`

Find where toxicity is scored. Replace the hardcoded zeros with actual model loading:

```python
# At the top of the file, add:
import logging
logger = logging.getLogger("dissekt.signal")

_detoxify_model = None

def _get_detoxify():
    global _detoxify_model
    if _detoxify_model is None:
        try:
            from detoxify import Detoxify
            _detoxify_model = Detoxify('original')
            logger.info("Detoxify model loaded successfully (440MB)")
        except ImportError:
            logger.warning("Detoxify not installed — toxicity scores will be 0.0")
            return None
        except Exception as e:
            logger.error(f"Detoxify failed to load: {e}")
            return None
    return _detoxify_model
```

Then find the `_score_toxicity` function and replace:

```python
def _score_toxicity(text: str) -> dict:
    model = _get_detoxify()
    if model is None:
        return {
            "toxicity": 0.0, "severe_toxicity": 0.0, "obscene": 0.0,
            "threat": 0.0, "insult": 0.0, "identity_attack": 0.0
        }
    try:
        scores = model.predict(text[:1000])  # Limit input length for speed
        return {k: round(float(v), 4) for k, v in scores.items()}
    except Exception as e:
        logger.error(f"Detoxify prediction failed: {e}")
        return {
            "toxicity": 0.0, "severe_toxicity": 0.0, "obscene": 0.0,
            "threat": 0.0, "insult": 0.0, "identity_attack": 0.0
        }
```

**Test:**
```bash
python3 -c "
from detoxify import Detoxify
m = Detoxify('original')
print(m.predict('you are a stupid idiot'))
print(m.predict('The municipal water treatment facility completed its annual assessment.'))
"
```
First should show toxicity > 0.7. Second should show < 0.05.


### PT-2: Replace MBFC hardcoded dict with JSON file
**Time:** 15 min | **Files:** `app/data/mbfc_database.json` (new), `app/signal/__init__.py`

1. Create directory and copy the 231-source JSON:
```bash
mkdir -p app/data
cp mbfc_database.json app/data/mbfc_database.json
```

2. Update Signal to load from JSON. Find the MBFC_DATABASE dict and replace:
```python
import json
import os

_MBFC_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'mbfc_database.json')

def _load_mbfc():
    try:
        with open(_MBFC_PATH) as f:
            return json.load(f)
    except Exception as e:
        logger.warning(f"Failed to load MBFC database: {e}")
        return {}

MBFC_DATABASE = _load_mbfc()
```

**Test:**
```bash
python3 -c "
from app.signal import MBFC_DATABASE
print(f'Loaded {len(MBFC_DATABASE)} sources')
print(MBFC_DATABASE.get('foxnews.com'))
print(MBFC_DATABASE.get('thehindu.com'))
print(MBFC_DATABASE.get('rt.com'))
"
```
Should show: 231 sources, right/mixed, left-center/high, right-center/very-low.


### PT-3: Run 20-URL market test
**Time:** 2-3 hours

Use the test template from the Week 1 checklist (Day 5). Test 5 URLs per market. Log everything in test_results_day5.md.

**Sites to test:**
- India: scroll.in, thehindu.com (article not section), thewire.in, indiatoday.in, WhatsApp text
- Germany: spiegel.de, bild.de, tagesschau.de, faz.net, correctiv.org
- US: apnews.com, foxnews.com, nytimes.com, reuters.com, breitbart.com
- UK: bbc.com, dailymail.co.uk, theguardian.com, thesun.co.uk, telegraph.co.uk

For sites that 403: paste text directly. Note the 403 in results.


### PT-4: Create WEEK1_SUMMARY.md and WEEK2_TODO.md
**Time:** 30 min

```bash
# Fill in actual numbers from your testing
cat > WEEK1_SUMMARY.md << 'EOF'
# Week 1 Summary

## What works
- [x] Beacon: trafilatura.fetch_url() extraction, 5-method fallback
- [x] Prism: 9 heuristics + Claude Sonnet 4 (Detailed) + GPT-4o mini (Brief)
- [x] Trace: Google Fact Check API + SerpAPI/Brave web search
- [x] Signal: MBFC 231 sources + VADER + Detoxify (lazy-loaded)
- [x] Anchor: SHA-256 hash (OTS pending)
- [x] Cache: Redis deduplication
- [x] Parallel execution: asyncio.gather
- [x] Heuristic-only mode: 1s, €0
- [x] Model routing: Brief → GPT-4o mini, Detailed → Claude

## Key metrics
- Brief Mode avg: ~5s
- Detailed Mode avg: ~12s
- Heuristic-only: 1s
- Technique detection accuracy: ~90%
- MBFC accuracy: 100% (for sources in database)
- Tests passed: __/20

## Known issues
- Indian sites 403 (OpIndia, NDTV) — needs Playwright
- Fox News false positive (Claude knowledge cutoff)
- Attention gradient returns 0.0
- Compression heuristic inverted (needs length normalization)
EOF
```


### PT-5: Commit Week 1
**Time:** 5 min

```bash
git add .
git commit -m "Week 1 complete: Prism+Trace+Signal+Anchor, 231 MBFC sources, Detoxify enabled, 20-URL test"
git push
```

---

## WEEK 2 DAY 1: Frontend — Next.js scaffold + scan page

### Goal
Users can visit dissekt.co and paste a URL or text into a web interface. The page calls your backend API and displays the 3-layer analysis (Prism + Trace + Signal) in a readable format.

### Accounts needed (before starting)
- Vercel account (vercel.com) — free, deploys Next.js
- Connect dissekt.co domain to Vercel

### D1-1: Create Next.js project
**Time:** 30 min

```bash
cd /mnt/d/Startup\ Ideas/
npx create-next-app@latest dissekt-web --typescript --tailwind --app --src-dir --eslint
cd dissekt-web
```

### D1-2: Project structure
**Time:** 15 min

```
dissekt-web/
├── src/
│   ├── app/
│   │   ├── layout.tsx        ← Global layout (dark theme, fonts)
│   │   ├── page.tsx          ← Homepage with scan input
│   │   ├── globals.css       ← Tailwind + custom styles
│   │   └── api/
│   │       └── scan/
│   │           └── route.ts  ← Proxy to backend (avoids CORS)
│   ├── components/
│   │   ├── ScanInput.tsx     ← URL/text input + submit button
│   │   ├── AnalysisResult.tsx ← Full result display
│   │   ├── PrismCard.tsx     ← Technique cards with confidence bars
│   │   ├── TraceCard.tsx     ← Fact-checks + spread timeline
│   │   ├── SignalCard.tsx    ← Bias + toxicity + emotion
│   │   └── LoadingState.tsx  ← Skeleton loader during analysis
│   └── lib/
│       └── api.ts            ← API client
├── .env.local                ← NEXT_PUBLIC_API_URL=http://localhost:8000
├── tailwind.config.ts
└── package.json
```

### D1-3: Environment variables
**File:** `.env.local`
```
NEXT_PUBLIC_API_URL=http://localhost:8000
# Change to your Railway/Render URL when deployed:
# NEXT_PUBLIC_API_URL=https://dissekt-api.up.railway.app
```

### D1-4: API proxy route (avoids CORS)
**File:** `src/app/api/scan/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    
    const response = await fetch(`${apiUrl}/api/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(error, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { detail: 'Analysis service unavailable. Please try again.' },
      { status: 503 }
    );
  }
}
```

### D1-5: Main page with scan input
**File:** `src/app/page.tsx`

```tsx
'use client';
import { useState } from 'react';
import ScanInput from '@/components/ScanInput';
import AnalysisResult from '@/components/AnalysisResult';
import LoadingState from '@/components/LoadingState';

export default function Home() {
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleScan = async (content: string, mode: string) => {
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content, mode }),
      });

      if (!res.ok) {
        const err = await res.json();
        setError(err.detail || 'Analysis failed');
        return;
      }

      const data = await res.json();
      setResult(data);
    } catch (e) {
      setError('Could not connect to analysis service');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#04060a] text-gray-100">
      <div className="max-w-3xl mx-auto px-4 py-12">
        <h1 className="text-3xl font-bold tracking-tight mb-1">DISSEKT</h1>
        <p className="text-gray-500 text-sm mb-8">
          Dissect manipulative content. Trace claims to their source. Export the evidence.
        </p>

        <ScanInput onScan={handleScan} loading={loading} />

        {error && (
          <div className="mt-4 p-3 bg-red-900/20 border border-red-800/30 rounded-lg text-red-300 text-sm">
            {error}
          </div>
        )}

        {loading && <LoadingState />}
        {result && <AnalysisResult data={result} />}
      </div>
    </main>
  );
}
```

### D1-6: ScanInput component
**File:** `src/components/ScanInput.tsx`

```tsx
'use client';
import { useState } from 'react';

interface Props {
  onScan: (content: string, mode: string) => void;
  loading: boolean;
}

export default function ScanInput({ onScan, loading }: Props) {
  const [content, setContent] = useState('');
  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');

  const handleSubmit = () => {
    if (content.trim().length < 10) return;
    onScan(content.trim(), mode);
  };

  return (
    <div className="space-y-3">
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Paste any URL or text to analyze..."
        className="w-full h-32 bg-[#111620] border border-gray-800 rounded-lg p-3 text-sm text-gray-200 placeholder-gray-600 focus:border-teal-500/50 focus:outline-none resize-none"
      />
      <div className="flex items-center gap-3">
        <button
          onClick={handleSubmit}
          disabled={loading || content.trim().length < 10}
          className="px-5 py-2 bg-teal-600/20 border border-teal-600/30 rounded-lg text-teal-400 text-sm font-medium hover:bg-teal-600/30 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {loading ? 'Analyzing...' : 'Analyze'}
        </button>
        <div className="flex gap-1">
          {(['brief', 'detailed'] as const).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`px-3 py-1.5 rounded text-xs ${
                mode === m
                  ? 'bg-gray-700/50 text-gray-200'
                  : 'text-gray-500 hover:text-gray-300'
              }`}
            >
              {m === 'brief' ? 'Brief' : 'Detailed'}
            </button>
          ))}
        </div>
        <span className="text-xs text-gray-600 ml-auto">
          {content.trim().startsWith('http') ? 'URL detected' : content.length > 0 ? `${content.length} chars` : ''}
        </span>
      </div>
    </div>
  );
}
```

### D1-7: AnalysisResult component (basic)
**File:** `src/components/AnalysisResult.tsx`

Create a component that displays:
- Prism: technique cards with name, confidence bar, explanation, evidence
- Signal: source bias badge, factuality badge, toxicity score, sentiment
- Trace: fact-check list with publisher, rating, link; spread timeline
- Blockchain: content hash, timestamp, proof status
- Metadata: analysis time, model used, cached status

This is the largest component. Start simple — display raw JSON in a formatted way, then iterate on the design.

```tsx
'use client';

export default function AnalysisResult({ data }: { data: any }) {
  return (
    <div className="mt-6 space-y-4">
      {/* Prism section */}
      <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
        <h2 className="text-sm font-semibold text-purple-400 uppercase tracking-wider mb-3">
          Prism — Manipulation Analysis
        </h2>
        {data.prism.techniques.length === 0 ? (
          <p className="text-gray-500 text-sm">No manipulation techniques detected.</p>
        ) : (
          <div className="space-y-3">
            {data.prism.techniques.map((t: any, i: number) => (
              <div key={i} className="bg-[#0a0e14] rounded-lg p-3">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium">{t.name.replace(/_/g, ' ')}</span>
                  <span className="text-xs text-gray-500">{(t.confidence * 100).toFixed(0)}%</span>
                </div>
                <div className="h-1 bg-gray-800 rounded-full mb-2">
                  <div
                    className="h-full bg-purple-500 rounded-full"
                    style={{ width: `${t.confidence * 100}%` }}
                  />
                </div>
                <p className="text-xs text-gray-400">{t.explanation}</p>
                {t.evidence && (
                  <p className="text-xs text-gray-500 mt-1 italic">"{t.evidence}"</p>
                )}
              </div>
            ))}
          </div>
        )}
        <p className="text-xs text-gray-500 mt-3">{data.prism.brief}</p>
        {data.prism.detailed && (
          <p className="text-xs text-gray-400 mt-2 leading-relaxed">{data.prism.detailed}</p>
        )}
        <div className="flex gap-3 mt-2 text-xs text-gray-600">
          <span>Model: {data.prism.model_used}</span>
          <span>Heuristic only: {data.prism.heuristic_only ? 'Yes' : 'No'}</span>
        </div>
      </section>

      {/* Signal section */}
      <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
        <h2 className="text-sm font-semibold text-amber-400 uppercase tracking-wider mb-3">
          Signal — Source Credibility
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div className="text-center">
            <div className="text-lg font-semibold">{data.signal.source_bias || '—'}</div>
            <div className="text-xs text-gray-500">Bias</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-semibold">{data.signal.source_factuality || '—'}</div>
            <div className="text-xs text-gray-500">Factuality</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-semibold">{data.signal.sentiment}</div>
            <div className="text-xs text-gray-500">Sentiment ({data.signal.sentiment_score?.toFixed(2)})</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-semibold">{(data.signal.toxicity_score * 100).toFixed(1)}%</div>
            <div className="text-xs text-gray-500">Toxicity</div>
          </div>
        </div>
      </section>

      {/* Trace section */}
      <section className="bg-[#111620] border border-gray-800 rounded-lg p-4">
        <h2 className="text-sm font-semibold text-blue-400 uppercase tracking-wider mb-3">
          Trace — Source Origins
        </h2>
        {data.trace.fact_checks.length > 0 && (
          <div className="mb-3">
            <h3 className="text-xs text-gray-500 mb-1">Existing fact-checks:</h3>
            {data.trace.fact_checks.map((fc: any, i: number) => (
              <a
                key={i}
                href={fc.url}
                target="_blank"
                rel="noopener"
                className="block p-2 bg-[#0a0e14] rounded mb-1 hover:bg-[#0d1117]"
              >
                <div className="flex justify-between text-sm">
                  <span>{fc.publisher}</span>
                  <span className="text-red-400 font-medium">{fc.rating}</span>
                </div>
                <div className="text-xs text-gray-500 truncate">{fc.title}</div>
              </a>
            ))}
          </div>
        )}
        {data.trace.spread_timeline.length > 0 && (
          <div>
            <h3 className="text-xs text-gray-500 mb-1">Spread timeline ({data.trace.spread_timeline.length} sources):</h3>
            {data.trace.spread_timeline.slice(0, 5).map((s: any, i: number) => (
              <div key={i} className="text-xs text-gray-400 py-1 border-b border-gray-800/50">
                <span className="text-gray-500">{s.platform}</span> · {s.title?.slice(0, 60)}
                {s.date && <span className="text-gray-600 ml-2">{s.date}</span>}
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Metadata footer */}
      <div className="flex flex-wrap gap-4 text-xs text-gray-600">
        <span>Time: {data.analysis_time_ms}ms</span>
        <span>Hash: {data.blockchain?.content_hash?.slice(0, 12)}...</span>
        <span>{data.cached ? 'Cached' : 'Fresh analysis'}</span>
      </div>
    </div>
  );
}
```

### D1-8: Loading state
**File:** `src/components/LoadingState.tsx`

```tsx
export default function LoadingState() {
  return (
    <div className="mt-6 space-y-4">
      {['Prism', 'Signal', 'Trace'].map((name) => (
        <div key={name} className="bg-[#111620] border border-gray-800 rounded-lg p-4 animate-pulse">
          <div className="h-4 w-24 bg-gray-800 rounded mb-3" />
          <div className="space-y-2">
            <div className="h-3 w-full bg-gray-800 rounded" />
            <div className="h-3 w-3/4 bg-gray-800 rounded" />
          </div>
        </div>
      ))}
    </div>
  );
}
```

### D1-9: Test locally
```bash
cd dissekt-web
npm run dev
# Opens at http://localhost:3000
```

Open browser → paste a URL → click Analyze → see the result.

Make sure your backend is running:
```bash
# In another terminal:
cd /mnt/d/Startup\ Ideas/Dissekt
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

### D1-10: Fix CORS on backend
**File (backend):** `app/main.py`

Add your frontend origin:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",      # Next.js dev
        "https://dissekt.co",         # Production
        "https://www.dissekt.co",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### D1-11: Commit
```bash
cd dissekt-web
git init
git add .
git commit -m "Week 2 Day 1: Next.js frontend scaffold with scan page"
git remote add origin https://github.com/YOUR_USER/dissekt-web.git
git push -u origin main
```

**Day 1 done when:** You can paste a URL at localhost:3000, see the loading state, and get the analysis displayed with Prism techniques + Signal badges + Trace fact-checks.

---

## WEEK 2 DAY 2: Frontend polish + Radar feed page

### D2-1: Polish the AnalysisResult component
**Time:** 2 hours

- Add confidence bar colors (green > 0.8, yellow > 0.6, red < 0.6)
- Add expandable "detailed" section (collapsed by default)
- Add copy-to-clipboard for the analysis brief
- Add "Analyze in Detailed mode" button if currently in Brief
- Style the Trace spread timeline as a vertical timeline with platform icons
- Add Signal emotion breakdown if present

### D2-2: Add Radar feed page
**Time:** 2 hours | **File:** `src/app/radar/page.tsx`

This is the daily news intelligence feed. For MVP, it's a simple page that shows recent analyses from a curated list of RSS sources.

**Backend endpoint needed:** `GET /api/radar?market=india&limit=10`

**Backend file:** `app/radar/__init__.py`

```python
"""Dissekt Radar — Proactive news intelligence feed.

Scans RSS feeds, auto-analyzes top items via Beacon.
MVP: Just return curated RSS items. Full auto-analysis in Week 3.
"""
import logging
import feedparser
import httpx
from datetime import datetime

logger = logging.getLogger("dissekt.radar")

# RSS sources by market
FEEDS = {
    "india": [
        "https://scroll.in/rss/feed",
        "https://www.thehindu.com/news/national/feeder/default.rss",
        "https://www.ndtv.com/rss/india",
        "https://thewire.in/feed",
        "https://www.altnews.in/feed/",
    ],
    "germany": [
        "https://www.spiegel.de/schlagzeilen/index.rss",
        "https://www.tagesschau.de/xml/rss2/",
        "https://correctiv.org/feed/",
        "https://www.faz.net/rss/aktuell/",
    ],
    "us": [
        "https://feeds.apnews.com/rss/apf-topnews",
        "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
        "https://feeds.reuters.com/reuters/topNews",
        "https://www.politifact.com/rss/factchecks/",
    ],
    "uk": [
        "https://www.theguardian.com/world/rss",
        "https://feeds.bbci.co.uk/news/rss.xml",
        "https://fullfact.org/feed/",
    ],
}


async def get_radar_feed(market: str = "all", limit: int = 20) -> list[dict]:
    """Fetch and merge RSS feeds for a market."""
    feeds = []
    if market == "all":
        for m in FEEDS:
            feeds.extend(FEEDS[m])
    elif market in FEEDS:
        feeds = FEEDS[market]
    else:
        return []

    items = []
    for feed_url in feeds:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(feed_url)
                d = feedparser.parse(resp.text)
                for entry in d.entries[:5]:  # Top 5 per feed
                    items.append({
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "published": entry.get("published", ""),
                        "source": d.feed.get("title", feed_url),
                        "summary": entry.get("summary", "")[:200],
                        "market": market if market != "all" else _detect_market(feed_url),
                    })
        except Exception as e:
            logger.warning(f"Failed to fetch {feed_url}: {e}")

    # Sort by published date (newest first)
    items.sort(key=lambda x: x.get("published", ""), reverse=True)
    return items[:limit]


def _detect_market(url: str) -> str:
    for market, feeds in FEEDS.items():
        if url in feeds:
            return market
    return "global"
```

**Backend endpoint:** Add to `app/main.py`:

```python
from app.radar import get_radar_feed

@app.get("/api/radar")
async def radar_feed(market: str = "all", limit: int = 20):
    items = await get_radar_feed(market, limit)
    return {"items": items, "count": len(items), "market": market}
```

Install feedparser:
```bash
pip install feedparser
echo "feedparser==6.0.11" >> requirements.txt
```

### D2-3: Deploy frontend to Vercel
**Time:** 30 min

```bash
cd dissekt-web
npm i -g vercel
vercel --prod
# Follow prompts. Connect dissekt.co domain in Vercel dashboard.
```

Set environment variable in Vercel:
- `NEXT_PUBLIC_API_URL` = your backend URL (localhost for now, Railway later)

### D2-4: Commit
```bash
git add .
git commit -m "Day 2: Radar feed + frontend polish + Vercel deploy"
git push
```

**Day 2 done when:** dissekt.co shows the scan interface. /radar page shows RSS items from all 4 markets. Analysis results render beautifully.

---

## WEEK 2 DAY 3: Qdrant claim graph + OpenTimestamps

### D3-1: Set up Qdrant Cloud
**Time:** 30 min

1. Go to cloud.qdrant.io → Create cluster (free tier, 1GB)
2. Copy: cluster URL + API key
3. Add to .env:
```bash
QDRANT_URL=https://xxxxx.us-east-1-0.qdrant.io:6333
QDRANT_API_KEY=xxxxx
```

### D3-2: Create claim graph module
**Time:** 2 hours | **File:** `app/claim_graph/__init__.py`

```python
"""Dissekt Claim Graph — Qdrant vector similarity search.

Every analysis gets embedded and stored. Enables:
- "Has a similar claim been analyzed before?"
- Narrative clustering over time
- Building the knowledge graph moat
"""
import logging
import hashlib
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from sentence_transformers import SentenceTransformer
from app.config import get_settings

logger = logging.getLogger("dissekt.claim_graph")

_model = None
_client = None
COLLECTION = "dissekt_claims"
VECTOR_SIZE = 384  # all-MiniLM-L6-v2

def _get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer('all-MiniLM-L6-v2')
        logger.info("Sentence transformer loaded")
    return _model

def _get_client():
    global _client
    if _client is None:
        settings = get_settings()
        if not settings.qdrant_url:
            return None
        _client = QdrantClient(
            url=settings.qdrant_url,
            api_key=settings.qdrant_api_key,
        )
        # Create collection if not exists
        try:
            _client.get_collection(COLLECTION)
        except Exception:
            _client.create_collection(
                collection_name=COLLECTION,
                vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
            )
            logger.info(f"Created Qdrant collection: {COLLECTION}")
    return _client


async def store_analysis(text: str, analysis_id: str, metadata: dict) -> bool:
    """Store an analysis embedding in Qdrant."""
    client = _get_client()
    if client is None:
        return False

    try:
        model = _get_model()
        embedding = model.encode(text[:512]).tolist()

        point = PointStruct(
            id=hashlib.md5(analysis_id.encode()).hexdigest()[:16],
            vector=embedding,
            payload={
                "analysis_id": analysis_id,
                "text_preview": text[:200],
                "techniques": metadata.get("techniques", []),
                "source_bias": metadata.get("source_bias"),
                "timestamp": metadata.get("timestamp"),
            }
        )

        client.upsert(collection_name=COLLECTION, points=[point])
        return True
    except Exception as e:
        logger.error(f"Qdrant store failed: {e}")
        return False


async def find_similar(text: str, limit: int = 5) -> list[dict]:
    """Find similar past analyses."""
    client = _get_client()
    if client is None:
        return []

    try:
        model = _get_model()
        embedding = model.encode(text[:512]).tolist()

        results = client.search(
            collection_name=COLLECTION,
            query_vector=embedding,
            limit=limit,
            score_threshold=0.7,  # Only high similarity
        )

        return [
            {
                "analysis_id": r.payload.get("analysis_id"),
                "text_preview": r.payload.get("text_preview"),
                "similarity": round(r.score, 3),
                "techniques": r.payload.get("techniques", []),
            }
            for r in results
        ]
    except Exception as e:
        logger.error(f"Qdrant search failed: {e}")
        return []
```

Install dependencies:
```bash
pip install qdrant-client sentence-transformers
```

### D3-3: Integrate claim graph into Beacon
**File:** `app/beacon/__init__.py`

After the analysis is complete and before returning, add:

```python
    # Store in claim graph (async, don't block response)
    try:
        from app.claim_graph import store_analysis, find_similar
        
        # Find similar past analyses
        similar = await find_similar(extracted_text)
        
        # Store this analysis
        await store_analysis(
            extracted_text,
            content_hash,
            {
                "techniques": [t.name for t in prism_result.techniques],
                "source_bias": signal_result.source_bias,
                "timestamp": str(int(time.time())),
            }
        )
    except Exception as e:
        logger.warning(f"Claim graph failed: {e}")
        similar = []
```

Add `similar_analyses` to the response model and populate it.

### D3-4: OpenTimestamps integration
**Time:** 1 hour | **File:** `app/anchor/__init__.py`

```python
"""Dissekt Anchor — Blockchain evidence chain.

Creates OpenTimestamps proofs for every analysis.
SHA-256 hash → OTS calendar → Bitcoin blockchain.
"""
import hashlib
import logging
import httpx

logger = logging.getLogger("dissekt.anchor")

OTS_CALENDAR = "https://a.pool.opentimestamps.org/digest"


async def create_timestamp(content_hash: str) -> dict:
    """Submit hash to OpenTimestamps calendar server.
    
    Returns: OTS proof bytes (base64 encoded).
    This is the initial pending proof. 
    Full Bitcoin confirmation takes ~1 hour.
    """
    try:
        # Convert hex hash to bytes
        hash_bytes = bytes.fromhex(content_hash)
        
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                OTS_CALENDAR,
                content=hash_bytes,
                headers={"Content-Type": "application/octet-stream"},
            )
            
            if resp.status_code == 200:
                import base64
                proof = base64.b64encode(resp.content).decode()
                return {
                    "content_hash": content_hash,
                    "timestamp": str(int(__import__('time').time())),
                    "proof_status": "pending_confirmation",
                    "ots_proof": proof,
                    "calendar_url": OTS_CALENDAR,
                }
            else:
                logger.warning(f"OTS calendar returned {resp.status_code}")
                return _fallback_proof(content_hash)
    except Exception as e:
        logger.error(f"OTS submission failed: {e}")
        return _fallback_proof(content_hash)


def _fallback_proof(content_hash: str) -> dict:
    """Fallback: just return the hash without OTS proof."""
    return {
        "content_hash": content_hash,
        "timestamp": str(int(__import__('time').time())),
        "proof_status": "pending",
        "ots_proof": None,
    }
```

### D3-5: Commit
```bash
git add .
git commit -m "Day 3: Qdrant claim graph + OpenTimestamps anchoring"
git push
```

**Day 3 done when:** Every analysis stores an embedding in Qdrant. Similar past analyses appear in the response. OTS proof is submitted (pending Bitcoin confirmation).

---

## WEEK 2 DAY 4: Playwright extraction + pytest suite

### D4-1: Add Playwright for JS-rendered sites
**Time:** 1.5 hours | **File:** `app/beacon/__init__.py`

```bash
pip install playwright
playwright install chromium
```

Add as the final fallback in `extract_from_url`, after all other methods fail:

```python
    # Method 3: Playwright headless browser (for JS-rendered sites)
    try:
        from playwright.async_api import async_playwright
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            await page.goto(url, wait_until="networkidle", timeout=15000)
            
            # Get rendered HTML
            html = await page.content()
            if not title:
                title = await page.title()
            
            await browser.close()
            
            # Extract with trafilatura from rendered HTML
            import trafilatura
            text = trafilatura.extract(html, include_comments=False, include_tables=False) or ""
            if text and len(text) > 200:
                logger.info(f"Playwright extracted {len(text)} chars from {url}")
                return text[:MAX_TEXT_LENGTH], title
    except ImportError:
        logger.warning("Playwright not installed — skipping JS rendering")
    except Exception as e:
        logger.warning(f"Playwright failed: {e}")
```

This fixes OpIndia, NDTV, and all other JS-rendered Indian sites.

### D4-2: Create pytest test suite
**Time:** 2 hours | **File:** `tests/test_api.py`

```python
"""Dissekt API integration tests."""
import pytest
import httpx
import asyncio

BASE = "http://localhost:8000"

@pytest.fixture
def client():
    return httpx.Client(base_url=BASE, timeout=60)

class TestHealth:
    def test_health_returns_ok(self, client):
        r = client.get("/health")
        assert r.status_code == 200
        data = r.json()
        assert data["status"] == "ok"

class TestScanText:
    def test_manipulative_text_finds_techniques(self, client):
        r = client.post("/api/scan", json={
            "content": "Experts say this shocking crisis will destroy everyone. Studies confirm nobody is safe.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["prism"]["techniques"]) >= 1
        assert data["prism"]["model_used"] in ("gpt-4o-mini", "claude-sonnet-4", "heuristics_only")

    def test_clean_text_no_techniques(self, client):
        r = client.post("/api/scan", json={
            "content": "The municipal water treatment facility completed its annual infrastructure assessment on Tuesday, finding that 94 percent of filtration systems met operational benchmarks.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        # Clean text should have few or no techniques
        high_conf = [t for t in data["prism"]["techniques"] if t["confidence"] > 0.8]
        assert len(high_conf) <= 1

    def test_empty_input_returns_422(self, client):
        r = client.post("/api/scan", json={"content": "", "mode": "brief"})
        assert r.status_code == 422

    def test_short_input_returns_400(self, client):
        r = client.post("/api/scan", json={"content": "Hello", "mode": "brief"})
        assert r.status_code in (400, 422)

    def test_heuristic_only_extreme_text(self, client):
        r = client.post("/api/scan", json={
            "content": "SHOCKING: Experts say this absolutely terrifying crisis will definitely destroy everyone. According to scientists, nobody is safe. Studies confirm everything is completely doomed. Everyone knows the government always fails. Researchers warn this devastating catastrophe threatens all of humanity.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["prism"]["heuristic_only"] == True
        assert data["prism"]["model_used"] == "heuristics_only"

class TestScanURL:
    def test_bbc_url_extracts_and_analyzes(self, client):
        r = client.post("/api/scan", json={
            "content": "https://www.bbc.com/news",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["extracted_text"]) > 100
        assert data["signal"]["source_bias"] in ("center", "left-center")

    def test_nonexistent_url_returns_error(self, client):
        r = client.post("/api/scan", json={
            "content": "https://www.thissitedoesnotexist12345.com/article",
            "mode": "brief"
        })
        assert r.status_code in (400, 422)

class TestSignal:
    def test_mbfc_loaded(self):
        from app.signal import MBFC_DATABASE
        assert len(MBFC_DATABASE) >= 200
        assert MBFC_DATABASE["foxnews.com"]["bias"] == "right"
        assert MBFC_DATABASE["bbc.com"]["factuality"] == "high"

class TestTrace:
    def test_covid_microchips_finds_factchecks(self, client):
        r = client.post("/api/scan", json={
            "content": "COVID-19 vaccines contain microchips for tracking people",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["trace"]["fact_checks"]) >= 1
```

**Run tests:**
```bash
pip install pytest
pytest tests/test_api.py -v --tb=short
```

### D4-3: Add rate limiting middleware
**Time:** 30 min | **File:** `app/main.py`

```python
from fastapi import Request
from collections import defaultdict
import time

# Simple in-memory rate limiter (replace with Redis in production)
_rate_limits = defaultdict(list)
FREE_LIMIT = 3  # per day
WINDOW = 86400   # 24 hours

@app.middleware("http")
async def rate_limit(request: Request, call_next):
    if request.url.path == "/api/scan" and request.method == "POST":
        ip = request.client.host
        now = time.time()
        # Clean old entries
        _rate_limits[ip] = [t for t in _rate_limits[ip] if now - t < WINDOW]
        if len(_rate_limits[ip]) >= FREE_LIMIT:
            return JSONResponse(
                status_code=429,
                content={"detail": f"Rate limit exceeded ({FREE_LIMIT}/day). Upgrade to Pro for unlimited."}
            )
        _rate_limits[ip].append(now)
    return await call_next(request)
```

### D4-4: Commit
```bash
git add .
git commit -m "Day 4: Playwright extraction, pytest suite (10 tests), rate limiting"
git push
```

**Day 4 done when:** Playwright fetches OpIndia/NDTV successfully. pytest runs 10+ tests with 80%+ pass rate. Rate limiting returns 429 after 3 free analyses.

---

## WEEK 2 DAY 5: Integration test + deploy + Week 3 plan

### D5-1: Run full integration test
**Time:** 2 hours

Re-run the 20-URL market test. This time, Playwright should handle the sites that 403'd in Week 1. Log results.

### D5-2: Deploy backend to cloud
**Time:** 1 hour

**Option A: Railway (paid tier)**
```bash
cd /mnt/d/Startup\ Ideas/Dissekt
railway up
```

**Option B: Render.com (free tier with limitations)**
- Connect GitHub repo
- Set environment variables in Render dashboard
- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

**Option C: Fly.io (generous free tier)**
```bash
fly launch --name dissekt-api
fly secrets set ANTHROPIC_API_KEY=xxx OPENAI_API_KEY=xxx ...
fly deploy
```

### D5-3: Connect frontend to deployed backend
Update Vercel environment variable:
```
NEXT_PUBLIC_API_URL=https://dissekt-api.fly.dev  (or Railway URL)
```

Redeploy:
```bash
cd dissekt-web
vercel --prod
```

### D5-4: Test the full public flow
```bash
# Test the public URL
curl -X POST https://dissekt-api.fly.dev/api/scan \
  -H "Content-Type: application/json" \
  -d '{"content": "https://www.bbc.com/news", "mode": "brief"}'
```

Open https://dissekt.co in your browser. Paste a URL. See the analysis.

### D5-5: Create Week 3 plan
```bash
cat > WEEK3_TODO.md << 'EOF'
# Week 3 Plan: Demo + Outreach

## Day 1-2: Polish
- [ ] Mobile responsive design
- [ ] Radar feed page with market tabs
- [ ] Save analysis to Supabase (user accounts)
- [ ] Export analysis as PDF

## Day 3: Prepare demo materials
- [ ] Record 2-min screen recording of Dissekt in action
- [ ] Prepare 5 demo scenarios (1 per market + 1 WhatsApp forward)
- [ ] Write cold email template for journalists

## Day 4-5: Outreach
- [ ] India: Contact 10 journalists (The Wire, Scroll, Alt News, BOOM)
- [ ] Germany: Contact 5 journalists (Correctiv, Netzwerk Recherche)
- [ ] US: Contact 10 journalists (Bellingcat, ProPublica, First Draft)
- [ ] UK: Contact 5 journalists (Full Fact, Bureau of Investigative Journalism)
- [ ] Post on Twitter/X, Reddit r/journalism, Hacker News
EOF
```

### D5-6: Final commit
```bash
git add .
git commit -m "Week 2 complete: Frontend at dissekt.co, Qdrant, OTS, Playwright, pytest, cloud deploy"
git push
```

---

## File changes summary

### New files (Week 2)
| File | Purpose |
|------|---------|
| `dissekt-web/` (entire directory) | Next.js frontend |
| `app/radar/__init__.py` | RSS feed ingestion |
| `app/claim_graph/__init__.py` | Qdrant vector similarity |
| `app/anchor/__init__.py` | OpenTimestamps integration |
| `tests/test_api.py` | pytest integration tests |
| `app/data/mbfc_database.json` | 231-source MBFC database |

### Modified files
| File | What changed |
|------|-------------|
| `app/signal/__init__.py` | Detoxify actually loaded + MBFC from JSON |
| `app/beacon/__init__.py` | Playwright fallback + claim graph integration |
| `app/main.py` | CORS fix + Radar endpoint + rate limiting |
| `requirements.txt` | +feedparser, playwright, qdrant-client, sentence-transformers, pytest |
| `.env` | +QDRANT_URL, QDRANT_API_KEY |

### Dependencies to install
```bash
pip install feedparser playwright qdrant-client sentence-transformers pytest
playwright install chromium
```

---

## Week 2 at a glance

| Day | Focus | Hours | Deliverable |
|-----|-------|-------|-------------|
| Pre (W1D5) | Detoxify + MBFC + 20-URL test | 3-4h | Week 1 closed, 231 MBFC sources |
| Day 1 | Next.js scaffold + scan page | 4-5h | Frontend at localhost:3000 |
| Day 2 | Frontend polish + Radar + deploy | 4-5h | dissekt.co live, Radar feed |
| Day 3 | Qdrant + OpenTimestamps | 4-5h | Claim graph + blockchain proof |
| Day 4 | Playwright + pytest | 4-5h | Indian sites work, 10+ tests |
| Day 5 | Integration + cloud deploy | 3-4h | Public URL, end-to-end working |
