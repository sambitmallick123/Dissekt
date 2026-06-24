"""Dissekt — Main FastAPI application.



Endpoints:
  GET  /health          — Health check
  POST /api/scan        — Main analysis endpoint (Beacon)
  POST /api/scan/text   — Direct text analysis
  GET  /api/techniques  — List all manipulation techniques
"""

import logging
import time
import asyncio
from pydantic import BaseModel
from contextlib import asynccontextmanager
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.models import ScanRequest, FullAnalysis, AnalysisMode
from app.beacon import scan
from app.middleware import validate_and_rate_limit
from app.factchecker_db import get_checker_info, tier_label
from app.scope import get_scope_feed
from fastapi.responses import JSONResponse
from collections import defaultdict
import time as _time

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger("dissekt")

# Constellation is gated OFF. Flip to True (and unhide the nav/route) to revive.
ENABLE_CONSTELLATION = False


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


def _resolve_reframe_model() -> str:
    """Resolve the reframe role model id for inline openai create() calls."""
    try:
        from app.models_registry import model_meta
        from app.config import get_settings
        from supabase import create_client
        s = get_settings()
        sb = create_client(s.supabase_url, s.supabase_key)
        rows = sb.table("model_config").select("role, model").eq("role", "reframe").execute()
        if rows.data:
            mid = rows.data[0]["model"]
            if model_meta(mid)["provider"] == "openai":
                return mid
    except Exception:
        pass
    return "gpt-4o-mini"


def _resolve_openai_model_for(role: str) -> str:
    """Resolve a role's configured model, but only if it's an OpenAI model
    (these inline calls use openai.AsyncOpenAI). Falls back to gpt-4o-mini."""
    try:
        from app.models_registry import model_meta
        from app.config import get_settings
        from supabase import create_client
        s = get_settings()
        sb = create_client(s.supabase_url, s.supabase_key)
        rows = sb.table("model_config").select("role, model").eq("role", role).execute()
        if rows.data:
            mid = rows.data[0]["model"]
            if model_meta(mid)["provider"] == "openai":
                return mid
    except Exception:
        pass
    return "gpt-4o-mini"


@app.get("/api/admin/models")
async def admin_get_models(adminKey: str = ""):
    """Return the model registry + current role assignments (override vs default)."""
    from fastapi import HTTPException
    settings = get_settings()
    if adminKey != settings.dissekt_admin_key:
        raise HTTPException(401, "Unauthorized")

    from app.models_registry import MODEL_REGISTRY, ROLE_DEFAULTS, ROLE_LABELS, ROLE_CAPABILITY, models_for_capability

    # Load current overrides from DB
    overrides = {}
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        rows = sb.table("model_config").select("role, model").execute()
        for r in (rows.data or []):
            overrides[r["role"]] = r["model"]
    except Exception as e:
        logger.warning(f"model_config read failed: {e}")

    roles = []
    for role, default in ROLE_DEFAULTS.items():
        cap = ROLE_CAPABILITY.get(role, "text")
        roles.append({
            "role": role,
            "label": ROLE_LABELS.get(role, role),
            "capability": cap,
            "default": default,
            "current": overrides.get(role, default),
            "is_override": role in overrides,
            "options": [
                {"id": mid, "label": MODEL_REGISTRY[mid]["label"], "cost": MODEL_REGISTRY[mid]["cost"], "provider": MODEL_REGISTRY[mid]["provider"]}
                for mid in models_for_capability(cap)
            ],
        })

    return {"roles": roles, "registry": MODEL_REGISTRY}


@app.post("/api/admin/models")
async def admin_set_model(body: dict):
    """Admin sets (or clears) a role's model override."""
    from fastapi import HTTPException
    settings = get_settings()
    if body.get("adminKey") != settings.dissekt_admin_key:
        raise HTTPException(401, "Unauthorized")

    role = body.get("role")
    model = body.get("model")  # model id, or null/empty to reset to default
    if not role:
        raise HTTPException(400, "role required")

    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)

    try:
        if not model:  # reset to default = delete the override row
            sb.table("model_config").delete().eq("role", role).execute()
            action = "reset"
        else:
            # upsert
            existing = sb.table("model_config").select("role").eq("role", role).execute()
            if existing.data:
                sb.table("model_config").update({"model": model}).eq("role", role).execute()
            else:
                sb.table("model_config").insert({"role": role, "model": model}).execute()
            action = "set"
    except Exception as e:
        raise HTTPException(500, f"DB error: {e}")

    # Invalidate the dispatch cache so the change takes effect immediately
    try:
        from app.llm_dispatch import invalidate_model_config
        invalidate_model_config()
    except Exception:
        pass

    return {"success": True, "role": role, "model": model or None, "action": action}



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


async def _extract_entities(text: str) -> list:
    """Extract entities + main topic via gpt-4o-mini. Returns [{name, type}]. Best-effort."""
    if not text or len(text.strip()) < 20:
        return []
    try:
        import openai, json as _json
        _settings = get_settings()
        client = openai.AsyncOpenAI(api_key=_settings.openai_api_key)
        prompt = (
            "Extract the key entities and main topic from this text. "
            "Return ONLY a JSON array, each item {\"name\": str, \"type\": one of "
            "\"person\"|\"org\"|\"place\"|\"theme\"|\"topic\"}. "
            "Include the single main topic with type \"topic\". "
            "Limit to the 8 most significant. No duplicates. No commentary.\n\n"
            + text[:2000]
        )
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0,
            max_tokens=300,
        )
        raw = resp.choices[0].message.content.strip()
        # strip code fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1] if "```" in raw[3:] else raw
            raw = raw.replace("json", "", 1).strip() if raw.lstrip().startswith("json") else raw
        start = raw.find("[")
        end = raw.rfind("]")
        if start != -1 and end != -1:
            raw = raw[start:end+1]
        ents = _json.loads(raw)
        # normalize
        out = []
        seen = set()
        for e in ents:
            name = (e.get("name") or "").strip()
            etype = (e.get("type") or "topic").strip().lower()
            if name and name.lower() not in seen:
                seen.add(name.lower())
                out.append({"name": name, "type": etype})
        return out[:8]
    except Exception as e:
        logger.warning(f"[ner] extraction failed (non-fatal): {e}")
        return []

async def _persist_scan(email: str, mode: str, result) -> None:
    """Persist scan METADATA for members only (no raw text). Best-effort."""
    logger.info(f"[persist] called with email={email!r} mode={mode}")
    if not email:
        logger.info("[persist] SKIPPED — no email (free/anonymous)")
        return  # free/anonymous -> not stored (member-only)
    try:
        from supabase import create_client
        _settings = get_settings()
        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)
        def g(obj, *path, default=None):
            cur = obj
            for p in path:
                if cur is None: return default
                cur = getattr(cur, p, None) if not isinstance(cur, dict) else cur.get(p)
            return cur if cur is not None else default

        techs_raw = g(result, "prism", "techniques", default=[]) or []
        techniques = []
        for t in techs_raw:
            name = getattr(t, "name", None) if not isinstance(t, dict) else t.get("name")
            conf = getattr(t, "confidence", None) if not isinstance(t, dict) else t.get("confidence")
            if name:
                techniques.append({"name": name, "confidence": conf or 0})

        scoring = g(result, "scoring", default={}) or {}
        clarity = None
        if isinstance(scoring, dict):
            clarity = scoring.get("clarity_score", scoring.get("clarity", scoring.get("score")))

        toxicity = g(result, "signal", "toxicity_score", default=0.0)
        language = g(result, "detected_language", default="en")

        # NER: extract entities + main topic from the analyzed text
        text_for_ner = g(result, "extracted_text", default="") or g(result, "input_content", default="")
        entities = await _extract_entities(text_for_ner) if ENABLE_CONSTELLATION else []

        analysis_id = g(result, "id", default="") or ""
        sb.table("scans").insert({
            "user_email": email,
            "analysis_id": analysis_id,
            "mode": mode,
            "language": language,
            "clarity": clarity,
            "techniques": techniques,
            "toxicity": toxicity,
            "entities": entities,
        }).execute()
        logger.info(f"[persist] ✓ saved scan for {email}")
    except Exception as e:
        logger.error(f"[persist] ✗ FAILED for {email}: {e}")

@app.post("/api/scan", response_model=FullAnalysis)
async def scan_content(request: ScanRequest, x_api_key: str = Header(None, alias="X-API-Key"), x_user_email: str = Header(None, alias="X-User-Email")):
    """Main analysis endpoint.

    Accepts a URL or text. Runs through Beacon → Prism + Trace + Signal.
    Returns full analysis with manipulation techniques, fact-checks,
    bias scores, and blockchain evidence hash.
    """
    # API key rate limiting (if key provided)
    if x_api_key:
        settings = get_settings()
        auth = await validate_and_rate_limit(x_api_key, settings.supabase_url, settings.supabase_key)
        if not auth["valid"]:
            from fastapi.responses import JSONResponse
            return JSONResponse(status_code=429 if "Rate limit" in auth.get("error", "") else 401, content={"error": auth["error"], "limit": auth.get("limit"), "used": auth.get("used")})
    
    try:
        result = await scan(
            content=request.content,
            mode=request.mode.value,
            image=request.image,
        )
        try:
            await _persist_scan(x_user_email or "", request.mode.value, result)
        except Exception:
            pass
        return result

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Scan error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Analysis failed. Please try again.")


@app.get("/api/constellation")
async def constellation(email: str, preview: bool = False, days: int = 7, x_admin_key: str = Header(default="")):
    """Member knowledge graph. Nodes=entities, edges=co-occurrence + technique-similarity.
    Each node carries related scans (analysis_id -> /report/{id}). preview bypasses threshold."""
    if not ENABLE_CONSTELLATION:
        return {"ready": False, "disabled": True, "nodes": [], "edges": [], "n_clusters": 0, "count": 0}
    from fastapi import HTTPException
    if not email:
        raise HTTPException(status_code=400, detail="email required")
    try:
        _settings = get_settings()
        from supabase import create_client
        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)
        # Hard cap: Constellation is a recent-activity view, max 7 days, ever.
        from datetime import datetime, timezone, timedelta
        days = max(1, min(int(days or 7), 7))
        since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        rows = sb.table("scans").select(
            "id, analysis_id, techniques, entities, toxicity, clarity, created_at"
        ).eq("user_email", email).gte("created_at", since).order("created_at", desc=True).limit(500).execute()
        scans = rows.data or []
        # No unlock gate — render whatever exists in the window. Empty only at zero.
        if not scans:
            return {"ready": True, "empty": True, "days": days, "count": 0, "nodes": [], "edges": [], "n_clusters": 0}

        import math
        from collections import defaultdict, Counter
        STOP = {"ever", "dumbest", "president", "the", "a", "an", "this", "that",
                "it", "is", "was", "they", "we", "you", "i"}

        node_data = {}
        for s in scans:
            ents = s.get("entities") or []
            techs = [t.get("name") for t in (s.get("techniques") or []) if t.get("name")]
            top_tech = techs[0] if techs else None
            tox = s.get("toxicity") or 0.0
            clar = s.get("clarity")
            aid = s.get("analysis_id") or ""
            created = s.get("created_at", "")
            for e in ents:
                name = (e.get("name") or "").strip()
                if not name or name.lower() in STOP or len(name) < 2:
                    continue
                key = name.lower()
                if key not in node_data:
                    node_data[key] = {"name": name, "type": e.get("type", "topic"),
                                      "freq": 0, "tox_sum": 0.0, "clar_sum": 0.0, "clar_n": 0,
                                      "tech": Counter(), "scans": []}
                nd = node_data[key]
                nd["freq"] += 1
                nd["tox_sum"] += tox
                if clar is not None:
                    nd["clar_sum"] += clar; nd["clar_n"] += 1
                for t in techs:
                    nd["tech"][t] += 1
                if aid:
                    nd["scans"].append({"analysis_id": aid,
                        "clarity": round(clar, 3) if clar is not None else None,
                        "top_technique": top_tech, "toxicity": round(tox, 3),
                        "created_at": created})

        items = list(node_data.items())
        if len(items) > 40:
            items = [(k, v) for k, v in items if v["freq"] >= 2]

        nodes = []
        for key, nd in items:
            avg_tox = nd["tox_sum"] / max(nd["freq"], 1)
            avg_clar = (nd["clar_sum"] / nd["clar_n"]) if nd["clar_n"] else None
            nodes.append({"id": key, "name": nd["name"], "type": nd["type"],
                "freq": nd["freq"], "toxicity": round(avg_tox, 3),
                "clarity": round(avg_clar, 3) if avg_clar is not None else None,
                "top_techniques": [t for t, _ in nd["tech"].most_common(3)],
                "scans": nd["scans"][:10]})
        valid = {k for k, _ in items}

        co = defaultdict(int)
        for s in scans:
            ks = sorted({(e.get("name") or "").strip().lower()
                         for e in (s.get("entities") or [])
                         if (e.get("name") or "").strip().lower() in valid})
            for i in range(len(ks)):
                for j in range(i+1, len(ks)):
                    co[(ks[i], ks[j])] += 1

        all_t = sorted({t for _, nd in items for t in nd["tech"]})
        tix = {t: i for i, t in enumerate(all_t)}
        def vec(nd):
            v = [0.0]*len(all_t)
            for t, ct in nd["tech"].items():
                v[tix[t]] = ct
            return v
        def cosim(a, b):
            d = sum(x*y for x, y in zip(a, b))
            na = math.sqrt(sum(x*x for x in a)); nb = math.sqrt(sum(y*y for y in b))
            return d/(na*nb) if na and nb else 0.0
        vecs = {k: vec(nd) for k, nd in items}
        tech_edges = []
        ks = list(vecs.keys())
        for i in range(len(ks)):
            for j in range(i+1, len(ks)):
                if any(vecs[ks[i]]) and any(vecs[ks[j]]):
                    sim = cosim(vecs[ks[i]], vecs[ks[j]])
                    if sim >= 0.5:
                        tier = "strong" if sim >= 0.78 else "medium" if sim >= 0.62 else "weak"
                        tech_edges.append((ks[i], ks[j], round(sim, 2), tier))

        edges = []
        for (a, b), ct in co.items():
            co_tier = "strong" if ct >= 3 else "medium" if ct == 2 else "weak"
            edges.append({"source": a, "target": b, "type": "co", "weight": ct, "tier": co_tier})
        for (a, b, sim, tier) in tech_edges:
            edges.append({"source": a, "target": b, "type": "tech", "weight": sim, "tier": tier})


        # Connected-component clustering: nodes linked by any edge form a cluster
        adj = defaultdict(set)
        node_ids = {n['id'] for n in nodes}
        for e in edges:
            if e['source'] in node_ids and e['target'] in node_ids:
                adj[e['source']].add(e['target'])
                adj[e['target']].add(e['source'])
        cluster_of = {}
        cid = 0
        for nid in node_ids:
            if nid in cluster_of:
                continue
            stack = [nid]; cluster_of[nid] = cid
            while stack:
                cur = stack.pop()
                for nb in adj.get(cur, ()):
                    if nb not in cluster_of:
                        cluster_of[nb] = cid; stack.append(nb)
            cid += 1
        for n in nodes:
            n['cluster'] = cluster_of.get(n['id'], -1)
        n_clusters = cid

        return {"ready": True, "count": len(scans), "nodes": nodes, "edges": edges, "n_clusters": n_clusters,
                "stats": {"nodes": len(nodes), "co_edges": len(co), "tech_edges": len(tech_edges)}}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[constellation] failed: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Constellation failed: {e}")

class KeywordRecommendRequest(BaseModel):
    keyword: str

class KeywordAnalyzeRequest(BaseModel):
    keywords: list[str]
    mode: str = "brief"


@app.post("/api/keyword/recommend")
async def keyword_recommend(request: KeywordRecommendRequest):
    """Suggest related keywords to refine a topic search (gpt-4o-mini)."""
    kw = (request.keyword or "").strip()
    if not kw:
        return {"suggestions": []}
    try:
        import openai, json as _json
        _s = get_settings()
        client = openai.AsyncOpenAI(api_key=_s.openai_api_key)
        prompt = (
            "Suggest 6 related search keywords/phrases for investigating media coverage "
            "of this topic. Mix angles: subtopics, key figures, opposing framings. "
            "Return ONLY a JSON array of short strings (1-3 words each). No commentary.\n\n"
            "Topic: " + kw
        )
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5, max_tokens=150,
        )
        raw = resp.choices[0].message.content.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1].replace("json", "", 1).strip()
        s, e = raw.find("["), raw.rfind("]")
        if s != -1 and e != -1:
            raw = raw[s:e+1]
        out = _json.loads(raw)
        seen, sug = set(), []
        for x in out:
            x = str(x).strip()
            if x and x.lower() != kw.lower() and x.lower() not in seen:
                seen.add(x.lower()); sug.append(x)
        return {"suggestions": sug[:6]}
    except Exception as e:
        logger.warning(f"[keyword] recommend failed: {e}")
        return {"suggestions": []}


async def _serpapi_broad(query: str, api_key: str, num: int = 10) -> list:
    """Broad (non-exact) news-style search for keyword topics."""
    import httpx
    url = "https://serpapi.com/search"
    params = {"api_key": api_key, "q": query[:120], "num": num, "sort": "date",
              "tbs": "qdr:m"}  # qdr:m = past month (keeps general web, adds recency)
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()
        out = []
        for item in data.get("organic_results", []):
            link = item.get("link", "")
            if link:
                out.append({"url": link, "title": item.get("title", ""),
                            "date": item.get("date", ""), "source": item.get("source", "")})
        return out
    except Exception as e:
        logger.error(f"[keyword] serpapi broad failed: {e}")
        return []


async def _keyword_synopsis(topic: str, good: list, summary: dict) -> str | None:
    """Grounded 2-3 sentence read of how a TOPIC is being covered, adapted from the
    Constellation cluster-report prompt. Aggregate-only facts; non-fatal."""
    if not good or (summary or {}).get("count", 0) < 1:
        return None
    try:
        import json as _json
        from app.llm_dispatch import call_model
        spread = sorted([a.get("clarity") for a in good if a.get("clarity") is not None])
        facts = {
            "topic": topic,
            "sources_analyzed": summary.get("count"),
            "avg_clarity": summary.get("avg_clarity"),
            "clarity_low": round(spread[0], 2) if spread else None,
            "clarity_high": round(spread[-1], 2) if spread else None,
            "dominant_techniques": summary.get("dominant_techniques", []),
            "sources": [
                {"title": (a.get("title") or "")[:120], "source": a.get("source", ""),
                 "clarity": a.get("clarity"), "techniques": (a.get("techniques") or [])[:3]}
                for a in good[:10]
            ],
        }
        system = (
            "You are an analyst briefing a JOURNALIST on how a TOPIC is being covered across "
            "multiple sources analyzed by Dissekt. You are given aggregate DATA only.\n"
            "Write 2-3 sentences, no headers:\n"
            "1. What the coverage looks like overall — is it uniform or split, and on what "
            "(clarity spread, recurring techniques with counts).\n"
            "2. End with one practical 'Watch for:' note for the journalist reading future coverage.\n"
            "RULES: Use ONLY the data given. Do NOT invent outlets, numbers, or claims. If the sources "
            "clearly span unrelated subjects, say so plainly rather than forcing one narrative. "
            "Clarity is 0-1, higher = more transparently constructed (not 'more true'). "
            "Cite specific techniques and counts. Be concrete, no vague editorializing."
        )
        disp = await call_model("keyword_summary", system=system,
                                user="DATA:\n" + _json.dumps(facts, indent=2),
                                max_tokens=220, temperature=0.4)
        out = (disp.get("text") or "").strip()
        return out or None
    except Exception as e:
        logger.warning(f"Keyword synopsis failed (non-fatal): {e}")
        return None


@app.post("/api/keyword/analyze")
async def keyword_analyze(request: KeywordAnalyzeRequest,
                          x_user_email: str = Header(None, alias="X-User-Email")):
    """Fetch recent coverage on the keywords, analyze each article, aggregate a topic report."""
    from fastapi import HTTPException
    kws = [k.strip() for k in (request.keywords or []) if k.strip()]
    if not kws:
        raise HTTPException(status_code=400, detail="keywords required")
    mode = "detailed" if request.mode == "detailed" else "brief"

    # Article count by tier + mode
    is_member = bool(x_user_email)  # logged-in == member (free users have no email header on this call? keep simple)
    if mode == "detailed":
        n_articles = 5 if is_member else 3
    else:
        n_articles = 8 if is_member else 5

    _s = get_settings()
    query = " ".join(kws)

    # Cache (Redis) on keywords+mode
    cache_key = f"kwa:{mode}:{'|'.join(sorted(k.lower() for k in kws))}"
    try:
        from app.cache import _get_redis
        rc = await _get_redis()
        if rc:
            import json as _json
            hit = await rc.get(cache_key)
            if hit:
                d = _json.loads(hit)
                d["cached"] = True
                return d
    except Exception:
        rc = None

    if not _s.serpapi_key:
        raise HTTPException(status_code=503, detail="search not configured")
    results = await _serpapi_broad(query, _s.serpapi_key, num=n_articles * 2)
    # Dedup by domain, take first n
    seen_dom, chosen = set(), []
    import urllib.parse as _up
    for r in results:
        dom = _up.urlparse(r["url"]).netloc.replace("www.", "")
        if dom and dom not in seen_dom:
            seen_dom.add(dom); chosen.append(r)
        if len(chosen) >= n_articles:
            break

    if not chosen:
        return {"topic": query, "keywords": kws, "mode": mode, "articles": [],
                "summary": {"count": 0}, "message": "No recent coverage found for these keywords."}

    # Analyze each article in parallel by passing the URL straight to scan()
    from app.beacon import scan as _scan
    async def _analyze_one(item):
        try:
            res = await _scan(item["url"], mode)
            rd = res.model_dump(mode="json") if hasattr(res, "model_dump") else res
            scoring = rd.get("scoring") or {}
            clarity = scoring.get("clarity_score")
            techs = [(t.get("name") if isinstance(t, dict) else t)
                     for t in ((rd.get("prism") or {}).get("techniques") or [])]
            tox = ((rd.get("signal") or {}).get("toxicity_score")) or 0.0
            return {"url": item["url"], "title": item.get("title", ""),
                    "source": item.get("source", "") or _up.urlparse(item["url"]).netloc.replace("www.", ""),
                    "analysis_id": rd.get("id", ""), "clarity": clarity,
                    "toxicity": round(tox, 3), "techniques": techs, "ok": True}
        except Exception as e:
            logger.warning(f"[keyword] article failed {item.get('url')}: {e}")
            return {"url": item["url"], "title": item.get("title", ""), "ok": False, "error": str(e)[:120]}

    analyzed = await asyncio.gather(*[_analyze_one(it) for it in chosen])
    good = [a for a in analyzed if a.get("ok")]

    # Aggregate
    from collections import Counter
    clar_vals = [a["clarity"] for a in good if a.get("clarity") is not None]
    tox_vals = [a["toxicity"] for a in good if a.get("toxicity") is not None]
    tech_counter = Counter()
    for a in good:
        for t in a.get("techniques", []):
            if t:
                tech_counter[t] += 1
    avg_clar = round(sum(clar_vals)/len(clar_vals), 3) if clar_vals else None
    avg_tox = round(sum(tox_vals)/len(tox_vals), 3) if tox_vals else None
    dom_tech = [{"name": n, "count": ct} for n, ct in tech_counter.most_common(6)]

    _summary = {"count": len(good), "attempted": len(chosen),
                "avg_clarity": avg_clar, "avg_toxicity": avg_tox,
                "dominant_techniques": dom_tech}
    _summary["synopsis"] = await _keyword_synopsis(query, good, _summary)

    out = {
        "topic": query, "keywords": kws, "mode": mode,
        "summary": _summary,
        "articles": good, "cached": False,
    }

    # Cache 30 min
    try:
        if rc:
            import json as _json
            await rc.set(cache_key, _json.dumps(out), ex=1800)
    except Exception:
        pass

    return out


@app.get("/api/constellation/report")
async def constellation_report(email: str, cluster: int, days: int = 7,
                               x_admin_key: str = Header(default="")):
    """Generate a grounded LLM report for one cluster of the member's Constellation."""
    if not ENABLE_CONSTELLATION:
        return {"ready": False, "disabled": True}
    from fastapi import HTTPException
    if not email:
        raise HTTPException(status_code=400, detail="email required")
    try:
        # Reuse the constellation builder to get nodes/edges with cluster ids
        data = await constellation(email=email, preview=True, days=days, x_admin_key=x_admin_key)
        if data.get("empty") or not data.get("nodes"):
            return {"ready": False, "empty": True, "count": data.get("count", 0)}

        nodes = [n for n in data["nodes"] if n.get("cluster") == cluster]
        if not nodes:
            raise HTTPException(status_code=404, detail=f"cluster {cluster} not found")

        # Gather grounded facts for this cluster
        from collections import Counter
        names = [n["name"] for n in nodes]
        tech_counter = Counter()
        clar_vals = []
        scan_ids = set()
        for n in nodes:
            for t in n.get("top_techniques", []):
                tech_counter[t] += 1
            if n.get("clarity") is not None:
                clar_vals.append(n["clarity"])
            for sc in (n.get("scans") or []):
                if sc.get("analysis_id"):
                    scan_ids.add(sc["analysis_id"])
        # edges within this cluster
        cl_ids = {n["id"] for n in nodes}
        co_pairs = [(e["source"], e["target"]) for e in data["edges"]
                    if e["type"] == "co" and e["source"] in cl_ids and e["target"] in cl_ids]
        tech_pairs = [(e["source"], e["target"]) for e in data["edges"]
                      if e["type"] == "tech" and e["source"] in cl_ids and e["target"] in cl_ids]

        clar_lo = round(min(clar_vals), 2) if clar_vals else None
        clar_hi = round(max(clar_vals), 2) if clar_vals else None
        top_techs = [{"name": t, "count": c} for t, c in tech_counter.most_common(6)]

        # Build verifiable references: one entry per unique scan that fed this cluster.
        ref_map = {}
        for n in nodes:
            for sc in (n.get("scans") or []):
                aid = sc.get("analysis_id")
                if aid and aid not in ref_map:
                    ref_map[aid] = {
                        "analysis_id": aid,
                        "clarity": sc.get("clarity"),
                        "top_technique": sc.get("top_technique"),
                        "created_at": sc.get("created_at", ""),
                    }
        references = sorted(ref_map.values(), key=lambda r: r.get("created_at") or "", reverse=True)

        facts = {
            "entities": names,
            "entity_count": len(names),
            "dominant_techniques": top_techs,
            "clarity_low": clar_lo,
            "clarity_high": clar_hi,
            "scans_involved": len(scan_ids),
            "co_occurrence_pairs": co_pairs[:20],
            "technique_similarity_pairs": tech_pairs[:20],
        }

        import openai, json as _json
        _s = get_settings()
        client = openai.AsyncOpenAI(api_key=_s.openai_api_key)
        prompt = (
            "You are an analyst writing a brief for a JOURNALIST who uses Dissekt to detect "
            "manipulation in media coverage. Below is structured DATA about one cluster of topics "
            "from THEIR analysis history (the entities they have scanned and the manipulation "
            "techniques found). Write a clear, grounded report.\n\n"
            "STRUCTURE — use these three labelled sections:\n"
            "**What this covers** — Briefly describe what topics and subjects these entities are about, "
            "and how many distinct topics the cluster spans. If the entities clearly belong to unrelated "
            "subjects (e.g. one set about Iran nuclear talks, another about 5G conspiracy), say so "
            "explicitly and group them. Do NOT force unrelated entities into one false narrative. "
            "Give the reader context on what they were analyzing.\n"
            "**What the analyses show** — Describe the manipulation pattern found across these scans: "
            "which techniques dominate (with counts), the clarity range, and what that implies about how "
            "this coverage is constructed.\n"
            "**Watch for** — One line starting 'Watch for:' giving the JOURNALIST a practical thing to look "
            "out for in FUTURE coverage of these topics. It is NOT advice for content producers to write "
            "better. Example tone: 'Watch for: coverage of X that omits Y, since missing context is the "
            "dominant tactic here.'\n\n"
            "RULES:\n"
            "- Use ONLY the data provided. Do not invent facts, sources, outlets, or numbers.\n"
            "- Cite specific techniques and their counts.\n"
            "- Be concise and concrete. No vague editorializing about 'democratic discourse' or "
            "'enhancing clarity'.\n"
            "- Clarity is scored 0-1 where higher = clearer/less manipulative.\n"
            "- 2-3 short paragraphs maximum, then the 'Watch for:' line.\n\n"
            "DATA:\n" + _json.dumps(facts, indent=2)
        )
        resp = await client.chat.completions.create(
            model=_resolve_openai_model_for("constellation_report"),
            messages=[{"role": "user", "content": prompt}],
            temperature=0.4, max_tokens=500,
        )
        report_text = resp.choices[0].message.content.strip()

        return {
            "ready": True,
            "cluster": cluster,
            "report": report_text,
            "facts": facts,
            "scan_ids": list(scan_ids),
            "references": references,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[constellation report] failed: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Report failed: {e}")



@app.get("/api/techniques")
async def list_techniques():
    """List all manipulation techniques Dissekt can detect."""
    from app.prism.techniques import TECHNIQUES
    return {
        "count": len(TECHNIQUES),
        "techniques": TECHNIQUES,
    }

@app.get("/api/scope")
async def scope_feed(market: str = "global", limit: int = 25, refresh: bool = False):
    """Scope feed with 6-hour Redis cache."""
    import json
    from datetime import datetime, timezone

    cache_key = f"scope:{market}"
    SCOPE_TTL = 21600  # 6 hours in seconds

    # Check Redis cache (unless force refresh)
    if not refresh:
        try:
            from app.cache import _get_redis
            redis_client = await _get_redis()
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
            logger.warning(f"Scope cache read failed: {e}")

    # Fetch fresh RSS feeds
    items = await get_scope_feed(market, limit=120)  # fetch more, cache all
    now = datetime.now(timezone.utc).isoformat()

    # Store in Redis with 6-hour TTL
    try:
        from app.cache import _get_redis
        redis_client = await _get_redis()
        if redis_client and items:  # never cache an empty result
            cache_data = json.dumps({"items": items, "timestamp": now})
            await redis_client.set(cache_key, cache_data, ex=SCOPE_TTL)
    except Exception as e:
        logger.warning(f"Scope cache write failed: {e}")

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
    
    # ── Per-user daily rate limit (10/day) ──
    user_id = update.message.from_user.id if update.message.from_user else chat_id
    try:
        from datetime import datetime, timezone
        from app.cache import _get_redis
        r = await _get_redis()
        if r is not None:
            day = datetime.now(timezone.utc).strftime("%Y%m%d")
            rk = f"tg:rl:{user_id}:{day}"
            used = await r.incr(rk)
            if used == 1:
                await r.expire(rk, 90000)  # ~25h, covers the day
            if used > 10:
                await bot.send_message(
                    chat_id=chat_id,
                    text="🚦 You've reached today's limit of 10 analyses. It resets at 00:00 UTC.\n\nFor unlimited use, try the web app at dissekt.info",
                    parse_mode=ParseMode.HTML,
                )
                return {"status": "ok"}
    except Exception as e:
        logger.warning(f"Telegram rate-limit check failed (allowing through): {e}")

    # ── Per-user daily rate limit (10/day) ──
    user_id = update.message.from_user.id if update.message.from_user else chat_id
    try:
        from datetime import datetime, timezone
        from app.cache import _get_redis
        r = await _get_redis()
        if r is not None:
            day = datetime.now(timezone.utc).strftime("%Y%m%d")
            rk = f"tg:rl:{user_id}:{day}"
            used = await r.incr(rk)
            if used == 1:
                await r.expire(rk, 90000)  # ~25h, covers the day
            if used > 10:
                await bot.send_message(
                    chat_id=chat_id,
                    text="🚦 You've reached today's limit of 10 analyses. It resets at 00:00 UTC.\n\nFor unlimited use, try the web app at dissekt.info",
                    parse_mode=ParseMode.HTML,
                )
                return {"status": "ok"}
    except Exception as e:
        logger.warning(f"Telegram rate-limit check failed (allowing through): {e}")

    # ── Per-user daily rate limit (10/day) ──
    user_id = update.message.from_user.id if update.message.from_user else chat_id
    try:
        from datetime import datetime, timezone
        from app.cache import _get_redis
        r = await _get_redis()
        if r is not None:
            day = datetime.now(timezone.utc).strftime("%Y%m%d")
            rk = f"tg:rl:{user_id}:{day}"
            used = await r.incr(rk)
            if used == 1:
                await r.expire(rk, 90000)  # ~25h, covers the day
            if used > 10:
                await bot.send_message(
                    chat_id=chat_id,
                    text="🚦 You've reached today's limit of 10 analyses. It resets at 00:00 UTC.\n\nFor unlimited use, try the web app at dissekt.info",
                    parse_mode=ParseMode.HTML,
                )
                return {"status": "ok"}
    except Exception as e:
        logger.warning(f"Telegram rate-limit check failed (allowing through): {e}")

    # Send "analyzing" message
    await bot.send_message(chat_id=chat_id, text="🔍 Analyzing... This takes 3-10 seconds.", parse_mode=ParseMode.HTML)
    
    try:
        result = await scan(content=text, mode="brief", image=None)
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
            model=_resolve_reframe_model(),
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
# Auth endpoints
# ============================================

@app.post("/api/auth/signup")
async def signup(body: dict):
    """Register a new user."""
    import bcrypt
    settings = get_settings()
    email = (body.get("email") or "").strip().lower()
    name = body.get("name", "")
    password = body.get("password", "")
    
    if not email or not password:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and password required")
    if len(password) < 8:
        from fastapi import HTTPException
        raise HTTPException(400, "Password must be at least 8 characters")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    existing = sb.table("users").select("id").eq("email", email).execute()
    if existing.data:
        from fastapi import HTTPException
        raise HTTPException(400, "Email already registered")
    
    pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    
    # Check if they have an invitation
    inv = sb.table("invitations").select("status, invite_code, access_expires_at").eq("email", email).eq("status", "approved").execute()
    tier = "invited" if inv.data else "free"
    expires = inv.data[0].get("access_expires_at") if inv.data else None
    
    result = sb.table("users").insert({
        "email": email, "name": name, "password_hash": pw_hash,
        "tier": tier, "invite_code": inv.data[0].get("invite_code") if inv.data else None,
        "access_expires_at": expires,
    }).execute()
    
    user = result.data[0] if result.data else {}
    
    import hashlib, time
    token = hashlib.sha256(f"{email}:{time.time()}:{settings.supabase_key}".encode()).hexdigest()[:48]
    
    return {"success": True, "token": token, "user": {"email": email, "name": name, "tier": tier}}


@app.post("/api/auth/login")
async def login(body: dict):
    """Login with email and password."""
    import bcrypt
    settings = get_settings()
    email = (body.get("email") or "").strip().lower()
    password = body.get("password", "")
    
    if not email or not password:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and password required")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    result = sb.table("users").select("*").eq("email", email).execute()
    if not result.data:
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid email or password")
    
    user = result.data[0]
    if not bcrypt.checkpw(password.encode(), user["password_hash"].encode()):
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid email or password")
    
    # Check access expiry
    from datetime import datetime
    if user.get("access_expires_at"):
        if datetime.fromisoformat(user["access_expires_at"].replace("Z", "+00:00")) < datetime.now(datetime.now().astimezone().tzinfo):
            sb.table("users").update({"tier": "free"}).eq("id", user["id"]).execute()
            user["tier"] = "free"
    
    sb.table("users").update({"last_login": datetime.utcnow().isoformat()}).eq("id", user["id"]).execute()
    
    import hashlib, time
    token = hashlib.sha256(f"{email}:{time.time()}:{settings.supabase_key}".encode()).hexdigest()[:48]
    
    return {"success": True, "token": token, "user": {"email": user["email"], "name": user.get("name"), "tier": user["tier"]}}



# ============================================
# API key management
# ============================================

@app.post("/api/keys/create")
async def create_api_key(body: dict):
    """Generate a new API key for a user."""
    import hashlib, secrets
    settings = get_settings()
    email = body.get("email", "")
    name = body.get("name", "Default")
    
    if not email:
        from fastapi import HTTPException
        raise HTTPException(400, "Email required")
    
    raw_key = f"dsk_{secrets.token_hex(24)}"
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    key_prefix = raw_key[:12]
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("api_keys").insert({
        "user_email": email, "key_hash": key_hash, "key_prefix": key_prefix, "name": name,
    }).execute()
    
    return {"key": raw_key, "prefix": key_prefix, "name": name, "note": "Save this key — it cannot be shown again."}


@app.get("/api/keys")
async def list_api_keys(email: str = ""):
    """List API keys for a user (shows prefix only)."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("api_keys").select("id, key_prefix, name, tier, rate_limit, requests_today, active, created_at").eq("user_email", email).execute()
    return {"keys": result.data or []}


@app.post("/api/keys/revoke")
async def revoke_api_key(body: dict):
    """Deactivate an API key."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("api_keys").update({"active": False}).eq("id", body.get("id")).execute()
    return {"success": True}


async def validate_api_key(key: str) -> dict | None:
    """Validate an API key and return user info. Returns None if invalid."""
    import hashlib
    settings = get_settings()
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("api_keys").select("*").eq("key_hash", key_hash).eq("active", True).execute()
    if not result.data:
        return None
    row = result.data[0]
    # Rate limit check (reset daily)
    from datetime import datetime, timedelta
    last_reset = datetime.fromisoformat(row["last_reset"].replace("Z", "+00:00")) if row.get("last_reset") else datetime.min
    now = datetime.utcnow()
    if (now - last_reset.replace(tzinfo=None)).days >= 1:
        sb.table("api_keys").update({"requests_today": 1, "last_reset": now.isoformat()}).eq("id", row["id"]).execute()
        return row
    if row["requests_today"] >= row["rate_limit"]:
        return None  # rate limited
    sb.table("api_keys").update({"requests_today": row["requests_today"] + 1}).eq("id", row["id"]).execute()
    return row



# ============================================
# Webhooks
# ============================================

@app.post("/api/webhooks/create")
async def create_webhook(body: dict):
    """Register a webhook URL."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("webhooks").insert({
        "user_email": body.get("email", ""),
        "url": body.get("url", ""),
        "events": body.get("events", ["scan.complete"]),
        "topic_filter": body.get("topic_filter"),
        "confidence_threshold": body.get("confidence_threshold", 0.7),
    }).execute()
    return {"success": True}


@app.get("/api/webhooks")
async def list_webhooks(email: str = ""):
    """List webhooks for a user."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    result = sb.table("webhooks").select("*").eq("user_email", email).execute()
    return {"webhooks": result.data or []}


@app.delete("/api/webhooks/{webhook_id}")
async def delete_webhook(webhook_id: str):
    """Delete a webhook."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    sb.table("webhooks").delete().eq("id", webhook_id).execute()
    return {"success": True}


async def fire_webhooks(event: str, data: dict):
    """Fire all matching webhooks for an event."""
    settings = get_settings()
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        hooks = sb.table("webhooks").select("*").eq("active", True).contains("events", [event]).execute()
        
        import httpx
        async with httpx.AsyncClient(timeout=10) as client:
            for hook in (hooks.data or []):
                topic = hook.get("topic_filter")
                if topic and topic.lower() not in str(data).lower():
                    continue
                try:
                    await client.post(hook["url"], json={"event": event, "data": data})
                except:
                    pass
    except:
        pass



# ============================================
# Dispatch cron (call weekly via external cron)
# ============================================

@app.post("/api/dispatch/cron")
async def dispatch_cron(body: dict = {}):
    """Send weekly digest to all invited users. Call via cron.org or Railway cron."""
    settings = get_settings()
    secret = body.get("secret", "")
    if secret != settings.dissekt_admin_key:
        from fastapi import HTTPException
        raise HTTPException(401, "Invalid secret")
    
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    # Get all invited users
    users = sb.table("invitations").select("email, name").eq("status", "approved").execute()
    emails = [u["email"] for u in (users.data or []) if u.get("email")]
    
    if not emails:
        return {"sent": 0, "reason": "No invited users"}
    
    # Get digest data
    digest = await weekly_digest()
    if digest["total_analyses"] == 0:
        return {"sent": 0, "reason": "No analyses this week"}
    
    techs_html = "".join(f"<li>{t['name'].replace('_', ' ')} ({t['count']}x)</li>" for t in digest.get("top_techniques", []))
    topics_html = "".join(f"<li>{t['topic']} ({t['count']} analyses)</li>" for t in digest.get("trending_topics", []))
    
    sent = 0
    import httpx
    async with httpx.AsyncClient() as client:
        for email in emails:
            try:
                await client.post("https://api.resend.com/emails",
                    headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                    json={
                        "from": "Dissekt <onboarding@resend.dev>",
                        "to": email,
                        "subject": f"Dissekt Dispatch: {digest['total_analyses']} analyses this week",
                        "html": f"""<div style="font-family:-apple-system,sans-serif;max-width:500px;margin:0 auto;">
                            <div style="background:#0d9488;padding:16px 20px;border-radius:10px 10px 0 0;"><h2 style="color:white;margin:0;">Dissekt Dispatch</h2></div>
                            <div style="background:#fff;padding:20px;border:1px solid #e5eaea;border-top:none;border-radius:0 0 10px 10px;">
                            <p>{digest['total_analyses']} analyses this week.</p>
                            <h3 style="font-size:14px;">Top techniques</h3><ul>{techs_html or '<li>None</li>'}</ul>
                            <h3 style="font-size:14px;">Trending topics</h3><ul>{topics_html or '<li>None</li>'}</ul>
                            <div style="text-align:center;margin:20px 0;"><a href="https://dissekt.info/analyze" style="background:#0d9488;color:white;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:600;">Analyze something</a></div>
                            <p style="font-size:11px;color:#aaa;text-align:center;">dissekt.info</p></div></div>"""
                    })
                sent += 1
            except:
                pass
    
    return {"sent": sent, "total_users": len(emails)}




@app.post("/api/admin/user-access")
async def set_user_access(body: dict):
    """Set/revoke per-user component access."""
    settings = get_settings()
    from supabase import create_client
    sb = create_client(settings.supabase_url, settings.supabase_key)
    
    user_id = body.get("id")
    custom_features = body.get("custom_features")  # list of feature keys or null
    custom_limits = body.get("custom_limits")  # {"brief": N, "detailed": N} or null
    
    update = {}
    if custom_features is not None:
        update["custom_features"] = custom_features
    if custom_limits is not None:
        update["custom_limits"] = custom_limits
    
    if not update:
        return {"error": "Nothing to update"}
    
    result = sb.table("invitations").update(update).eq("id", user_id).execute()
    return {"success": True}


# ─────────────────────────────────────────────────────────────
# ADMIN: Supabase Auth user management (service_role key required)
# ─────────────────────────────────────────────────────────────
def _admin_sb():
    """Supabase client with the SERVICE ROLE key (full admin access)."""
    from supabase import create_client
    return create_client(settings.supabase_url, settings.supabase_service_key)

def _check_admin(adminKey: str):
    if adminKey != settings.dissekt_admin_key:
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="Invalid admin key")

@app.get("/api/admin/users")
async def admin_list_users(adminKey: str, page: int = 1, per_page: int = 100):
    """List all Supabase Auth users."""
    _check_admin(adminKey)
    try:
        sb = _admin_sb()
        resp = sb.auth.admin.list_users(page=page, per_page=per_page)
        # resp may be a list or have .users depending on sdk version
        users = resp if isinstance(resp, list) else getattr(resp, "users", [])
        out = []
        for u in users:
            meta = getattr(u, "user_metadata", {}) or {}
            out.append({
                "id": getattr(u, "id", ""),
                "email": getattr(u, "email", ""),
                "name": meta.get("name", ""),
                "created_at": str(getattr(u, "created_at", "")),
                "last_sign_in_at": str(getattr(u, "last_sign_in_at", "") or ""),
                "banned_until": str(getattr(u, "banned_until", "") or ""),
                "confirmed": bool(getattr(u, "email_confirmed_at", None)),
            })
        return {"users": out, "count": len(out)}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"List users failed: {e}")

@app.post("/api/admin/users/delete")
async def admin_delete_user(body: dict):
    """Delete a Supabase Auth user by id."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        sb = _admin_sb()
        # Look up the user's email first so we can purge their scan metadata
        email = None
        try:
            u = sb.auth.admin.get_user_by_id(uid)
            email = getattr(getattr(u, "user", None), "email", None) or (u.get("user", {}).get("email") if isinstance(u, dict) else None)
        except Exception as e:
            logger.warning(f"[delete] could not resolve email for {uid}: {e}")
        # Delete all user-identifiable data (GDPR erasure) before removing the auth user.
        # These tables are keyed on user_email.
        purged = {}
        if email:
            for tbl in ("scans", "api_keys", "webhooks"):
                try:
                    res = sb.table(tbl).delete().eq("user_email", email).execute()
                    n = len(res.data) if getattr(res, "data", None) else 0
                    purged[tbl] = n
                    logger.info(f"[delete] purged {n} rows from {tbl} for {email}")
                except Exception as e:
                    logger.error(f"[delete] purge failed for {tbl}/{email}: {e}")
                    purged[tbl] = "error"
        sb.auth.admin.delete_user(uid)
        return {"success": True, "action": "deleted", "user_id": uid, "purged": purged}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Delete failed: {e}")

@app.post("/api/admin/users/ban")
async def admin_ban_user(body: dict):
    """Ban or unban a user. ban=True sets a long ban; ban=False lifts it."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    ban = body.get("ban", True)
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        # ban_duration: a duration string; "876000h" ~ 100 years; "none" lifts the ban
        dur = "876000h" if ban else "none"
        _admin_sb().auth.admin.update_user_by_id(uid, {"ban_duration": dur})
        return {"success": True, "action": "banned" if ban else "unbanned", "user_id": uid}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Ban failed: {e}")

@app.post("/api/admin/users/reset-password")
async def admin_reset_password(body: dict):
    """Trigger a password-reset email for a user."""
    _check_admin(body.get("adminKey", ""))
    email = body.get("email")
    if not email:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="email required")
    try:
        # generate a recovery link / send reset email
        _admin_sb().auth.admin.generate_link({"type": "recovery", "email": email})
        return {"success": True, "action": "reset_sent", "email": email}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Reset failed: {e}")

@app.post("/api/admin/users/set-limits")
async def admin_set_user_limits(body: dict):
    """Adjust a user's per-day limits. Stored in user_metadata."""
    _check_admin(body.get("adminKey", ""))
    uid = body.get("user_id")
    brief = body.get("brief_limit")
    detailed = body.get("detailed_limit")
    if not uid:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="user_id required")
    try:
        sb = _admin_sb()
        # fetch current metadata, merge limits
        u = sb.auth.admin.get_user_by_id(uid)
        user_obj = getattr(u, "user", u)
        meta = dict(getattr(user_obj, "user_metadata", {}) or {})
        if brief is not None: meta["brief_limit"] = brief
        if detailed is not None: meta["detailed_limit"] = detailed
        sb.auth.admin.update_user_by_id(uid, {"user_metadata": meta})
        return {"success": True, "action": "limits_set", "user_id": uid, "brief_limit": brief, "detailed_limit": detailed}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Set limits failed: {e}")

@app.get("/api/admin/users/activity")
async def admin_user_activity(adminKey: str, email: str):
    """View a user's scan activity. GATED by admin_can_view_activity flag (off after test period)."""
    _check_admin(adminKey)
    # Config flag: read from a simple config table; default True for now
    try:
        sb_anon = create_client_anon()
        flag = sb_anon.table("app_config").select("value").eq("key", "admin_can_view_activity").execute()
        can_view = True  # default
        if flag.data:
            can_view = str(flag.data[0]["value"]).lower() in ("true", "1", "yes")
    except Exception:
        can_view = True  # if table/flag missing, default to allowing during test
    if not can_view:
        return {"enabled": False, "message": "Activity viewing is disabled.", "scans": []}
    try:
        sb = _admin_sb()
        # scans/usage keyed by user_email (existing pattern)
        result = sb.table("scans").select("*").eq("user_email", email).order("created_at", desc=True).limit(50).execute()
        return {"enabled": True, "scans": result.data or [], "count": len(result.data or [])}
    except Exception as e:
        # scans table may not exist yet; return empty rather than erroring
        return {"enabled": True, "scans": [], "count": 0, "note": str(e)[:80]}

def create_client_anon():
    from supabase import create_client
    return create_client(settings.supabase_url, settings.supabase_key)

@app.post("/api/admin/send-message")
async def admin_send_message(body: dict):
    """Admin sends email to a user."""
    settings = get_settings()
    to_email = body.get("to")
    subject = body.get("subject", "Message from Dissekt")
    message = body.get("message", "")
    
    if not to_email or not message:
        from fastapi import HTTPException
        raise HTTPException(400, "Email and message required")
    
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post("https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {settings.resend_api_key}"},
                json={
                    "from": "Dissekt <onboarding@resend.dev>",
                    "to": to_email,
                    "subject": subject,
                    "html": f"""<div style="font-family:-apple-system,sans-serif;max-width:500px;margin:0 auto;">
                        <div style="background:#0d9488;padding:14px 20px;border-radius:10px 10px 0 0;">
                            <h2 style="color:white;margin:0;font-size:16px;">Message from Dissekt</h2>
                        </div>
                        <div style="background:#fff;padding:20px;border:1px solid #e5eaea;border-top:none;border-radius:0 0 10px 10px;">
                            <p style="font-size:14px;color:#333;line-height:1.7;">{message.replace(chr(10), '<br/>')}</p>
                            <hr style="border:none;border-top:0.5px solid #e5eaea;margin:16px 0;"/>
                            <p style="font-size:11px;color:#aaa;">This message was sent by the Dissekt team.<br/>
                            <a href="https://dissekt.info" style="color:#0d9488;">dissekt.info</a></p>
                        </div>
                    </div>"""
                })
        
        # Log the message
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        sb.table("admin_messages").insert({"to_email": to_email, "subject": subject, "body": message}).execute()
        
        return {"success": res.status_code == 200}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ============================================
# Run with: uvicorn app.main:app --reload
# ============================================
