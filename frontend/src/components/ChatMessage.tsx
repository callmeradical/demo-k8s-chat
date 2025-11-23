import React from 'react';
import { 
  Box, 
  Paper, 
  Typography, 
  Avatar, 
  Chip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Alert
} from '@mui/material';
import { 
  Person, 
  SmartToy, 
  Build as BuildIcon,
  ExpandMore,
  CheckCircle,
  Error as ErrorIcon
} from '@mui/icons-material';
import ReactMarkdown from 'react-markdown';
import { ChatMessage as ChatMessageType, ToolCall, ToolResult } from '../types/chat';

interface ChatMessageProps {
  message: ChatMessageType;
  isStreaming?: boolean;
}

export const ChatMessage: React.FC<ChatMessageProps> = ({ message, isStreaming = false }) => {
  const isUser = message.role === 'user';
  const isSystem = message.role === 'system';

  if (isSystem) {
    return (
      <Box sx={{ my: 1, textAlign: 'center' }}>
        <Typography variant="caption" color="text.secondary">
          {message.content}
        </Typography>
      </Box>
    );
  }

  const renderToolCall = (toolCall: ToolCall) => (
    <Box key={toolCall.id} sx={{ mt: 1, mb: 1 }}>
      <Chip
        icon={<BuildIcon />}
        label={`🔧 Using tool: ${toolCall.name}`}
        variant="outlined"
        color="primary"
        size="small"
        sx={{ mb: 1 }}
      />
      <Accordion variant="outlined" sx={{ mt: 1 }}>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="caption">
            Tool Arguments
          </Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Box
            component="pre"
            sx={{
              backgroundColor: 'grey.100',
              p: 1,
              borderRadius: 1,
              fontSize: '0.75rem',
              fontFamily: 'monospace',
              overflow: 'auto',
              maxHeight: '200px'
            }}
          >
            {JSON.stringify(toolCall.arguments, null, 2)}
          </Box>
        </AccordionDetails>
      </Accordion>
    </Box>
  );

  const renderToolResult = (toolResult: ToolResult) => (
    <Box key={toolResult.id} sx={{ mt: 1, mb: 1 }}>
      <Alert
        severity={toolResult.success ? "success" : "error"}
        icon={toolResult.success ? <CheckCircle /> : <ErrorIcon />}
        variant="outlined"
        sx={{ mb: 1 }}
      >
        <Typography variant="caption" fontWeight="bold">
          Tool: {toolResult.name}
        </Typography>
        {toolResult.error && (
          <Typography variant="body2" color="error">
            {toolResult.error}
          </Typography>
        )}
      </Alert>
      
      {toolResult.success && toolResult.result && (
        <Accordion variant="outlined">
          <AccordionSummary expandIcon={<ExpandMore />}>
            <Typography variant="caption">
              Tool Results
            </Typography>
          </AccordionSummary>
          <AccordionDetails>
            {typeof toolResult.result === 'object' ? (
              <Box
                component="pre"
                sx={{
                  backgroundColor: 'grey.100',
                  p: 1,
                  borderRadius: 1,
                  fontSize: '0.75rem',
                  fontFamily: 'monospace',
                  overflow: 'auto',
                  maxHeight: '300px'
                }}
              >
                {JSON.stringify(toolResult.result, null, 2)}
              </Box>
            ) : (
              <Typography variant="body2" component="pre" sx={{ whiteSpace: 'pre-wrap' }}>
                {toolResult.result}
              </Typography>
            )}
          </AccordionDetails>
        </Accordion>
      )}
    </Box>
  );

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: isUser ? 'flex-end' : 'flex-start',
        mb: 2,
      }}
    >
      <Box
        sx={{
          display: 'flex',
          flexDirection: isUser ? 'row-reverse' : 'row',
          alignItems: 'flex-start',
          maxWidth: '85%',
          gap: 1,
        }}
      >
        <Avatar
          sx={{
            bgcolor: isUser ? 'primary.main' : 'secondary.main',
            width: 32,
            height: 32,
          }}
        >
          {isUser ? <Person /> : <SmartToy />}
        </Avatar>

        <Paper
          elevation={1}
          sx={{
            p: 2,
            backgroundColor: isUser ? 'primary.light' : 'grey.100',
            color: isUser ? 'primary.contrastText' : 'text.primary',
            borderRadius: 2,
            position: 'relative',
            minWidth: '200px',
          }}
        >
          {/* Tool calls section */}
          {message.tool_calls && message.tool_calls.length > 0 && (
            <Box sx={{ mb: 2 }}>
              {message.tool_calls.map(renderToolCall)}
            </Box>
          )}

          {/* Tool results section */}
          {message.tool_results && message.tool_results.length > 0 && (
            <Box sx={{ mb: 2 }}>
              {message.tool_results.map(renderToolResult)}
            </Box>
          )}

          {/* Message content */}
          <Box sx={{ wordBreak: 'break-word' }}>
            {isUser ? (
              <Typography variant="body1">{message.content}</Typography>
            ) : (
              <ReactMarkdown
                components={{
                  code: ({ children, className }) => {
                    const isInline = !className;
                    return (
                      <Box
                        component={isInline ? 'code' : 'pre'}
                        sx={{
                          backgroundColor: 'rgba(0, 0, 0, 0.1)',
                          padding: isInline ? '0.2em 0.4em' : '1em',
                          borderRadius: 1,
                          fontFamily: 'monospace',
                          fontSize: '0.875em',
                          overflowX: 'auto',
                          display: isInline ? 'inline' : 'block',
                        }}
                      >
                        {children}
                      </Box>
                    );
                  },
                  p: ({ children }) => (
                    <Typography variant="body1" component="div" sx={{ mb: 1 }}>
                      {children}
                    </Typography>
                  ),
                  ul: ({ children }) => (
                    <Box component="ul" sx={{ mt: 0, mb: 1, pl: 2 }}>
                      {children}
                    </Box>
                  ),
                  ol: ({ children }) => (
                    <Box component="ol" sx={{ mt: 0, mb: 1, pl: 2 }}>
                      {children}
                    </Box>
                  ),
                }}
              >
                {message.content}
              </ReactMarkdown>
            )}
          </Box>

          {/* Streaming indicator */}
          {isStreaming && !isUser && (
            <Box
              sx={{
                display: 'inline-block',
                width: 8,
                height: 16,
                backgroundColor: 'text.primary',
                animation: 'blink 1s infinite',
                ml: 0.5,
              }}
            />
          )}

          {/* Timestamp */}
          <Typography
            variant="caption"
            color={isUser ? 'primary.contrastText' : 'text.secondary'}
            sx={{
              display: 'block',
              mt: 1,
              opacity: 0.7,
            }}
          >
            {new Date(message.timestamp).toLocaleTimeString()}
          </Typography>
        </Paper>
      </Box>

      <style>{`
        @keyframes blink {
          0%, 50% { opacity: 1; }
          51%, 100% { opacity: 0; }
        }
      `}</style>
    </Box>
  );
};
