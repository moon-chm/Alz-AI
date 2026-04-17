import { useAuthContext } from '../context/AuthContext';

const useAuth = () => {
  const { user, token, login, logout, isAuthenticated, hasRole } = useAuthContext();

  return {
    user,
    token,
    login,
    logout,
    isAuthenticated,
    hasRole,
  };
};

export default useAuth;
