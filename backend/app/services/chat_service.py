import uuid
import json
from typing import Dict, List, Any, AsyncGenerator
from datetime import datetime
import structlog

from temporalio.client import Client
from temporalio.worker import Worker

from app.models.chat import ChatMessage, MessageRole, Conversation
from app.services.anthropic_service import anthropic_service
from app.temporal.workflows import ChatWorkflow
from app.temporal.activities import (
    get_claude_response,
    execute_k8s_command,
    get_cluster_status,
    analyze_user_intent
)
from app.config.settings import settings

logger = structlog.get_logger()


class ChatService:
    """
    Service for managing chat conversations and integrating with Temporal workflows
    """
    
    def __init__(self):
        self.conversations: Dict[str, Conversation] = {}
        self.temporal_client: Client = None
        
    async def initialize_temporal(self):
        """Initialize Temporal client"""
        try:
            self.temporal_client = await Client.connect(settings.temporal_host)
            logger.info("Connected to Temporal server", host=settings.temporal_host)
        except Exception as e:
            logger.error("Failed to connect to Temporal server", error=str(e))
            # For development, we can fall back to direct processing
            self.temporal_client = None
    
    async def create_conversation(self, title: str = None) -> Conversation:
        """Create a new conversation"""
        conversation_id = str(uuid.uuid4())
        conversation = Conversation(
            id=conversation_id,
            title=title or f"Chat {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            messages=[],
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        self.conversations[conversation_id] = conversation
        logger.info("Created new conversation", conversation_id=conversation_id)
        return conversation
    
    async def get_conversation(self, conversation_id: str) -> Conversation:
        """Get an existing conversation"""
        if conversation_id not in self.conversations:
            # Create a new conversation if it doesn't exist
            return await self.create_conversation()
        return self.conversations[conversation_id]
    
    async def add_message(self, conversation_id: str, role: MessageRole, content: str) -> ChatMessage:
        """Add a message to a conversation"""
        conversation = await self.get_conversation(conversation_id)
        
        message = ChatMessage(
            id=str(uuid.uuid4()),
            role=role,
            content=content,
            timestamp=datetime.now()
        )
        
        conversation.messages.append(message)
        conversation.updated_at = datetime.now()
        
        return message
    
    async def process_user_message(self, message: str, conversation_id: str = None) -> AsyncGenerator[str, None]:
        """
        Process a user message and stream the response
        """
        # Get or create conversation
        if conversation_id:
            conversation = await self.get_conversation(conversation_id)
        else:
            conversation = await self.create_conversation()
            conversation_id = conversation.id
        
        # Add user message
        await self.add_message(conversation_id, MessageRole.USER, message)
        
        try:
            if self.temporal_client:
                # Use Temporal workflow
                async for chunk in self._process_with_temporal(message, conversation):
                    yield chunk
            else:
                # Fallback to direct processing
                async for chunk in self._process_directly(message, conversation):
                    yield chunk
                    
        except Exception as e:
            logger.error("Error processing user message", error=str(e))
            yield f"Error: {str(e)}"
    
    async def _process_with_temporal(self, message: str, conversation: Conversation) -> AsyncGenerator[str, None]:
        """Process message using Temporal workflow"""
        try:
            # Convert conversation history to dict format
            conversation_history = [
                {
                    "id": msg.id,
                    "role": msg.role.value,
                    "content": msg.content,
                    "timestamp": msg.timestamp.isoformat() if msg.timestamp else None,
                    "metadata": msg.metadata
                }
                for msg in conversation.messages[:-1]  # Exclude the current user message
            ]
            
            # Start workflow
            workflow_id = f"chat-{conversation.id}-{uuid.uuid4()}"
            handle = await self.temporal_client.start_workflow(
                ChatWorkflow.run,
                message,
                conversation_history,
                conversation.id,
                id=workflow_id,
                task_queue=settings.temporal_task_queue,
            )
            
            # Wait for result
            result = await handle.result()
            
            # Stream the response
            response = result.get("response", "No response generated")
            
            # For now, yield the entire response at once
            # In a future version, we could implement streaming within the workflow
            yield response
            
            # Add assistant response to conversation
            await self.add_message(conversation.id, MessageRole.ASSISTANT, response)
            
        except Exception as e:
            logger.error("Error in Temporal workflow processing", error=str(e))
            yield f"Workflow error: {str(e)}"
    
    async def _process_directly(self, message: str, conversation: Conversation) -> AsyncGenerator[str, None]:
        """Process message directly without Temporal (fallback)"""
        try:
            # Stream response from Claude
            full_response = ""
            async for chunk in anthropic_service.stream_chat_completion(conversation.messages):
                full_response += chunk
                yield chunk
            
            # Add assistant response to conversation
            await self.add_message(conversation.id, MessageRole.ASSISTANT, full_response)
            
        except Exception as e:
            logger.error("Error in direct processing", error=str(e))
            yield f"Direct processing error: {str(e)}"
    
    async def get_conversation_history(self, conversation_id: str) -> List[ChatMessage]:
        """Get conversation history"""
        conversation = await self.get_conversation(conversation_id)
        return conversation.messages
    
    async def list_conversations(self) -> List[Conversation]:
        """List all conversations"""
        return list(self.conversations.values())


# Create singleton instance
chat_service = ChatService()
