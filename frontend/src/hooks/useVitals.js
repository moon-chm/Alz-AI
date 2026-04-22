import { useState, useEffect } from 'react';
import caretakerService from '../services/caretaker.service';

const useVitals = (patientId) => {
  const [vitals, setVitals] = useState({ hr: 0, spo2: 0, steps: 0, sleep: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchVitals = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await caretakerService.getVitals();
      setVitals({
        hr: data.hr || 0,
        spo2: data.spo2 || 0,
        steps: data.steps || 0,
        sleep: data.sleep || 0,
      });
      setLastUpdated(data.recorded_at ? new Date(data.recorded_at) : new Date());
    } catch (err) {
      setError(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchVitals();
    const intervalId = setInterval(fetchVitals, 60000); // Background refresh

    // Real-time WebSocket Logic
    let socket = null;
    if (patientId) {
       const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
       const wsUrl = `${protocol}//${window.location.host}/ws/${patientId}`;
       
       socket = new WebSocket(wsUrl);
       socket.onmessage = (event) => {
          try {
             const data = JSON.parse(event.data);
             if (data.event_type === 'vitals_updated') {
                console.log('Real-time Vitals Updated:', data);
                setVitals({
                   hr: data.hr ?? vitals.hr,
                   spo2: data.spo2 ?? vitals.spo2,
                   steps: data.steps ?? vitals.steps,
                   sleep: data.sleep ?? vitals.sleep,
                });
                setLastUpdated(data.recorded_at ? new Date(data.recorded_at) : new Date());
             }
          } catch (e) {
             console.error('Vitals WS error:', e);
          }
       };
    }

    return () => {
      clearInterval(intervalId);
      if (socket) socket.close();
    };
  }, [patientId]);

  return {
    vitals,
    isLoading,
    error,
    lastUpdated,
    refresh: fetchVitals
  };
};

export default useVitals;
