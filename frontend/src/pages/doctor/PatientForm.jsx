import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import doctorService from '../../services/doctor.service';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Loader2, ArrowLeft, Save } from 'lucide-react';

const PatientForm = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    full_name: '',
    dob: '',
    gender: 'Male',
    level: '1',
    urgency: 'Green',
    language: 'Hindi',
    trusted_phone: '',
    diagnosis_notes: ''
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const payload = {
        ...formData,
        level: parseInt(formData.level, 10)
      };
      const data = await doctorService.addPatient(payload);
      showSuccess(`Patient ${data.full_name} created successfully!`);
      navigate(`/doctor/patient/${data.id}`);
    } catch (err) {
      showError(err.response?.data?.detail || 'Failed to create patient record');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Add New Patient">
      <div className="max-w-3xl mx-auto pb-12">
        <button 
          onClick={() => navigate('/doctor/dashboard')}
          className="flex items-center gap-2 text-gray-600 hover:text-blue-600 font-medium transition-colors mb-6"
        >
          <ArrowLeft className="w-5 h-5" /> Back to Dashboard
        </button>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="bg-blue-600 p-6 text-white">
            <h2 className="text-2xl font-bold">Register Patient</h2>
            <p className="text-blue-100 mt-1">Enter patient details to generate ALZ-ID</p>
          </div>

          <form onSubmit={handleSubmit} className="p-8 space-y-6">
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name <span className="text-red-500">*</span></label>
                <input 
                  type="text" 
                  name="full_name" 
                  required
                  value={formData.full_name} 
                  onChange={handleChange}
                  placeholder="e.g., Ramesh Kumar"
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Date of Birth <span className="text-red-500">*</span></label>
                  <input 
                    type="date" 
                    name="dob" 
                    required
                    value={formData.dob} 
                    onChange={handleChange}
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Gender</label>
                  <select 
                    name="gender" 
                    value={formData.gender} 
                    onChange={handleChange}
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors appearance-none"
                  >
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4 border-t border-gray-100">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Alzheimer's Level</label>
                <select 
                  name="level" 
                  value={formData.level} 
                  onChange={handleChange}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors appearance-none"
                >
                  <option value="1">Level 1 - Early</option>
                  <option value="2">Level 2 - Moderate</option>
                  <option value="3">Level 3 - Severe</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Urgency Status</label>
                <select 
                  name="urgency" 
                  value={formData.urgency} 
                  onChange={handleChange}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors appearance-none"
                >
                  <option value="Green">Green (Stable)</option>
                  <option value="Amber">Amber (Moderate)</option>
                  <option value="Red">Red (Critical)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Preferred Language</label>
                <select 
                  name="language" 
                  value={formData.language} 
                  onChange={handleChange}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors appearance-none"
                >
                  <option value="Hindi">Hindi</option>
                  <option value="English">English</option>
                  <option value="Marathi">Marathi</option>
                  <option value="Tamil">Tamil</option>
                  <option value="Telugu">Telugu</option>
                  <option value="Kannada">Kannada</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Emergency Phone <span className="text-red-500">*</span></label>
                <input 
                  type="tel" 
                  name="trusted_phone" 
                  required
                  value={formData.trusted_phone} 
                  onChange={handleChange}
                  placeholder="+91..."
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
                />
              </div>
            </div>

            <div className="pt-4 border-t border-gray-100">
              <label className="block text-sm font-medium text-gray-700 mb-1">Diagnosis Notes</label>
              <textarea 
                name="diagnosis_notes" 
                rows="4"
                value={formData.diagnosis_notes} 
                onChange={handleChange}
                placeholder="Include initial observations, comorbidities, and initial treatment plan..."
                className="w-full px-4 py-2 bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors resize-y"
              ></textarea>
            </div>

            <div className="flex justify-end gap-4 pt-6 mt-6 border-t border-gray-100">
              <button 
                type="button" 
                onClick={() => navigate('/doctor/dashboard')}
                className="px-6 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button 
                type="submit" 
                disabled={loading}
                className="bg-blue-600 flex items-center justify-center gap-2 hover:bg-blue-700 text-white px-8 py-2.5 rounded-lg font-medium transition-colors shadow-sm disabled:opacity-70 min-w-[160px]"
              >
                {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <><Save className="w-5 h-5"/> Save Patient</>}
              </button>
            </div>

          </form>
        </div>
      </div>
    </Layout>
  );
};

export default PatientForm;
