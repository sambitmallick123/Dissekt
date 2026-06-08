"""Dissekt — Prism LLM integration.

Multi-model architecture:
- Claude Sonnet 4: Primary reasoning engine (Detailed Mode)
- GPT-4o mini: Fast, cheap (Brief Mode)
- Model router selects based on mode + content complexity
"""

import json
import logging
from anthropic import AsyncAnthropic
from openai import AsyncOpenAI
from app.config import get_settings
from app.prism.techniques import TECHNIQUES, TECHNIQUE_NAMES
from app.prism.heuristics import HeuristicResult

logger = logging.getLogger("dissekt.prism.llm")

# ============================================
# System prompts
# ============================================

SYSTEM_PROMPT_BRIEF = """You are Dissekt's analysis engine. You identify manipulation techniques in text.

RULES:
1. NEVER say "true" or "false." You identify techniques, not truth.
2. Output a 2-3 sentence analysis identifying the PRIMARY technique used.
3. Be specific: name the technique, cite the evidence from the text, explain briefly.
4. If no manipulation technique is detected, say "No obvious manipulation techniques detected in this text."

AVAILABLE TECHNIQUES:
{techniques}

OUTPUT FORMAT (JSON):
{{
  "brief": "2-3 sentence analysis",
  "techniques": [
    {{
      "name": "technique_name",
      "confidence": 0.0-1.0,
      "explanation": "Why this technique was identified",
      "evidence": "Specific text that triggered detection"
    }}
  ]
}}

Respond with ONLY valid JSON. No markdown, no code fences."""

SYSTEM_PROMPT_DETAILED = """You are Dissekt's analysis engine. You dissect manipulative content by identifying specific techniques used, explaining WHY they are manipulative, and providing counter-evidence or context.

CRITICAL RULES:
1. NEVER declare content "true" or "false." You explain HOW it's constructed, not WHAT to believe.
2. Identify ALL manipulation techniques present, not just the primary one.
3. For each technique, provide: the technique name, confidence (0.0-1.0), a clear explanation of why this technique applies, and the specific text evidence.
4. Include a "context" field with what information is missing or what counter-evidence exists.
5. Be thorough but concise. Journalists will use this analysis in their work.

AVAILABLE TECHNIQUES:
{techniques}

HEURISTIC PRE-ANALYSIS (from statistical models — use as additional evidence):
{heuristic_context}

OUTPUT FORMAT (JSON):
{{
  "brief": "2-3 sentence summary of the analysis",
  "detailed": "Full 4-8 paragraph analysis explaining each technique found, the evidence, and missing context",
  "techniques": [
    {{
      "name": "technique_name",
      "confidence": 0.0-1.0,
      "explanation": "Why this technique was identified",
      "evidence": "Specific text that triggered detection"
    }}
  ],
  "missing_context": "What important context or counter-evidence is absent from this content",
  "source_assessment": "Brief assessment of the source's credibility if identifiable"
}}

Respond with ONLY valid JSON. No markdown, no code fences."""


def _format_techniques() -> str:
    """Format technique list for the system prompt."""
    lines = []
    for t in TECHNIQUES:
        lines.append(f"- {t['name']}: {t['description']}")
    return "\n".join(lines)


def _format_heuristic_context(heuristics: HeuristicResult) -> str:
    """Format heuristic results as context for the LLM."""
    if not heuristics.signals:
        return "No strong heuristic signals detected."

    lines = ["Statistical pre-analysis found:"]
    for s in heuristics.signals:
        lines.append(f"- {s.technique} (confidence: {s.confidence}): {s.evidence}")

    if heuristics.source_bias:
        lines.append(f"- Source bias: {heuristics.source_bias}, factuality: {heuristics.source_factuality}")

    return "\n".join(lines)


# ============================================
# Claude (Anthropic) — Primary for Detailed
# ============================================

async def analyze_with_claude(
    text: str,
    mode: str,
    heuristics: HeuristicResult,
) -> dict:
    """Run analysis via Claude Sonnet 4."""
    settings = get_settings()
    # Language-aware analysis instruction
    lang_names = {"en": "English", "hi": "Hindi", "de": "German", "es": "Spanish", "fr": "French"}
    lang_note = ""
    if detected_language != "en":
        lang_name = lang_names.get(detected_language, detected_language)
        lang_note = f"\nIMPORTANT: The input text is in {lang_name}. Analyze the manipulation techniques in the original language but write your response (technique names, explanations, summary) in English. Quote evidence in the original {lang_name} text."

    if not settings.anthropic_api_key:
        raise ValueError("ANTHROPIC_API_KEY not set")

    client = AsyncAnthropic(api_key=settings.anthropic_api_key)

    if mode == "detailed":
        system = SYSTEM_PROMPT_DETAILED.format(
            techniques=_format_techniques(),
            heuristic_context=_format_heuristic_context(heuristics),
        )
    else:
        system = SYSTEM_PROMPT_BRIEF.format(techniques=_format_techniques())

    try:
        response = await client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2000 if mode == "detailed" else 500,
            system=system,
            messages=[{"role": "user", "content": f"Analyze this content for manipulation techniques:\n\n{text[:4000]}"}],
        )

        raw = response.content[0].text.strip()
        # Strip markdown fences if present
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            if raw.endswith("```"):
                raw = raw[:-3]

        result = json.loads(raw)
        result["_model"] = "claude-sonnet-4"
        return result

    except json.JSONDecodeError as e:
        logger.error(f"Claude returned invalid JSON: {e}")
        return {"brief": "Analysis failed — model returned invalid format.", "techniques": [], "_model": "claude-sonnet-4", "_error": str(e)}
    except Exception as e:
        logger.error(f"Claude API error: {e}")
        raise


# ============================================
# GPT-4o mini (OpenAI) — Fast Brief Mode
# ============================================

async def analyze_with_gpt4o_mini(
    text: str,
    heuristics: HeuristicResult,
) -> dict:
    """Run Brief Mode analysis via GPT-4o mini."""
    settings = get_settings()
    if not settings.openai_api_key:
        raise ValueError("OPENAI_API_KEY not set")

    client = AsyncOpenAI(api_key=settings.openai_api_key)

    system = SYSTEM_PROMPT_BRIEF.format(techniques=_format_techniques())

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=500,
            temperature=0.3,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": f"Analyze this content for manipulation techniques:\n\n{text[:3000]}"},
            ],
        )

        raw = response.choices[0].message.content.strip()
        result = json.loads(raw)
        result["_model"] = "gpt-4o-mini"
        return result

    except json.JSONDecodeError as e:
        logger.error(f"GPT-4o mini returned invalid JSON: {e}")
        return {"brief": "Analysis failed.", "techniques": [], "_model": "gpt-4o-mini", "_error": str(e)}
    except Exception as e:
        logger.error(f"OpenAI API error: {e}")
        raise


# ============================================
# Model router
# ============================================

async def route_and_analyze(
    text: str,
    mode: str,
    heuristics: HeuristicResult,
) -> dict:
    """Route to the best model based on mode and content.

    Routing logic:
    - Brief Mode + heuristics have strong signals → skip LLM entirely
    - Brief Mode + no strong signals → GPT-4o mini (fast, cheap)
    - Detailed Mode → Claude Sonnet 4 (best reasoning)
    - Fallback: if primary fails, try the other
    """
    # If Brief Mode and heuristics found strong signals, skip LLM
    if mode == "brief" and heuristics.has_strong_signals:
        return _build_heuristic_only_result(heuristics)

    # Brief Mode → try GPT-4o mini first, fall back to Claude
    if mode == "brief":
        try:
            return await analyze_with_gpt4o_mini(text, heuristics)
        except Exception as e:
            logger.warning(f"GPT-4o mini failed, falling back to Claude: {e}")
            try:
                return await analyze_with_claude(text, mode, heuristics)
            except Exception:
                return _build_heuristic_only_result(heuristics)

    # Detailed Mode → Claude primary, GPT-4o mini fallback
    try:
        return await analyze_with_claude(text, mode, heuristics)
    except Exception as e:
        logger.warning(f"Claude failed, falling back to GPT-4o mini: {e}")
        try:
            return await analyze_with_gpt4o_mini(text, heuristics)
        except Exception:
            return _build_heuristic_only_result(heuristics)


def _build_heuristic_only_result(heuristics: HeuristicResult) -> dict:
    """Build a result from heuristic signals only (no LLM called)."""
    techniques = []
    brief_parts = []

    for signal in heuristics.signals:
        if signal.confidence >= 0.5:
            techniques.append({
                "name": signal.technique,
                "confidence": signal.confidence,
                "explanation": signal.evidence,
                "evidence": signal.detail,
            })
            brief_parts.append(f"Uses {signal.technique.replace('_', ' ')} ({signal.evidence}).")

    brief = " ".join(brief_parts) if brief_parts else "No strong manipulation signals detected."

    return {
        "brief": brief,
        "techniques": techniques,
        "_model": "heuristics_only",
        "_heuristic_only": True,
    }
