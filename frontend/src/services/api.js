import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  withCredentials: false,
  headers: { 'Content-Type': 'application/json' },
});

let isRefreshing = false;
let failedQueue = [];

const processQueue = (error, token = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  
  // Smart Header Guard: If sending FormData, don't force JSON content-type
  if (config.data instanceof FormData) {
    if (config.headers['Content-Type']) {
      delete config.headers['Content-Type'];
    }
  }
  
  return config;
});

api.interceptors.response.use(
  (response) => {
    // If we have the wrapped structure, unwrap it for the rest of the app
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      const { success, data, error, message } = response.data;
      if (success) {
        // Return only the inner data to keep existing code compatible
        return {
          ...response,
          data: data,
          meta: { message } // Optional helper if a component needs the message
        };
      } else {
        // Handle explicit failure returned with 200/other code if necessary
        // Re-routing to the error interceptor logic essentially
        const err = new Error(error || message || 'API Error');
        err.response = response;
        return Promise.reject(err);
      }
    }
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    
    if (originalRequest.url.includes('/auth/refresh')) {
      return Promise.reject(error);
    }

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise(function(resolve, reject) {
          failedQueue.push({resolve, reject});
        }).then(token => {
          originalRequest.headers['Authorization'] = 'Bearer ' + token;
          return api(originalRequest);
        }).catch(err => {
          return Promise.reject(err);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem('refresh_token');
        const response = await axios.post('/api/auth/refresh', { refresh_token: refreshToken }, {
          withCredentials: false
        });
        
        const { access_token, refresh_token } = response.data.data || response.data;
        localStorage.setItem('access_token', access_token);
        if (refresh_token) localStorage.setItem('refresh_token', refresh_token);
        
        api.defaults.headers.common['Authorization'] = 'Bearer ' + access_token;
        originalRequest.headers['Authorization'] = 'Bearer ' + access_token;
        
        processQueue(null, access_token);
        return api(originalRequest);
      } catch (err) {
        processQueue(err, null);
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(err);
      } finally {
        isRefreshing = false;
      }
    }
    
    if (error.response?.status === 422 || error.response?.data?.success === false) {
      // Formatted validation or clinical error from our contract
      const errorData = error.response.data;
      const validationDetail = errorData.error || errorData.message || errorData.detail || "Request failed";
      console.warn("API Error:", validationDetail);
      
      // Map to the format standard UI components expect (.detail)
      if (errorData) {
        errorData.detail = validationDetail;
      }
      error.friendlyMessage = validationDetail;
    }
    
    return Promise.reject(error);
  }
);

export default api;
