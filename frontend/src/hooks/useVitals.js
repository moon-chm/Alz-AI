import { useState, useEffect } from 'react';
import caretakerService from '../services/caretaker.service';

const useVitals = () => {
  const [vitals, setVitals] = useState({ hr: 0, spo2: 0, steps: 0, sleep: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  useEffect(() => {
    let isMounted = true;
    let intervalId;

    const fetchVitals = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const data = await caretakerService.getVitals();
        if (isMounted) {
          setVitals({
            hr: data.hr || 0,
            spo2: data.spo2 || 0,
            steps: data.steps || 0,
            sleep: data.sleep || 0,
          });
          setLastUpdated(new Date());
        }
      } catch (err) {
        if (isMounted) setError(err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };

    fetchVitals();
    intervalId = setInterval(fetchVitals, 60000);

    return () => {
      isMounted = false;
      clearInterval(intervalId);
    };
  }, []);

  return {
    vitals,
    isLoading,
    error,
    lastUpdated,
  };
};

export default useVitals;
