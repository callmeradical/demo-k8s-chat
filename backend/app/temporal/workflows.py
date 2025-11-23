from typing import List, Dict, Any
from temporalio import workflow
from datetime import timedelta
import structlog

from app.temporal.activities import (
    get_claude_response,
    execute_k8s_command,
    get_cluster_status,
    analyze_user_intent
)

logger = structlog.get_logger()


@workflow.defn
class ChatWorkflow:
    """
    Temporal workflow for processing chat requests with K8s integration
    """

    @workflow.run
    async def run(
        self, 
        user_message: str, 
        conversation_history: List[Dict[str, Any]], 
        conversation_id: str
    ) -> Dict[str, Any]:
        """
        Main workflow for processing chat requests
        """
        workflow.logger.info(f"Starting chat workflow for conversation {conversation_id}")
        
        # Step 1: Analyze user intent
        intent_analysis = await workflow.execute_activity(
            analyze_user_intent,
            user_message,
            conversation_history,
            start_to_close_timeout=timedelta(seconds=30),
        )
        
        response_data = {
            "conversation_id": conversation_id,
            "intent_analysis": intent_analysis,
            "k8s_data": None,
            "response": None,
            "error": None
        }
        
        try:
            # Step 2: If K8s operations are needed, execute them
            if intent_analysis.get("requires_k8s", False):
                workflow.logger.info("K8s operations required, executing commands")
                
                # Get cluster status for context
                cluster_status = await workflow.execute_activity(
                    get_cluster_status,
                    start_to_close_timeout=timedelta(seconds=60),
                )
                response_data["k8s_data"] = cluster_status
                
                # Execute specific K8s commands if suggested
                suggested_tools = intent_analysis.get("suggested_tools", [])
                for tool in suggested_tools:
                    try:
                        tool_result = await workflow.execute_activity(
                            execute_k8s_command,
                            tool,
                            {},  # Empty arguments for now, could be enhanced
                            start_to_close_timeout=timedelta(seconds=60),
                        )
                        if "k8s_tool_results" not in response_data:
                            response_data["k8s_tool_results"] = {}
                        response_data["k8s_tool_results"][tool] = tool_result
                    except Exception as e:
                        workflow.logger.error(f"Failed to execute K8s tool {tool}", error=str(e))
            
            # Step 3: Get Claude response with all context
            enhanced_messages = self._enhance_messages_with_k8s_context(
                conversation_history, 
                user_message,
                response_data.get("k8s_data"),
                response_data.get("k8s_tool_results")
            )
            
            claude_response = await workflow.execute_activity(
                get_claude_response,
                enhanced_messages,
                None,  # Use default system prompt
                start_to_close_timeout=timedelta(seconds=60),
            )
            
            response_data["response"] = claude_response
            
        except Exception as e:
            workflow.logger.error("Error in chat workflow", error=str(e))
            response_data["error"] = str(e)
            response_data["response"] = f"I encountered an error while processing your request: {str(e)}"
        
        return response_data

    def _enhance_messages_with_k8s_context(
        self, 
        conversation_history: List[Dict[str, Any]], 
        user_message: str,
        k8s_data: Dict[str, Any] = None,
        k8s_tool_results: Dict[str, Any] = None
    ) -> List[Dict[str, Any]]:
        """
        Enhance the conversation with K8s context data
        """
        messages = conversation_history.copy()
        
        # Add the current user message
        messages.append({
            "id": f"user-{len(messages)}",
            "role": "user",
            "content": user_message,
            "timestamp": workflow.now().isoformat()
        })
        
        # If we have K8s data, add it as context in a system message
        if k8s_data or k8s_tool_results:
            context_content = "Current Kubernetes cluster context:\n\n"
            
            if k8s_data:
                context_content += f"Cluster Status: {k8s_data}\n\n"
            
            if k8s_tool_results:
                context_content += "Tool Results:\n"
                for tool, result in k8s_tool_results.items():
                    context_content += f"- {tool}: {result}\n"
                context_content += "\n"
            
            # Insert context before the current user message
            messages.insert(-1, {
                "id": f"system-context-{len(messages)}",
                "role": "system",
                "content": context_content,
                "timestamp": workflow.now().isoformat()
            })
        
        return messages
