import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import useAuth from '../../hooks/useAuth';
import LoadingSpinner from './LoadingSpinner';

const RoleRoute = ({ requiredRole, children }) => {
  const { user, loading } = useAuth();

  if (loading) return <LoadingSpinner fullScreen />;

  if (user?.role !== requiredRole) {
    return <Navigate to="/login" replace />;
  }

  return children ? children : <Outlet />;
};

export default RoleRoute;
