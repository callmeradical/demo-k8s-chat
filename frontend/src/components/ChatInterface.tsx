import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Container,
  Typography,
  AppBar,
  Toolbar,
  Alert,
  Snackbar,
  Chip,
  Button,
} from '@mui/material';
import { 
  Psychology as GooseIcon, 
  Refresh as RefreshIcon
} from '@mui/icons-material';
import { ChatMessage as ChatMessageComponent } from './ChatMessage';
import { ChatInput } from './ChatInput';
import { ChatMessage, GooseWebSocketMessage, ToolCall, ToolResult } from '../types/chat';
import { gooseChatWebSocketService } from '../services/websocket';
import { gooseApiService } from '../services/api';

export const GooseChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentStreamingMessage, setCurrentStreamingMessage] = useState<string>('');
  const [currentToolCalls, setCurrentToolCalls] = useState<ToolCall[]>([]);
  const [currentToolResults, setCurrentToolResults] = useState<ToolResult[]>([]);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [sessionStatus, setSessionStatus] = useState<string>('inactive');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    initializeGooseSession();
    return () => {
      gooseChatWebSocketService.disconnect();
    };
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, currentStreamingMessage]);

  const initializeGooseSession = async () => {
    try {
      // Create a new Goose session
      const sessionResult = await gooseApiService.createSession();
      if (sessionResult.data) {
        setSessionId(sessionResult.data.id);
        setSessionStatus(sessionResult.data.status);
        
        // Connect WebSocket
        await connectWebSocket();
        
        // Add welcome message
        const welcomeMessage: ChatMessage = {
          id: 'welcome',
          role: 'assistant',
          content: `🦢 **Welcome to K8s Chat powered by Goose!**

I'm your Kubernetes assistant with access to powerful tools for cluster management. I can help you:

- **Monitor your cluster** - Check pod status, node health, and resource usage
- **Manage workloads** - Scale deployments, view logs, and troubleshoot issues  
- **Execute kubectl commands** - Run safe kubectl operations with built-in validation
- **Analyze cluster data** - Get insights from live cluster information via MCP

Ask me anything about your Kubernetes cluster! For example:
- "What pods are running in the default namespace?"
- "Show me the status of all deployments"
- "Scale the frontend deployment to 3 replicas"
- "Check the logs for the nginx pod"

I'll show you exactly what tools I'm using and their results.`,
          timestamp: new Date().toISOString(),
        };
        
        setMessages([welcomeMessage]);
      } else {
        setError('Failed to create Goose session');
      }
    } catch (error) {
      console.error('Failed to initialize Goose session:', error);
      setError('Failed to initialize AI session');
    }
  };

  const connectWebSocket = async () => {
    try {
      await gooseChatWebSocketService.connect();
      setIsConnected(true);
      setError(null);

      gooseChatWebSocketService.onMessage(handleGooseMessage);
    } catch (error) {
      console.error('Failed to connect WebSocket:', error);
      setError('Failed to connect to AI service');
      setIsConnected(false);
    }
  };

  const handleGooseMessage = (gooseMessage: GooseWebSocketMessage) => {
    switch (gooseMessage.type) {
      case 'session_start':
        setIsLoading(true);
        setCurrentStreamingMessage('');
        setCurrentToolCalls([]);
        setCurrentToolResults([]);
        break;

      case 'message_delta':
        if (gooseMessage.delta) {
          setCurrentStreamingMessage(prev => prev + gooseMessage.delta);
        }
        break;

      case 'tool_call':
        if (gooseMessage.tool_call) {
          setCurrentToolCalls(prev => [...prev, gooseMessage.tool_call!]);
        }
        break;

      case 'tool_result':
        if (gooseMessage.tool_result) {
          setCurrentToolResults(prev => [...prev, gooseMessage.tool_result!]);
        }
        break;

      case 'message_complete':
        if (gooseMessage.content && sessionId) {
          const assistantMessage: ChatMessage = {
            id: gooseMessage.message_id || `assistant-${Date.now()}`,
            role: 'assistant',
            content: gooseMessage.content,
            timestamp: new Date().toISOString(),
            tool_calls: currentToolCalls.length > 0 ? currentToolCalls : undefined,
            tool_results: currentToolResults.length > 0 ? currentToolResults : undefined,
          };

          setMessages(prev => [...prev, assistantMessage]);
          setCurrentStreamingMessage('');
          setCurrentToolCalls([]);
          setCurrentToolResults([]);
          setIsLoading(false);
        }
        break;

      case 'session_complete':
        setSessionStatus('completed');
        setIsLoading(false);
        break;

      case 'error':
        setError(gooseMessage.error || 'An error occurred');
        setIsLoading(false);
        setCurrentStreamingMessage('');
        setCurrentToolCalls([]);
        setCurrentToolResults([]);
        break;
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = (content: string) => {
    if (!isConnected || !sessionId) {
      setError('Not connected to AI service');
      return;
    }

    const userMessage: ChatMessage = {
      id: `user-${Date.now()}`,
      role: 'user',
      content,
      timestamp: new Date().toISOString(),
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    setError(null);

    gooseChatWebSocketService.sendMessage(content, sessionId);
  };

  const handleNewSession = () => {
    setMessages([]);
    setCurrentStreamingMessage('');
    setCurrentToolCalls([]);
    setCurrentToolResults([]);
    initializeGooseSession();
  };

  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <AppBar position="static" color="primary">
        <Toolbar>
          <GooseIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            K8s Chat - Goose Powered
          </Typography>
          
          {/* Session status indicators */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Chip
              label={isConnected ? '🟢 Connected' : '🔴 Disconnected'}
              size="small"
              variant="outlined"
              sx={{ color: 'white', borderColor: 'white' }}
            />
            {sessionId && (
              <Chip
                label={`Session: ${sessionStatus}`}
                size="small"
                variant="outlined"
                sx={{ color: 'white', borderColor: 'white' }}
              />
            )}
            <Button
              startIcon={<RefreshIcon />}
              onClick={handleNewSession}
              color="inherit"
              size="small"
            >
              New Session
            </Button>
          </Box>
        </Toolbar>
      </AppBar>

      <Container
        maxWidth="lg"
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          py: 2,
          overflow: 'hidden',
        }}
      >
        <Box
          sx={{
            flex: 1,
            overflowY: 'auto',
            mb: 2,
            px: 1,
          }}
        >
          {messages.map((message) => (
            <ChatMessageComponent key={message.id} message={message} />
          ))}

          {/* Show current streaming message with tool activity */}
          {(currentStreamingMessage || currentToolCalls.length > 0 || currentToolResults.length > 0) && (
            <ChatMessageComponent
              message={{
                id: 'streaming',
                role: 'assistant',
                content: currentStreamingMessage,
                timestamp: new Date().toISOString(),
                tool_calls: currentToolCalls,
                tool_results: currentToolResults,
              }}
              isStreaming={true}
            />
          )}

          <div ref={messagesEndRef} />
        </Box>

        <ChatInput
          onSendMessage={handleSendMessage}
          disabled={!isConnected || !sessionId}
          isLoading={isLoading}
        />
      </Container>

      <Snackbar
        open={!!error}
        autoHideDuration={6000}
        onClose={() => setError(null)}
        anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      >
        <Alert onClose={() => setError(null)} severity="error">
          {error}
        </Alert>
      </Snackbar>
    </Box>
  );
};
