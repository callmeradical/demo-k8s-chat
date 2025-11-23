import axios, { AxiosResponse } from 'axios';
import { Conversation, ChatMessage, ApiResponse, GooseSession } from '../types/chat';

const API_BASE_URL = import.meta.env.DEV 
  ? 'http://localhost:8000/api/v1'
  : '/api/v1';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
});

// Add response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export class GooseApiService {
  async healthCheck(): Promise<ApiResponse<any>> {
    try {
      const response: AxiosResponse = await apiClient.get('/health');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Health check failed',
        status: error.response?.status || 500
      };
    }
  }

  // Goose Session Management
  async createSession(): Promise<ApiResponse<GooseSession>> {
    try {
      const response: AxiosResponse<GooseSession> = await apiClient.post('/goose/sessions');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to create Goose session',
        status: error.response?.status || 500
      };
    }
  }

  async getSession(sessionId: string): Promise<ApiResponse<GooseSession>> {
    try {
      const response: AxiosResponse<GooseSession> = await apiClient.get(`/goose/sessions/${sessionId}`);
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to get Goose session',
        status: error.response?.status || 500
      };
    }
  }

  async listSessions(): Promise<ApiResponse<GooseSession[]>> {
    try {
      const response: AxiosResponse<GooseSession[]> = await apiClient.get('/goose/sessions');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to list Goose sessions',
        status: error.response?.status || 500
      };
    }
  }

  async sendMessage(sessionId: string, message: string): Promise<ApiResponse<any>> {
    try {
      const response: AxiosResponse = await apiClient.post(`/goose/sessions/${sessionId}/messages`, {
        message
      });
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to send message',
        status: error.response?.status || 500
      };
    }
  }

  // Conversation Management (built on top of Goose sessions)
  async createConversation(title?: string): Promise<ApiResponse<Conversation>> {
    try {
      const response: AxiosResponse<Conversation> = await apiClient.post('/conversations', {
        title
      });
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to create conversation',
        status: error.response?.status || 500
      };
    }
  }

  async listConversations(): Promise<ApiResponse<Conversation[]>> {
    try {
      const response: AxiosResponse<Conversation[]> = await apiClient.get('/conversations');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to list conversations',
        status: error.response?.status || 500
      };
    }
  }

  async getConversation(conversationId: string): Promise<ApiResponse<Conversation>> {
    try {
      const response: AxiosResponse<Conversation> = await apiClient.get(`/conversations/${conversationId}`);
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to get conversation',
        status: error.response?.status || 500
      };
    }
  }

  async getConversationMessages(conversationId: string): Promise<ApiResponse<ChatMessage[]>> {
    try {
      const response: AxiosResponse<ChatMessage[]> = await apiClient.get(`/conversations/${conversationId}/messages`);
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to get conversation messages',
        status: error.response?.status || 500
      };
    }
  }

  // K8s Extension Tools
  async getK8sTools(): Promise<ApiResponse<any>> {
    try {
      const response: AxiosResponse = await apiClient.get('/k8s/tools');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to get K8s tools',
        status: error.response?.status || 500
      };
    }
  }

  async callK8sTool(toolName: string, arguments?: any): Promise<ApiResponse<any>> {
    try {
      const response: AxiosResponse = await apiClient.post(`/k8s/tools/${toolName}`, arguments);
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || `Failed to call K8s tool: ${toolName}`,
        status: error.response?.status || 500
      };
    }
  }

  async getClusterInfo(): Promise<ApiResponse<any>> {
    try {
      const response: AxiosResponse = await apiClient.get('/k8s/cluster');
      return {
        data: response.data,
        status: response.status
      };
    } catch (error: any) {
      return {
        error: error.message || 'Failed to get cluster information',
        status: error.response?.status || 500
      };
    }
  }
}

export const gooseApiService = new GooseApiService();
