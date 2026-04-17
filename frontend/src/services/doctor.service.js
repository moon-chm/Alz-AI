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
  const response = await api.get('/appointments');
  return response.data;
};

const updateAppointment = async (id, data) => {
  const response = await api.put(`/appointments/${id}`, data);
  return response.data;
};

const getPatients = async () => {
  const response = await api.get('/doctor/dashboard');
  return response.data.patients || [];
};

export default {
  getDashboard,
  addPatient,
  getPatient,
  updatePatientLevel,
  getAnalytics,
  uploadMRI,
  getAppointments,
  updateAppointment,
  getPatients,
};
