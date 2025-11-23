"""
Pods Tool for Goose K8s Extension

Provides pod listing, filtering, and basic operations.
"""

import json
from typing import List, Dict, Any, Optional
from goose.toolkit.base import Tool
import structlog

logger = structlog.get_logger()


class PodsTool(Tool):
    """
    Tool for pod operations and querying
    """
    
    def __init__(self, 
                 default_namespace: str = "default",
                 mcp_client = None):
        super().__init__(
            name="get_pods",
            description="""List and filter pods across namespaces.
            
Can filter by status, labels, and field selectors. Provides detailed pod information
including status, resource usage, and container details.

Examples:
- get_pods() - List pods in default namespace
- get_pods(namespace="kube-system") - List pods in specific namespace
- get_pods(all_namespaces=True) - List all pods across all namespaces
- get_pods(status_filter="Running") - Filter by pod status
- get_pods(label_selector="app=nginx") - Filter by labels

Parameters:
- namespace: specific namespace (optional)
- all_namespaces: list pods from all namespaces
- status_filter: filter by pod status (Running, Pending, Failed, etc.)
- label_selector: filter by labels (e.g., "app=nginx,version=v1")
- field_selector: filter by fields (e.g., "spec.nodeName=node1")
- include_details: include detailed container and resource information
"""
        )
        self.default_namespace = default_namespace
        self.mcp_client = mcp_client
    
    async def execute(self, 
                     namespace: Optional[str] = None,
                     all_namespaces: bool = False,
                     status_filter: Optional[str] = None,
                     label_selector: Optional[str] = None,
                     field_selector: Optional[str] = None,
                     include_details: bool = False) -> Dict[str, Any]:
        """
        List and filter pods
        
        Args:
            namespace: specific namespace to query
            all_namespaces: query all namespaces
            status_filter: filter by pod status
            label_selector: kubernetes label selector
            field_selector: kubernetes field selector
            include_details: include detailed information
        
        Returns:
            Dict containing pod information and metadata
        """
        try:
            # Try MCP client first if available
            if self.mcp_client:
                try:
                    mcp_result = await self._get_pods_via_mcp(
                        namespace, all_namespaces, status_filter, 
                        label_selector, field_selector, include_details
                    )
                    if mcp_result.get("success"):
                        return mcp_result
                except Exception as e:
                    logger.warning("MCP client failed, falling back to kubectl", error=str(e))
            
            # Fallback to kubectl
            return await self._get_pods_via_kubectl(
                namespace, all_namespaces, status_filter,
                label_selector, field_selector, include_details
            )
            
        except Exception as e:
            logger.error("Error getting pods", error=str(e))
            return {
                "success": False,
                "error": f"Failed to get pods: {str(e)}",
                "pods": []
            }
    
    async def _get_pods_via_mcp(self, 
                               namespace: Optional[str] = None,
                               all_namespaces: bool = False,
                               status_filter: Optional[str] = None,
                               label_selector: Optional[str] = None,
                               field_selector: Optional[str] = None,
                               include_details: bool = False) -> Dict[str, Any]:
        """Get pods via MCP server"""
        args = {}
        if namespace:
            args["namespace"] = namespace
        if all_namespaces:
            args["all_namespaces"] = True
        if status_filter:
            args["status_filter"] = status_filter
        if label_selector:
            args["label_selector"] = label_selector
        if field_selector:
            args["field_selector"] = field_selector
        if include_details:
            args["include_details"] = True
            
        result = await self.mcp_client.call_tool("get_pods", args)
        return {
            "success": not result.get("error"),
            "pods": result.get("pods", []),
            "source": "mcp",
            "error": result.get("error")
        }
    
    async def _get_pods_via_kubectl(self,
                                   namespace: Optional[str] = None,
                                   all_namespaces: bool = False,
                                   status_filter: Optional[str] = None,
                                   label_selector: Optional[str] = None,
                                   field_selector: Optional[str] = None,
                                   include_details: bool = False) -> Dict[str, Any]:
        """Get pods via kubectl command"""
        from .kubectl import KubectlTool
        
        kubectl = KubectlTool(self.default_namespace)
        
        # Build kubectl arguments
        args = ["pods"]
        
        if all_namespaces:
            args.append("--all-namespaces")
        
        if label_selector:
            args.extend(["-l", label_selector])
            
        if field_selector:
            args.extend(["--field-selector", field_selector])
        
        # Execute kubectl command
        result = await kubectl.execute(
            command="get",
            args=args,
            namespace=None if all_namespaces else namespace,
            output="json"
        )
        
        if not result["success"]:
            return {
                "success": False,
                "error": result["error"],
                "pods": []
            }
        
        # Parse kubectl output
        try:
            kubectl_data = json.loads(result["output"])
            pods = kubectl_data.get("items", [])
            
            # Filter by status if requested
            if status_filter:
                pods = [p for p in pods if p.get("status", {}).get("phase") == status_filter]
            
            # Process pods for easier consumption
            processed_pods = []
            for pod in pods:
                pod_info = {
                    "name": pod["metadata"]["name"],
                    "namespace": pod["metadata"]["namespace"],
                    "status": pod.get("status", {}).get("phase", "Unknown"),
                    "node": pod.get("spec", {}).get("nodeName", ""),
                    "created": pod["metadata"].get("creationTimestamp", ""),
                    "labels": pod["metadata"].get("labels", {}),
                    "containers": []
                }
                
                # Add container information
                for container in pod.get("spec", {}).get("containers", []):
                    container_info = {
                        "name": container["name"],
                        "image": container["image"],
                        "ready": False,
                        "restarts": 0
                    }
                    
                    # Get container status
                    container_statuses = pod.get("status", {}).get("containerStatuses", [])
                    for status in container_statuses:
                        if status["name"] == container["name"]:
                            container_info["ready"] = status.get("ready", False)
                            container_info["restarts"] = status.get("restartCount", 0)
                            break
                    
                    pod_info["containers"].append(container_info)
                
                # Add detailed information if requested
                if include_details:
                    pod_info["details"] = {
                        "conditions": pod.get("status", {}).get("conditions", []),
                        "resources": pod.get("spec", {}).get("containers", [{}])[0].get("resources", {}),
                        "volumes": pod.get("spec", {}).get("volumes", [])
                    }
                
                processed_pods.append(pod_info)
            
            return {
                "success": True,
                "pods": processed_pods,
                "total": len(processed_pods),
                "source": "kubectl",
                "namespace": namespace or "all" if all_namespaces else self.default_namespace
            }
            
        except json.JSONDecodeError as e:
            return {
                "success": False,
                "error": f"Failed to parse kubectl output: {str(e)}",
                "pods": []
            }
