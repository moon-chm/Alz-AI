import api from './api';

const getSteps = async (patientId) => {
  const response = await api.get(`/analytics/steps/${patientId}`);
  return response.data;
};

const getHeartRate = async (patientId) => {
  const response = await api.get(`/analytics/heartrate/${patientId}`);
  return response.data;
};

const getSleep = async (patientId) => {
  const response = await api.get(`/analytics/sleep/${patientId}`);
  return response.data;
};

const getMedicationCompliance = async (patientId) => {
  const response = await api.get(`/analytics/medication/${patientId}`);
  return response.data;
};

const getVoiceResponseRate = async (patientId) => {
  const response = await api.get(`/analytics/voice/${patientId}`);
  return response.data;
};

export default {
  getSteps,
  getHeartRate,
  getSleep,
  getMedicationCompliance,
  getVoiceResponseRate,
};
