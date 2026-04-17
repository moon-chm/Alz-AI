import api from './api';

const getDashboard = async (signal) => {
  const response = await api.get('/caretaker/dashboard', { signal });
  return response.data;
};

const getPatientStatus = async (signal) => {
  const response = await api.get('/caretaker/patient/status', { signal });
  return response.data;
};

const getLocation = async (signal) => {
  const response = await api.get('/caretaker/location', { signal });
  return response.data;
};

const getAlerts = async (signal) => {
  const response = await api.get('/caretaker/alerts', { signal });
  return response.data;
};

const createAppointment = async (apptData, signal) => {
  const response = await api.post('/caretaker/appointments', apptData, { signal });
  return response.data;
};

const setGeofence = async (polygon, signal) => {
  const response = await api.post('/caretaker/geofence/set', { coordinates: polygon }, { signal });
  return response.data;
};

const getVitals = async (signal) => {
  const response = await api.get('/caretaker/vitals', { signal });
  return response.data;
};

const getMedications = async (signal) => {
  const response = await api.get('/caretaker/medications', { signal });
  return response.data;
};

const updateMedication = async (id, data, signal) => {
  const response = await api.put(`/caretaker/medications/${id}`, data, { signal });
  return response.data;
};

const addMedication = async (data, signal) => {
  const response = await api.post('/caretaker/medications', data, { signal });
  return response.data;
};

const deleteMedication = async (id, signal) => {
  const response = await api.delete(`/caretaker/medications/${id}`, { signal });
  return response.data;
};

const sendPhoto = async (file, caption, patientId = null, signal) => {
  const formData = new FormData();
  formData.append('file', file);
  if (caption) {
    formData.append('caption', caption);
  }
  
  const url = patientId ? `/caretaker/photo/send?patient_id=${patientId}` : '/caretaker/photo/send';
  const response = await api.post(url, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    signal
  });
  return response.data;
};

const getPhotos = async (signal) => {
  const response = await api.get('/caretaker/photos', { signal });
  return response.data;
};

const addMemory = async (data, signal) => {
  const response = await api.post('/caretaker/memory', data, { signal });
  return response.data;
};

const getMemories = async (signal) => {
  const response = await api.get('/caretaker/memory', { signal });
  return response.data;
};

const updateMemory = async (id, data, signal) => {
  const response = await api.put(`/caretaker/memory/${id}`, data, { signal });
  return response.data;
};

const deleteMemory = async (id, signal) => {
  const response = await api.delete(`/caretaker/memory/${id}`, { signal });
  return response.data;
};

const getAppointments = async (signal) => {
  const response = await api.get('/caretaker/appointments', { signal });
  return response.data;
};

const generateReport = async (period_days, patientId = null, signal) => {
  const payload = { period_days };
  if (patientId) payload.patient_id = patientId;
  const response = await api.post('/caretaker/reports/pdf', payload, { signal });
  return response.data;
};

const linkPatient = async (patientUniqueId, signal) => {
  const response = await api.post('/caretaker/link-patient', { patient_unique_id: patientUniqueId }, { signal });
  return response.data;
};

export default {
  getDashboard,
  getPatientStatus,
  getLocation,
  getAlerts,
  getAppointments,
  createAppointment,
  setGeofence,
  getVitals,
  getMedications,
  updateMedication,
  addMedication,
  deleteMedication,
  sendPhoto,
  getPhotos,
  addMemory,
  getMemories,
  updateMemory,
  deleteMemory,
  generateReport,
  linkPatient,
};
