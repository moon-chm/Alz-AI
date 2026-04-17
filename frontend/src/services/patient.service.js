import api from './api';

const getProfile = async (patientId = null) => {
  const url = patientId ? `/patient/profile?patient_id=${patientId}` : '/patient/profile';
  const response = await api.get(url);
  return response.data;
};

const getPhotos = async (patientId = null) => {
  const url = patientId ? `/patient/photos?patient_id=${patientId}` : '/patient/photos';
  const response = await api.get(url);
  return response.data;
};

const confirmMedication = async (medicationId, patientId = null) => {
  const payload = { medication_id: medicationId };
  if (patientId) payload.patient_id = patientId;
  const response = await api.post('/patient/medication/confirm', payload);
  return response.data;
};

const triggerSOS = async (lat, lng, patientId = null) => {
  const payload = { lat, lng };
  if (patientId) payload.patient_id = patientId;
  const response = await api.post('/patient/sos', payload);
  return response.data;
};

const getFamily = async (patientId = null) => {
  const url = patientId ? `/patient/family?patient_id=${patientId}` : '/patient/family';
  const response = await api.get(url);
  return response.data;
};

export default {
  getProfile,
  getPhotos,
  confirmMedication,
  triggerSOS,
  getFamily,
};