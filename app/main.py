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
async def radar_feed(market: str = "all", limit: int = 20):
    items = await get_radar_feed(market, limit)
    return {"items": items, "count": len(items), "market": market}


# ============================================
# Run with: uvicorn app.main:app --reload
# ============================================
