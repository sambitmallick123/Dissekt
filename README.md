# DISSEKT

**Dissect manipulative content. Trace claims to their source. Export the evidence.**

DISSEKT is an AI-assisted investigation platform for analysing online content. It combines deterministic NLP heuristics, LLM-based analysis, source tracing, fact-check lookup, and structured evaluation to help users examine *how* a piece of content is written, *where* its claims may originate, and *what evidence* is available around it.

The project is designed as an engineering and research system rather than a single-prompt LLM demo: model outputs are combined with deterministic signals, explicit source evidence, and an evaluation workflow for identifying failure modes.

**Live application:** https://www.dissekt.info  
**Repository:** https://github.com/sambitmallick123/Dissekt

---

## Why DISSEKT?

AI systems are increasingly used to summarize, rank, and interpret information, but fluent output is not the same as reliable evidence.

DISSEKT explores a more inspectable workflow:

1. acquire and normalize content,
2. run low-cost deterministic analysis,
3. use LLMs for higher-level contextual analysis,
4. search for source and fact-check evidence,
5. combine independent signals into a structured result,
6. evaluate where the system succeeds and where it fails.

The goal is not to declare whether an article is simply "true" or "false". Instead, DISSEKT exposes evidence and analytical signals that can support a more informed assessment.

---

## What it does

Given a URL or text, DISSEKT can produce a structured analysis including:

- manipulation and rhetorical-technique signals,
- heuristic linguistic indicators,
- LLM-assisted contextual analysis,
- source and origin tracing,
- existing fact-check evidence,
- source-bias and toxicity signals where available,
- structured scores and explanations,
- results suitable for web and API consumption.

The system supports a web interface and is developed alongside browser-facing tooling so analysis can be brought closer to the content being inspected.

---

## Architecture

```text
                         ┌─────────────────────┐
                         │   URL / Raw Text    │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       Beacon        │
                         │    Orchestration    │
                         └──────┬─────┬───────┘
                                │     │
                 ┌──────────────┘     └──────────────┐
                 ▼                                   ▼
        ┌─────────────────┐                 ┌─────────────────┐
        │      Prism      │                 │      Trace      │
        │ Content analysis│                 │ Source tracing  │
        ├─────────────────┤                 ├─────────────────┤
        │ NLP heuristics  │                 │ Fact-check APIs │
        │ LLM analysis    │                 │ Web search      │
        │ Techniques      │                 │ Origin evidence │
        └────────┬────────┘                 └────────┬────────┘
                 │                                   │
                 └──────────────┬────────────────────┘
                                ▼
                       ┌─────────────────┐
                       │      Signal     │
                       │ Extra indicators│
                       ├─────────────────┤
                       │ Bias metadata   │
                       │ Toxicity        │
                       │ Sentiment       │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Structured API  │
                       │     result      │
                       └────────┬────────┘
                                │
                     ┌──────────┴──────────┐
                     ▼                     ▼
              ┌─────────────┐       ┌─────────────┐
              │ Web client  │       │ Evaluation  │
              │ / extension │       │  workflow   │
              └─────────────┘       └─────────────┘
```

### Beacon — orchestration

Coordinates content acquisition and the analysis pipeline. It brings together independent modules rather than delegating the full task to a single model call.

### Prism — manipulation analysis

Combines deterministic heuristics with LLM-based contextual analysis. Heuristics provide inexpensive, reproducible signals before an LLM is used for higher-level interpretation.

### Trace — source and evidence discovery

Looks for existing fact checks and source/origin evidence using external search and fact-check services.

### Signal — complementary indicators

Adds supporting signals such as source-bias metadata, toxicity, and sentiment where they are useful and available.

---

## Engineering principles

DISSEKT is built around a few principles that are especially important for LLM applications:

### Hybrid before model-only

Tasks that can be measured deterministically should not automatically become LLM calls. Statistical and linguistic heuristics provide reproducible signals, reduce model dependence, and can lower inference cost.

### Structured outputs

Model responses are converted into typed application data rather than treated as free-form prose. This makes downstream API use, validation, evaluation, and UI rendering more reliable.

### Evidence over opaque scores

A numerical score without traceable evidence is of limited value. The system aims to surface the signals and sources behind an analysis.

### Evaluate the evaluator

DISSEKT includes an evaluation corpus and documented failure analysis. The purpose is not only to measure system performance, but also to identify cases where the scoring framework itself produces misleading results.

### Production concerns are part of the system

Caching, asynchronous processing, API boundaries, containerization, tests, deployment, and observability are treated as part of the product rather than as post-prototype additions.

---

## Evaluation

The [`eval/`](./eval) directory contains evaluation material used to investigate system behaviour and failure modes.

Evaluation work includes examining issues such as:

- genre-dependent attribution signals,
- misleading scores for satire,
- weak genre detection,
- score compression,
- disagreement between heuristic and LLM-based signals.

These findings are intentionally documented. For an analytical AI system, knowing *where a metric fails* is as important as reporting where it performs well.

The long-term direction is to expand this into a regression-oriented benchmark suite covering:

- multilingual content,
- adversarial examples,
- satire and opinion,
- source-quality variation,
- calibration and confidence,
- model/version regressions.

---

## Tech stack

### Backend

- Python
- FastAPI
- Pydantic
- asynchronous APIs and services

### AI / NLP

- Anthropic Claude
- OpenAI models
- deterministic linguistic heuristics
- sentiment / toxicity analysis
- source and fact-check retrieval

### Infrastructure

- Docker
- Redis-compatible caching
- Fly.io deployment
- GitHub Actions
- environment-based configuration

### Quality

- pytest
- integration tests
- evaluation corpus
- documented failure analysis

---

## API

Core endpoints include:

```http
GET  /health
POST /api/scan
GET  /api/techniques
```

Example request:

```bash
curl -X POST http://localhost:8000/api/scan \
  -H "Content-Type: application/json" \
  -d '{
    "content": "https://example.com/article",
    "mode": "brief"
  }'
```

The exact response schema may evolve as the analysis pipeline develops. Refer to the FastAPI/OpenAPI documentation of a running instance for the current schema.

---

## Run locally

### 1. Clone the repository

```bash
git clone https://github.com/sambitmallick123/Dissekt.git
cd Dissekt
```

### 2. Create a virtual environment

Linux / macOS:

```bash
python -m venv venv
source venv/bin/activate
```

Windows:

```powershell
python -m venv venv
venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure the environment

```bash
cp .env.example .env
```

Add the credentials for the services you intend to use. The application is designed so that some integrations are optional or replaceable.

Typical integrations include:

| Service | Purpose |
|---|---|
| Anthropic | LLM analysis |
| OpenAI | Alternative / complementary model provider |
| Google Fact Check Tools API | Existing fact-check retrieval |
| Redis / Upstash | Caching |
| SerpAPI or Brave Search | Web/source search |

**Never commit API keys or secrets to the repository.**

### 5. Start the API

```bash
uvicorn app.main:app --reload --port 8000
```

### 6. Verify the service

```bash
curl http://localhost:8000/health
```

FastAPI's interactive API documentation is normally available at:

```text
http://localhost:8000/docs
```

---

## Testing

Run the test suite with:

```bash
pytest
```

The repository contains integration-level coverage for application/API behaviour.

A current engineering priority is to strengthen the test pyramid further with:

- smaller deterministic unit tests,
- API contract tests,
- mocked external-provider tests,
- regression tests against the evaluation corpus,
- automated test execution in CI before deployment.

---

## Deployment

DISSEKT is containerized with Docker and can be deployed to a container platform such as Fly.io.

Build locally:

```bash
docker build -t dissekt .
```

Run:

```bash
docker run --env-file .env -p 8000:8000 dissekt
```

For production deployments, configure secrets through the deployment platform rather than baking them into the image.

The repository also contains GitHub Actions automation for deployment.

---

## Project structure

The repository continues to evolve, but the main areas are conceptually organized as follows:

```text
Dissekt/
├── app/                    # FastAPI backend
│   ├── main.py             # Application / API entry point
│   ├── config.py           # Runtime configuration
│   ├── models.py           # Typed API/domain models
│   ├── beacon/             # Analysis orchestration
│   ├── prism/              # Manipulation / NLP / LLM analysis
│   ├── trace/              # Source and fact-check tracing
│   └── signal/             # Supporting analytical signals
│
├── web/                    # Web-facing client
├── extension/              # Browser-facing tooling
├── eval/                   # Evaluation corpus, results and findings
├── tests/                  # Automated tests
├── docs/                   # Project documentation
├── .github/workflows/      # CI/CD automation
├── Dockerfile
├── requirements.txt
└── README.md
```

---

## Known limitations

DISSEKT is an experimental analytical system, not an automated arbiter of truth.

Important limitations include:

- LLM outputs can be incorrect or unstable.
- Manipulation signals can depend heavily on genre and context.
- Satire, opinion, advocacy, and rhetorical writing can confuse simple scoring systems.
- Source-bias databases and fact-check indexes have incomplete coverage.
- Search results vary over time and by provider.
- A high or low score should not be interpreted as a factual verdict.
- Automated analysis should complement, not replace, human judgment.

These limitations are part of the reason the project maintains explicit evaluation and failure-analysis work.

---

## Roadmap

Current areas of improvement include:

- [ ] decompose the application layer into smaller domain-oriented routers and services
- [ ] expand deterministic unit and API contract testing
- [ ] run tests automatically in CI before production deployment
- [ ] build regression evaluation across model and prompt versions
- [ ] expand multilingual and adversarial evaluation sets
- [ ] improve confidence calibration
- [ ] strengthen end-to-end provenance for sources, prompts, models and intermediate decisions
- [ ] improve observability of latency, failures and external-provider behaviour
- [ ] document public APIs and architectural decisions in greater detail

---

## Responsible use

DISSEKT analyses language and publicly available evidence. Its outputs should be interpreted as analytical signals, not definitive judgments about an author, publication, or claim.

When using the project:

- inspect the evidence behind a result,
- verify important claims independently,
- account for genre and context,
- avoid treating model-generated explanations as ground truth,
- use human review for consequential decisions.

---

## Contributing

Contributions, bug reports, evaluation examples, and discussions about methodology are welcome.

If you are proposing a change to an analytical metric or LLM workflow, please include:

1. the behaviour you want to improve,
2. representative examples,
3. expected behaviour,
4. any new failure modes or trade-offs,
5. tests or evaluation cases where practical.

This keeps changes measurable rather than relying only on subjective impressions.

---

## Author

**Sambit Mallick**  
AI Engineer · LLM / NLP · Production AI Systems

- GitHub: https://github.com/sambitmallick123
- LinkedIn: https://www.linkedin.com/in/sambit-mallick-87251019/
- Project: https://www.dissekt.info

---

## License

The repository is publicly accessible, but an explicit open-source license should be added before describing the project as open source.

If the intention is to make DISSEKT open source, add a standard license such as **Apache-2.0** or **MIT** in a root-level `LICENSE` file and update this section accordingly.
