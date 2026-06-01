"""
DISSEKT — Code Patches for Week 2
Apply these changes to your existing files.
"""

# ============================================================
# PATCH 1: app/main.py — Add Radar endpoint + rate limiting + CORS fix
# ============================================================
# Add these imports at the top:
"""
from app.radar import get_radar_feed
from fastapi.responses import JSONResponse
from collections import defaultdict
import time as _time
"""

# Replace the CORS middleware block with:
"""
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://dissekt.co",
        "https://www.dissekt.co",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
"""

# Add rate limiting middleware BEFORE the endpoints:
"""
_rate_limits = defaultdict(list)
FREE_LIMIT = 3
WINDOW = 86400  # 24 hours

@app.middleware("http")
async def rate_limit(request: Request, call_next):
    if request.url.path == "/api/scan" and request.method == "POST":
        ip = request.client.host
        now = _time.time()
        _rate_limits[ip] = [t for t in _rate_limits[ip] if now - t < WINDOW]
        if len(_rate_limits[ip]) >= FREE_LIMIT:
            return JSONResponse(
                status_code=429,
                content={"detail": f"Rate limit exceeded ({FREE_LIMIT}/day). Upgrade to Pro for unlimited."}
            )
        _rate_limits[ip].append(now)
    return await call_next(request)
"""

# Add Radar endpoint (after /api/techniques):
"""
@app.get("/api/radar")
async def radar_feed(market: str = "all", limit: int = 20):
    items = await get_radar_feed(market, limit)
    return {"items": items, "count": len(items), "market": market}
"""


# ============================================================
# PATCH 2: app/beacon/__init__.py — Add Playwright fallback
# ============================================================
# Add this as Method 3 INSIDE extract_from_url(), 
# AFTER Method 2 (httpx fallback) and BEFORE the final raise ValueError:
"""
    # Method 3: Playwright headless browser (for JS-rendered / bot-blocked sites)
    try:
        from playwright.async_api import async_playwright
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            await page.goto(url, wait_until="networkidle", timeout=15000)
            
            html = await page.content()
            if not title:
                title = await page.title()
            
            await browser.close()
            
            import trafilatura
            text = trafilatura.extract(html, include_comments=False, include_tables=False) or ""
            if text and len(text) > 200:
                logger.info(f"Playwright extracted {len(text)} chars from {url}")
                return text[:MAX_TEXT_LENGTH], title
    except ImportError:
        logger.warning("Playwright not installed — skipping JS rendering")
    except Exception as e:
        logger.warning(f"Playwright failed: {e}")
"""

# ============================================================
# PATCH 3: app/beacon/__init__.py — Add claim graph integration
# ============================================================
# Add AFTER the analysis is assembled (after the FullAnalysis() creation)
# and BEFORE the cache step:
"""
    # Store in claim graph (async, don't block response)
    try:
        from app.claim_graph import store_analysis, find_similar
        
        similar = await find_similar(extracted_text)
        
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
"""
