#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Full rename: radar→scope, signal→spectrum, trace→lens, compass→meridian, pulse→flare
# Touches: folders, imports, API routes, function names, frontend calls
set -e

echo "════════════════════════════════════════"
echo " COMPONENT RENAME — full 5-module rename"
echo "════════════════════════════════════════"
echo ""

# Safety: commit checkpoint
git add -A 2>/dev/null && git commit -m "checkpoint before component rename" 2>/dev/null || echo "(git checkpoint skipped or nothing to commit)"
echo ""

# ─────────────────────────────────────────
# STEP 1: Rename backend folders (git mv preserves history)
# ─────────────────────────────────────────
echo "STEP 1: Renaming backend folders..."
for pair in "radar:scope" "signal:spectrum" "trace:lens" "compass:meridian" "pulse:flare"; do
  old="${pair%%:*}"
  new="${pair##*:}"
  if [ -d "app/$old" ]; then
    git mv "app/$old" "app/$new" 2>/dev/null || mv "app/$old" "app/$new"
    echo "  ✅ app/$old → app/$new"
  else
    echo "  ⊘ app/$old not found (skip)"
  fi
done
# Clear stale pycache
rm -rf app/__pycache__ app/*/__pycache__ 2>/dev/null || true
echo ""

# ─────────────────────────────────────────
# STEP 2: Update Python imports + function names across all backend files
# ─────────────────────────────────────────
echo "STEP 2: Updating Python imports & function names..."
python3 << 'PYEOF'
import os, glob

# (old_module, new_module, old_func, new_func)
renames = [
    ("radar",   "scope",    "get_radar_feed",  "get_scope_feed"),
    ("signal",  "spectrum", "run_signal",      "run_spectrum"),
    ("trace",   "lens",     "run_trace",       "run_lens"),
    ("compass", "meridian", None,              None),
    ("pulse",   "flare",    None,              None),
]

py_files = []
for root, dirs, files in os.walk("app"):
    dirs[:] = [d for d in dirs if d != "__pycache__"]
    for f in files:
        if f.endswith(".py"):
            py_files.append(os.path.join(root, f))

changed = 0
for path in py_files:
    c = open(path).read()
    orig = c
    for old_mod, new_mod, old_fn, new_fn in renames:
        # module references in imports: "from app.radar import" / "import app.radar"
        c = c.replace(f"from app.{old_mod} import", f"from app.{new_mod} import")
        c = c.replace(f"import app.{old_mod}", f"import app.{new_mod}")
        c = c.replace(f"app.{old_mod}.", f"app.{new_mod}.")
        # function names
        if old_fn and new_fn:
            c = c.replace(old_fn, new_fn)
    if c != orig:
        open(path, "w").write(c)
        changed += 1
        print(f"  ✅ {path}")

print(f"  ({changed} Python files updated)")
PYEOF
echo ""

# ─────────────────────────────────────────
# STEP 3: Update API route /api/radar → /api/scope in main.py
# ─────────────────────────────────────────
echo "STEP 3: Updating API routes..."
python3 << 'PYEOF'
c = open("app/main.py").read()
orig = c
c = c.replace('"/api/radar"', '"/api/scope"')
c = c.replace("'/api/radar'", "'/api/scope'")
if c != orig:
    open("app/main.py", "w").write(c)
    print("  ✅ /api/radar → /api/scope in main.py")
else:
    print("  ⊘ no /api/radar route found in main.py")
PYEOF
echo ""

# ─────────────────────────────────────────
# STEP 4: Update frontend API calls /api/radar → /api/scope
# ─────────────────────────────────────────
echo "STEP 4: Updating frontend API calls..."
FE_CHANGED=0
while IFS= read -r f; do
  if grep -q "/api/radar" "$f" 2>/dev/null; then
    sed -i 's|/api/radar|/api/scope|g' "$f"
    echo "  ✅ $(basename $f)"
    FE_CHANGED=$((FE_CHANGED+1))
  fi
done < <(find dissekt-web/src -name "*.tsx" -o -name "*.ts")
echo "  ($FE_CHANGED frontend files updated)"
echo ""

# ─────────────────────────────────────────
# STEP 5: Verify everything parses
# ─────────────────────────────────────────
echo "STEP 5: Verifying Python parses..."
ALL_OK=1
for f in app/main.py app/beacon/__init__.py app/scope/__init__.py app/spectrum/__init__.py app/lens/__init__.py app/meridian/__init__.py app/flare/__init__.py; do
  if [ -f "$f" ]; then
    if python3 -c "import ast; ast.parse(open('$f').read())" 2>/dev/null; then
      echo "  ✅ $f"
    else
      echo "  ❌ $f FAILED TO PARSE"
      ALL_OK=0
    fi
  fi
done
echo ""

# ─────────────────────────────────────────
# STEP 6: Check for any leftover old references
# ─────────────────────────────────────────
echo "STEP 6: Checking for leftover old references..."
LEFTOVER=$(grep -rn "app\.radar\|app\.signal\|app\.trace\|app\.compass\|app\.pulse\|from app\.radar\|from app\.signal\|from app\.trace\|from app\.compass\|from app\.pulse\|get_radar_feed\|run_signal\|run_trace\|/api/radar" app/ dissekt-web/src/ 2>/dev/null | grep -v "__pycache__" || true)
if [ -z "$LEFTOVER" ]; then
  echo "  ✅ No leftover old references"
else
  echo "  ⚠️ LEFTOVERS FOUND:"
  echo "$LEFTOVER"
fi
echo ""

if [ "$ALL_OK" = "1" ]; then
  echo "════════════════════════════════════════"
  echo " ✅ RENAME COMPLETE"
  echo "════════════════════════════════════════"
  echo "Next:"
  echo "  1. Restart uvicorn (Ctrl+C, re-run)"
  echo "  2. cd dissekt-web && rm -rf .next && npm run build"
  echo "  3. Test: scan something, check Observatory/Scope feed loads"
else
  echo "⚠️ Some files failed to parse — review above before restarting."
fi
