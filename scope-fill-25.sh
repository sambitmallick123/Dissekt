#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Tiered fill to 25: loosen per-source cap first (recency), then widen time. Raise pool size.
set -e

python3 << 'PYEOF'
content = open('app/scope/__init__.py').read()

# 1. Default limit 20 → 25
content = content.replace(
    'async def get_scope_feed(market: str = "global", limit: int = 20) -> list[dict]:',
    'async def get_scope_feed(market: str = "global", limit: int = 25) -> list[dict]:'
)

# 2. Raise per-feed parse 8 → 15 (bigger pool before filtering)
content = content.replace(
    'for entry in d.entries[:8]:',
    'for entry in d.entries[:15]:'
)

# 3. Replace the whole 24h-window + fixed-cap block with the tiered fill
old_block = '''    # ── Rolling 24h window: keep only items published in the last 24 hours ──
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    recent = [it for it in items if it.get("published", "") and it["published"] >= cutoff]
    # Fallback: if too few in the last 24h, relax to all items (most-recent first)
    if len(recent) < min(limit, 8):
        recent = items
    # ── Sampling: shuffle, then cap per source so no single feed dominates ──
    random.shuffle(recent)
    MAX_PER_SOURCE = 3
    capped, per_source = [], {}
    for it in recent:
        src = it.get("source", "")
        if per_source.get(src, 0) < MAX_PER_SOURCE:
            capped.append(it)
            per_source[src] = per_source.get(src, 0) + 1
        if len(capped) >= limit:
            break
    # Within the capped, sampled set, present newest first
    capped.sort(key=lambda x: x.get("published", ""), reverse=True)
    return capped[:limit]'''

new_block = '''    # ── Tiered fill toward `limit` items, preferring recency then diversity ──
    now = datetime.now(timezone.utc)

    def _within(hours):
        cut = (now - timedelta(hours=hours)).isoformat()
        return [it for it in items if it.get("published", "") and it["published"] >= cut]

    def _sample(pool, cap):
        pool = list(pool)
        random.shuffle(pool)
        out, per = [], {}
        for it in pool:
            src = it.get("source", "")
            if per.get(src, 0) < cap:
                out.append(it)
                per[src] = per.get(src, 0) + 1
            if len(out) >= limit:
                break
        return out

    def _newest_first(lst):
        return sorted(lst, key=lambda x: x.get("published", ""), reverse=True)

    chosen = []
    # Stage 1: stay within 24h, progressively loosen the per-source cap (recency-first)
    pool_24 = _within(24)
    for cap in (3, 5, 8, 9999):
        got = _sample(pool_24, cap)
        if len(got) >= limit:
            chosen = got
            break
        chosen = got  # keep best-so-far
    # Stage 2: still short → widen the time window, generous cap
    if len(chosen) < limit:
        for hours in (48, 72, 168):  # 2d, 3d, 7d
            got = _sample(_within(hours), 9999)
            if len(got) >= limit:
                chosen = got
                break
            if len(got) > len(chosen):
                chosen = got
    # Final fallback: everything we have
    if len(chosen) < limit:
        got = _sample(items, 9999)
        if len(got) > len(chosen):
            chosen = got

    return _newest_first(chosen)[:limit]'''

content = content.replace(old_block, new_block)
open('app/scope/__init__.py', 'w').write(content)
print('✅ Tiered fill-to-25 applied (cap-loosen → time-widen), pool raised to 15/feed')
PYEOF

python3 -c "import ast; ast.parse(open('app/scope/__init__.py').read()); print('✅ scope parses')"

# Update sample_items helper default too (used by endpoint cached path)
python3 << 'PYEOF'
content = open('app/scope/__init__.py').read()
content = content.replace(
    'def sample_items(items: list[dict], limit: int = 20, max_per_source: int = 3)',
    'def sample_items(items: list[dict], limit: int = 25, max_per_source: int = 3)'
)
open('app/scope/__init__.py', 'w').write(content)
print('✅ sample_items default → 25')
PYEOF

# Update endpoint defaults limit 20 → 25
python3 << 'PYEOF'
content = open('app/main.py').read()
content = content.replace(
    'async def scope_feed(market: str = "global", limit: int = 20, refresh: bool = False):',
    'async def scope_feed(market: str = "global", limit: int = 25, refresh: bool = False):'
)
# The internal fetch "fetch more, cache all" — bump to 120 for a healthy pool
content = content.replace(
    'items = await get_scope_feed(market, limit=100)  # fetch more, cache all',
    'items = await get_scope_feed(market, limit=120)  # fetch more, cache all'
)
open('app/main.py', 'w').write(content)
print('✅ endpoint limit → 25, pool → 120')
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ main.py parses')"

echo ""
echo "═══ TEST: each tab should reach 25 (or close) ═══"
python3 << 'PYEOF'
import asyncio
from app.scope import get_scope_feed
from collections import Counter
for mkt in ['global', 'india', 'us', 'germany', 'uk']:
    items = asyncio.run(get_scope_feed(market=mkt, limit=25))
    srcs = len(set(it['source'] for it in items))
    print(f'{mkt:8} → {len(items):>2} items, {srcs} sources')
PYEOF
