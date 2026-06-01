# Dissekt Codebase Package

**Date:** June 1, 2026
**Contents:** All files needed to complete Week 2 of the Dissekt MVP

---

## Package Contents

```
dissekt-package/
├── frontend/
│   └── concept-b-inline.sh       ← Run inside dissekt-web/ to apply the UI
│
├── backend/
│   ├── app/
│   │   ├── signal/__init__.py     ← REPLACE existing file (Detoxify fix)
│   │   ├── data/mbfc_database.json ← REPLACE existing file (231 sources)
│   │   ├── radar/__init__.py      ← NEW: RSS feed module
│   │   ├── claim_graph/__init__.py ← NEW: Qdrant vector search
│   │   └── anchor/__init__.py     ← NEW: OpenTimestamps integration
│   ├── tests/
│   │   └── test_api.py            ← NEW: 10+ pytest tests
│   └── PATCHES.py                 ← Code to add to main.py and beacon
│
└── docs/
    ├── Dissekt_Status_Report.md   ← Current project status
    ├── Dissekt_Week2_Action_Plan.md ← Full Week 2 plan with code
    └── DISSEKT_TEST_RESULTS.md    ← Week 1 test results
```

---

## How to Apply

### Step 1: Backend fixes (replace/add files)

```bash
cd /mnt/d/Startup\ Ideas/Dissekt

# Replace Signal (Detoxify fix)
cp dissekt-package/backend/app/signal/__init__.py app/signal/__init__.py

# Replace MBFC database (231 sources)
mkdir -p app/data
cp dissekt-package/backend/app/data/mbfc_database.json app/data/mbfc_database.json

# Add new modules
cp -r dissekt-package/backend/app/radar app/radar/
cp -r dissekt-package/backend/app/claim_graph app/claim_graph/
cp -r dissekt-package/backend/app/anchor app/anchor/

# Add tests
cp dissekt-package/backend/tests/test_api.py tests/test_api.py

# Install new dependencies
pip install feedparser sentence-transformers --break-system-packages
```

### Step 2: Apply patches to main.py and beacon

Open `PATCHES.py` and manually apply each patch to:
- `app/main.py` — Radar endpoint + rate limiting + CORS
- `app/beacon/__init__.py` — Playwright fallback + claim graph

### Step 3: Frontend (if not already applied)

```bash
cd dissekt-web
bash ../dissekt-package/frontend/concept-b-inline.sh
npm run dev
```

### Step 4: Test

```bash
# Backend
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd dissekt-web && npm run dev

# Tests
pytest tests/test_api.py -v --tb=short
```

---

## What's Already Working (no changes needed)

- Prism: heuristics + LLM routing (GPT-4o mini Brief / Claude Detailed)
- Trace: Google Fact Check API + SerpAPI
- Beacon: trafilatura extraction + parallel execution
- Cache: Redis deduplication
- All API keys configured
- Frontend: Concept B threat intelligence dashboard
