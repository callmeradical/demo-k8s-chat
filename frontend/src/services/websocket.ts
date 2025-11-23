import { GooseWebSocketMessage } from '../types/chat';

export class GooseChatWebSocketService {
  private ws: WebSocket | null = null;
  private url: string;
  private messageHandlers: Set<(message: GooseWebSocketMessage) => void> = new Set();
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;

  constructor(url: string) {
    this.url = url;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(this.url);

        this.ws.onopen = () => {
          console.log('Goose WebSocket connected');
          this.reconnectAttempts = 0;
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const message: GooseWebSocketMessage = JSON.parse(event.data);
            this.messageHandlers.forEach(handler => handler(message));
          } catch (error) {
            console.error('Failed to parse Goose WebSocket message:', error);
          }
        };

        this.ws.onclose = (event) => {
          console.log('Goose WebSocket disconnected:', event.code, event.reason);
          this.handleReconnect();
        };

        this.ws.onerror = (error) => {
          console.error('Goose WebSocket error:', error);
          reject(error);
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  private handleReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Attempting to reconnect... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
      
      setTimeout(() => {
        this.connect().catch(console.error);
      }, this.reconnectDelay * this.reconnectAttempts);
    } else {
      console.error('Max reconnection attempts reached');
    }
  }

  sendMessage(message: string, sessionId?: string) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      const payload = {
        message,
        session_id: sessionId
      };
      this.ws.send(JSON.stringify(payload));
    } else {
      console.error('Goose WebSocket is not connected');
    }
  }

  onMessage(handler: (message: GooseWebSocketMessage) => void) {
    this.messageHandlers.add(handler);
    
    // Return unsubscribe function
    return () => {
      this.messageHandlers.delete(handler);
    };
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}

// Create singleton instance
const wsUrl = import.meta.env.DEV 
  ? 'ws://localhost:8000/api/v1/ws/goose'
  : `ws://${window.location.host}/api/v1/ws/goose`;

export const gooseChatWebSocketService = new GooseChatWebSocketService(wsUrl);
