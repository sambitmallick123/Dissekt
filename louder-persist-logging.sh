#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Make persist logging unambiguous: log entry, skip-reason, success, and failure
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

old = '''def _persist_scan(email: str, mode: str, result) -> None:
    """Persist scan METADATA for members only (no raw text). Best-effort."""
    if not email:
        return  # free/anonymous -> not stored (member-only)'''

new = '''def _persist_scan(email: str, mode: str, result) -> None:
    """Persist scan METADATA for members only (no raw text). Best-effort."""
    logger.info(f"[persist] called with email={email!r} mode={mode}")
    if not email:
        logger.info("[persist] SKIPPED — no email (free/anonymous)")
        return  # free/anonymous -> not stored (member-only)'''

c = c.replace(old, new)

# Add a success log after the insert
old_insert = '''            "entities": [],
        }).execute()
    except Exception as e:
        logger.warning(f"Scan persist failed (non-fatal): {e}")'''
new_insert = '''            "entities": [],
        }).execute()
        logger.info(f"[persist] ✓ saved scan for {email}")
    except Exception as e:
        logger.error(f"[persist] ✗ FAILED for {email}: {e}")'''
c = c.replace(old_insert, new_insert)

open('app/main.py','w').write(c)
print("✅ persist logging is now loud (info on entry/skip/success, error on fail)")
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"

echo ""
echo "Verify:"
grep -n "\[persist\]" app/main.py

echo ""
echo "Commit + push to deploy:"
echo "  git add app/main.py"
echo "  git commit -m 'debug: loud persist logging'"
echo "  git push"
