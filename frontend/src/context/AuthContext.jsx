import React, { createContext, useState, useEffect, useContext } from 'react';
import authService from '../services/auth.service';
import api from '../services/api';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  const initAuth = async () => {
    try {
      const storedToken = localStorage.getItem('access_token');
      if (storedToken) {
        const userData = await authService.getMe();
        setToken(storedToken);
        setUser(userData);
      }
    } catch (err) {
      console.warn("Auth initialization failed, clearing state:", err);
      // Let the interceptor handle the actual logout/localStorage clear if refresh fails
      setToken(null);
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    initAuth();
  }, []);

  const login = (newToken, userData) => {
    setToken(newToken);
    setUser(userData);
  };

  const logout = async () => {
    try {
      await api.post('/auth/logout');
    } catch (e) {
      console.log('Server logout failed, clearing local state anyway');
    }
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    setToken(null);
    setUser(null);
    window.location.href = '/login';
  };

  const isAuthenticated = () => {
    return !!token && !!user;
  };

  const hasRole = (role) => {
    return user?.role === role;
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, isAuthenticated, hasRole, loading }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuthContext = () => useContext(AuthContext);