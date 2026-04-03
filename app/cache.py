"""Dissekt Cache — Redis-based analysis deduplication.

Content hash → cached analysis result.
Brief Mode: 24hr TTL. Detailed Mode: 72hr TTL.
Reduces LLM API calls by 60-80%.
"""

import json
import logging
import redis.asyncio as redis
from app.config import get_settings

logger = logging.getLogger("dissekt.cache")

_redis_client = None


async def _get_redis():
    """Get or create Redis connection."""
    global _redis_client
    settings = get_settings()

    if not settings.redis_url:
        return None

    if _redis_client is None:
        try:
            _redis_client = redis.from_url(
                settings.redis_url,
                decode_responses=True,
                socket_timeout=5,
            )
            await _redis_client.ping()
            logger.info("Redis connected")
        except Exception as e:
            logger.warning(f"Redis connection failed (caching disabled): {e}")
            _redis_client = "disabled"
            return None

    return _redis_client if _redis_client != "disabled" else None


async def get_cached(content_hash: str, mode: str) -> dict | None:
    """Look up cached analysis by content hash + mode."""
    client = await _get_redis()
    if not client:
        return None

    key = f"dissekt:{mode}:{content_hash}"
    try:
        data = await client.get(key)
        if data:
            logger.debug(f"Cache HIT: {key}")
            return json.loads(data)
        return None
    except Exception as e:
        logger.warning(f"Cache read error: {e}")
        return None


async def set_cached(content_hash: str, mode: str, result: dict) -> None:
    """Store analysis result in cache."""
    client = await _get_redis()
    if not client:
        return

    settings = get_settings()
    key = f"dissekt:{mode}:{content_hash}"
    ttl = settings.redis_cache_ttl_brief if mode == "brief" else settings.redis_cache_ttl_detailed

    try:
        await client.setex(key, ttl, json.dumps(result, default=str))
        logger.debug(f"Cache SET: {key} (TTL: {ttl}s)")
    except Exception as e:
        logger.warning(f"Cache write error: {e}")
