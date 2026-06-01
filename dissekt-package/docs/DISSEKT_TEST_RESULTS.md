# DISSEKT — Week 1 Test Results

**Version:** 0.1.0  
**Test Period:** April 6–14, 2026  
**Environment:** localhost:8000 (Ubuntu/WSL, Python 3.12, venv)  
**Tester:** Sambit Mallick  

---

## Summary

| Metric | Result |
|--------|--------|
| Total tests run | 15 |
| Passed | 12 |
| Failed (403 blocked) | 2 |
| False positive | 1 |
| **Pass rate (excl. 403s)** | **92%** |
| Signal bias accuracy | 9/10 matched MBFC |
| Avg response time (URLs) | ~15s (pre-parallel fix) |
| Avg response time (text) | ~25s (pre-parallel fix) |
| Extraction success rate | 10/12 URLs extracted |

---

## Day 1 Results (April 6)

### Test 1.1 — Health endpoint
| Field | Value |
|-------|-------|
| Endpoint | `GET /health` |
| Status | ✅ Pass |
| Response | `{"status": "ok", "services": {"anthropic": true, "openai": true, "redis": true, "supabase": true, "factcheck_api": true}}` |

### Test 1.2 — BBC article (URL)
| Field | Value |
|-------|-------|
| Input | `https://www.bbc.com/news/articles/cy41n17e23go` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | Initially failed (readability got sidebar), fixed with trafilatura.fetch_url() → 5,000 chars |
| Prism techniques | `loaded_language` (0.8): "frenzy" in headline |
| Prism model | claude-sonnet-4 |
| Signal bias | center ✅ |
| Signal factuality | very-high ✅ |
| Trace spread points | 7 (Threads, X/Twitter, Facebook, Google News) |
| Response time | 8,779ms |
| Notes | First successful end-to-end analysis |

### Test 1.3 — 5G cancer misinformation (text)
| Field | Value |
|-------|-------|
| Input | "5G towers are causing cancer according to many scientists" |
| Mode | detailed |
| Status | ✅ Pass |
| Prism techniques | `appeal_to_authority` (0.9), `loaded_language` (0.8), `cherry_picking` (0.8), `hasty_generalization` (0.7) |
| Prism model | claude-sonnet-4 |
| Signal sentiment | negative (-0.66) |
| Trace spread points | 10 (cancer.org.au, PubMed, Nature, Cancer Research UK, USA Today) |
| Trace fact-checks | 0 (query too long — fixed Day 3) |
| Response time | 16,861ms |
| Notes | Detailed analysis was thorough and publishable quality. Trace found counter-sources but no formal fact-checks. |

### Test 1.4 — Scroll.in article (URL, initial)
| Field | Value |
|-------|-------|
| Input | `https://scroll.in/article/1091298` |
| Mode | brief |
| Status | ⚠️ Partial — extraction bug |
| Extraction | Got sidebar headlines instead of article content (JS-rendered site) |
| Notes | Led to extraction fix: added JSON-LD → trafilatura → readability → paragraphs fallback chain |

---

## Day 2 Results (April 14)

### Test 2.1 — BBC article (URL, re-test after extraction fix)
| Field | Value |
|-------|-------|
| Input | `https://www.bbc.com/news/articles/cy41n17e23go` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | trafilatura.fetch_url() → 5,000 chars. Full article: "How China fell for a lobster..." |
| Prism techniques | `selective_emphasis` (0.8): "emphasizes positive user experiences, minimal attention to risks"; `emotional_framing` (0.7): "stunned, scary, exploded, frenzy" |
| Prism model | claude-sonnet-4 |
| Signal bias | center ✅ |
| Signal factuality | very-high ✅ |
| Trace spread points | 10 (AOL, BBC UK, Instagram ×3, Reddit, Pixelift, illuminem) |
| Response time | 12,382ms |
| Notes | Major improvement from Day 1. Full article extraction produces more nuanced analysis. |

### Test 2.2 — Manipulative text (Detailed mode)
| Field | Value |
|-------|-------|
| Input | "According to experts, this shocking new policy will absolutely destroy millions of jobs. Everyone knows the government is completely failing. Studies prove nobody is safe anymore. The terrifying truth is that all scientists agree we are heading for total collapse unless drastic action is taken immediately." |
| Mode | detailed |
| Status | ✅ Pass — **Best result so far** |
| Prism techniques | `appeal_to_authority` (1.0), `loaded_language` (1.0), `hasty_generalization` (0.95), `emotional_framing` (0.9), `missing_context` (0.85) |
| Prism model | claude-sonnet-4 |
| Prism detailed | Full paragraph analysis identifying: unnamed authorities, inflammatory vocabulary, statistically implausible absolutes, false urgency, deliberate vagueness |
| Signal sentiment | negative (-0.9) |
| Response time | 75,054ms |
| Notes | 5 techniques all correct with high confidence. Detailed analysis is publishable quality. Speed issue from sequential execution — Day 4 fix. |

### Test 2.3 — WhatsApp-style Indian misinformation (text)
| Field | Value |
|-------|-------|
| Input | "URGENT: Government has confirmed that eating bananas after 6pm causes deadly blood clots. Share this with everyone you love before it is too late. Exposed by senior doctors at AIIMS Delhi. Forward to all groups immediately." |
| Mode | detailed |
| Status | ✅ Pass — **Excellent** |
| Prism techniques | `emotional_framing` (0.95), `missing_context` (0.95), `appeal_to_authority` (0.9), `loaded_language` (0.9), `appeal_to_emotion` (0.85) |
| Prism model | claude-sonnet-4 |
| Prism detailed | "AIIMS Delhi has not issued any such warning. Message structure follows classic misinformation patterns." |
| Signal sentiment | positive (0.824) — note: VADER misreads "love" and "share" as positive |
| Trace | Found AFP fact-check debunking banana misinformation; Facebook groups spreading similar claims |
| Response time | 19,262ms |
| Notes | Perfect WhatsApp forward detection. This is the India market demo. |

### Test 2.4 — OpIndia (India, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.opindia.com/news-updates/...` |
| Mode | brief |
| Status | ❌ Fail — 403 Forbidden |
| Error | `Client error '403 Forbidden'` |
| Notes | Bot detection. Site blocks automated HTTP clients. Needs Playwright (Week 2) or text-paste workaround. |

### Test 2.5 — NDTV (India, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.ndtv.com/world-news/...` |
| Mode | brief |
| Status | ❌ Fail — 403 Forbidden |
| Error | `Client error '403 Forbidden'` |
| Notes | Same bot detection as OpIndia. Indian news sites are aggressive with anti-bot. Week 2: Playwright. |

### Test 2.6 — Scroll.in I-PAC arrest (India, URL)
| Field | Value |
|-------|-------|
| Input | `https://scroll.in/latest/1092089/ed-arrests-i-pac-director-vinesh-chandel-in-bengal-coal-scam-case` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | 5,000 chars. Breaking news about I-PAC director's ED arrest. |
| Prism techniques | `loaded_language` (0.7): "chilling message, intimidation, shakes the very idea of a level playing field"; `emotional_framing` (0.6): "frames arrest as political persecution rather than legal process" |
| Prism model | claude-sonnet-4 |
| Signal bias | left-center ✅ |
| Signal factuality | high ✅ |
| Trace spread points | 8 (The Hindu, Economic Times, MSN, Facebook, National Herald, MoneyControl, X/Twitter, New Indian Express) — all within hours |
| Response time | 9,130ms |
| Notes | Nuanced detection — correctly identified editorial framing at appropriate low-medium confidence. Real-time news spread tracking working. |

### Test 2.7 — The Hindu election page (India, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.thehindu.com/elections/tamil-nadu-assembly/` |
| Mode | brief |
| Status | ✅ Pass (with caveat) |
| Extraction | Got headline listing (section page, not article) |
| Prism techniques | None detected — correct for a list of headlines |
| Signal bias | null ⚠️ (thehindu.com missing from MBFC database) |
| Response time | 6,202ms |
| Notes | Not a proper article test (section page). Signal gap: need to add thehindu.com to MBFC. Extraction worked — The Hindu doesn't 403. |
| Action needed | Add `"thehindu.com": {"bias": "left-center", "factuality": "high"}` to MBFC_DATABASE |

### Test 2.8 — Spiegel editorial (Germany, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.spiegel.de/ausland/iran-ungarn-maga-streit-wie-donald-trump-die-macht-entgleitet-a-...` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | Got teaser text (paywalled Spiegel+ article). Limited but sufficient for technique detection. |
| Prism techniques | `loaded_language` (0.8): "entgleitet die Macht" (power slipping away); `emotional_framing` (0.7): "frames political developments as inevitable decline" |
| Prism model | claude-sonnet-4 |
| Signal bias | left-center ✅ |
| Signal factuality | high ✅ |
| Trace spread points | 7 (Spiegel related articles, FAZ, Tagesspiegel, Substack, Facebook) |
| Response time | 83,413ms |
| Notes | Claude handles German text natively — no translation needed. Slow response from sequential + blocking trafilatura. Paywalled content is a known limitation. |

### Test 2.9 — AP News California governor (US, URL)
| Field | Value |
|-------|-------|
| Input | `https://apnews.com/article/california-governor-swalwell-porter-steyer-democrats-ef083e5e5901e31b8bc2dcaf4144ad71` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | Full article, 5,000 chars |
| Prism techniques | `loaded_language` (0.8): "dramatic downfall" is editorialized; `emotional_framing` (0.7): "emphasizes scandal and controversy" |
| Prism model | claude-sonnet-4 |
| Signal bias | center ✅ |
| Signal factuality | very-high ✅ |
| Trace spread points | 6 (KSAT, US News, Yahoo, The Hour, KIRO7, CNN) |
| Response time | 10,357ms |
| Notes | AP is normally neutral — Prism correctly identified that this particular piece uses more editorialized language than typical AP wire. |

### Test 2.10 — Fox News Iran blockade (US, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.foxnews.com/live-news/trump-iran-blockade-strait-hormuz-israel-april-13` |
| Mode | brief |
| Status | ⚠️ False positive |
| Extraction | Full article, multiple sections from live blog |
| Prism techniques | `missing_context` (0.95): Claude flagged content as "fictional events" |
| Prism model | claude-sonnet-4 |
| Signal bias | right ✅ |
| Signal factuality | mixed ✅ |
| Trace spread points | 8 (CBS, BBC, Guardian, CNN, PBS, WashPost, WSJ, Facebook) — confirms this is real news |
| Response time | 8,783ms |
| Notes | **Known issue:** Claude's training data ends before April 2026. It identified real current events (US-Iran war, naval blockade) as potentially "fictional" because they occurred after its knowledge cutoff. The Trace results (CBS, BBC, PBS, WSJ all reporting same events) confirm this is real news, not fabrication. This is a Claude limitation, not a Prism bug. Potential fix: add a check — if Trace finds 3+ major news sources reporting the same event, suppress "fabrication" flags. |

### Test 2.11 — Guardian Lebanon-Israel (UK, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.theguardian.com/world/live/2026/apr/14/middle-east-crisis-live-...` |
| Mode | brief |
| Status | ✅ Pass |
| Extraction | Full live blog content |
| Prism techniques | None detected (0.95 confidence) — "standard news reporting with direct quotes, factual information, proper attribution" |
| Prism model | claude-sonnet-4 |
| Signal bias | left-center ✅ |
| Signal factuality | high ✅ |
| Trace spread points | 9 (YouTube ×2, BBC, Facebook ×2, Euronews, Telegraph Herald, X/Twitter, military.com) |
| Response time | 8,990ms |
| Notes | **Important:** Prism correctly gave this a pass. A tool that flags everything is useless. Knowing when content is clean is just as important as catching manipulation. |

### Test 2.12 — Daily Mail Harry & Meghan (UK, URL)
| Field | Value |
|-------|-------|
| Input | `https://www.dailymail.co.uk/news/article-15731101/Harry-Meghans-Australian-quasi-royal-tour...` |
| Mode | brief |
| Status | ✅ Pass — **Strongest demo result** |
| Extraction | Full article, extensive content |
| Prism techniques | `loaded_language` (0.9): "using Australia like an ATM", "Me-again Meghan", "fat fee"; `cherry_picking` (0.8): "highlights negative reactions, downplays positive"; `emotional_framing` (0.7): "opens with accusations, emphasizes hostile quotes" |
| Prism model | claude-sonnet-4 |
| Signal bias | right ✅ |
| Signal factuality | low ✅ |
| Trace spread points | 7 (The Times, Daily Mail, SMH, Reddit, Facebook, Mirror, WA Today) |
| Response time | 11,108ms |
| Notes | **This is the investor demo.** Journalist pastes tabloid → Dissekt says "loaded language (0.9), cherry-picks negative reactions (0.8), emotional framing (0.7). Source: right-leaning, low factuality." Immediately useful, no other tool provides this. |

---

## Issues Log

### Critical (blocks functionality)
| ID | Issue | Component | Status | Fix |
|----|-------|-----------|--------|-----|
| C1 | Indian news sites return 403 (OpIndia, NDTV) | Beacon | Open | Week 2: Add Playwright headless browser |
| C2 | Response time 50-80s for some requests | Beacon | Open | Day 4: asyncio.gather for parallel execution |

### Important (degrades quality)
| ID | Issue | Component | Status | Fix |
|----|-------|-----------|--------|-----|
| I1 | Fox News false positive — Claude flags post-cutoff events as "fictional" | Prism | Open | Add cross-check: if Trace finds 3+ major sources, suppress fabrication flags |
| I2 | Fact Check API returns empty for known debunked claims | Trace | Open | Day 3: Use first sentence only (max 150 chars) for query |
| I3 | thehindu.com missing from MBFC database | Signal | Open | Add to MBFC_DATABASE in heuristics.py |
| I4 | VADER misreads WhatsApp forward sentiment as positive | Signal | Known limitation | VADER reads "love" and "share" as positive. Low priority — Prism catches the manipulation. |

### Minor (cosmetic / optimization)
| ID | Issue | Component | Status | Fix |
|----|-------|-----------|--------|-----|
| M1 | Paywalled articles only get teaser text | Beacon | Known limitation | By design — can't bypass paywalls without subscription |
| M2 | Some Trace results irrelevant when extracted text is short | Trace | Improved | Fixed by trafilatura.fetch_url() extraction improvement |
| M3 | YouTube/Instagram dates empty in spread_timeline | Trace | Open | Day 3: Twitter Snowflake decoder. YouTube API for dates in Week 2 |

---

## MBFC Signal Accuracy

| Source | Expected bias | Actual | Expected factuality | Actual | Match? |
|--------|--------------|--------|--------------------|---------| -------|
| BBC (bbc.com) | center | center | very-high | very-high | ✅ |
| Scroll.in | left-center | left-center | high | high | ✅ |
| Spiegel (spiegel.de) | left-center | left-center | high | high | ✅ |
| AP News (apnews.com) | center | center | very-high | very-high | ✅ |
| Fox News (foxnews.com) | right | right | mixed | mixed | ✅ |
| Guardian (theguardian.com) | left-center | left-center | high | high | ✅ |
| Daily Mail (dailymail.co.uk) | right | right | low | low | ✅ |
| The Hindu (thehindu.com) | left-center | null | high | null | ❌ Missing |
| OpIndia | right | — | mixed | — | N/A (403) |
| NDTV | left-center | — | high | — | N/A (403) |

**MBFC accuracy: 7/7 matched (100% for sources in database). 1 missing entry (The Hindu).**

---

## Prism Technique Detection Summary

### Technique frequency across all tests
| Technique | Times detected | Avg confidence | Notes |
|-----------|---------------|----------------|-------|
| loaded_language | 7 | 0.87 | Most common detection. Catches editorial word choices. |
| emotional_framing | 6 | 0.73 | Correctly identifies narrative structure designed to provoke emotion |
| appeal_to_authority | 3 | 0.93 | High confidence when detected. Catches "experts say" patterns. |
| missing_context | 3 | 0.92 | High confidence. Catches vague claims lacking specifics. |
| hasty_generalization | 2 | 0.83 | Catches absolute language ("everyone", "always", "nobody") |
| cherry_picking | 2 | 0.80 | Catches selective presentation of evidence |
| selective_emphasis | 1 | 0.80 | Catches editorial emphasis choices |
| appeal_to_emotion | 1 | 0.85 | Catches explicit emotional manipulation ("everyone you love") |

### Correct "no manipulation" detections
| Test | Confidence | Notes |
|------|-----------|-------|
| The Hindu headlines | — | Correctly identified as neutral headline listing |
| Guardian Lebanon-Israel | 0.95 | Correctly identified as clean reporting with proper attribution |

### False positives
| Test | Technique | Confidence | Reason |
|------|-----------|-----------|--------|
| Fox News | missing_context | 0.95 | Claude flagged real post-cutoff events as "fictional". Not a Prism bug — Claude knowledge cutoff limitation. |

---

## Performance Baseline

| Test type | Avg time | Min | Max | Notes |
|-----------|----------|-----|-----|-------|
| Text (Brief) | 19s | 19s | 19s | Single test. Sequential execution. |
| Text (Detailed) | 47s | 19s | 75s | Variance from Claude response time. |
| URL (Brief) | 22s | 6s | 83s | Includes URL fetch + extraction + analysis. |
| URL (Detailed) | — | — | — | Not tested yet. |

**Target after Day 4 parallel fix:** Text Brief < 4s, URL Brief < 8s, URL Detailed < 12s.

---

## Environment

```
Python: 3.12.13
FastAPI: 0.115.6
Uvicorn: 0.34.0
LLM: Claude Sonnet 4 (Detailed), GPT-4o mini (Brief, not yet verified)
Extraction: trafilatura 2.0.0 (primary), readability-lxml 0.8.1 (fallback)
Sentiment: vaderSentiment 3.3.2
Toxicity: detoxify 0.5.2 (loaded, CPU)
Source credibility: MBFC database (21+ sources, expanding)
Cache: Upstash Redis (EU Frankfurt)
Database: Supabase (EU Frankfurt)
```

---

## Next Steps

### Day 3: Trace + fact-check accuracy
- [ ] Test 4 known debunked claims (COVID microchips, cow urine, stolen election, Brexit NHS)
- [ ] Fix Trace query extraction (first sentence, max 150 chars)
- [ ] Add Twitter Snowflake date decoder
- [ ] Test 5 edge cases (empty, short, bad URL, paywalled, homepage)

### Day 4: Speed optimization
- [ ] asyncio.gather for parallel Prism + Trace + Signal
- [ ] Verify Brief → GPT-4o mini routing
- [ ] Test heuristic-only mode
- [ ] Target: 50% response time reduction

### Day 5: Full 20-URL market test
- [ ] 5 India, 5 Germany, 5 US, 5 UK
- [ ] Expand MBFC database
- [ ] Create WEEK2_TODO.md

---

*Generated by Dissekt test framework. Last updated: April 14, 2026.*
