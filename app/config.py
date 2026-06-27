"""Dissekt configuration — loaded from environment variables."""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    telegram_bot_token: str = ""

    # Core
    app_env: str = "development"
    app_name: str = "Dissekt"
    app_version: str = "0.1.0"
    debug: bool = True

    # LLM API Keys
    anthropic_api_key: str = ""
    openai_api_key: str = ""
    google_api_key: str = ""

    # Supabase
    supabase_url: str = ""
    supabase_key: str = ""
    supabase_service_key: str = ""

    # Redis
    redis_url: str = ""
    redis_cache_ttl_brief: int = 86400  # 24 hours
    redis_cache_ttl_detailed: int = 259200  # 72 hours

    # Qdrant
    qdrant_url: str = ""
    qdrant_api_key: str = ""
    qdrant_collection: str = "dissekt_analyses"

    # Search APIs
    google_factcheck_api_key: str = ""
    serpapi_key: str = ""
    gnews_key: str = ""
    brave_search_api_key: str = ""

    # Analysis
    confidence_threshold: float = 0.60
    max_brief_length: int = 300
    max_detailed_length: int = 3000

    # ── Feature flags (per-scan engines) ──
    # Flip to hide a component everywhere. Frontend cards auto-hide when the
    # backend returns no data for that engine. Env-overridable, e.g. ENABLE_PULSE=true
    enable_compass: bool = True            # Meridian — political context  (Phase 3 merge target)
    enable_claims: bool = True             # Facet — extracted claims       (Phase 3 merge target)
    enable_blockchain: bool = False         # Anchor — OTS on-chain anchoring
    enable_pulse: bool = False             # Flare — coordination detection  [HIDDEN]
    enable_counterfactual: bool = False    # Mirror — alternative framings   [HIDDEN]

    # Bias / language signal tags (lexicon-based, descriptive)
    enable_bias: bool = True

    # Rate limiting
    rate_limit_free: int = 3
    rate_limit_pro: int = 100
    # Admin
    dissekt_admin_key: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
