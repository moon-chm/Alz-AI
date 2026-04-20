import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import authService from '../../services/auth.service';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Loader2 } from 'lucide-react';

const Register = () => {
  const [role, setRole] = useState('doctor');
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: '',
    nmc_number: '',
    specialization: '',
    hospital_name: '',
    patient_id: ''
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});
  const navigate = useNavigate();

  const handleToggle = (r) => {
    setRole(r);
    setErrors({});
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
    if (errors[e.target.name]) {
      setErrors({ ...errors, [e.target.name]: null });
    }
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.full_name.trim()) newErrors.full_name = 'Name is required';
    if (!formData.email.trim() || !/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = 'Valid email is required';
    if (formData.password.length < 8) newErrors.password = 'Password must be at least 8 characters';
    if (formData.password !== formData.confirmPassword) newErrors.confirmPassword = 'Passwords do not match';

    if (!/^[6-9]\d{9}$/.test(formData.phone.trim())) {
      newErrors.phone = 'Valid 10-digit Indian phone number is required';
    }

    if (role === 'doctor') {
      const nmc = formData.nmc_number.trim().toUpperCase();
      if (!/^NMC-[A-Z0-9]{5}$/.test(nmc)) {
        newErrors.nmc_number = 'Format: NMC-XXXXX (5 alphanumeric characters)';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    setLoading(true);
    try {
      // Normalize payload outgoing values
      const normalizedPhone = formData.phone.startsWith('+91') 
        ? formData.phone 
        : `+91${formData.phone}`;
        
      const normalizedNMC = (role === 'doctor' && !formData.nmc_number.startsWith('NMC-'))
        ? `NMC-${formData.nmc_number}`
        : formData.nmc_number;

      const payload = {
        full_name: formData.full_name,
        role: role, // Explicitly include role
        email: formData.email,
        password: formData.password,
        phone: normalizedPhone,
        ...(role === 'doctor' && { 
          nmc_number: normalizedNMC,
          specialization: formData.specialization,
          hospital_name: formData.hospital_name
        }),
        ...(role === 'caretaker' && { 
          patient_unique_id: formData.patient_id 
        })
      };

      console.log('Final Registration Payload:', payload);

      if (role === 'doctor') {
        await authService.registerDoctor(payload);
        showSuccess('Registration successful! Your account is pending medical verification.');
        navigate('/login'); // We could also navigate to a specific /pending page
      } else {
        const response = await authService.registerCaretaker(payload);
        showSuccess('Details staged correctly. Authorizing via Patient Family...');
        
        // PATCH 4: Use explicit verification_key from backend
        navigate('/verify-otp', { 
          state: { 
            phone: response.verification_key, 
            recipientPreview: response.recipient_phone_masked 
          } 
        });
      }
    } catch (err) {
      console.error('Registration API Error:', err.response?.data || err.message);
      const msg = err.response?.data?.detail || 'Registration failed';
      showError(msg);
      setErrors({ submit: msg });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center items-center p-4">
      <div className="w-full max-w-lg bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden">

        <div className="bg-[#1a2332] p-6 text-center text-white">
          <h1 className="text-2xl font-bold tracking-wider">Alz-AI Registration</h1>
          <p className="text-gray-400 mt-1 text-sm">Join the leading Alzheimer's care platform</p>
        </div>

        <div className="flex border-b border-gray-200">
          <button
            type="button"
            className={`flex-1 py-4 text-center font-medium transition-colors ${role === 'doctor' ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50/50' : 'text-gray-500 hover:bg-gray-50'}`}
            onClick={() => handleToggle('doctor')}
          >
            I am a Doctor
          </button>
          <button
            type="button"
            className={`flex-1 py-4 text-center font-medium transition-colors ${role === 'caretaker' ? 'text-green-600 border-b-2 border-green-600 bg-green-50/50' : 'text-gray-500 hover:bg-gray-50'}`}
            onClick={() => handleToggle('caretaker')}
          >
            I am a Caretaker
          </button>
        </div>

        <div className="p-8 relative">
          {errors.submit && (
            <div className="mb-4 bg-red-50 text-red-600 p-3 rounded-lg text-sm font-medium border border-red-100 text-center">
              {errors.submit}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input
                  type="text" name="full_name" value={formData.full_name} onChange={handleChange}
                  className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-gray-50 ${errors.full_name ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'}`}
                  placeholder="John Doe"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email" name="email" value={formData.email} onChange={handleChange}
                  className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-gray-50 ${errors.email ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'}`}
                  placeholder="john@example.com"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input
                  type="password" name="password" value={formData.password} onChange={handleChange}
                  className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-gray-50 ${errors.password ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'}`}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Confirm</label>
                <input
                  type="password" name="confirmPassword" value={formData.confirmPassword} onChange={handleChange}
                  className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-gray-50 ${errors.confirmPassword ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'}`}
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Personal Phone Number</label>
              <input
                type="tel" name="phone" value={formData.phone} onChange={handleChange} placeholder="e.g. 9876543210"
                className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-gray-50 ${errors.phone ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'}`}
              />
            </div>

            {role === 'caretaker' && (
              <div className="bg-blue-50/50 p-4 rounded-xl border border-blue-100">
                <label className="block text-sm font-semibold text-blue-900 mb-1">Patient ID (Provided by Doctor)</label>
                <input
                  type="text" name="patient_id" value={formData.patient_id} onChange={handleChange} placeholder="PAT-XXXXXX"
                  className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 bg-white ${errors.patient_id ? 'border-red-500 focus:ring-red-500' : 'border-blue-200 focus:ring-blue-500'}`}
                />
                <p className="text-[11px] text-blue-600 mt-2 italic">OTP will be sent to the Patient's trusted family number for authorization.</p>
              </div>
            )}

            {role === 'doctor' && (
              <div className="space-y-4 pt-2">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">NMC Number</label>
                    <input
                      type="text" name="nmc_number" value={formData.nmc_number} onChange={handleChange} placeholder="NMC-XXXXX"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Specialization</label>
                    <input
                      type="text" name="specialization" value={formData.specialization} onChange={handleChange} placeholder="Neurologist"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Hospital / Clinic Name</label>
                  <input
                    type="text" name="hospital_name" value={formData.hospital_name} onChange={handleChange} placeholder="Central Health Hospital"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50"
                  />
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className={`w-full mt-6 text-white py-3 rounded-lg font-medium transition-colors shadow-sm disabled:opacity-70 flex justify-center items-center ${role === 'doctor' ? 'bg-blue-600 hover:bg-blue-700' : 'bg-green-600 hover:bg-green-700'}`}
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : `Continue as ${role === 'doctor' ? 'Doctor' : 'Caretaker'}`}
            </button>
          </form>

          <div className="mt-8 text-center text-sm text-gray-500">
            Already have an account? <Link to="/login" className="text-blue-600 hover:underline font-medium">Log in</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;
