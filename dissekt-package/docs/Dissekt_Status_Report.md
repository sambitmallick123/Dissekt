# DISSEKT — Project Status Report
**Date:** June 1, 2026 | **Position:** ~Week 2 Day 2 of 3-week MVP plan

---

## WHAT'S DONE (✅)

### Week 1: Backend — COMPLETE
| Task | Status | Evidence |
|------|--------|----------|
| FastAPI backend running | ✅ | `uvicorn app.main:app` on port 8000 |
| Prism: 9 heuristics + LLM analysis | ✅ | Detects loaded language, appeal to authority, cherry-picking, etc. |
| Prism: GPT-4o mini routing (Brief) | ✅ | `model_used: gpt-4o-mini`, ~3-5s |
| Prism: Claude Sonnet 4 (Detailed) | ✅ | Deep multi-technique analysis, ~12-18s |
| Prism: Heuristic-only mode | ✅ | 1 second, €0 cost, triggers on extreme content |
| Trace: Google Fact Check API | ✅ | 10 fact-checks found for COVID microchips |
| Trace: SerpAPI web search | ✅ | Spread timeline with platform detection |
| Signal: Detoxify toxicity (in API) | ✅ | toxicity=0.993 for toxic text, all 6 labels |
| Signal: MBFC 231 sources | ✅ | JSON database loaded, covers 4 markets |
| Signal: VADER sentiment | ✅ | Working correctly |
| Beacon: trafilatura extraction | ✅ | Multi-method fallback chain |
| Beacon: Parallel execution | ✅ | asyncio.gather, 2x speed improvement |
| Cache: Redis deduplication | ✅ | Upstash EU Frankfurt |
| Anchor: SHA-256 content hash | ✅ | Hash computed for every analysis |
| Edge cases: proper error handling | ✅ | Empty, short, bad URL, paywalled — no 500s |
| All API keys configured | ✅ | Anthropic, OpenAI, Google, SerpAPI, Supabase, Redis, Qdrant |
| Git: 5 commits pushed | ✅ | Latest: "feat: add global styles, layout, and main page components" |

### Week 2 Day 1: Frontend — COMPLETE
| Task | Status | Evidence |
|------|--------|----------|
| Next.js project created | ✅ | `dissekt-web/` inside Dissekt directory |
| Concept B dashboard UI | ✅ | Threat score ring, 2×2 panel grid, inline styles |
| ScanInput component | ✅ | Search bar + mode toggle + scan button |
| ThreatScore component | ✅ | Animated ring, 6-metric strip, normalized scoring |
| PrismCard component | ✅ | Color-coded confidence bars, category badges, collapsible detail |
| TraceCard component | ✅ | Expandable fact-checks + spread timeline with platform dots |
| SignalCard component | ✅ | Bias dots, factuality colors, toxicity breakdown |
| MetaCard component | ✅ | Time, model, cache, heuristic, hash, proof status |
| LoadingState component | ✅ | Shimmer skeletons matching panel layout |
| API proxy route | ✅ | `/api/scan` proxies to backend (avoids CORS) |
| Frontend ↔ Backend connection | ✅ | Working on localhost:3000 → localhost:8000 |
| Playwright installed | ✅ | Not yet integrated into Beacon |

---

## WHAT'S NOT DONE (remaining tasks)

### Week 1 Loose Ends (1-2 hours)
| Task | Priority | Time | How |
|------|----------|------|-----|
| **PT-3: 20-URL market test** | Medium | 2h | Run 5 URLs per market (India/Germany/US/UK), log results |
| **PT-4: WEEK1_SUMMARY.md** | Low | 15m | Write summary doc with test results |
| **PT-5: Git commit Week 1** | Medium | 5m | `git add . && git commit -m "Week 1 complete"` |
| **CORS restrict** | Low | 5m | Change `allow_origins=["*"]` to `["localhost:3000", "dissekt.co"]` in `app/main.py` |

### Week 2 Day 2: Radar + Deploy (4-5 hours)
| Task | Priority | Time | How |
|------|----------|------|-----|
| **Radar RSS backend** | High | 2h | Create `app/radar/__init__.py` with 16 RSS feeds across 4 markets. Add `GET /api/radar` endpoint. Install `feedparser`. See Week 2 Action Plan for complete code. |
| **Radar frontend page** | Medium | 1h | Create `src/app/radar/page.tsx` — market tabs + RSS item cards |
| **Frontend polish** | Medium | 1h | Mobile responsive, copy-to-clipboard, "Analyze in Detailed" button |
| **Vercel deploy** | High | 30m | `npm i -g vercel && vercel --prod` from `dissekt-web/`. Connect dissekt.co domain. Set `NEXT_PUBLIC_API_URL` env var. |

**Steps for Day 2:**
```bash
# 1. Install feedparser on backend
cd /mnt/d/Startup\ Ideas/Dissekt
source venv/bin/activate
pip install feedparser

# 2. Create app/radar/__init__.py (code in Week 2 Action Plan)
# 3. Add /api/radar endpoint to app/main.py
# 4. Test: curl http://localhost:8000/api/radar?market=india

# 5. Create Radar page in frontend
cd dissekt-web
# Create src/app/radar/page.tsx

# 6. Deploy frontend to Vercel
npm i -g vercel
vercel --prod
# Connect dissekt.co domain in Vercel dashboard
# Set env: NEXT_PUBLIC_API_URL=http://localhost:8000 (change to cloud URL later)
```

### Week 2 Day 3: Qdrant + OpenTimestamps (4-5 hours)
| Task | Priority | Time | How |
|------|----------|------|-----|
| **Qdrant claim graph** | High | 2h | Create `app/claim_graph/__init__.py`. Store embeddings with `sentence-transformers`. `store_analysis()` + `find_similar()`. See Week 2 Action Plan for code. |
| **Integrate into Beacon** | High | 30m | After analysis completes, call `store_analysis()` and `find_similar()`. Add `similar_analyses` to response. |
| **OpenTimestamps** | Medium | 1h | Create `app/anchor/__init__.py`. Submit SHA-256 hash to OTS calendar. Replace hardcoded "pending" with actual submission. |

**Steps for Day 3:**
```bash
# 1. Install dependencies
pip install sentence-transformers --break-system-packages

# 2. Qdrant is already configured (cloud.qdrant.io key in .env)
# 3. Create app/claim_graph/__init__.py (code in Week 2 Action Plan)
# 4. Add store/find calls to app/beacon/__init__.py after analysis
# 5. Create app/anchor/__init__.py for OTS submission
# 6. Test: analyze something twice, check if "similar_analyses" appears
```

### Week 2 Day 4: Playwright + pytest (4-5 hours)
| Task | Priority | Time | How |
|------|----------|------|-----|
| **Playwright in Beacon** | High | 1.5h | Add as Method 3 fallback in `extract_from_url()` after trafilatura and httpx fail. Fixes Reuters, OpIndia, NDTV. `playwright install chromium` already done. |
| **pytest suite** | High | 2h | Create `tests/test_api.py` with 10+ tests: health, manipulative text, clean text, edge cases, heuristic-only, URL extraction, MBFC loading, fact-check search. |
| **Rate limiting** | Medium | 30m | Add middleware to `app/main.py`. In-memory for now (3/day per IP). |

**Steps for Day 4:**
```bash
# 1. Add Playwright fallback to app/beacon/__init__.py (code in Week 2 Action Plan)
# 2. Test: curl with Reuters URL that was 401-blocked
# 3. Create tests/test_api.py (code in Week 2 Action Plan)
# 4. Run: pytest tests/test_api.py -v --tb=short
# 5. Add rate limit middleware to app/main.py
```

### Week 2 Day 5: Cloud deploy + Integration (3-4 hours)
| Task | Priority | Time | How |
|------|----------|------|-----|
| **Deploy backend to cloud** | Critical | 1h | Fly.io / Railway / Render. Dockerfile already exists. |
| **Connect frontend to cloud** | Critical | 30m | Update `NEXT_PUBLIC_API_URL` in Vercel to cloud backend URL. Redeploy. |
| **End-to-end test** | High | 1h | Test dissekt.co → cloud backend → full analysis |
| **Week 3 plan** | Medium | 30m | Create WEEK3_TODO.md for outreach + polish |

**Steps for Day 5:**
```bash
# Option A: Fly.io (recommended)
fly launch --name dissekt-api
fly secrets set ANTHROPIC_API_KEY=xxx OPENAI_API_KEY=xxx ...
fly deploy

# Option B: Railway
railway up

# Then update Vercel:
# NEXT_PUBLIC_API_URL=https://dissekt-api.fly.dev
# Redeploy: vercel --prod

# Test public URL:
curl -X POST https://dissekt-api.fly.dev/api/scan \
  -H "Content-Type: application/json" \
  -d '{"content": "COVID-19 vaccines contain microchips", "mode": "brief"}'
```

---

## KNOWN TECHNICAL DEBT

| # | Issue | Severity | Target |
|---|-------|----------|--------|
| TD1 | CORS still `allow_origins=["*"]` | Low | Day 2 (restrict to dissekt.co) |
| TD2 | No rate limiting | Low | Day 4 |
| TD3 | ClaimBuster check_worthiness stubbed (always 0.0) | Low | Week 3 |
| TD4 | Blockchain proof_status always "pending" (no OTS) | Medium | Day 3 |
| TD5 | Qdrant not integrated (installed but not wired) | Medium | Day 3 |
| TD6 | No pytest suite | Medium | Day 4 |
| TD7 | Playwright not in Beacon (Reuters/OpIndia 401) | Medium | Day 4 |
| TD8 | No cloud deployment | Critical | Day 5 |
| TD9 | Compression heuristic inverted | Low | Week 3 |
| TD10 | Attention gradient returns 0.0 | Low | Week 3 |
| TD11 | Radar page not implemented | Medium | Day 2 |

---

## WHAT WORKS END-TO-END TODAY

A user at localhost:3000 can:
1. Paste text or a URL
2. Choose Brief or Detailed mode
3. Click Scan
4. See a threat score ring (0-100)
5. See manipulation techniques with confidence bars and category badges
6. See existing fact-checks with ratings (False/True/Misleading)
7. See a spread timeline with platform-colored dots
8. See source bias, factuality, sentiment, toxicity
9. See analysis metadata (time, model, cache, hash)
10. Expand/collapse fact-checks and timeline sources

What does NOT work yet: URL analysis for bot-protected sites (Reuters, OpIndia), no public URL (localhost only), no Radar page, no claim similarity.

---

## RECOMMENDED NEXT ACTION

**If you have 2 hours right now:** Do Day 2 — create the Radar backend + deploy frontend to Vercel. This gets dissekt.co live.

**If you have 30 minutes right now:** Commit everything and deploy frontend to Vercel. Even without Radar, having dissekt.co accessible is a milestone.

```bash
# Quick deploy (30 min)
cd /mnt/d/Startup\ Ideas/Dissekt
git add . && git commit -m "Week 2: Frontend complete, Concept B dashboard"
git push

cd dissekt-web
npm i -g vercel
vercel --prod
```
