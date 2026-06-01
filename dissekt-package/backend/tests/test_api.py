"""Dissekt API integration tests.

Run with: pytest tests/test_api.py -v --tb=short
Requires: backend running at localhost:8000
"""
import pytest
import httpx

BASE = "http://localhost:8000"


@pytest.fixture
def client():
    return httpx.Client(base_url=BASE, timeout=60)


class TestHealth:
    def test_health_returns_ok(self, client):
        r = client.get("/health")
        assert r.status_code == 200
        data = r.json()
        assert data["status"] == "ok"


class TestScanText:
    def test_manipulative_text_finds_techniques(self, client):
        r = client.post("/api/scan", json={
            "content": "Experts say this shocking crisis will destroy everyone. Studies confirm nobody is safe.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["prism"]["techniques"]) >= 1
        assert data["prism"]["model_used"] in ("gpt-4o-mini", "claude-sonnet-4", "heuristics_only")

    def test_clean_text_few_techniques(self, client):
        r = client.post("/api/scan", json={
            "content": "The municipal water treatment facility completed its annual infrastructure assessment on Tuesday, finding that 94 percent of filtration systems met operational benchmarks.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        high_conf = [t for t in data["prism"]["techniques"] if t["confidence"] > 0.8]
        assert len(high_conf) <= 1

    def test_empty_input_returns_422(self, client):
        r = client.post("/api/scan", json={"content": "", "mode": "brief"})
        assert r.status_code == 422

    def test_short_input_returns_400(self, client):
        r = client.post("/api/scan", json={"content": "Hello", "mode": "brief"})
        assert r.status_code in (400, 422)

    def test_heuristic_only_extreme_text(self, client):
        r = client.post("/api/scan", json={
            "content": "SHOCKING: Experts say this absolutely terrifying crisis will definitely destroy everyone. According to scientists, nobody is safe. Studies confirm everything is completely doomed. Everyone knows the government always fails. Researchers warn this devastating catastrophe threatens all of humanity.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["prism"]["heuristic_only"] == True
        assert data["prism"]["model_used"] == "heuristics_only"

    def test_toxic_text_detoxify_works(self, client):
        r = client.post("/api/scan", json={
            "content": "You are all disgusting idiots who deserve to suffer. Every single one of you pathetic losers.",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert data["signal"]["toxicity_score"] > 0.5
        assert len(data["signal"]["toxicity_labels"]) >= 5


class TestScanURL:
    def test_bbc_url_extracts(self, client):
        r = client.post("/api/scan", json={
            "content": "https://www.bbc.com/news",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["extracted_text"]) > 100

    def test_nonexistent_url_returns_error(self, client):
        r = client.post("/api/scan", json={
            "content": "https://www.thissitedoesnotexist12345.com/article",
            "mode": "brief"
        })
        assert r.status_code in (400, 422)


class TestSignal:
    def test_mbfc_loaded(self):
        from app.signal import MBFC_DATABASE
        assert len(MBFC_DATABASE) >= 200
        assert MBFC_DATABASE["foxnews.com"]["bias"] == "right"
        assert MBFC_DATABASE["bbc.com"]["factuality"] == "high"


class TestTrace:
    def test_covid_microchips_finds_factchecks(self, client):
        r = client.post("/api/scan", json={
            "content": "COVID-19 vaccines contain microchips for tracking people",
            "mode": "brief"
        })
        assert r.status_code == 200
        data = r.json()
        assert len(data["trace"]["fact_checks"]) >= 1
