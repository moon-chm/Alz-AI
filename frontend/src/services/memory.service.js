import api from './api';

const createMemory = async (data) => {
  const response = await api.post('/caretaker/memory', data);
  return response.data;
};

const getMemories = async (patientId) => {
  const response = await api.get(`/memory/${patientId}`);
  return response.data;
};

const updateMemory = async (id, data) => {
  const response = await api.put(`/caretaker/memory/${id}`, data);
  return response.data;
};

const deleteMemory = async (id) => {
  const response = await api.delete(`/caretaker/memory/${id}`);
  return response.data;
};

const createFamilyMember = async (data) => {
  const response = await api.post('/memory/family', data);
  return response.data;
};

const getFamilyMembers = async (patientId) => {
  const response = await api.get(`/patient/family`);
  return response.data;
};

const getMoodHistory = async (patientId) => {
  const response = await api.get(`/memory/mood/${patientId}`);
  return response.data;
};

const getConversations = async (patientId) => {
  const response = await api.get(`/memory/conversations/${patientId}`);
  return response.data;
};

export default {
  createMemory,
  getMemories,
  updateMemory,
  deleteMemory,
  createFamilyMember,
  getFamilyMembers,
  getMoodHistory,
  getConversations,
};
