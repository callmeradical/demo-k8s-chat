from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import structlog
import asyncio
from contextlib import asynccontextmanager

from app.config.settings import settings
from app.api.goose_chat import router as goose_chat_router
from app.services.goose_service import goose_service

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    logger = structlog.get_logger()
    logger.info("Starting K8s Chat application with Goose")
    
    try:
        # Initialize Goose service
        await goose_service.initialize()
        logger.info("Goose service initialized successfully")
    except Exception as e:
        logger.error("Failed to initialize Goose service", error=str(e))
        # Continue startup even if Goose fails to initialize
    
    yield
    
    # Shutdown
    logger.info("Shutting down K8s Chat application")
    
    # Close all Goose sessions
    try:
        sessions = await goose_service.list_sessions()
        for session in sessions:
            await goose_service.close_session(session.id)
        logger.info("Closed all Goose sessions")
    except Exception as e:
        logger.error("Error during Goose session cleanup", error=str(e))


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="A ChatGPT-like interface for Kubernetes operations powered by Goose AI agent framework with Claude and custom K8s extensions",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(goose_chat_router, prefix="/api/v1")

# Root endpoint
@app.get("/")
async def root():
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "status": "running",
        "description": "Goose-powered Kubernetes Chat Assistant",
        "docs_url": "/docs",
        "health_check": "/api/v1/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )
