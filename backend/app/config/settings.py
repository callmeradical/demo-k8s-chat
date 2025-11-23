from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # API Configuration
    app_name: str = "K8s Chat - Goose Powered"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000
    
    # Anthropic Configuration (for Goose)
    anthropic_api_key: str
    anthropic_model: str = "claude-3-5-sonnet-20241022"
    anthropic_max_tokens: int = 4096
    
    # Goose Configuration
    goose_config_path: str = "./goose-config.yaml"
    goose_session_timeout: int = 3600
    goose_extensions_path: str = "./extensions"
    
    # MCP Server Configuration
    k8s_mcp_server_url: str = "http://localhost:8080"
    
    # K8s Extension Configuration
    k8s_default_namespace: str = "default"
    kubectl_context: Optional[str] = None
    
    # CORS Configuration
    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    
    @property
    def cors_origins_list(self) -> list[str]:
        """Convert comma-separated CORS origins to list"""
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]
    
    # Logging
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
