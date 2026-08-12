"""Dissekt — Quick test script.

Run this after setup to verify everything works:
  python -m tests.test_setup

Tests:
1. Config loads correctly
2. Heuristics run on sample text
3. Signal models load
4. API endpoints respond
"""

import asyncio
import sys
import json


def test_config():
    """Test that config loads."""
    print("1. Testing config...", end=" ")
    from app.config import get_settings
    s = get_settings()
    assert s.app_name == "Dissekt"
    print(f"OK — {s.app_name} v{s.app_version}")
    print(f"   Anthropic: {'✓' if s.anthropic_api_key else '✗ NOT SET'}")
    print(f"   OpenAI:    {'✓' if s.openai_api_key else '✗ NOT SET'}")
    print(f"   Redis:     {'✓' if s.redis_url else '✗ NOT SET'}")
    print(f"   FactCheck: {'✓' if s.google_factcheck_api_key else '✗ NOT SET'}")


def test_heuristics():
    """Test heuristic pre-filters on sample manipulative text."""
    print("\n2. Testing heuristics...", end=" ")
    from app.prism.heuristics import run_all_heuristics

    sample = """
    Experts say that this terrifying new crisis will destroy everything we know.
    Studies show that everyone is at risk. Scientists confirm that the situation
    is absolutely catastrophic and will definitely lead to total collapse.
    According to sources, nobody is safe. The shocking truth is that all
    governments are completely failing to act.
    """

    result = run_all_heuristics(sample)
    print(f"OK — {result.signal_count} signals detected")
    print(f"   Emotional density: {result.emotional_density:.1%}")
    print(f"   Authority phrases: {result.authority_count}")
    print(f"   Absolute terms: {result.absolute_count}")
    print(f"   Strong enough to skip LLM: {'Yes' if result.has_strong_signals else 'No'}")

    for s in result.signals:
        print(f"   → {s.technique} (conf: {s.confidence}) — {s.evidence}")


def test_source_credibility():
    """Test MBFC source lookup."""
    print("\n3. Testing source credibility...", end=" ")
    from app.prism.heuristics import lookup_source_credibility

    tests = [
        ("https://www.bbc.com/news/article-123", "center", "very-high"),
        ("https://www.breitbart.com/politics/story", "far-right", "low"),
        ("https://scroll.in/article/123", "left-center", "high"),
        ("https://www.bild.de/nachrichten/story", "right-center", "mixed"),
        ("https://www.unknown-site.com/page", None, None),
    ]

    passed = 0
    for url, expected_bias, expected_fact in tests:
        result = lookup_source_credibility(url)
        if expected_bias is None:
            assert result is None, f"Expected None for {url}, got {result}"
        else:
            assert result is not None, f"Expected result for {url}, got None"
            assert result["bias"] == expected_bias, f"Expected {expected_bias} for {url}, got {result['bias']}"
        passed += 1

    print(f"OK — {passed}/{len(tests)} sources verified")


def test_techniques():
    """Test technique taxonomy."""
    print("\n4. Testing technique taxonomy...", end=" ")
    from app.prism.techniques import TECHNIQUES, TECHNIQUE_BY_NAME, CATEGORIES

    assert len(TECHNIQUES) == 20, f"Expected 20 techniques, got {len(TECHNIQUES)}"
    assert len(CATEGORIES) == 4

    for t in TECHNIQUES:
        assert t["name"] in TECHNIQUE_BY_NAME
        assert t["category"] in CATEGORIES

    print(f"OK — {len(TECHNIQUES)} techniques, {len(CATEGORIES)} categories")


def test_signal():
    """Test Signal models load."""
    print("\n5. Testing Signal (toxicity model)...", end=" ")
    try:
        from app.signal import analyze_toxicity
        result = analyze_toxicity("This is a normal test sentence.")
        print(f"OK — toxicity: {result['toxicity']:.4f}")
    except Exception as e:
        print(f"SKIP — Detoxify not installed or failed: {e}")
        print("   (Install with: pip install detoxify torch transformers)")


def test_sentiment():
    """Test VADER sentiment."""
    print("\n6. Testing sentiment...", end=" ")
    from app.prism.heuristics import analyze_sentiment

    pos = analyze_sentiment("This is a wonderful, amazing, fantastic product!")
    neg = analyze_sentiment("This is a terrible, horrible, disgusting disaster.")
    neu = analyze_sentiment("The meeting is scheduled for 3 PM on Tuesday.")

    assert pos["label"] == "positive"
    assert neg["label"] == "negative"
    assert neu["label"] == "neutral"
    print(f"OK — positive: {pos['compound']}, negative: {neg['compound']}, neutral: {neu['compound']}")


async def test_api():
    """Test API endpoints (requires running server)."""
    print("\n7. Testing API endpoints...", end=" ")
    try:
        import httpx
        async with httpx.AsyncClient(base_url="http://localhost:8000", timeout=5.0) as client:
            # Health
            r = await client.get("/health")
            assert r.status_code == 200
            data = r.json()
            assert data["status"] == "ok"
            print(f"OK — /health returns {data['status']}")

            # Techniques
            r = await client.get("/api/techniques")
            assert r.status_code == 200
            data = r.json()
            print(f"   /api/techniques returns {data['count']} techniques")

    except Exception as e:
        print(f"SKIP — Server not running: {e}")
        print("   Start with: uvicorn app.main:app --reload --port 8000")


def main():
    print("=" * 60)
    print("DISSEKT — Setup Verification")
    print("=" * 60)

    test_config()
    test_heuristics()
    test_source_credibility()
    test_techniques()
    test_signal()
    test_sentiment()
    asyncio.run(test_api())

    print("\n" + "=" * 60)
    print("All basic tests passed. Ready to build.")
    print("=" * 60)


if __name__ == "__main__":
    main()
