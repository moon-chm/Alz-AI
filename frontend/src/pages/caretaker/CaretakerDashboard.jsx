import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import VitalsPanel from '../../components/caretaker/VitalsPanel';
import StatusCard from '../../components/caretaker/StatusCard';
import AlertFeed from '../../components/caretaker/AlertFeed';
import { usePatientContext } from '../../context/PatientContext';
import caretakerService from '../../services/caretaker.service';
import useAuth from '../../hooks/useAuth';
import { Settings, MapPin, Search, Link as LinkIcon, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { showSuccess, showError } from '../../components/shared/Toast';
import useWebSocket from '../../hooks/useWebSocket';

const CaretakerDashboard = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { selectedPatient, fetchPatientData, loading: contextLoading } = usePatientContext();
  
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [linkingPatient, setLinkingPatient] = useState(false);
  const [patientIdInput, setPatientIdInput] = useState('');

  // 1. Real-time WebSocket hook
  const { isConnected } = useWebSocket(selectedPatient?.id, (data) => {
    console.log('Dashboard Real-time Event:', data.event_type);
    
    if (['vitals_updated', 'alert_created', 'mood_updated', 'location_updated'].includes(data.event_type)) {
       // Deep refresh of context data on any critical event
       fetchPatientData();
       
       if (data.event_type === 'alert_created' && data.severity >= 4) {
          showSuccess(`CRITICAL ALERT: ${data.message}`);
       }
    }
  });
  
  useEffect(() => {
    loadDashboardData();
    
    // 2. Slow heartbeat fallback (60s instead of 30s)
    const interval = setInterval(() => {
      if (selectedPatient && !isConnected) {
        fetchPatientData();
      }
    }, 60000);
    
    return () => clearInterval(interval);
  }, [selectedPatient, isConnected]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      if (!selectedPatient) {
        await fetchPatientData('default'); 
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading || contextLoading) {
    return (
      <Layout title="Dashboard">
         <div className="flex items-center justify-center h-full min-h-[500px]">
            <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full"></div>
         </div>
      </Layout>
    );
  }

  const handleLinkPatient = async (e) => {
    e.preventDefault();
    if (!patientIdInput.trim()) return;
    
    setLinkingPatient(true);
    try {
      await caretakerService.linkPatient(patientIdInput.trim());
      showSuccess('Patient linked successfully!');
      // Trigger a context refresh
      await fetchPatientData();
    } catch (err) {
      showError(err.response?.data?.detail || 'Failed to link patient');
    } finally {
      setLinkingPatient(false);
    }
  };

  if (error || !selectedPatient) {
    return (
      <Layout title="Dashboard">
        <div className="flex flex-col items-center justify-center min-h-[60vh] max-w-lg mx-auto text-center px-4">
          <div className="w-20 h-20 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner">
             <LinkIcon className="w-10 h-10" />
          </div>
          <h2 className="text-2xl font-extrabold text-gray-900 mb-2">No Active Patient</h2>
          <p className="text-gray-500 mb-8 font-medium">To begin monitoring, please enter the Unique Patient ID provided by the doctor.</p>
          
          <form onSubmit={handleLinkPatient} className="w-full bg-white p-6 rounded-2xl shadow-xl border border-gray-100">
            <div className="flex flex-col gap-4">
              <div className="relative">
                <input 
                  type="text" 
                  value={patientIdInput}
                  onChange={(e) => setPatientIdInput(e.target.value.toUpperCase())}
                  placeholder="ALZ-XX-XXXX-XXXXX"
                  className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none font-mono text-center tracking-widest uppercase transition-all"
                />
              </div>
              <button 
                type="submit" 
                disabled={linkingPatient || !patientIdInput}
                className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-all shadow-md disabled:bg-gray-300 flex justify-center items-center gap-2"
              >
                {linkingPatient ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Link Patient Profile'}
              </button>
            </div>
          </form>
          
          <p className="mt-8 text-sm text-gray-400">
            Need help? Contact the primary doctor to get your Patient's Unique ID.
          </p>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Monitoring Dashboard">
      <div className="max-w-7xl mx-auto space-y-6 pb-12">
        
        {/* Welcome Section */}
        <div className="flex justify-between items-center bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">Hello, {user?.full_name?.split(' ')[0] || 'Caretaker'}</h2>
            <p className="text-gray-500 font-medium">Monitoring {selectedPatient.full_name}</p>
          </div>
          <div className="flex gap-3">
             <button 
               onClick={() => navigate('/caretaker/location')}
               className="flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg font-medium transition-colors border border-blue-100"
             >
               <MapPin className="w-5 h-5" /> View Location
             </button>
          </div>
        </div>

        {/* Top Grid: Status & Vitals */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="xl:col-span-1 border border-gray-100 rounded-2xl overflow-hidden shadow-sm">
             <StatusCard 
               status={selectedPatient.urgency} 
               patientName={selectedPatient.full_name} 
               lastUpdated={new Date()} 
             />
          </div>
          
          <div className="xl:col-span-2">
             <VitalsPanel />
          </div>
        </div>

        {/* Secondary Grid: Meds & Alerts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
           <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 h-[400px] flex flex-col">
              <div className="flex justify-between items-center mb-4">
                 <h3 className="text-lg font-bold text-gray-900">Today's Schedule & Meds</h3>
                 <button onClick={() => navigate('/caretaker/medications')} className="text-sm text-blue-600 hover:text-blue-800 font-medium">View All</button>
              </div>
              <div className="flex-1 flex flex-col items-center justify-center text-center">
                 <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mb-3">
                    <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
                 </div>
                 <p className="text-gray-500 font-medium">Schedule is clear for the next few hours.</p>
                 <button onClick={() => navigate('/caretaker/medications')} className="mt-4 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors text-sm font-medium">
                   Manage Schedule
                 </button>
              </div>
           </div>

           <div className="h-[400px]">
              <AlertFeed patientId={selectedPatient.id} />
           </div>
        </div>

      </div>
    </Layout>
  );
};

export default CaretakerDashboard;
