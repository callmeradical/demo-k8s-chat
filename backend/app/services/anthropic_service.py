import asyncio
from typing import AsyncGenerator, List, Dict, Any
from anthropic import AsyncAnthropic
import structlog

from app.config.settings import settings
from app.models.chat import ChatMessage, MessageRole

logger = structlog.get_logger()


class AnthropicService:
    def __init__(self):
        self.client = AsyncAnthropic(api_key=settings.anthropic_api_key)
        self.model = settings.anthropic_model
        self.max_tokens = settings.anthropic_max_tokens

    async def stream_chat_completion(
        self, 
        messages: List[ChatMessage], 
        system_prompt: str = None
    ) -> AsyncGenerator[str, None]:
        """
        Stream chat completion from Anthropic Claude
        """
        try:
            # Convert our message format to Anthropic format
            anthropic_messages = self._convert_messages_to_anthropic_format(messages)
            
            # Create system message if provided
            system_message = system_prompt or self._get_default_system_prompt()
            
            logger.info("Starting streaming chat completion", 
                       model=self.model, 
                       message_count=len(anthropic_messages))
            
            # Stream the response
            async with self.client.messages.stream(
                model=self.model,
                max_tokens=self.max_tokens,
                system=system_message,
                messages=anthropic_messages,
            ) as stream:
                async for text in stream.text_stream:
                    if text:
                        yield text
                        
        except Exception as e:
            logger.error("Error in streaming chat completion", error=str(e))
            yield f"Error: {str(e)}"

    async def get_chat_completion(
        self, 
        messages: List[ChatMessage], 
        system_prompt: str = None
    ) -> str:
        """
        Get non-streaming chat completion from Anthropic Claude
        """
        try:
            anthropic_messages = self._convert_messages_to_anthropic_format(messages)
            system_message = system_prompt or self._get_default_system_prompt()
            
            logger.info("Getting chat completion", 
                       model=self.model, 
                       message_count=len(anthropic_messages))
            
            response = await self.client.messages.create(
                model=self.model,
                max_tokens=self.max_tokens,
                system=system_message,
                messages=anthropic_messages,
            )
            
            return response.content[0].text if response.content else ""
            
        except Exception as e:
            logger.error("Error in chat completion", error=str(e))
            raise e

    def _convert_messages_to_anthropic_format(self, messages: List[ChatMessage]) -> List[Dict[str, str]]:
        """Convert our message format to Anthropic's expected format"""
        anthropic_messages = []
        
        for msg in messages:
            # Skip system messages as they're handled separately
            if msg.role != MessageRole.SYSTEM:
                anthropic_messages.append({
                    "role": msg.role.value,
                    "content": msg.content
                })
        
        return anthropic_messages

    def _get_default_system_prompt(self) -> str:
        """Get the default system prompt for K8s Chat"""
        return """You are K8s Chat, an AI assistant specialized in Kubernetes operations and management.

You have access to a Kubernetes cluster through an MCP (Model Context Protocol) server that provides real-time cluster information and the ability to execute kubectl commands.

Your capabilities include:
- Viewing cluster resources (pods, services, deployments, etc.)
- Executing kubectl commands
- Analyzing cluster state and health
- Helping with troubleshooting
- Providing Kubernetes best practices and guidance
- Explaining Kubernetes concepts

Always provide helpful, accurate information about Kubernetes. When performing operations, explain what you're doing and why. If you're unsure about something, ask for clarification rather than making assumptions that could impact the cluster.

Be conversational but professional. Format your responses clearly, using code blocks for commands and YAML/JSON when appropriate."""


# Create a singleton instance
anthropic_service = AnthropicService()
