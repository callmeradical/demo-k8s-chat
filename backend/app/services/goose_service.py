"""
Goose Service for K8s Chat

Manages Goose sessions, toolkits, and streaming responses.
"""

import uuid
import asyncio
import yaml
import os
from typing import Dict, List, Any, AsyncGenerator, Optional
from datetime import datetime, timedelta
import structlog

# Import Goose components - with compatibility fixes for goose-ai 0.9.x
from goose.toolkit.base import Toolkit
from typing import Any, Dict, List, Optional

# Stub classes for missing components in goose-ai 0.9.x
class SessionManager:
    """Stub SessionManager for compatibility"""
    def __init__(self, session_name: str = "default"):
        self.session_name = session_name
        self.messages = []
    
    def add_message(self, role: str, content: str):
        self.messages.append({"role": role, "content": content})
    
    def get_messages(self):
        return self.messages

class AnthropicProvider:
    """Stub AnthropicProvider for compatibility"""
    def __init__(self, api_key: str):
        self.api_key = api_key
    
    async def generate(self, messages: List[Dict], **kwargs) -> Dict[str, Any]:
        # This is a placeholder - in a real implementation, this would call Anthropic API
        return {"content": "This is a placeholder response. Backend integration in progress.", "role": "assistant"}

from app.config.settings import settings
from app.models.chat import ChatMessage, MessageRole
from extensions.k8s import K8sToolkit

logger = structlog.get_logger()


class GooseSessionData:
    """Data model for Goose sessions"""
    
    def __init__(self, session_id: str, goose_session, created_at: datetime):
        self.id = session_id
        self.goose_session = goose_session
        self.created_at = created_at
        self.updated_at = created_at
        self.status = "active"
        self.messages: List[ChatMessage] = []
        self.metadata: Dict[str, Any] = {}


class GooseService:
    """
    Service for managing Goose sessions and K8s operations
    """
    
    def __init__(self):
        self.sessions: Dict[str, GooseSessionData] = {}
        self.session_manager: Optional[SessionManager] = None
        self.toolkits: Dict[str, Toolkit] = {}
        self._initialized = False
    
    async def initialize(self):
        """Initialize Goose service with configuration"""
        try:
            # Load Goose configuration
            config_path = settings.goose_config_path
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config = yaml.safe_load(f)
            else:
                config = self._get_default_config()
            
            # Initialize Anthropic provider
            anthropic_provider = AnthropicProvider(
                api_key=settings.anthropic_api_key,
                model=settings.anthropic_model,
                max_tokens=settings.anthropic_max_tokens,
                **config.get("providers", {}).get("anthropic", {})
            )
            
            # Initialize K8s toolkit
            k8s_toolkit = K8sToolkit(
                mcp_server_url=settings.k8s_mcp_server_url,
                default_namespace=settings.k8s_default_namespace,
                kubectl_context=settings.kubectl_context
            )
            
            # Register toolkits
            self.toolkits["k8s"] = k8s_toolkit
            
            # Initialize session manager
            self.session_manager = SessionManager(
                provider=anthropic_provider,
                toolkits=list(self.toolkits.values()),
                config=config.get("session", {})
            )
            
            self._initialized = True
            logger.info("Goose service initialized successfully")
            
        except Exception as e:
            logger.error("Failed to initialize Goose service", error=str(e))
            raise
    
    async def create_session(self) -> GooseSessionData:
        """Create a new Goose session"""
        if not self._initialized:
            await self.initialize()
        
        session_id = str(uuid.uuid4())
        
        try:
            # Create Goose session
            goose_session = await self.session_manager.create_session(
                session_id=session_id,
                system_prompt=self._get_system_prompt()
            )
            
            # Create session data
            session_data = GooseSessionData(
                session_id=session_id,
                goose_session=goose_session,
                created_at=datetime.now()
            )
            
            self.sessions[session_id] = session_data
            
            logger.info("Created new Goose session", session_id=session_id)
            return session_data
            
        except Exception as e:
            logger.error("Failed to create Goose session", error=str(e))
            raise
    
    async def get_session(self, session_id: str) -> Optional[GooseSessionData]:
        """Get a Goose session by ID"""
        session = self.sessions.get(session_id)
        
        if session and self._is_session_expired(session):
            await self.close_session(session_id)
            return None
        
        return session
    
    async def list_sessions(self) -> List[GooseSessionData]:
        """List all active sessions"""
        # Clean up expired sessions
        expired_sessions = [
            sid for sid, session in self.sessions.items()
            if self._is_session_expired(session)
        ]
        
        for sid in expired_sessions:
            await self.close_session(sid)
        
        return list(self.sessions.values())
    
    async def send_message(self, 
                          session_id: str, 
                          message: str) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Send a message to a Goose session and stream the response
        
        Yields events like:
        - {"type": "session_start", "session_id": "..."}
        - {"type": "message_delta", "delta": "text", "message_id": "..."}
        - {"type": "tool_call", "tool_call": {...}}
        - {"type": "tool_result", "tool_result": {...}}
        - {"type": "message_complete", "content": "...", "message_id": "..."}
        """
        session = await self.get_session(session_id)
        if not session:
            yield {
                "type": "error",
                "error": f"Session {session_id} not found or expired"
            }
            return
        
        try:
            # Add user message to session
            user_message = ChatMessage(
                id=str(uuid.uuid4()),
                role=MessageRole.USER,
                content=message,
                timestamp=datetime.now()
            )
            session.messages.append(user_message)
            session.updated_at = datetime.now()
            
            yield {
                "type": "session_start",
                "session_id": session_id
            }
            
            # Stream response from Goose
            response_content = ""
            message_id = str(uuid.uuid4())
            current_tool_calls = []
            current_tool_results = []
            
            async for event in session.goose_session.send_message(message):
                if event.type == "text_delta":
                    response_content += event.content
                    yield {
                        "type": "message_delta",
                        "delta": event.content,
                        "message_id": message_id,
                        "session_id": session_id
                    }
                
                elif event.type == "tool_call":
                    tool_call_data = {
                        "id": str(uuid.uuid4()),
                        "name": event.tool_name,
                        "arguments": event.arguments
                    }
                    current_tool_calls.append(tool_call_data)
                    
                    yield {
                        "type": "tool_call",
                        "tool_call": tool_call_data,
                        "session_id": session_id
                    }
                
                elif event.type == "tool_result":
                    tool_result_data = {
                        "id": str(uuid.uuid4()),
                        "name": event.tool_name,
                        "result": event.result,
                        "success": event.success,
                        "error": event.error if not event.success else None
                    }
                    current_tool_results.append(tool_result_data)
                    
                    yield {
                        "type": "tool_result",
                        "tool_result": tool_result_data,
                        "session_id": session_id
                    }
                
                elif event.type == "message_complete":
                    # Add assistant message to session
                    assistant_message = ChatMessage(
                        id=message_id,
                        role=MessageRole.ASSISTANT,
                        content=response_content,
                        timestamp=datetime.now(),
                        tool_calls=current_tool_calls if current_tool_calls else None,
                        tool_results=current_tool_results if current_tool_results else None
                    )
                    session.messages.append(assistant_message)
                    session.updated_at = datetime.now()
                    
                    yield {
                        "type": "message_complete",
                        "content": response_content,
                        "message_id": message_id,
                        "session_id": session_id
                    }
                    break
            
        except Exception as e:
            logger.error("Error in Goose session", session_id=session_id, error=str(e))
            yield {
                "type": "error",
                "error": str(e),
                "session_id": session_id
            }
    
    async def close_session(self, session_id: str) -> bool:
        """Close and clean up a Goose session"""
        session = self.sessions.get(session_id)
        if not session:
            return False
        
        try:
            if session.goose_session:
                await session.goose_session.close()
            
            session.status = "closed"
            del self.sessions[session_id]
            
            logger.info("Closed Goose session", session_id=session_id)
            return True
            
        except Exception as e:
            logger.error("Error closing Goose session", session_id=session_id, error=str(e))
            return False
    
    async def get_toolkit_health(self) -> Dict[str, Any]:
        """Get health status of all toolkits"""
        health = {}
        
        for name, toolkit in self.toolkits.items():
            try:
                if hasattr(toolkit, 'health_check'):
                    health[name] = await toolkit.health_check()
                else:
                    health[name] = {"status": "unknown", "tools": len(toolkit.tools)}
            except Exception as e:
                health[name] = {"status": "error", "error": str(e)}
        
        return health
    
    def _is_session_expired(self, session: GooseSessionData) -> bool:
        """Check if a session is expired"""
        timeout = timedelta(seconds=settings.goose_session_timeout)
        return datetime.now() - session.updated_at > timeout
    
    def _get_system_prompt(self) -> str:
        """Get the system prompt for K8s Chat"""
        return """You are K8s Chat, an expert Kubernetes assistant with access to powerful tools for managing Kubernetes clusters.

Your capabilities include:
- Executing kubectl commands safely with built-in validation
- Getting real-time cluster information via MCP servers  
- Managing pods, deployments, services, and other K8s resources
- Troubleshooting cluster issues and providing recommendations
- Scaling applications and managing workloads

When working with the cluster:
1. Always explain what you're doing before using tools
2. Use the most appropriate tool for each task
3. Validate operations before executing destructive commands
4. Provide clear explanations of tool results
5. Offer suggestions for improvements or best practices

Be helpful, accurate, and always prioritize cluster safety. If you're unsure about an operation, ask for confirmation before proceeding."""
    
    def _get_default_config(self) -> Dict[str, Any]:
        """Get default Goose configuration"""
        return {
            "providers": {
                "anthropic": {
                    "model": settings.anthropic_model,
                    "max_tokens": settings.anthropic_max_tokens,
                    "temperature": 0.1
                }
            },
            "session": {
                "timeout": settings.goose_session_timeout,
                "max_exchanges": 50
            },
            "logging": {
                "level": settings.log_level,
                "format": "structured"
            }
        }


# Create singleton instance
goose_service = GooseService()
