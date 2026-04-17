import React, { useState } from 'react';
import { useNavigate, Link, Navigate } from 'react-router-dom';
import useAuth from '../../hooks/useAuth';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
  const { login: authenticate, isAuthenticated, user } = useAuth();
  const navigate = useNavigate();

  if (isAuthenticated()) {
    if (user?.role === 'doctor') return <Navigate to="/doctor/dashboard" replace />;
    if (user?.role === 'caretaker') return <Navigate to="/caretaker/dashboard" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }
    
    setLoading(true);
    setError(null);
    
    try {
      const authService = (await import('../../services/auth.service')).default;
      const { token, role, user: userData } = await authService.login(email, password);
      
      authenticate(token, userData); 
      
      if (role === 'doctor') navigate('/doctor/dashboard');
      else navigate('/caretaker/dashboard');
      
    } catch (err) {
      setError(err.response?.data?.detail || 'Invalid email or password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center items-center p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-[#1a2332] rounded-xl flex items-center justify-center mx-auto mb-4 shadow-lg">
            <span className="text-white text-2xl font-bold tracking-wider">AI</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Alz-AI</h1>
          <p className="text-gray-500 mt-1 font-medium">Care Platform</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm border border-red-100 text-center font-medium">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input 
              type="email" 
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
              placeholder="name@example.com"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1">
              <label className="block text-sm font-medium text-gray-700">Password</label>
              <a href="#" className="text-xs text-blue-600 hover:underline">Forgot Password?</a>
            </div>
            <div className="relative">
              <input 
                type={showPassword ? "text" : "password"} 
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
                placeholder="••••••••"
              />
              <button 
                type="button" 
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-sm font-medium"
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2.5 rounded-lg font-medium transition-colors shadow-sm disabled:opacity-70 flex justify-center items-center mt-2"
          >
            {loading ? (
              <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            ) : "Log In"}
          </button>
        </form>

        <div className="mt-8 text-center text-sm text-gray-500">
          Don't have an account? <Link to="/register" className="text-blue-600 hover:underline font-medium">Register here</Link>
        </div>
      </div>
    </div>
  );
};

export default Login;
