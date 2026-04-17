import React, { createContext, useState, useContext, useCallback } from 'react';
import caretakerService from '../services/caretaker.service';

export const PatientContext = createContext();

export const PatientProvider = ({ children }) => {
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [patientMood, setPatientMood] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchPatientData = useCallback(async (id = 'default') => {
    setLoading(true);
    try {
      // In this version, we fetch the dashboard for the current user
      const data = await caretakerService.getDashboard();
      if (data && data.patient_id) {
        setSelectedPatient({
          id: data.patient_id,
          full_name: data.patient_name,
          urgency: data.patient_status
        });
      }
    } catch (err) {
      console.error("Failed to fetch patient data:", err);
    } finally {
      setLoading(false);
    }
  }, []);

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