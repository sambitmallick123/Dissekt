"""Central model dispatch.

call_model(role, ...) resolves the admin-chosen model for that role,
routes to the right provider SDK, and returns (text, model_id_used).

Resolution order: admin DB config -> ROLE_DEFAULTS.
"""
import logging
from app.config import get_settings
from app.models_registry import MODEL_REGISTRY, ROLE_DEFAULTS, model_meta

logger = logging.getLogger(__name__)

# Simple in-process cache of the DB model config (role -> model_id)
_model_config_cache = None


async def _load_model_config() -> dict:
    """Load role->model overrides from Supabase model_config table. Falls back to defaults."""
    global _model_config_cache
    if _model_config_cache is not None:
        return _model_config_cache
    cfg = dict(ROLE_DEFAULTS)  # start from defaults
    try:
        settings = get_settings()
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_key)
        rows = sb.table("model_config").select("role, model").execute()
        for r in (rows.data or []):
            if r.get("role") and r.get("model"):
                cfg[r["role"]] = r["model"]
    except Exception as e:
        logger.warning(f"model_config load failed, using defaults: {e}")
    _model_config_cache = cfg
    return cfg


def invalidate_model_config():
    """Call after admin updates models."""
    global _model_config_cache
    _model_config_cache = None


def resolve_model(role: str, config: dict) -> str:
    """Get the model id for a role."""
    return config.get(role) or ROLE_DEFAULTS.get(role, "gpt-4o-mini")


async def call_model(role: str, *, system: str = None, user: str, messages: list = None,
                     max_tokens: int = 1000, temperature: float = 0.3,
                     json_mode: bool = False, image_url: str = None) -> dict:
    """Call the model assigned to `role`. Returns {text, model, provider}.

    - system/user: simple prompt pair (most call-sites)
    - messages: full message list (overrides user) for multimodal/complex
    - image_url: if set, attaches an image (vision roles)
    """
    config = await _load_model_config()
    model_id = resolve_model(role, config)
    meta = model_meta(model_id)
    provider = meta["provider"]
    settings = get_settings()

    try:
        if provider == "anthropic":
            from anthropic import AsyncAnthropic
            client = AsyncAnthropic(api_key=settings.anthropic_api_key)
            content = []
            if image_url:
                # Anthropic expects base64 image blocks
                if image_url.startswith("data:"):
                    media_type = image_url.split(";")[0].split(":")[1]
                    b64 = image_url.split(",", 1)[1]
                    content.append({"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}})
            content.append({"type": "text", "text": user})
            resp = await client.messages.create(
                model=model_id,
                max_tokens=max_tokens,
                system=system or "",
                messages=messages or [{"role": "user", "content": content}],
            )
            text = resp.content[0].text
        else:  # openai
            from openai import AsyncOpenAI
            client = AsyncOpenAI(api_key=settings.openai_api_key)
            if messages is None:
                msgs = []
                if system:
                    msgs.append({"role": "system", "content": system})
                if image_url:
                    msgs.append({"role": "user", "content": [
                        {"type": "text", "text": user},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ]})
                else:
                    msgs.append({"role": "user", "content": user})
            else:
                msgs = messages
            kwargs = {"model": model_id, "max_tokens": max_tokens, "temperature": temperature, "messages": msgs}
            if json_mode:
                kwargs["response_format"] = {"type": "json_object"}
            resp = await client.chat.completions.create(**kwargs)
            text = resp.choices[0].message.content

        return {"text": text or "", "model": model_id, "label": meta["label"], "provider": provider}

    except Exception as e:
        logger.error(f"call_model({role}, {model_id}) failed: {e}")
        return {"text": "", "model": model_id, "label": meta["label"], "provider": provider, "error": str(e)}
