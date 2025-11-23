"""
MCP Client for K8s Extension Resources

Provides integration with Kubernetes MCP servers for live cluster data.
"""

import httpx
import json
from typing import Dict, Any, List, Optional
import structlog

logger = structlog.get_logger()


class MCPClient:
    """
    Client for communicating with the Kubernetes MCP Server
    """
    
    def __init__(self, base_url: str):
        self.base_url = base_url
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
                    return {"error": f"MCP tool error: {result['error']}"}
                else:
                    return {"error": "Unexpected response format"}
                    
        except Exception as e:
            logger.error("Failed to call MCP tool", tool=tool_name, error=str(e))
            return {"error": str(e)}
