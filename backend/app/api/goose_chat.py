"""
Goose-powered API routes for K8s Chat

Provides REST and WebSocket endpoints for Goose session management and K8s operations.
"""

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from typing import List, Dict, Any, Optional
import json
import structlog
from datetime import datetime

from app.models.chat import (
    ChatRequest, 
    GooseSession, 
    ChatMessage,
    HealthResponse,
    Conversation
)
from app.services.goose_service import goose_service
from app.config.settings import settings

logger = structlog.get_logger()
router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Enhanced health check with Goose toolkit status"""
    try:
        # Get toolkit health from Goose service
        toolkit_health = await goose_service.get_toolkit_health()
        
        services = {
            "api": "healthy",
            "goose": "healthy" if goose_service._initialized else "initializing",
        }
        
        # Add MCP server health if available
        if "k8s" in toolkit_health:
            k8s_health = toolkit_health["k8s"]
            if "checks" in k8s_health and "mcp_server" in k8s_health["checks"]:
                mcp_status = k8s_health["checks"]["mcp_server"].get("status", "unknown")
                services["mcp_server"] = mcp_status
            else:
                services["mcp_server"] = "not_configured"
        
        return HealthResponse(
            status="healthy",
            version=settings.app_version,
            timestamp=datetime.now(),
            services=services,
            toolkit_health=toolkit_health
        )
    except Exception as e:
        logger.error("Health check failed", error=str(e))
        return HealthResponse(
            status="unhealthy",
            version=settings.app_version,
            timestamp=datetime.now(),
            services={"api": "error", "error": str(e)},
            toolkit_health={}
        )


# Goose Session Management
@router.post("/goose/sessions", response_model=GooseSession)
async def create_goose_session():
    """Create a new Goose session"""
    try:
        session_data = await goose_service.create_session()
        
        return GooseSession(
            id=session_data.id,
            status=session_data.status,
            created_at=session_data.created_at,
            updated_at=session_data.updated_at,
            messages=session_data.messages,
            metadata=session_data.metadata
        )
    except Exception as e:
        logger.error("Failed to create Goose session", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create session")


@router.get("/goose/sessions", response_model=List[GooseSession])
async def list_goose_sessions():
    """List all active Goose sessions"""
    try:
        sessions = await goose_service.list_sessions()
        
        return [
            GooseSession(
                id=session.id,
                status=session.status,
                created_at=session.created_at,
                updated_at=session.updated_at,
                messages=session.messages,
                metadata=session.metadata
            )
            for session in sessions
        ]
    except Exception as e:
        logger.error("Failed to list Goose sessions", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list sessions")


@router.get("/goose/sessions/{session_id}", response_model=GooseSession)
async def get_goose_session(session_id: str):
    """Get a specific Goose session"""
    try:
        session_data = await goose_service.get_session(session_id)
        if not session_data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        return GooseSession(
            id=session_data.id,
            status=session_data.status,
            created_at=session_data.created_at,
            updated_at=session_data.updated_at,
            messages=session_data.messages,
            metadata=session_data.metadata
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to get Goose session", session_id=session_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get session")


@router.post("/goose/sessions/{session_id}/messages")
async def send_message_to_session(session_id: str, request: ChatRequest):
    """Send a message to a Goose session (non-streaming endpoint)"""
    try:
        session_data = await goose_service.get_session(session_id)
        if not session_data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # For REST endpoint, we'll collect all streaming events and return the final result
        final_content = ""
        tool_calls = []
        tool_results = []
        
        async for event in goose_service.send_message(session_id, request.message):
            if event["type"] == "message_delta":
                final_content += event.get("delta", "")
            elif event["type"] == "tool_call":
                tool_calls.append(event["tool_call"])
            elif event["type"] == "tool_result":
                tool_results.append(event["tool_result"])
            elif event["type"] == "message_complete":
                break
            elif event["type"] == "error":
                raise HTTPException(status_code=500, detail=event["error"])
        
        return {
            "content": final_content,
            "tool_calls": tool_calls,
            "tool_results": tool_results,
            "session_id": session_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to send message", session_id=session_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to send message")


@router.delete("/goose/sessions/{session_id}")
async def close_goose_session(session_id: str):
    """Close a Goose session"""
    try:
        success = await goose_service.close_session(session_id)
        if not success:
            raise HTTPException(status_code=404, detail="Session not found")
        
        return {"message": "Session closed successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to close session", session_id=session_id, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to close session")


# Conversation Management (backward compatibility)
@router.post("/conversations", response_model=Conversation)
async def create_conversation(title: Optional[str] = None):
    """Create a new conversation (creates a Goose session internally)"""
    try:
        session_data = await goose_service.create_session()
        
        return Conversation(
            id=session_data.id,  # Use session ID as conversation ID
            title=title or f"K8s Chat - {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            session_id=session_data.id,
            messages=session_data.messages,
            created_at=session_data.created_at,
            updated_at=session_data.updated_at,
            metadata=session_data.metadata
        )
    except Exception as e:
        logger.error("Failed to create conversation", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create conversation")


@router.get("/conversations", response_model=List[Conversation])
async def list_conversations():
    """List all conversations"""
    try:
        sessions = await goose_service.list_sessions()
        
        return [
            Conversation(
                id=session.id,
                title=f"K8s Chat - {session.created_at.strftime('%Y-%m-%d %H:%M')}",
                session_id=session.id,
                messages=session.messages,
                created_at=session.created_at,
                updated_at=session.updated_at,
                metadata=session.metadata
            )
            for session in sessions
        ]
    except Exception as e:
        logger.error("Failed to list conversations", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list conversations")


# K8s Tools and Cluster Information
@router.get("/k8s/tools")
async def get_k8s_tools():
    """Get available K8s tools from the Goose toolkit"""
    try:
        toolkit_health = await goose_service.get_toolkit_health()
        k8s_toolkit = goose_service.toolkits.get("k8s")
        
        if not k8s_toolkit:
            return {"tools": [], "status": "not_available"}
        
        tools = []
        for tool in k8s_toolkit.tools:
            tools.append({
                "name": tool.name,
                "description": tool.description,
                "available": True
            })
        
        return {
            "tools": tools,
            "status": "available",
            "health": toolkit_health.get("k8s", {})
        }
        
    except Exception as e:
        logger.error("Failed to get K8s tools", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get K8s tools")


@router.post("/k8s/tools/{tool_name}")
async def call_k8s_tool(tool_name: str, arguments: Optional[Dict[str, Any]] = None):
    """Call a specific K8s tool directly"""
    try:
        k8s_toolkit = goose_service.toolkits.get("k8s")
        if not k8s_toolkit:
            raise HTTPException(status_code=404, detail="K8s toolkit not available")
        
        # Find the tool
        tool = None
        for t in k8s_toolkit.tools:
            if t.name == tool_name:
                tool = t
                break
        
        if not tool:
            raise HTTPException(status_code=404, detail=f"Tool '{tool_name}' not found")
        
        # Execute the tool
        args = arguments or {}
        result = await tool.execute(**args)
        
        return {
            "tool": tool_name,
            "arguments": args,
            "result": result,
            "success": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to call K8s tool", tool=tool_name, error=str(e))
        raise HTTPException(status_code=500, detail=f"Failed to call tool: {str(e)}")


@router.get("/k8s/cluster")
async def get_cluster_info():
    """Get general cluster information"""
    try:
        k8s_toolkit = goose_service.toolkits.get("k8s")
        if not k8s_toolkit:
            raise HTTPException(status_code=404, detail="K8s toolkit not available")
        
        # Try to get cluster info using the cluster_info tool
        cluster_tool = None
        for tool in k8s_toolkit.tools:
            if tool.name == "cluster_info":
                cluster_tool = tool
                break
        
        if cluster_tool:
            result = await cluster_tool.execute()
            return result
        else:
            # Fallback: get basic toolkit health
            health = await k8s_toolkit.health_check() if hasattr(k8s_toolkit, 'health_check') else {}
            return {
                "status": "limited_info",
                "toolkit_health": health,
                "message": "Full cluster info tool not available"
            }
            
    except Exception as e:
        logger.error("Failed to get cluster info", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get cluster information")


# WebSocket endpoint for real-time Goose communication
@router.websocket("/ws/goose")
async def websocket_goose_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time Goose session communication"""
    await websocket.accept()
    logger.info("Goose WebSocket connection established")
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            try:
                message_data = json.loads(data)
                user_message = message_data.get("message", "")
                session_id = message_data.get("session_id")
                
                if not user_message:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "error": "Message is required"
                    }))
                    continue
                
                if not session_id:
                    # Create a new session if none provided
                    session_data = await goose_service.create_session()
                    session_id = session_data.id
                    
                    await websocket.send_text(json.dumps({
                        "type": "session_start",
                        "session_id": session_id
                    }))
                
                logger.info("Processing Goose WebSocket message", 
                           session_id=session_id, 
                           message_length=len(user_message))
                
                # Stream response from Goose
                async for event in goose_service.send_message(session_id, user_message):
                    await websocket.send_text(json.dumps(event))
                
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "error": "Invalid JSON format"
                }))
            except Exception as e:
                logger.error("Error processing Goose WebSocket message", error=str(e))
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "error": str(e)
                }))
                
    except WebSocketDisconnect:
        logger.info("Goose WebSocket connection disconnected")
    except Exception as e:
        logger.error("Goose WebSocket error", error=str(e))
