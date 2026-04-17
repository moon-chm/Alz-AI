import { useQueries } from '@tanstack/react-query';
import doctorService from '../services/doctor.service';

const usePatient = (id) => {
  const [patientQuery, analyticsQuery] = useQueries({
    queries: [
      {
        queryKey: ['patient', id],
        queryFn: () => doctorService.getPatient(id),
        enabled: !!id,
        staleTime: 30000,
      },
      {
        queryKey: ['analytics', id],
        queryFn: () => doctorService.getAnalytics(id),
        enabled: !!id,
        staleTime: 60000,
      }
    ]
  });

  return {
    patient: patientQuery.data,
    analytics: analyticsQuery.data,
    loading: patientQuery.isLoading || analyticsQuery.isLoading,
    error: patientQuery.error || analyticsQuery.error,
    refetch: () => {
      patientQuery.refetch();
      analyticsQuery.refetch();
    }
  };
};

export default usePatient;
