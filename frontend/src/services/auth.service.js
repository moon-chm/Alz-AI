import api from './api';

const login = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  const { access_token, role } = response.data;
  if (access_token) {
    localStorage.setItem('alz_token', access_token);
    // Fetch full user data immediately using the newly set token
    api.defaults.headers.common['Authorization'] = 'Bearer ' + access_token;
    const userRes = await api.get('/auth/me');
    return { token: access_token, role, user: userRes.data };
  }
  return response.data;
};

const registerDoctor = async (data) => {
  const response = await api.post('/auth/register/doctor', data);
  return response.data;
};

const registerCaretaker = async (data) => {
  const response = await api.post('/auth/register/caretaker', data);
  return response.data;
};

const sendOTP = async (phone) => {
  // Use the unified professional endpoint
  const response = await api.post('/auth/request-otp', { 
    role: 'caretaker', 
    identifier: phone 
  });
  return response.data;
};

const verifyOTP = async (verificationKey, otp) => {
  // PATCH 4: Use verification_key (caretaker_phone) for identity reference
  // PATCH 5: Direct verification endpoint
  const response = await api.post('/auth/verify-otp', { 
    phone: verificationKey,
    otp 
  });
  
  const { access_token, role, user_id } = response.data;
  if (access_token) {
    // PATCH 8: Clear any stale session first
    localStorage.removeItem('alz_token');
    
    localStorage.setItem('alz_token', access_token);
    api.defaults.headers.common['Authorization'] = 'Bearer ' + access_token;
    
    // Fetch full profile to ensure context is pure (Patch 6)
    const userRes = await api.get('/auth/me');
    return { token: access_token, role, user: userRes.data };
  }
  return response.data;
};

const logout = () => {
  localStorage.removeItem('alz_token');
  window.location.href = '/login';
};

const getMe = async () => {
  const response = await api.get('/auth/me');
  return response.data;
};

const decodeToken = (token) => {
  if (!token) return null;
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      window.atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    return null;
  }
};

const isTokenValid = () => {
  const token = localStorage.getItem('alz_token');
  if (!token) return false;
  const decoded = decodeToken(token);
  if (!decoded) return false;
  return decoded.exp > Date.now() / 1000;
};

export default {
  login,
  registerDoctor,
  registerCaretaker,
  sendOTP,
  verifyOTP,
  logout,
  getMe,
  decodeToken,
  isTokenValid,
};
