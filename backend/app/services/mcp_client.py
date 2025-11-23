import httpx
import json
from typing import Dict, Any, List, Optional
import structlog

from app.config.settings import settings

logger = structlog.get_logger()


class MCPClient:
    """
    Client for communicating with the Kubernetes MCP Server
    """
    
    def __init__(self):
        self.base_url = settings.k8s_mcp_server_url
        self.timeout = 30.0
        
    async def health_check(self) -> Dict[str, Any]:
        """Check if MCP server is healthy"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.base_url}/health")
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error("MCP health check failed", error=str(e))
            return {"status": "unhealthy", "error": str(e)}
    
    async def list_tools(self) -> List[Dict[str, Any]]:
        """List available tools from the MCP server"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/mcp",
                    json={
                        "jsonrpc": "2.0",
                        "id": "1",
                        "method": "tools/list",
                        "params": {}
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                if "result" in result:
                    return result["result"].get("tools", [])
                return []
                
        except Exception as e:
            logger.error("Failed to list MCP tools", error=str(e))
            return []
    
    async def call_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Call a specific tool on the MCP server"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/mcp",
                    json={
                        "jsonrpc": "2.0",
                        "id": "1",
                        "method": "tools/call",
                        "params": {
                            "name": tool_name,
                            "arguments": arguments
                        }
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                if "result" in result:
                    return result["result"]
                elif "error" in result:
                    raise Exception(f"MCP tool error: {result['error']}")
                else:
                    return {"error": "Unexpected response format"}
                    
        except Exception as e:
            logger.error("Failed to call MCP tool", tool=tool_name, error=str(e))
            return {"error": str(e)}
    
    async def execute_kubectl(self, command: List[str], namespace: Optional[str] = None) -> Dict[str, Any]:
        """Execute a kubectl command through the MCP server"""
        arguments = {"command": command}
        if namespace:
            arguments["namespace"] = namespace
            
        return await self.call_tool("kubectl", arguments)
    
    async def get_cluster_info(self) -> Dict[str, Any]:
        """Get general cluster information"""
        return await self.call_tool("cluster_info", {})
    
    async def get_pods(self, namespace: Optional[str] = None) -> Dict[str, Any]:
        """Get pod information"""
        arguments = {}
        if namespace:
            arguments["namespace"] = namespace
        return await self.call_tool("get_pods", arguments)
    
    async def get_services(self, namespace: Optional[str] = None) -> Dict[str, Any]:
        """Get service information"""
        arguments = {}
        if namespace:
            arguments["namespace"] = namespace
        return await self.call_tool("get_services", arguments)
    
    async def get_deployments(self, namespace: Optional[str] = None) -> Dict[str, Any]:
        """Get deployment information"""
        arguments = {}
        if namespace:
            arguments["namespace"] = namespace
        return await self.call_tool("get_deployments", arguments)


# Create a singleton instance
mcp_client = MCPClient()
