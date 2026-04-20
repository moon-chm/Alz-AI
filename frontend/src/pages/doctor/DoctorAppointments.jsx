import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import doctorService from '../../services/doctor.service';
import { Video, Calendar, Clock, User, MessageSquare, ExternalLink, ChevronRight, Loader2 } from 'lucide-react';
import { format } from 'date-fns';
import { showSuccess, showError } from '../../components/shared/Toast';

const DoctorAppointments = () => {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
    setLoading(true);
    try {
      const data = await doctorService.getAppointments();
      setAppointments(data);
    } catch (err) {
      setError('Failed to load appointments. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const handleJoinCall = (appointment) => {
    // Modular WebRTC point - for now, using a placeholder or window.open
    const roomName = `alz-ai-${appointment.id.substring(0, 8)}`;
    const jitsiUrl = `https://meet.jit.si/${roomName}`;
    
    showSuccess(`Joining teleconsultation for ${appointment.patient_name}`);
    window.open(jitsiUrl, '_blank');
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'confirmed': return 'bg-green-100 text-green-700 border-green-200';
      case 'pending': return 'bg-amber-100 text-amber-700 border-amber-200';
      case 'cancelled': return 'bg-red-100 text-red-700 border-red-200';
      default: return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  return (
    <Layout title="Appointments">
      <div className="max-w-7xl mx-auto space-y-6 pb-12">
        
        {/* Header Section */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 lg:p-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
           <div>
              <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Consultation Schedule</h1>
              <p className="text-gray-500 font-medium mt-1">Manage your teleconsults and in-person visits.</p>
           </div>
           <div className="flex items-center gap-3 bg-blue-50 px-4 py-2 rounded-xl border border-blue-100">
              <Calendar className="w-5 h-5 text-blue-600" />
              <span className="font-bold text-blue-900">{format(new Date(), 'MMMM d, yyyy')}</span>
           </div>
        </div>

        {/* List Section */}
        {loading ? (
          <div className="flex flex-col items-center justify-center min-h-[400px] bg-white rounded-2xl border border-gray-100">
             <Loader2 className="w-10 h-10 text-blue-600 animate-spin mb-4" />
             <p className="text-gray-500 font-medium font-inter">Loading your schedule...</p>
          </div>
        ) : error ? (
           <div className="bg-red-50 p-12 rounded-2xl border border-red-100 text-center">
              <p className="text-red-700 font-bold text-lg mb-4">{error}</p>
              <button onClick={fetchAppointments} className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors">
                 Try Again
              </button>
           </div>
        ) : appointments.length === 0 ? (
           <div className="bg-white p-16 rounded-2xl border border-gray-100 shadow-sm text-center">
              <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-6">
                 <Calendar className="w-10 h-10 text-gray-300" />
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2">No appointments found</h3>
              <p className="text-gray-500 max-w-sm mx-auto">You don't have any consultations scheduled for the coming week.</p>
           </div>
        ) : (
          <div className="grid grid-cols-1 gap-4">
             {appointments.map((app) => (
                <div key={app.id} className="bg-white hover:bg-gray-50 transition-colors border border-gray-100 rounded-2xl p-5 lg:p-6 shadow-sm flex flex-col md:flex-row items-start md:items-center gap-6 group relative overflow-hidden">
                   {/* status side indicator */}
                   <div className={`absolute left-0 top-0 bottom-0 w-1.5 ${app.status === 'confirmed' ? 'bg-green-500' : 'bg-blue-500'}`}></div>

                   {/* Time & Date */}
                   <div className="flex flex-col items-center justify-center min-w-[100px] bg-gray-50/50 p-3 rounded-xl border border-gray-100">
                      <span className="text-sm font-bold text-blue-600 uppercase tracking-wider">{format(new Date(app.scheduled_at), 'EEE')}</span>
                      <span className="text-2xl font-black text-gray-900">{format(new Date(app.scheduled_at), 'dd')}</span>
                      <span className="text-xs font-bold text-gray-500">{format(new Date(app.scheduled_at), 'HH:mm')}</span>
                   </div>

                   {/* Patient Info */}
                   <div className="flex-1 space-y-2">
                      <div className="flex items-center gap-3">
                         <h3 className="text-xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors leading-tight">
                            {app.patient_name}
                         </h3>
                         <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${getStatusColor(app.status)}`}>
                            {app.status || 'Pending'}
                         </span>
                      </div>
                      <div className="flex flex-wrap gap-4 text-sm font-medium text-gray-500">
                         <div className="flex items-center gap-1.5">
                            <Clock className="w-4 h-4" /> 40 min session
                         </div>
                         <div className="flex items-center gap-1.5">
                            <User className="w-4 h-4" /> with {app.caretaker_name || 'N/A'}
                         </div>
                      </div>
                      {app.notes && (
                        <div className="mt-2 text-sm text-gray-600 bg-gray-50 p-2 rounded-lg border-l-2 border-gray-200">
                           <span className="font-bold text-gray-500 text-xs uppercase block mb-0.5">Doctor's Notes</span>
                           "{app.notes}"
                        </div>
                      )}
                   </div>

                   {/* Action Buttons */}
                   <div className="flex items-center gap-3 w-full md:w-auto mt-4 md:mt-0 pt-4 md:pt-0 border-t md:border-t-0 border-gray-100">
                      <button 
                        onClick={() => handleJoinCall(app)}
                        className="flex-1 md:flex-none flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-all shadow-md active:scale-95"
                      >
                         <Video className="w-5 h-5" /> Join Teleconsult
                      </button>
                      <button className="p-3 bg-gray-100 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all border border-transparent hover:border-blue-100">
                         <MessageSquare className="w-5 h-5" />
                      </button>
                   </div>
                </div>
             ))}
          </div>
        )}
      </div>
    </Layout>
  );
};

export default DoctorAppointments;
