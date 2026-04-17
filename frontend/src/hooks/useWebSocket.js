import { useState, useEffect, useRef, useCallback } from 'react';

const useWebSocket = (patientId) => {
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState(null);
  const [alertFeed, setAlertFeed] = useState([]); // ✅ Added state for AlertFeed
  const socketRef = useRef(null);
  const reconnectTimeoutRef = useRef(null);
  const reconnectAttemptsRef = useRef(0);
  const MAX_RECONNECT_DELAY = 30000;

  const connect = useCallback(() => {
    if (!patientId) return;

    // Detect protocol: wss for https, ws for http
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host; // includes port if present (e.g. localhost:5173 or localhost)
    
    // In production/Docker, we want /ws/ mapped via Nginx.
    // window.location.host handles the hostname and port automatically.
    const wsUrl = `${protocol}//${host}/ws/${patientId}`;

    console.log(`Connecting to WebSocket: ${wsUrl}`);
    
    try {
      const socket = new WebSocket(wsUrl);

      socket.onopen = () => {
        console.log('WebSocket Connected');
        setIsConnected(true);
        setError(null);
        reconnectAttemptsRef.current = 0;
      };

      socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          // ✅ Buffer alerts locally in this hook
          if (data.type === 'alert' || data.severity) {
            setAlertFeed((prev) => [data, ...prev].slice(0, 50)); 
          }
        } catch (err) {
          console.error('WebSocket message parse error:', err);
        }
      };

      socket.onclose = (event) => {
        console.log('WebSocket Closed', event.code, event.reason);
        setIsConnected(false);
        
        // Anti-loop: don't reconnect on clean close
        if (event.code !== 1000) {
          const delay = Math.min(1000 * Math.pow(2, reconnectAttemptsRef.current), MAX_RECONNECT_DELAY);
          console.log(`Attempting reconnect in ${delay}ms (Attempt ${reconnectAttemptsRef.current + 1})`);
          
          reconnectAttemptsRef.current++;
          reconnectTimeoutRef.current = setTimeout(connect, delay);
        }
      };

      socket.onerror = (err) => {
        console.error('WebSocket Error:', err);
        setError('Connection error');
      };

      socketRef.current = socket;
    } catch (err) {
      console.error('WebSocket initialization error:', err);
      setError('Failed to initialize connection');
    }
  }, [patientId]);

  useEffect(() => {
    connect();

    return () => {
      if (socketRef.current) {
        socketRef.current.close(1000); 
      }
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
    };
  }, [connect]);

  const sendMessage = useCallback((message) => {
    if (socketRef.current?.readyState === WebSocket.OPEN) {
      socketRef.current.send(JSON.stringify(message));
    }
  }, []);

  return { isConnected, error, alertFeed, sendMessage };
};

export default useWebSocket;
