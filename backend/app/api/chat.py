from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from typing import List, Dict, Any
import json
import structlog

from app.models.chat import (
    ChatRequest, 
    ChatResponse, 
    Conversation, 
    ChatMessage,
    StreamingChunk,
    HealthResponse
)
from app.services.chat_service import chat_service
from app.services.mcp_client import mcp_client
from app.config.settings import settings
from datetime import datetime

logger = structlog.get_logger()
router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    # Check MCP server health
    mcp_health = await mcp_client.health_check()
    
    services = {
        "api": "healthy",
        "mcp_server": mcp_health.get("status", "unknown"),
        "temporal": "healthy" if chat_service.temporal_client else "disconnected"
    }
    
    return HealthResponse(
        status="healthy",
        version=settings.app_version,
        timestamp=datetime.now(),
        services=services
    )


@router.post("/conversations", response_model=Conversation)
async def create_conversation(title: str = None):
    """Create a new conversation"""
    try:
        conversation = await chat_service.create_conversation(title)
        return conversation
    except Exception as e:
        logger.error("Failed to create conversation", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to create conversation")


@router.get("/conversations", response_model=List[Conversation])
async def list_conversations():
    """List all conversations"""
    try:
        conversations = await chat_service.list_conversations()
        return conversations
    except Exception as e:
        logger.error("Failed to list conversations", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to list conversations")


@router.get("/conversations/{conversation_id}", response_model=Conversation)
async def get_conversation(conversation_id: str):
    """Get a specific conversation"""
    try:
        conversation = await chat_service.get_conversation(conversation_id)
        return conversation
    except Exception as e:
        logger.error("Failed to get conversation", conversation_id=conversation_id, error=str(e))
        raise HTTPException(status_code=404, detail="Conversation not found")


@router.get("/conversations/{conversation_id}/messages", response_model=List[ChatMessage])
async def get_conversation_messages(conversation_id: str):
    """Get messages from a conversation"""
    try:
        messages = await chat_service.get_conversation_history(conversation_id)
        return messages
    except Exception as e:
        logger.error("Failed to get conversation messages", conversation_id=conversation_id, error=str(e))
        raise HTTPException(status_code=404, detail="Conversation not found")


@router.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time chat"""
    await websocket.accept()
    logger.info("WebSocket connection established")
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            try:
                message_data = json.loads(data)
                user_message = message_data.get("message", "")
                conversation_id = message_data.get("conversation_id")
                
                if not user_message:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "error": "Message is required"
                    }))
                    continue
                
                logger.info("Processing WebSocket message", 
                           conversation_id=conversation_id, 
                           message_length=len(user_message))
                
                # Send typing indicator
                await websocket.send_text(json.dumps({
                    "type": "typing",
                    "conversation_id": conversation_id
                }))
                
                # Process message and stream response
                full_response = ""
                async for chunk in chat_service.process_user_message(user_message, conversation_id):
                    full_response += chunk
                    
                    # Send chunk to client
                    chunk_data = {
                        "type": "chunk",
                        "chunk": chunk,
                        "conversation_id": conversation_id,
                        "finished": False
                    }
                    await websocket.send_text(json.dumps(chunk_data))
                
                # Send completion message
                completion_data = {
                    "type": "complete",
                    "conversation_id": conversation_id,
                    "finished": True,
                    "full_response": full_response
                }
                await websocket.send_text(json.dumps(completion_data))
                
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "error": "Invalid JSON format"
                }))
            except Exception as e:
                logger.error("Error processing WebSocket message", error=str(e))
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "error": str(e)
                }))
                
    except WebSocketDisconnect:
        logger.info("WebSocket connection disconnected")
    except Exception as e:
        logger.error("WebSocket error", error=str(e))


@router.get("/mcp/tools")
async def list_mcp_tools():
    """List available MCP tools"""
    try:
        tools = await mcp_client.list_tools()
        return {"tools": tools}
    except Exception as e:
        logger.error("Failed to list MCP tools", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to get MCP tools")


@router.post("/mcp/tools/{tool_name}")
async def call_mcp_tool(tool_name: str, arguments: Dict[str, Any] = None):
    """Call a specific MCP tool"""
    try:
        if arguments is None:
            arguments = {}
        
        result = await mcp_client.call_tool(tool_name, arguments)
        return result
    except Exception as e:
        logger.error("Failed to call MCP tool", tool=tool_name, error=str(e))
        raise HTTPException(status_code=500, detail=f"Failed to call tool: {tool_name}")
