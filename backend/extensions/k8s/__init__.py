"""
K8s Extension for Goose - Kubernetes Operations Extension

This extension provides Goose with tools to interact with Kubernetes clusters
through kubectl commands, direct API calls, and MCP server integration.
"""

from typing import List, Dict, Any, Optional
from goose.toolkit.base import Tool, Toolkit
from goose.utils.ask import ask_an_ai
import structlog

from .tools.kubectl import KubectlTool
from .tools.cluster_info import ClusterInfoTool
from .tools.pods import PodsTool
from .tools.deployments import DeploymentsTool
from .tools.services import ServicesTool
from .tools.nodes import NodesTool
from .resources.mcp_client import MCPClient

logger = structlog.get_logger()


class K8sToolkit(Toolkit):
    """
    Kubernetes Operations Toolkit for Goose
    
    Provides comprehensive Kubernetes cluster management capabilities
    including pod management, deployments, services, and cluster health.
    """
    
    def __init__(self, 
                 mcp_server_url: Optional[str] = None,
                 default_namespace: str = "default",
                 kubectl_context: Optional[str] = None):
        """
        Initialize the K8s toolkit
        
        Args:
            mcp_server_url: URL of the MCP server for live cluster data
            default_namespace: Default namespace for operations
            kubectl_context: Kubectl context to use
        """
        super().__init__()
        
        self.mcp_server_url = mcp_server_url
        self.default_namespace = default_namespace
        self.kubectl_context = kubectl_context
        
        # Initialize MCP client if URL provided
        self.mcp_client = None
        if mcp_server_url:
            self.mcp_client = MCPClient(mcp_server_url)
        
        # Initialize tools
        self._tools = self._create_tools()
        
        logger.info("K8s Toolkit initialized", 
                   mcp_enabled=bool(self.mcp_client),
                   default_namespace=self.default_namespace)
    
    def _create_tools(self) -> List[Tool]:
        """Create and configure all K8s tools"""
        tools = [
            KubectlTool(
                default_namespace=self.default_namespace,
                kubectl_context=self.kubectl_context
            ),
            ClusterInfoTool(
                mcp_client=self.mcp_client
            ),
            PodsTool(
                default_namespace=self.default_namespace,
                mcp_client=self.mcp_client
            ),
            DeploymentsTool(
                default_namespace=self.default_namespace
            ),
            ServicesTool(
                default_namespace=self.default_namespace
            ),
            NodesTool(
                mcp_client=self.mcp_client
            )
        ]
        
        return tools
    
    @property
    def tools(self) -> List[Tool]:
        """Get all available tools"""
        return self._tools
    
    def system_prompt(self) -> str:
        """Get the system prompt for this toolkit"""
        return """You are a Kubernetes expert assistant with access to cluster management tools.

You can help with:
- Cluster monitoring and health checks
- Pod management and troubleshooting
- Deployment scaling and management
- Service discovery and networking
- Node status and resource usage
- Executing kubectl commands safely

When performing operations:
1. Always explain what you're doing and why
2. Use the most specific tool available for the task
3. Check cluster state before making changes
4. Provide clear feedback on operation results
5. Suggest best practices and improvements

Available tools:
- kubectl: Execute kubectl commands with safety checks
- cluster_info: Get cluster overview and health status
- get_pods: List and filter pods across namespaces
- get_deployments: List deployment information and status
- scale_deployment: Scale deployments up or down
- get_services: List services and their endpoints
- get_nodes: Check node status and resource availability

Remember to be cautious with destructive operations and always confirm before making significant changes."""
    
    async def health_check(self) -> Dict[str, Any]:
        """Check the health of the toolkit and its dependencies"""
        health = {
            "status": "healthy",
            "tools_available": len(self._tools),
            "mcp_enabled": bool(self.mcp_client),
            "checks": {}
        }
        
        # Check MCP server if enabled
        if self.mcp_client:
            try:
                mcp_health = await self.mcp_client.health_check()
                health["checks"]["mcp_server"] = mcp_health
            except Exception as e:
                health["checks"]["mcp_server"] = {
                    "status": "unhealthy",
                    "error": str(e)
                }
                health["status"] = "degraded"
        
        # Check kubectl availability
        try:
            from .tools.kubectl import KubectlTool
            kubectl_check = await KubectlTool.check_kubectl_available()
            health["checks"]["kubectl"] = kubectl_check
        except Exception as e:
            health["checks"]["kubectl"] = {
                "status": "unavailable", 
                "error": str(e)
            }
            health["status"] = "degraded"
        
        return health
