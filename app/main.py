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

# ============================================
# Run with: uvicorn app.main:app --reload
# ============================================
