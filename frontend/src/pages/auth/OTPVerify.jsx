import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useLocation, Navigate } from 'react-router-dom';
import authService from '../../services/auth.service';
import useAuth from '../../hooks/useAuth';
import { Loader2 } from 'lucide-react';

// ─── Role → Route Mapping ────────────────────────────────────────────────────
const ROLE_ROUTES = {
  caretaker: '/caretaker/dashboard',
  doctor: '/doctor/dashboard',
  admin: '/admin/dashboard',
};
const DEFAULT_ROUTE = '/dashboard';

// ─── Component ───────────────────────────────────────────────────────────────
const OTPVerify = () => {
  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [cooldown, setCooldown] = useState(30);
  const [recipientPreview, setRecipientPreview] = useState(null);

  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useAuth();

  const inputRefs = useRef([]);
  const isSubmitting = useRef(false);

  const phone = location.state?.phone;

  // Initialize preview from navigation state if available
  useEffect(() => {
    if (location.state?.recipientPreview) {
      setRecipientPreview(location.state.recipientPreview);
    }
  }, [location.state]);

  // ── Cooldown timer ──────────────────────────────────────────────────────────
  useEffect(() => {
    if (cooldown <= 0) return;
    const timer = setTimeout(() => setCooldown(prev => prev - 1), 1000);
    return () => clearTimeout(timer);
  }, [cooldown]);

  if (!phone) {
    return <Navigate to="/register" replace />;
  }

  const handleSubmit = useCallback(async (e, otpOverride = null) => {
    if (e) e.preventDefault();

    const otpCode = (otpOverride ?? otp).join('');
    if (otpCode.length !== 6) return;

    if (isSubmitting.current) return;
    isSubmitting.current = true;

    setLoading(true);
    setError(null);

    try {
      const response = await authService.verifyOTP(phone, otpCode);
      login(response.token, response.user);

      // PATCH 7: Strict role-based routing
      const userRole = response.user?.role || response.role;
      const destination = ROLE_ROUTES[userRole] ?? DEFAULT_ROUTE;
      
      console.log(`[AUTH] Routing ${userRole} to ${destination}`);
      navigate(destination);
    } catch (err) {
      setOtp(['', '', '', '', '', '']);
      inputRefs.current[0]?.focus();
      setError(err.response?.data?.detail || 'Invalid OTP. Please try again.');
    } finally {
      setLoading(false);
      isSubmitting.current = false;
    }
  }, [otp, phone, login, navigate]);

  const handleChange = (e, index) => {
    let val = e.target.value;
    if (isNaN(val)) return;

    val = val.substring(val.length - 1);
    setError(null);

    const newOtp = [...otp];
    newOtp[index] = val;
    setOtp(newOtp);

    if (val && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (e, index) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text/plain').trim();
    if (!/^\d{6}$/.test(pastedData)) return;

    const newOtp = pastedData.split('');
    setOtp(newOtp);
    inputRefs.current[5]?.focus();
    setError(null);

    setTimeout(() => handleSubmit(null, newOtp), 0);
  };

  const handleResend = async () => {
    if (cooldown > 0) return;
    try {
      const response = await authService.sendOTP(phone);
      if (response.recipient_preview) {
        setRecipientPreview(response.recipient_preview);
      }
      setCooldown(30);
      setOtp(['', '', '', '', '', '']);
      setError(null);
      inputRefs.current[0]?.focus();
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to resend OTP');
    }
  };

  const isComplete = otp.every(digit => digit !== '');

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center items-center p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl border border-gray-100 p-8 text-center">

        <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6">
          <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2"
              d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">Verify Your Account</h1>
        <p className="text-gray-500 mb-8">
          Enter the 6-digit OTP sent to{' '}
          <span className="font-semibold text-gray-800">
            {recipientPreview || phone}
          </span>
        </p>

        {error && (
          <div className="mb-6 bg-red-50 text-red-600 p-3 rounded-lg text-sm font-medium border border-red-100">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="flex justify-center gap-2 sm:gap-3 mb-8">
            {otp.map((digit, index) => (
              <input
                key={index}
                ref={el => (inputRefs.current[index] = el)}
                type="text"
                inputMode="numeric"
                maxLength="1"
                value={digit}
                onChange={e => handleChange(e, index)}
                onKeyDown={e => handleKeyDown(e, index)}
                onPaste={handlePaste}
                className={`w-10 h-12 sm:w-12 sm:h-14 text-center text-xl font-bold border-2 rounded-lg
                  focus:outline-none focus:ring-0 focus:border-blue-500 transition-colors
                  ${error ? 'border-red-400 bg-red-50' : 'border-gray-200 bg-gray-50'}`}
              />
            ))}
          </div>

          <button
            type="submit"
            disabled={!isComplete || loading}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium
              transition-colors shadow-sm disabled:opacity-50 flex justify-center items-center mb-6"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Verify & Proceed'}
          </button>
        </form>

        <div className="text-sm">
          {cooldown > 0 ? (
            <p className="text-gray-500">
              Resend OTP in <span className="font-medium text-gray-900">{cooldown}s</span>
            </p>
          ) : (
            <button onClick={handleResend} className="text-blue-600 font-medium hover:underline">
              Resend OTP
            </button>
          )}
        </div>

      </div>
    </div>
  );
};

export default OTPVerify;