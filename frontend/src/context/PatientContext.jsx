import React, { createContext, useState, useContext, useCallback } from 'react';
import caretakerService from '../services/caretaker.service';
import { useAuthContext } from './AuthContext';

export const PatientContext = createContext();

export const PatientProvider = ({ children }) => {
  const { user } = useAuthContext();
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [patientMood, setPatientMood] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchPatientData = useCallback(async (id = 'default') => {
    setLoading(true);
    try {
      const data = await caretakerService.getDashboard();
      if (data && data.patient_id) {
        const patientData = {
          id: data.patient_id,
          full_name: data.patient_name,
          urgency: data.patient_status,
          primary_doctor_id: data.primary_doctor_id,
          primary_doctor_name: data.primary_doctor_name
        };
        setSelectedPatient(patientData);
        console.log("Context Rehydrated:", patientData);
      }
    } catch (err) {
      console.error("Failed to fetch patient data:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Rehydration on mount - Only if token exists and patient context is empty
  React.useEffect(() => {
    const hasToken = !!localStorage.getItem('access_token');
    if (hasToken && user?.role === 'caretaker' && !selectedPatient) {
      console.log("Session detected, rehydrating patient context...");
      fetchPatientData();
    }
  }, [fetchPatientData, selectedPatient, user]);

  return (
    <PatientContext.Provider
      value={{
        selectedPatient,
        setSelectedPatient,
        patientMood,
        setPatientMood,
        fetchPatientData,
        loading
      }}
    >
      {children}
    </PatientContext.Provider>
  );
};

export const usePatientContext = () => useContext(PatientContext);