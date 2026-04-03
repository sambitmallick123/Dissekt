# DISSEKT

**Dissect manipulative content. Trace claims to their source. Export the evidence.**

A web-based investigation tool for journalists. Paste any URL or text → get a structured analysis of manipulation techniques, existing fact-checks, source origins, and bias scores.

## Quick Start

```bash
# 1. Clone and enter
git clone https://github.com/YOUR_USERNAME/dissekt.git
cd dissekt

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# Edit .env with your API keys (see below)

# 5. Run locally
uvicorn app.main:app --reload --port 8000

# 6. Test
curl http://localhost:8000/health
```

## API Keys Required

| Service | Where to get | Cost | Priority |
|---------|-------------|------|----------|
| Anthropic (Claude) | console.anthropic.com | ~$3/1M in tokens | Required |
| OpenAI (GPT-4o mini) | platform.openai.com | ~$0.15/1M in tokens | Recommended |
| Google Fact Check | console.cloud.google.com (enable Fact Check API) | Free (10K/day) | Required |
| Upstash Redis | upstash.com | Free tier | Recommended |
| SerpAPI | serpapi.com | $50/mo for 5000 searches | Optional (can use Brave) |
| Brave Search | api.search.brave.com | Free (2K/mo) | Alternative to SerpAPI |

## API Endpoints

```
GET  /health            → Service status + configured APIs
POST /api/scan          → Main analysis (body: {"content": "url or text", "mode": "brief"})
GET  /api/techniques    → List all 20 manipulation techniques
```

## Architecture

```
User → Beacon (orchestrator)
         ├── Prism (manipulation analysis)
         │    ├── Heuristic pre-filters (7 models, €0)
         │    └── LLM (Claude / GPT-4o mini)
         ├── Trace (source finder)
         │    ├── Google Fact Check API
         │    └── Web search (SerpAPI / Brave)
         └── Signal (bias + toxicity)
              ├── Detoxify (self-hosted)
              ├── MBFC database (6K+ sources)
              └── VADER sentiment
```

## Deploy to Railway

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and init
railway login
railway init

# Add environment variables
railway variables set ANTHROPIC_API_KEY=sk-ant-xxxxx
railway variables set OPENAI_API_KEY=sk-xxxxx
# ... add all variables from .env.example

# Deploy
railway up
```

## Project Structure

```
dissekt/
├── app/
│   ├── main.py              # FastAPI app + endpoints
│   ├── config.py            # Environment settings
│   ├── models.py            # Pydantic request/response models
│   ├── cache.py             # Redis caching
│   ├── prism/
│   │   ├── techniques.py    # 20 manipulation techniques taxonomy
│   │   ├── heuristics.py    # 7 statistical pre-filters (€0)
│   │   └── llm.py           # Claude + GPT-4o mini integration
│   ├── trace/
│   │   └── __init__.py      # Fact Check API + origin tracing
│   ├── signal/
│   │   └── __init__.py      # Detoxify + MBFC + VADER
│   └── beacon/
│       └── __init__.py      # URL/text scanner orchestrator
├── requirements.txt
├── Dockerfile
├── railway.toml
├── .env.example
└── README.md
```

## License

Proprietary — Dissekt © 2026
