import api from './api';

const getDashboard = async () => {
  const response = await api.get('/doctor/dashboard');
  return response.data;
};

const addPatient = async (data) => {
  const response = await api.post('/doctor/patient/create', data);
  return response.data;
};

const getPatient = async (id) => {
  const response = await api.get(`/doctor/patient/${id}`);
  return response.data;
};

const updatePatientLevel = async (id, level) => {
  const response = await api.put(`/doctor/patient/${id}/level`, { level });
  return response.data;
};

const getAnalytics = async (id) => {
  const response = await api.get(`/doctor/patient/${id}/analytics`);
  return response.data;
};

const uploadMRI = async (patientId, file) => {
  const formData = new FormData();
  formData.append('file', file);
  const response = await api.post(`/doctor/patient/${patientId}/mri`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

const getAppointments = async () => {
  const response = await api.get('/appointments/');
  // Ensure we always return an array even if the API shape changes
  return Array.isArray(response.data) ? response.data : (response.data?.items ?? response.data?.appointments ?? []);
};

const updateAppointment = async (id, data) => {
  const response = await api.put(`/appointments/${id}`, data);
  return response.data;
};

const initTeleconsult = async (id) => {
  const response = await api.post(`/appointments/${id}/init-teleconsult`);
  return response.data;
};

const getPatients = async () => {
  const response = await api.get('/doctor/dashboard');
  return response.data.patients || [];
};

const getMRIStatus = async (taskId) => {
  const response = await api.get(`/doctor/mri/status/${taskId}`);
  return response.data;
};

const getMRIAnalysis = async (patientId, scanId) => {
  const response = await api.get(`/doctor/patient/${patientId}/mri/${scanId}/result`);
  return response.data;
};

const confirmMRIAnalysis = async (historyId, confirm, note = '') => {
  const response = await api.post('/doctor/mri/confirm', {
    history_id: historyId,
    confirm: confirm,
    doctor_note: note
  });
  return response.data;
};

const getMRIHistory = async (patientId, limit = 10, offset = 0) => {
  const response = await api.get(`/doctor/patient/${patientId}/mri/history?limit=${limit}&offset=${offset}`);
  return response.data;
};

const createClinicalPlan = async (data) => {
  const response = await api.post('/clinical-plans', data);
  return response.data;
};

const getClinicalPlans = async (patientId) => {
  const response = await api.get(`/clinical-plans/${patientId}`);
  return response.data;
};

export default {
  getDashboard,
  addPatient,
  getPatient,
  updatePatientLevel,
  getAnalytics,
  uploadMRI,
  getMRIStatus,
  getMRIAnalysis,
  confirmMRIAnalysis,
  getAppointments,
  updateAppointment,
  initTeleconsult,
  getPatients,
  getMRIHistory,
  createClinicalPlan,
  getClinicalPlans,
};
