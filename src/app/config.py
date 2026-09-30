from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

WORKDIR = Path(__file__).resolve().parents[2]
ENV_LOCATION = WORKDIR / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=ENV_LOCATION,extra="ignore")

    # LLM Configuration
    openai_api_key : str = ""
    primary_model : str = "gpt-4o-mini"
    fallback_model : str = "gpt-4o-mini"

    # LangSmith
    langchain_tracing : bool = True
    langsmith_api_key : str = ""
    langchain_project : str = "production-api"

    # Application
    app_env : str = "development"
    log_level : str = "INFO"
    rate_limit : str = "20/minute"
    cache_ttl_seconds : int = 300
    max_retries : int = 3

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

@lru_cache
def get_settings() -> Settings:
    """ Cached Settings instance - loaded once, reused everywhere.
        Prevents reading the env file at every request.
    """
    return Settings()

