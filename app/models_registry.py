"""Plug-n-play model registry.

To add a model: add one line to MODEL_REGISTRY. That's it.
Each role (brief_text, detailed_text, vision...) maps to a model id here.
The dispatch layer (llm_dispatch.py) routes to the right provider automatically.
"""

# provider: which SDK to use | caps: what the model can do | cost: rough $ tier | label: UI display
MODEL_REGISTRY = {
    # ─── OpenAI ───
    "gpt-4o-mini":          {"provider": "openai",    "caps": ["text", "vision"], "cost": "$",    "label": "GPT-4o mini"},
    "gpt-4o":               {"provider": "openai",    "caps": ["text", "vision"], "cost": "$$$",  "label": "GPT-4o"},
    "gpt-4.1-mini":         {"provider": "openai",    "caps": ["text", "vision"], "cost": "$",    "label": "GPT-4.1 mini"},
    "gpt-4.1":              {"provider": "openai",    "caps": ["text", "vision"], "cost": "$$$",  "label": "GPT-4.1"},
    "o4-mini":              {"provider": "openai",    "caps": ["text", "vision"], "cost": "$$",   "label": "o4-mini (reasoning)"},

    # ─── Anthropic (current as of June 2026) ───
    "claude-haiku-4-5-20251001":  {"provider": "anthropic", "caps": ["text", "vision"], "cost": "$",    "label": "Claude Haiku 4.5"},
    "claude-sonnet-4-6":          {"provider": "anthropic", "caps": ["text", "vision"], "cost": "$$",   "label": "Claude Sonnet 4.6"},
    "claude-opus-4-8":            {"provider": "anthropic", "caps": ["text", "vision"], "cost": "$$$$", "label": "Claude Opus 4.8"},
}

# Which roles exist in the pipeline + their safe defaults (current production behavior)
ROLE_DEFAULTS = {
    "brief_text":       "gpt-4o-mini",            # fast brief analysis
    "detailed_text":    "claude-sonnet-4-6",      # deep analysis
    "vision":           "gpt-4o-mini",            # image extraction
    "router":           "gpt-4o-mini",            # heuristic escalation / extraction
    "reframe":          "gpt-4o-mini",            # compare / mirror / kaleidoscope
}

# Human-readable role labels for the admin UI
ROLE_LABELS = {
    "brief_text":    "Brief analysis (fast)",
    "detailed_text": "Detailed analysis (deep)",
    "vision":        "Image / vision",
    "router":        "Escalation router",
    "reframe":       "Compare & reframe",
}

# Which capability each role REQUIRES (so the admin UI only offers valid models)
ROLE_CAPABILITY = {
    "brief_text":    "text",
    "detailed_text": "text",
    "vision":        "vision",
    "router":        "text",
    "reframe":       "text",
}


def models_for_capability(cap: str) -> list:
    """Return model ids that support a given capability (for admin dropdowns)."""
    return [mid for mid, m in MODEL_REGISTRY.items() if cap in m["caps"]]


def model_meta(model_id: str) -> dict:
    """Look up a model's metadata, with a safe fallback."""
    return MODEL_REGISTRY.get(model_id, {"provider": "openai", "caps": ["text"], "cost": "?", "label": model_id})
