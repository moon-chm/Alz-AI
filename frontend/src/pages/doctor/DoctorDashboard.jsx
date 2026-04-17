import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import PatientCard from '../../components/doctor/PatientCard';
import doctorService from '../../services/doctor.service';
import useAuth from '../../hooks/useAuth';
import { Users, AlertCircle, PlusCircle, Search } from 'lucide-react';

const DoctorDashboard = () => {
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    fetchPatients();
  }, []);

  const fetchPatients = async () => {
    setLoading(true);
    try {
      const data = await doctorService.getPatients();
      setPatients(data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load patients');
    } finally {
      setLoading(false);
    }
  };

  const filteredPatients = patients.filter(p => 
    p.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.patient_unique_id?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStats = () => {
    const critical = patients.filter(p => p.urgency?.toLowerCase() === 'red').length;
    const moderate = patients.filter(p => p.urgency?.toLowerCase() === 'amber' || p.urgency?.toLowerCase() === 'orange').length;
    return {
      total: patients.length,
      critical,
      moderate,
      stable: patients.length - critical - moderate
    };
  };

  const stats = getStats();

  return (
    <Layout title="Doctor Dashboard" onSearch={setSearchTerm}>
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* Welcome & Quick Stats */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Welcome back, Dr. {user?.full_name?.split(' ')[0] || ''}</h2>
              <p className="text-gray-500">Here's your patient overview for today.</p>
            </div>
            <button 
              onClick={() => navigate('/doctor/patient/new')}
              className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2 shadow-sm"
            >
              <PlusCircle className="w-5 h-5" />
              Add Patient
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-blue-50/50 rounded-xl p-4 border border-blue-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 bg-blue-100 rounded-lg text-blue-600">
                  <Users className="w-5 h-5" />
                </div>
                <span className="font-semibold text-gray-700">Total Patients</span>
              </div>
              <p className="text-3xl font-bold text-gray-900 ml-1">{stats.total}</p>
            </div>
            <div className="bg-red-50/50 rounded-xl p-4 border border-red-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 bg-red-100 rounded-lg text-red-600">
                  <AlertCircle className="w-5 h-5" />
                </div>
                <span className="font-semibold text-red-800">Critical Needs</span>
              </div>
              <p className="text-3xl font-bold text-red-700 ml-1">{stats.critical}</p>
            </div>
            <div className="bg-amber-50/50 rounded-xl p-4 border border-amber-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 bg-amber-100 rounded-lg text-amber-600">
                  <AlertCircle className="w-5 h-5" />
                </div>
                <span className="font-semibold text-amber-800">Moderate Needs</span>
              </div>
              <p className="text-3xl font-bold text-amber-700 ml-1">{stats.moderate}</p>
            </div>
            <div className="bg-green-50/50 rounded-xl p-4 border border-green-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 bg-green-100 rounded-lg text-green-600">
                  <Users className="w-5 h-5" />
                </div>
                <span className="font-semibold text-green-800">Stable</span>
              </div>
              <p className="text-3xl font-bold text-green-700 ml-1">{stats.stable}</p>
            </div>
          </div>
        </div>

        {/* Patient List */}
        <div>
          <div className="flex justify-between items-end mb-4">
            <h3 className="text-lg font-bold text-gray-900">Patient Directory</h3>
            
            {/* Search visible on mobile/small screens if topbar search is hidden, but usually we just rely on topbar */}
            <div className="md:hidden relative w-full mt-4">
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg"
              />
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            </div>
          </div>

          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {[1, 2, 3, 4, 5, 6, 7, 8].map(i => (
                <div key={i} className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 h-48 animate-pulse flex flex-col justify-between">
                  <div>
                    <div className="h-6 bg-gray-200 rounded w-3/4 mb-4"></div>
                    <div className="h-4 bg-gray-200 rounded w-1/2 mb-4"></div>
                    <div className="flex gap-2">
                      <div className="h-6 bg-gray-200 rounded-full w-20"></div>
                      <div className="h-6 bg-gray-200 rounded-full w-16"></div>
                    </div>
                  </div>
                  <div className="h-4 bg-gray-200 rounded w-full"></div>
                </div>
              ))}
            </div>
          ) : error ? (
            <div className="bg-red-50 text-red-600 p-6 rounded-xl border border-red-100 text-center">
              <p className="font-medium text-lg mb-2">Error Loading Patients</p>
              <p>{error}</p>
              <button onClick={fetchPatients} className="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors">
                Try Again
              </button>
            </div>
          ) : filteredPatients.length === 0 ? (
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
              <div className="w-16 h-16 bg-gray-100 text-gray-400 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="w-8 h-8" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">No patients found</h3>
              <p className="text-gray-500 mb-6">
                {searchTerm ? 'Try adjusting your search terms.' : 'Start by adding your first patient.'}
              </p>
              {!searchTerm && (
                <button 
                  onClick={() => navigate('/doctor/patient/new')}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors"
                >
                  Add Patient
                </button>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {filteredPatients.map(patient => (
                <PatientCard key={patient.id} patient={patient} />
              ))}
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};

export default DoctorDashboard;
