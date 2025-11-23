export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: string;
  metadata?: Record<string, any>;
  tool_calls?: ToolCall[];
  tool_results?: ToolResult[];
}

export interface ToolCall {
  id: string;
  name: string;
  arguments: Record<string, any>;
}

export interface ToolResult {
  id: string;
  name: string;
  result: any;
  success: boolean;
  error?: string;
}

export interface GooseSession {
  id: string;
  status: 'active' | 'completed' | 'error';
  created_at: string;
  updated_at: string;
  messages: ChatMessage[];
  metadata?: Record<string, any>;
}

export interface Conversation {
  id: string;
  title?: string;
  session_id: string;
  messages: ChatMessage[];
  created_at: string;
  updated_at: string;
  metadata?: Record<string, any>;
}

export interface ChatRequest {
  message: string;
  session_id?: string;
  context?: Record<string, any>;
}

export interface GooseWebSocketMessage {
  type: 'session_start' | 'message_delta' | 'tool_call' | 'tool_result' | 'message_complete' | 'session_complete' | 'error';
  session_id?: string;
  message_id?: string;
  delta?: string;
  content?: string;
  tool_call?: ToolCall;
  tool_result?: ToolResult;
  error?: string;
  finished?: boolean;
}

export interface ApiResponse<T> {
  data?: T;
  error?: string;
  status: number;
}

export interface K8sClusterInfo {
  status: string;
  version: string;
  nodes: number;
  namespaces: string[];
  health_checks: Record<string, any>;
}

export interface K8sPod {
  name: string;
  namespace: string;
  status: string;
  node: string;
  created: string;
  containers: K8sContainer[];
  labels: Record<string, string>;
}

export interface K8sContainer {
  name: string;
  image: string;
  ready: boolean;
  restarts: number;
}
