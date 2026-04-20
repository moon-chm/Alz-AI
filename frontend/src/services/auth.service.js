import api from './api';

const login = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  // response.data is already unwrapped by the interceptor
  const { access_token, refresh_token, role, user } = response.data;
  
  if (access_token) {
    localStorage.setItem('access_token', access_token);
    if (refresh_token) localStorage.setItem('refresh_token', refresh_token);
    
    // Set for current instance immediate use
    api.defaults.headers.common['Authorization'] = 'Bearer ' + access_token;
    
    // The login response already contains the user object in my new contract
    return { token: access_token, role, user: user };
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
  const response = await api.post('/auth/verify-otp', { 
    phone: verificationKey,
    otp 
  });
  
  const { access_token, refresh_token, role, user } = response.data;
  if (access_token) {
    localStorage.setItem('access_token', access_token);
    if (refresh_token) localStorage.setItem('refresh_token', refresh_token);
    
    api.defaults.headers.common['Authorization'] = 'Bearer ' + access_token;
    
    return { token: access_token, role, user: user };
  }
  return response.data;
};

const logout = () => {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
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
  const token = localStorage.getItem('access_token');
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
