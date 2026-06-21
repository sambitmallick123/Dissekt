#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Fix telegram bot: (1) image crash, (2) score default, (3) add 10/day per-user rate limit
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

# ── FIX 1: the crash — image=request.image -> image=None ──
if "image=request.image" in c:
    c = c.replace(
        "result = await scan(content=text, mode=\"brief\", image=request.image)",
        "result = await scan(content=text, mode=\"brief\", image=None)"
    )
    print("✅ Fix 1: image crash fixed (request.image -> None)")
else:
    print("⚠️ Fix 1: image=request.image not found (already fixed?)")

# ── FIX 2 + RATE LIMIT: insert a daily per-user cap before the 'Analyzing' message ──
# Anchor: the analyzing message send.
anchor = '''    # Send "analyzing" message
    await bot.send_message(chat_id=chat_id, text="🔍 Analyzing... This takes 3-10 seconds.", parse_mode=ParseMode.HTML)'''

ratelimit = '''    # ── Per-user daily rate limit (10/day) ──
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
                    text="🚦 You've reached today's limit of 10 analyses. It resets at 00:00 UTC.\\n\\nFor unlimited use, try the web app at dissekt.info",
                    parse_mode=ParseMode.HTML,
                )
                return {"status": "ok"}
    except Exception as e:
        logger.warning(f"Telegram rate-limit check failed (allowing through): {e}")

    # Send "analyzing" message
    await bot.send_message(chat_id=chat_id, text="🔍 Analyzing... This takes 3-10 seconds.", parse_mode=ParseMode.HTML)'''

if anchor in c:
    c = c.replace(anchor, ratelimit)
    print("✅ Rate limit: 10/day per Telegram user (Redis, daily expiry)")
else:
    print("⚠️ Rate limit anchor not found")

open('app/main.py','w').write(c)
PYEOF

# ── FIX 2b: score default in the bot module (50 -> 0.5, it's a 0-1 scale) ──
python3 << 'PYEOF'
c = open('app/telegram_bot/__init__.py').read()
if 'scoring.get("clarity_score", 50)' in c:
    c = c.replace('scoring.get("clarity_score", 50)', 'scoring.get("clarity_score", 0.5)')
    print("✅ Fix 2: score default 50 -> 0.5 (0-1 scale)")
else:
    print("⚠️ Fix 2: score default not found")
open('app/telegram_bot/__init__.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ main.py parses')"
python3 -c "import app.main; print('✅ imports cleanly')" 2>&1 | grep -v pkg_resources | grep -v UserWarning | tail -1

echo ""
echo "Verify:"
grep -n "image=None\|tg:rl:\|reached today's limit\|clarity_score., 0.5" app/main.py app/telegram_bot/__init__.py | head

echo ""
echo "Commit + push:"
echo "  git add app/main.py app/telegram_bot/__init__.py && git commit -m 'fix: telegram bot image crash + 10/day rate limit' && git push"
