"""
Kubectl Tool for Goose K8s Extension

Provides safe kubectl command execution with validation and security checks.
"""

import asyncio
import shlex
import json
from typing import List, Dict, Any, Optional
from goose.toolkit.base import Tool
import structlog

logger = structlog.get_logger()


class KubectlTool(Tool):
    """
    Tool for executing kubectl commands with safety checks and validation
    """
    
    # Safe kubectl commands that are read-only or low-risk
    SAFE_COMMANDS = {
        'get', 'describe', 'logs', 'top', 'version', 'cluster-info',
        'config', 'explain', 'api-resources', 'api-versions'
    }
    
    # Commands that require confirmation
    WRITE_COMMANDS = {
        'apply', 'create', 'replace', 'patch', 'edit', 'scale', 'autoscale',
        'expose', 'set', 'label', 'annotate'
    }
    
    # Dangerous commands that are restricted
    DANGEROUS_COMMANDS = {
        'delete', 'rollout', 'drain', 'cordon', 'uncordon', 'taint'
    }
    
    def __init__(self, 
                 default_namespace: str = "default",
                 kubectl_context: Optional[str] = None):
        super().__init__(
            name="kubectl",
            description="""Execute kubectl commands safely with built-in security checks.
            
Supports read-only operations by default. Write operations require confirmation.
Dangerous operations like 'delete' are restricted for safety.

Examples:
- kubectl get pods
- kubectl get deployments -n kube-system
- kubectl describe pod my-pod
- kubectl logs my-pod --tail=50
- kubectl scale deployment my-app --replicas=3

Parameters:
- command: kubectl subcommand (get, describe, logs, etc.)
- args: additional arguments as a list
- namespace: namespace to operate in (optional)
- output: output format (json, yaml, wide, etc.)
- confirm: set to true for write operations
"""
        )
        self.default_namespace = default_namespace
        self.kubectl_context = kubectl_context
    
    async def execute(self, 
                     command: str,
                     args: Optional[List[str]] = None,
                     namespace: Optional[str] = None,
                     output: Optional[str] = None,
                     confirm: bool = False) -> Dict[str, Any]:
        """
        Execute a kubectl command with safety checks
        
        Args:
            command: kubectl subcommand (e.g., 'get', 'describe')
            args: additional arguments
            namespace: namespace to operate in
            output: output format (json, yaml, wide, etc.)
            confirm: required for write operations
        
        Returns:
            Dict containing command output, status, and metadata
        """
        try:
            # Validate command
            if not command:
                return {
                    "success": False,
                    "error": "Command is required",
                    "output": ""
                }
            
            # Check if kubectl is available
            kubectl_available = await self.check_kubectl_available()
            if not kubectl_available["available"]:
                return {
                    "success": False,
                    "error": "kubectl is not available",
                    "details": kubectl_available,
                    "output": ""
                }
            
            # Build command
            cmd_parts = ["kubectl"]
            
            # Add context if specified
            if self.kubectl_context:
                cmd_parts.extend(["--context", self.kubectl_context])
            
            # Add subcommand
            cmd_parts.append(command)
            
            # Add namespace
            target_namespace = namespace or self.default_namespace
            if target_namespace and command not in ['version', 'cluster-info', 'config']:
                cmd_parts.extend(["-n", target_namespace])
            
            # Add additional args
            if args:
                cmd_parts.extend(args)
            
            # Add output format
            if output and command in self.SAFE_COMMANDS:
                cmd_parts.extend(["-o", output])
            
            # Security checks
            security_check = self._check_command_security(command, confirm)
            if not security_check["allowed"]:
                return {
                    "success": False,
                    "error": security_check["reason"],
                    "output": "",
                    "security_check": security_check
                }
            
            # Execute command
            logger.info("Executing kubectl command", 
                       command=command, 
                       namespace=target_namespace,
                       args=args)
            
            result = await self._execute_command(cmd_parts)
            
            # Parse output if JSON format requested
            if output == "json" and result["success"]:
                try:
                    result["parsed_output"] = json.loads(result["output"])
                except json.JSONDecodeError:
                    pass
            
            result["command_executed"] = " ".join(cmd_parts)
            result["namespace"] = target_namespace
            
            return result
            
        except Exception as e:
            logger.error("Error executing kubectl command", error=str(e))
            return {
                "success": False,
                "error": f"Failed to execute kubectl command: {str(e)}",
                "output": ""
            }
    
    def _check_command_security(self, command: str, confirm: bool) -> Dict[str, Any]:
        """
        Check if a command is safe to execute
        
        Args:
            command: kubectl subcommand
            confirm: whether user confirmed the operation
        
        Returns:
            Dict with allowed status and reason
        """
        if command in self.DANGEROUS_COMMANDS:
            return {
                "allowed": False,
                "reason": f"Command '{command}' is dangerous and not allowed for safety",
                "category": "dangerous"
            }
        
        if command in self.WRITE_COMMANDS and not confirm:
            return {
                "allowed": False,
                "reason": f"Command '{command}' modifies cluster state and requires confirmation (set confirm=true)",
                "category": "write_needs_confirmation"
            }
        
        if command in self.SAFE_COMMANDS or (command in self.WRITE_COMMANDS and confirm):
            return {
                "allowed": True,
                "reason": "Command is safe to execute",
                "category": "safe" if command in self.SAFE_COMMANDS else "confirmed_write"
            }
        
        # Unknown command - be cautious
        return {
            "allowed": False,
            "reason": f"Unknown command '{command}' - not in allowed list",
            "category": "unknown"
        }
    
    async def _execute_command(self, cmd_parts: List[str]) -> Dict[str, Any]:
        """
        Execute the kubectl command
        
        Args:
            cmd_parts: command parts to execute
        
        Returns:
            Dict with execution results
        """
        try:
            # Use asyncio.create_subprocess_exec for better control
            process = await asyncio.create_subprocess_exec(
                *cmd_parts,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            output = stdout.decode('utf-8')
            error_output = stderr.decode('utf-8')
            
            success = process.returncode == 0
            
            result = {
                "success": success,
                "return_code": process.returncode,
                "output": output.strip() if output else "",
                "error": error_output.strip() if error_output else ""
            }
            
            if not success:
                logger.warning("kubectl command failed", 
                             command=" ".join(cmd_parts),
                             return_code=process.returncode,
                             error=error_output)
            
            return result
            
        except Exception as e:
            logger.error("Failed to execute kubectl command", error=str(e))
            return {
                "success": False,
                "error": f"Execution failed: {str(e)}",
                "output": "",
                "return_code": -1
            }
    
    @staticmethod
    async def check_kubectl_available() -> Dict[str, Any]:
        """
        Check if kubectl is available and working
        
        Returns:
            Dict with availability status and version info
        """
        try:
            process = await asyncio.create_subprocess_exec(
                "kubectl", "version", "--client=true", "--output=json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                try:
                    version_info = json.loads(stdout.decode('utf-8'))
                    return {
                        "available": True,
                        "version": version_info.get("clientVersion", {}),
                        "status": "ready"
                    }
                except json.JSONDecodeError:
                    return {
                        "available": True,
                        "version": "unknown",
                        "status": "ready"
                    }
            else:
                return {
                    "available": False,
                    "error": stderr.decode('utf-8'),
                    "status": "error"
                }
                
        except FileNotFoundError:
            return {
                "available": False,
                "error": "kubectl not found in PATH",
                "status": "not_installed"
            }
        except Exception as e:
            return {
                "available": False,
                "error": str(e),
                "status": "error"
            }
