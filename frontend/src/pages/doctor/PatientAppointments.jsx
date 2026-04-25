import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import useAuth from '../../hooks/useAuth';
import usePatient from '../../hooks/usePatient';
import api from '../../services/api';
import { Calendar, Clock, Video, Loader2, ArrowLeft, Send, CheckCircle2 } from 'lucide-react';
import { format } from 'date-fns';
import { showSuccess, showError } from '../../components/shared/Toast';

const PatientAppointments = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { patient, loading: patientLoading } = usePatient(id);

  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Form State
  const [scheduledAt, setScheduledAt] = useState('');
  const [notes, setNotes] = useState('');
  const [mode, setMode] = useState('teleconsult');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (id) {
      fetchPatientAppointments();
    }
  }, [id]);

  const fetchPatientAppointments = async () => {
    setLoading(true);
    try {
      // Backend /appointments/ returns all for doctor. We must filter locally or backend endpoint.
      // We will fetch doctor appointments and filter by patient id.
      const res = await api.get('/appointments/');
      const data = res.data?.data || res.data;
      if (Array.isArray(data)) {
        setAppointments(data.filter(app => app.patient_id === id));
      } else {
        setAppointments([]);
      }
    } catch (err) {
      console.error(err);
      showError('Failed to fetch patient appointments');
    } finally {
      setLoading(false);
    }
  };

  const handleSchedule = async (e) => {
    e.preventDefault();
    if (!scheduledAt) return;
    setSubmitting(true);
    try {
      await api.post('/appointments/', {
        patient_id: id,
        doctor_id: user.id,
        caretaker_id: patient?.caretaker_info?.[0]?.id || null, // Assuming first caretaker
        scheduled_at: new Date(scheduledAt).toISOString(),
        notes: notes,
        mode: mode
      });
      showSuccess('Intervention scheduled successfully');
      setScheduledAt('');
      setNotes('');
      fetchPatientAppointments();
    } catch (err) {
      console.error(err);
      showError('Failed to schedule intervention');
    } finally {
      setSubmitting(false);
    }
  };

  if (patientLoading) {
    return (
      <Layout title="Schedule Intervention">
        <div className="flex items-center justify-center min-h-[500px]">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      </Layout>
    );
  }

  return (
    <Layout title={`Schedule Intervention for ${patient?.full_name}`}>
      <div className="max-w-5xl mx-auto space-y-8 pb-12">
        {/* Header */}
        <div className="flex justify-between items-center bg-white/80 backdrop-blur-xl rounded-[2rem] p-6 shadow-sm border border-white/50">
          <button 
            onClick={() => navigate(`/doctor/patient/${id}`)}
            className="flex items-center gap-2 text-gray-500 hover:text-blue-600 font-bold transition-colors uppercase tracking-wider text-xs"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Patient Profile
          </button>
          <div className="text-sm font-black text-amber-600 uppercase tracking-widest bg-amber-50 px-4 py-2 rounded-xl">
             Clinical Intervention
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Form Side */}
          <div className="bg-white/80 backdrop-blur-xl rounded-[2rem] shadow-xl shadow-blue-900/5 border border-white/50 p-8 relative overflow-hidden">
             <div className="absolute top-0 right-0 w-64 h-64 bg-amber-100/40 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
             
             <div className="relative z-10 mb-8">
               <h2 className="text-2xl font-black text-gray-900 tracking-tighter mb-2">Schedule Session</h2>
               <p className="text-gray-500 font-medium text-sm">Assign an immediate teleconsult or clinical visit for protocol adjustment.</p>
             </div>

             <form onSubmit={handleSchedule} className="space-y-6 relative z-10">
                <div>
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-wider mb-2">Date & Time</label>
                  <input 
                    type="datetime-local" 
                    required
                    value={scheduledAt}
                    onChange={(e) => setScheduledAt(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-50/50 border border-gray-200 rounded-xl font-medium focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-wider mb-2">Consultation Mode</label>
                  <div className="flex gap-4">
                    <button
                      type="button"
                      onClick={() => setMode('teleconsult')}
                      className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-bold transition-all ${mode === 'teleconsult' ? 'bg-amber-100 text-amber-700 border-2 border-amber-500 shadow-sm' : 'bg-gray-50 text-gray-500 border-2 border-transparent hover:bg-gray-100'}`}
                    >
                      <Video className="w-4 h-4" /> Teleconsult
                    </button>
                    <button
                      type="button"
                      onClick={() => setMode('in_person')}
                      className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-bold transition-all ${mode === 'in_person' ? 'bg-amber-100 text-amber-700 border-2 border-amber-500 shadow-sm' : 'bg-gray-50 text-gray-500 border-2 border-transparent hover:bg-gray-100'}`}
                    >
                      <Calendar className="w-4 h-4" /> In Person
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-wider mb-2">Clinical Notes & Adjustments</label>
                  <textarea 
                    rows={4}
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="E.g., Suggesting modification to dosage. Low adherence to current schedule."
                    className="w-full px-4 py-3 bg-gray-50/50 border border-gray-200 rounded-xl font-medium focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none resize-none"
                  />
                </div>

                <div className="pt-4 border-t border-gray-100">
                   <button 
                     type="submit" 
                     disabled={submitting || !scheduledAt}
                     className="w-full py-4 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white font-black rounded-xl shadow-lg shadow-amber-500/30 flex items-center justify-center gap-2 transition-all transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                   >
                     {submitting ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
                     DISPATCH INTERVENTION
                   </button>
                </div>
             </form>
          </div>

          {/* Existing Appointments Side */}
          <div className="bg-white/80 backdrop-blur-xl rounded-[2rem] shadow-sm border border-gray-100 p-8 flex flex-col h-full">
            <h3 className="text-xl font-black text-gray-900 tracking-tighter mb-6 flex items-center gap-2">
               <Clock className="w-5 h-5 text-gray-400" /> Patient Schedule
            </h3>

            <div className="flex-1 overflow-y-auto space-y-4 pr-2">
              {loading ? (
                <div className="flex items-center justify-center h-full">
                  <Loader2 className="w-8 h-8 animate-spin text-gray-300" />
                </div>
              ) : appointments.length === 0 ? (
                <div className="text-center py-12">
                   <div className="w-16 h-16 bg-gray-50 border-2 border-dashed border-gray-200 rounded-full flex items-center justify-center mx-auto mb-4">
                     <Calendar className="w-8 h-8 text-gray-300" />
                   </div>
                   <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">No Upcoming Sessions</p>
                </div>
              ) : (
                appointments.map((app) => (
                  <div key={app.id} className="p-4 rounded-xl border border-gray-100 shadow-sm bg-white hover:border-amber-200 transition-colors group">
                     <div className="flex justify-between items-start mb-2">
                        <div>
                          <span className={`px-2 py-1 rounded text-xs font-black uppercase tracking-wider ${app.mode === 'teleconsult' ? 'bg-blue-50 text-blue-600' : 'bg-green-50 text-green-600'}`}>
                             {app.mode}
                          </span>
                        </div>
                        <span className={`px-2 py-1 rounded text-[10px] font-black uppercase tracking-widest ${app.status === 'confirmed' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'}`}>
                          {app.status || 'Pending'}
                        </span>
                     </div>
                     
                     <div className="flex items-center gap-2 my-3">
                        <div className="w-10 h-10 rounded-lg bg-gray-50 border border-gray-100 flex flex-col items-center justify-center">
                           <span className="text-[10px] font-bold text-gray-400 leading-none">{format(new Date(app.scheduled_at), 'MMM')}</span>
                           <span className="text-sm font-black text-gray-900 leading-tight">{format(new Date(app.scheduled_at), 'dd')}</span>
                        </div>
                        <div>
                           <div className="font-bold text-gray-900">{format(new Date(app.scheduled_at), 'EEEE')}</div>
                           <div className="text-xs font-medium text-gray-500">{format(new Date(app.scheduled_at), 'hh:mm a')}</div>
                        </div>
                     </div>

                     {app.notes && (
                       <div className="mt-3 text-sm text-gray-600 bg-gray-50/80 p-2.5 rounded-lg border border-gray-100 italic">
                         "{app.notes}"
                       </div>
                     )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

      </div>
    </Layout>
  );
};

export default PatientAppointments;
