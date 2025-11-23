from typing import List, Dict, Any, AsyncGenerator
from temporalio import activity
import structlog

from app.services.anthropic_service import anthropic_service
from app.services.mcp_client import mcp_client
from app.models.chat import ChatMessage

logger = structlog.get_logger()


@activity.defn
async def get_claude_response(messages: List[Dict[str, Any]], system_prompt: str = None) -> str:
    """
    Activity to get a response from Claude
    """
    try:
        # Convert dict messages back to ChatMessage objects
        chat_messages = [
            ChatMessage(
                id=msg.get("id", ""),
                role=msg["role"],
                content=msg["content"],
                timestamp=msg["timestamp"],
                metadata=msg.get("metadata")
            ) for msg in messages
        ]
        
        response = await anthropic_service.get_chat_completion(chat_messages, system_prompt)
        return response
        
    except Exception as e:
        logger.error("Failed to get Claude response", error=str(e))
        raise


@activity.defn
async def execute_k8s_command(tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
    """
    Activity to execute a Kubernetes command via MCP
    """
    try:
        result = await mcp_client.call_tool(tool_name, arguments)
        return result
        
    except Exception as e:
        logger.error("Failed to execute K8s command", tool=tool_name, error=str(e))
        raise


@activity.defn
async def get_cluster_status() -> Dict[str, Any]:
    """
    Activity to get cluster status information
    """
    try:
        cluster_info = await mcp_client.get_cluster_info()
        return cluster_info
        
    except Exception as e:
        logger.error("Failed to get cluster status", error=str(e))
        raise


@activity.defn
async def analyze_user_intent(message: str, conversation_context: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Activity to analyze user intent and determine if K8s operations are needed
    """
    try:
        # Create a simple analysis prompt
        analysis_messages = [
            ChatMessage(
                id="analysis",
                role="user",
                content=f"""Analyze this user message and determine if it requires Kubernetes operations:

User message: "{message}"

Previous conversation context: {conversation_context[-3:] if conversation_context else "None"}

Respond with a JSON object containing:
- requires_k8s: boolean (true if K8s operations are needed)
- intent: string (description of what the user wants)
- suggested_tools: array of strings (which K8s tools might be needed)
- confidence: number (0-1, how confident you are about the intent)

Example response:
{{"requires_k8s": true, "intent": "list all pods", "suggested_tools": ["get_pods"], "confidence": 0.9}}""",
                timestamp=None
            )
        ]
        
        response = await anthropic_service.get_chat_completion(
            messages=analysis_messages,
            system_prompt="You are an intent analysis assistant. Analyze user messages to determine if they require Kubernetes operations."
        )
        
        # Try to parse the JSON response
        import json
        try:
            intent_data = json.loads(response)
        except json.JSONDecodeError:
            # Fallback if Claude doesn't return valid JSON
            intent_data = {
                "requires_k8s": "kubectl" in message.lower() or "pod" in message.lower() or "deployment" in message.lower(),
                "intent": "General inquiry",
                "suggested_tools": [],
                "confidence": 0.5
            }
        
        return intent_data
        
    except Exception as e:
        logger.error("Failed to analyze user intent", error=str(e))
        return {
            "requires_k8s": False,
            "intent": "Error in analysis",
            "suggested_tools": [],
            "confidence": 0.0
        }
