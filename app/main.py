"""Dissekt — Main FastAPI application.

Endpoints:
  GET  /health          — Health check
  POST /api/scan        — Main analysis endpoint (Beacon)
  POST /api/scan/text   — Direct text analysis
  GET  /api/techniques  — List all manipulation techniques
"""

import logging
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.models import ScanRequest, FullAnalysis, AnalysisMode
from app.beacon import scan
from app.radar import get_radar_feed
from fastapi.responses import JSONResponse
from collections import defaultdict
import time as _time

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger("dissekt")


# ============================================
# App lifecycle
# ============================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    settings = get_settings()
    logger.info(f"Starting Dissekt {settings.app_version} ({settings.app_env})")
    logger.info(f"Anthropic API: {'configured' if settings.anthropic_api_key else 'NOT SET'}")
    logger.info(f"OpenAI API: {'configured' if settings.openai_api_key else 'NOT SET'}")
    logger.info(f"Redis: {'configured' if settings.redis_url else 'NOT SET'}")
    logger.info(f"Fact Check API: {'configured' if settings.google_factcheck_api_key else 'NOT SET'}")
    yield
    logger.info("Shutting down Dissekt")


# ============================================
# App setup
# ============================================

app = FastAPI(
    title="Dissekt API",
    description="Dissect manipulative content. Trace claims to their source. Export the evidence.",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS — allow all origins in development, restrict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://dissekt.info",
        "https://www.dissekt.info",
        "https://dissekt-web.vercel.app",
    ],  # TODO: Restrict to dissekt.co in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting (in-memory, replace with Redis in production)
_rate_limits = defaultdict(list)
FREE_LIMIT = 50  # generous for testing, lower to 3 for production
WINDOW = 86400

@app.middleware("http")
async def rate_limit(request: Request, call_next):
    if request.url.path == "/api/scan" and request.method == "POST":
        ip = request.client.host
        now = _time.time()
        _rate_limits[ip] = [t for t in _rate_limits[ip] if now - t < WINDOW]
        if len(_rate_limits[ip]) >= FREE_LIMIT:
            return JSONResponse(
                status_code=429,
                content={"detail": f"Rate limit exceeded ({FREE_LIMIT}/day)."}
            )
        _rate_limits[ip].append(now)
    return await call_next(request)

# ============================================
# Endpoints
# ============================================

@app.get("/health")
async def health():
    """Health check endpoint."""
    settings = get_settings()
    return {
        "status": "ok",
        "version": settings.app_version,
        "env": settings.app_env,
        "services": {
            "anthropic": bool(settings.anthropic_api_key),
            "openai": bool(settings.openai_api_key),
            "redis": bool(settings.redis_url),
            "supabase": bool(settings.supabase_url),
            "factcheck_api": bool(settings.google_factcheck_api_key),
        },
    }


@app.post("/api/scan", response_model=FullAnalysis)
async def scan_content(request: ScanRequest):
    """Main analysis endpoint.

    Accepts a URL or text. Runs through Beacon → Prism + Trace + Signal.
    Returns full analysis with manipulation techniques, fact-checks,
    bias scores, and blockchain evidence hash.
    """
    try:
        result = await scan(
            content=request.content,
            mode=request.mode.value,
        )
        return result

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Scan error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Analysis failed. Please try again.")


@app.get("/api/techniques")
async def list_techniques():
    """List all manipulation techniques Dissekt can detect."""
    from app.prism.techniques import TECHNIQUES
    return {
        "count": len(TECHNIQUES),
        "techniques": TECHNIQUES,
    }

@app.get("/api/radar")
async def radar_feed(market: str = "all", limit: int = 20, refresh: bool = False):
    """Radar feed with 6-hour Redis cache."""
    import json
    from datetime import datetime, timezone

    cache_key = f"radar:{market}"
    RADAR_TTL = 21600  # 6 hours in seconds

    # Check Redis cache (unless force refresh)
    if not refresh:
        try:
            from app.cache import redis_client
            if redis_client:
                cached = await redis_client.get(cache_key)
                if cached:
                    data = json.loads(cached)
                    return {
                        "items": data["items"][:limit],
                        "count": len(data["items"][:limit]),
                        "market": market,
                        "cached": True,
                        "last_refreshed": data.get("timestamp", None),
                    }
        except Exception as e:
            logger.warning(f"Radar cache read failed: {e}")

    # Fetch fresh RSS feeds
    items = await get_radar_feed(market, limit=100)  # fetch more, cache all
    now = datetime.now(timezone.utc).isoformat()

    # Store in Redis with 6-hour TTL
    try:
        from app.cache import redis_client
        if redis_client:
            cache_data = json.dumps({"items": items, "timestamp": now})
            await redis_client.set(cache_key, cache_data, ex=RADAR_TTL)
    except Exception as e:
        logger.warning(f"Radar cache write failed: {e}")

    return {
        "items": items[:limit],
        "count": len(items[:limit]),
        "market": market,
        "cached": False,
        "last_refreshed": now,
    }




@app.post("/api/telegram")
async def telegram_webhook(request: Request):
    """Telegram bot webhook."""
    import json
    from telegram import Update, Bot
    from app.telegram_bot import format_result, WELCOME_MSG, HELP_MSG
    from telegram.constants import ParseMode
    
    settings = get_settings()
    bot = Bot(token=settings.telegram_bot_token)
    
    body = await request.json()
    update = Update.de_json(body, bot)
    
    if not update or not update.message:
        return {"status": "ok"}
    
    chat_id = update.message.chat_id
    text = update.message.text or ""
    
    # Handle commands
    if text.startswith("/start"):
        try:
            await bot.send_message(chat_id=chat_id, text=WELCOME_MSG, parse_mode=ParseMode.HTML)
        except Exception as e:
            logger.warning(f"Telegram send failed: {e}")
        return {"status": "ok"}
    
    if text.startswith("/help"):
        await bot.send_message(chat_id=chat_id, text=HELP_MSG, parse_mode=ParseMode.HTML)
        return {"status": "ok"}
    
    # Handle image
    if update.message.photo:
        await bot.send_message(chat_id=chat_id, text="📷 Image analysis coming soon! For now, please paste the text from the image.", parse_mode=ParseMode.HTML)
        return {"status": "ok"}
    
    if not text or len(text) < 10:
        await bot.send_message(chat_id=chat_id, text="Please send more text (at least 10 characters) or a URL to analyze.", parse_mode=ParseMode.HTML)
        return {"status": "ok"}
    
    # Send "analyzing" message
    await bot.send_message(chat_id=chat_id, text="🔍 Analyzing... This takes 3-10 seconds.", parse_mode=ParseMode.HTML)
    
    try:
        result = await scan(content=text, mode="brief")
        result_dict = result.model_dump(mode="json")
        
        # Save report to Supabase so the link works
        report_id = result_dict.get("id", "")
        try:
            import os
            from supabase import create_client
            sb = create_client(os.getenv("SUPABASE_URL", ""), os.getenv("SUPABASE_KEY", ""))
            sb.table("reports").upsert({
                "id": report_id,
                "analysis": result_dict,
                "input_content": text[:500],
                "mode": "brief",
            }).execute()
        except Exception as e:
            logger.warning(f"Report save failed: {e}")
        reply = format_result(result_dict)
        await bot.send_message(chat_id=chat_id, text=reply, parse_mode=ParseMode.HTML, disable_web_page_preview=True)
    except ValueError as e:
        err_msg = str(e)
        await bot.send_message(chat_id=chat_id, text=f"⚠️ {err_msg}", parse_mode=ParseMode.HTML)
    except Exception as e:
        logger.error(f"Telegram analysis failed: {e}")
        await bot.send_message(chat_id=chat_id, text="❌ Analysis failed. Please try again.", parse_mode=ParseMode.HTML)
    
    return {"status": "ok"}



@app.post("/api/scan/compare")
async def compare_content(request: Request):
    """Compare two pieces of content side-by-side."""
    import openai
    
    body = await request.json()
    content_a = body.get("content_a", "")
    content_b = body.get("content_b", "")
    mode = body.get("mode", "brief")
    
    if len(content_a) < 10 or len(content_b) < 10:
        raise HTTPException(status_code=400, detail="Both inputs must be at least 10 characters")
    
    try:
        # Run both scans in parallel
        import asyncio
        result_a, result_b = await asyncio.gather(
            scan(content=content_a, mode=mode),
            scan(content=content_b, mode=mode),
        )
        
        dict_a = result_a.model_dump(mode="json")
        dict_b = result_b.model_dump(mode="json")
        
        # Generate comparison summary using GPT-4o mini
        settings = get_settings()
        client = openai.AsyncOpenAI(api_key=settings.openai_api_key)
        
        techs_a = [t.get("name", "") for t in dict_a.get("prism", {}).get("techniques", [])]
        techs_b = [t.get("name", "") for t in dict_b.get("prism", {}).get("techniques", [])]
        shared = set(techs_a) & set(techs_b)
        only_a = set(techs_a) - set(techs_b)
        only_b = set(techs_b) - set(techs_a)
        
        brief_a = dict_a.get("prism", {}).get("brief", "")
        brief_b = dict_b.get("prism", {}).get("brief", "")
        
        comparison_prompt = f"""Compare these two content analyses:

Content A summary: {brief_a[:300]}
Content A techniques: {', '.join(techs_a) or 'none'}

Content B summary: {brief_b[:300]}  
Content B techniques: {', '.join(techs_b) or 'none'}

Write a 2-3 sentence comparison of how these two pieces of content differ in their use of manipulation techniques, framing, and credibility. Be specific."""

        comp_response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=200,
            messages=[
                {"role": "system", "content": "You are a media analysis expert comparing two pieces of content."},
                {"role": "user", "content": comparison_prompt},
            ],
        )
        
        comparison_summary = comp_response.choices[0].message.content.strip()
        
        return {
            "result_a": dict_a,
            "result_b": dict_b,
            "comparison": {
                "summary": comparison_summary,
                "shared_techniques": list(shared),
                "only_a_techniques": list(only_a),
                "only_b_techniques": list(only_b),
                "score_diff": abs(
                    (dict_a.get("signal", {}).get("toxicity_score", 0) * 100) -
                    (dict_b.get("signal", {}).get("toxicity_score", 0) * 100)
                ),
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Compare failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Comparison failed")



@app.get("/api/memory")
async def search_memory(q: str = "", limit: int = 10):
    """Search past analyses by topic using Qdrant similarity."""
    if len(q) < 3:
        return {"results": [], "query": q}
    
    try:
        from app.claim_graph import find_similar
        results = await find_similar(q, limit=limit)
        return {"results": results, "query": q, "count": len(results)}
    except Exception as e:
        logger.warning(f"Memory search failed: {e}")
        return {"results": [], "query": q, "error": str(e)}



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



@app.get("/api/digest")
async def weekly_digest():
    """Generate weekly digest data: trending topics, top techniques, recent analyses."""
    from datetime import datetime, timedelta
    
    try:
        # Get analyses from last 7 days via Qdrant
        from app.claim_graph import find_similar
        recent = await find_similar("news analysis", limit=50)
        
        # Aggregate techniques
        technique_counts: dict = {}
        topics: dict = {}
        total = len(recent)
        
        for r in recent:
            for t in r.get("techniques", []):
                technique_counts[t] = technique_counts.get(t, 0) + 1
            preview = r.get("text_preview", "")[:50]
            if preview:
                # Simple topic extraction: first 3 significant words
                words = [w for w in preview.split()[:6] if len(w) > 3]
                key = " ".join(words[:3])
                if key:
                    topics[key] = topics.get(key, 0) + 1
        
        top_techniques = sorted(technique_counts.items(), key=lambda x: -x[1])[:5]
        trending_topics = sorted(topics.items(), key=lambda x: -x[1])[:5]
        
        return {
            "total_analyses": total,
            "period": "last 7 days",
            "top_techniques": [{"name": t[0], "count": t[1]} for t in top_techniques],
            "trending_topics": [{"topic": t[0], "count": t[1]} for t in trending_topics],
        }
    except Exception as e:
        logger.warning(f"Digest failed: {e}")
        return {"total_analyses": 0, "top_techniques": [], "trending_topics": []}


@app.post("/api/digest/send")
async def send_digest(email: str = ""):
    """Send weekly digest email to specified address or all invited users."""
    settings = get_settings()
    digest = await weekly_digest()
    
    if digest["total_analyses"] == 0:
        return {"sent": False, "reason": "No analyses this week"}
    
    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest["top_techniques"])
    topics_html = "".join(f"<li>{t['topic']} ({t['count']} analyses)</li>" for t in digest["trending_topics"])
    
    html = f"""
    <div style="font-family: -apple-system, sans-serif; max-width: 520px; margin: 0 auto;">
      <div style="background: #0d9488; padding: 16px 20px; border-radius: 10px 10px 0 0;">
        <h2 style="color: white; margin: 0; font-size: 18px;">Dissekt Weekly Digest</h2>
      </div>
      <div style="background: #fff; padding: 20px; border: 1px solid #e5eaea; border-top: none; border-radius: 0 0 10px 10px;">
        <p style="font-size: 14px; color: #555;">{digest['total_analyses']} analyses this week.</p>
        
        <h3 style="font-size: 14px; color: #1a1a1a; margin: 16px 0 8px;">Top techniques detected</h3>
        <ul style="font-size: 13px; color: #555; padding-left: 20px;">{techs_html}</ul>
        
        <h3 style="font-size: 14px; color: #1a1a1a; margin: 16px 0 8px;">Trending topics</h3>
        <ul style="font-size: 13px; color: #555; padding-left: 20px;">{topics_html}</ul>
        
        <div style="margin-top: 20px; text-align: center;">
          <a href="https://dissekt.info/analyze" style="display: inline-block; background: #0d9488; color: white; padding: 10px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;">Analyze something new</a>
        </div>
        
        <p style="font-size: 11px; color: #aaa; margin-top: 20px; text-align: center;">
          You're receiving this because you have a Dissekt invitation.<br/>
          <a href="https://dissekt.info" style="color: #0d9488;">dissekt.info</a>
        </p>
      </div>
    </div>
    """
    
    target = email or "sambitmallick123@gmail.com"
    
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post("https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                json={
                    "from": "Dissekt <onboarding@resend.dev>",
                    "to": target,
                    "subject": f"Dissekt Weekly: {digest['total_analyses']} analyses, top trends",
                    "html": html,
                })
            return {"sent": res.status_code == 200, "to": target}
    except Exception as e:
        return {"sent": False, "error": str(e)}



@app.get("/api/annotations/{report_id}")
async def get_annotations(report_id: str):
    """Get collaborative annotations for a report."""
    settings = get_settings()
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        result = sb.table("annotations").select("*").eq("report_id", report_id).order("created_at").execute()
        return {"annotations": result.data or []}
    except Exception as e:
        return {"annotations": [], "error": str(e)}


@app.post("/api/annotations")
async def add_annotation(body: dict):
    """Add a collaborative annotation to a report."""
    settings = get_settings()
    report_id = body.get("report_id")
    text = body.get("text", "")
    author = body.get("author", "Anonymous")
    
    if not report_id or not text:
        from fastapi import HTTPException
        raise HTTPException(400, "report_id and text required")
    
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        result = sb.table("annotations").insert({
            "report_id": report_id,
            "text": text[:500],
            "author": author,
        }).execute()
        return {"success": True, "annotation": result.data[0] if result.data else None}
    except Exception as e:
        return {"success": False, "error": str(e)}



@app.get("/api/fingerprint")
async def technique_fingerprint(source: str = ""):
    """Analyze technique patterns for a specific source/outlet across all past analyses."""
    settings = get_settings()
    
    if len(source) < 2:
        return {"error": "Provide a source name (e.g., 'bbc', 'ndtv', 'fox')"}
    
    try:
        from app.claim_graph import find_similar
        results = await find_similar(source, limit=50)
        
        technique_counts: dict = {}
        total_analyses = len(results)
        confidence_sums: dict = {}
        
        for r in results:
            for t in r.get("techniques", []):
                technique_counts[t] = technique_counts.get(t, 0) + 1
                confidence_sums[t] = confidence_sums.get(t, 0) + 0.7  # approx avg
        
        # Calculate rates (how often each technique appears per analysis)
        technique_rates = {}
        for tech, count in technique_counts.items():
            technique_rates[tech] = {
                "count": count,
                "rate": round(count / max(total_analyses, 1), 2),
                "avg_confidence": round(confidence_sums.get(tech, 0) / max(count, 1), 2),
            }
        
        sorted_techs = sorted(technique_rates.items(), key=lambda x: -x[1]["count"])
        
        # Build fingerprint summary
        top3 = [t[0].replace("_", " ") for t in sorted_techs[:3]]
        
        return {
            "source": source,
            "total_analyses": total_analyses,
            "techniques": dict(sorted_techs),
            "fingerprint_summary": f"{source} most frequently uses: {', '.join(top3)}." if top3 else "Not enough data.",
            "unique_techniques": len(technique_counts),
        }
    except Exception as e:
        logger.warning(f"Fingerprint failed: {e}")
        return {"source": source, "total_analyses": 0, "techniques": {}, "error": str(e)}


@app.get("/api/fingerprint/compare")
async def compare_fingerprints(sources: str = ""):
    """Compare technique fingerprints across multiple sources. Pass comma-separated source names."""
    source_list = [s.strip() for s in sources.split(",") if s.strip()]
    if len(source_list) < 2:
        return {"error": "Provide 2+ sources comma-separated (e.g., 'bbc,fox,ndtv')"}
    
    results = {}
    for src in source_list[:5]:
        from starlette.testclient import TestClient
        fp = await technique_fingerprint(src)
        results[src] = fp
    
    return {"sources": results, "count": len(results)}



@app.get("/api/claim-lifecycle")
async def claim_lifecycle(claim: str = ""):
    """Track a claim's lifecycle: first appearance, spread, fact-checks, evolution."""
    if len(claim) < 10:
        return {"error": "Provide a claim (min 10 chars)"}
    
    try:
        from app.claim_graph import find_similar
        matches = await find_similar(claim, limit=30)
        
        # Sort by timestamp
        timeline = []
        for m in matches:
            ts = m.get("timestamp", "")
            try:
                ts_val = float(ts) if ts else 0
            except:
                ts_val = 0
            timeline.append({
                "text_preview": m.get("text_preview", ""),
                "similarity": m.get("similarity", 0),
                "techniques": m.get("techniques", []),
                "timestamp": ts_val,
                "date": "",
            })
        
        timeline.sort(key=lambda x: x["timestamp"])
        
        # Add formatted dates
        from datetime import datetime
        for item in timeline:
            if item["timestamp"] > 0:
                item["date"] = datetime.fromtimestamp(item["timestamp"]).strftime("%Y-%m-%d %H:%M")
        
        # Calculate lifecycle stats
        if len(timeline) >= 2 and timeline[0]["timestamp"] > 0:
            first_seen = timeline[0]["date"]
            last_seen = timeline[-1]["date"]
            spread_days = round((timeline[-1]["timestamp"] - timeline[0]["timestamp"]) / 86400, 1)
        else:
            first_seen = "Unknown"
            last_seen = "Unknown"
            spread_days = 0
        
        # Technique evolution
        early_techs: dict = {}
        late_techs: dict = {}
        mid = len(timeline) // 2
        for item in timeline[:mid]:
            for t in item["techniques"]:
                early_techs[t] = early_techs.get(t, 0) + 1
        for item in timeline[mid:]:
            for t in item["techniques"]:
                late_techs[t] = late_techs.get(t, 0) + 1
        
        return {
            "claim": claim,
            "total_appearances": len(timeline),
            "first_seen": first_seen,
            "last_seen": last_seen,
            "spread_days": spread_days,
            "timeline": timeline[:20],
            "technique_evolution": {
                "early": dict(sorted(early_techs.items(), key=lambda x: -x[1])[:5]),
                "late": dict(sorted(late_techs.items(), key=lambda x: -x[1])[:5]),
            },
        }
    except Exception as e:
        logger.warning(f"Claim lifecycle failed: {e}")
        return {"claim": claim, "total_appearances": 0, "error": str(e)}



@app.get("/api/trust-network/{report_id}")
async def trust_network(report_id: str):
    """Get aggregate anonymous trust signals for a report or claim."""
    settings = get_settings()
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        
        result = sb.table("decisions").select("decision, note").eq("analysis_id", report_id).execute()
        decisions = result.data or []
        
        total = len(decisions)
        trust = sum(1 for d in decisions if d["decision"] == "trust")
        unsure = sum(1 for d in decisions if d["decision"] == "unsure")
        reject = sum(1 for d in decisions if d["decision"] == "reject")
        
        # Extract common concerns from notes
        notes = [d.get("note", "") for d in decisions if d.get("note")]
        
        return {
            "report_id": report_id,
            "total_votes": total,
            "trust": trust,
            "unsure": unsure,
            "reject": reject,
            "trust_pct": round(trust / max(total, 1) * 100),
            "unsure_pct": round(unsure / max(total, 1) * 100),
            "reject_pct": round(reject / max(total, 1) * 100),
            "notes": notes[:5],
        }
    except Exception as e:
        return {"report_id": report_id, "total_votes": 0, "error": str(e)}


# ============================================
# Run with: uvicorn app.main:app --reload
# ============================================
