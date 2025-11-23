from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class ToolCall(BaseModel):
    id: str
    name: str
    arguments: Dict[str, Any]


class ToolResult(BaseModel):
    id: str
    name: str
    result: Any
    success: bool
    error: Optional[str] = None


class ChatMessage(BaseModel):
    id: str
    role: MessageRole
    content: str
    timestamp: datetime
    metadata: Optional[Dict[str, Any]] = None
    tool_calls: Optional[List[ToolCall]] = None
    tool_results: Optional[List[ToolResult]] = None


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class GooseSession(BaseModel):
    id: str
    status: str
    created_at: datetime
    updated_at: datetime
    messages: List[ChatMessage] = []
    metadata: Optional[Dict[str, Any]] = None


class Conversation(BaseModel):
    id: str
    title: Optional[str] = None
    session_id: str
    messages: List[ChatMessage] = []
    created_at: datetime
    updated_at: datetime
    metadata: Optional[Dict[str, Any]] = None


class StreamingChunk(BaseModel):
    chunk: str
    finished: bool = False
    error: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: datetime
    services: Dict[str, str]
    toolkit_health: Optional[Dict[str, Any]] = None
