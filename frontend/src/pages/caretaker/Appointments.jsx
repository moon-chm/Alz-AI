import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import caretakerService from '../../services/caretaker.service';
import { usePatientContext } from '../../context/PatientContext';
import { Calendar, Clock, User, Plus, X, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import { format, isAfter, isBefore, startOfToday } from 'date-fns';
import { showSuccess, showError } from '../../components/shared/Toast';

const Appointments = () => {
  const { selectedPatient } = usePatientContext();
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    doctor_id: '', // Would normally fetch from a list of doctors
    scheduled_at_date: format(new Date(), 'yyyy-MM-dd'),
    scheduled_at_time: '10:00',
    notes: ''
  });

  useEffect(() => {
    if (selectedPatient?.id) fetchAppointments();
  }, [selectedPatient]);

  const fetchAppointments = async () => {
    setLoading(true);
    try {
      const data = await caretakerService.getAppointments();
      setAppointments(data);
    } catch (err) {
      console.error('Failed to fetch appointments:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!selectedPatient?.id) return;
    
    setIsSubmitting(true);
    try {
      const scheduledAt = new Date(`${formData.scheduled_at_date}T${formData.scheduled_at_time}`);
      
      await caretakerService.createAppointment({
        patient_id: selectedPatient.id,
        doctor_id: selectedPatient.doctor_id, // Default to primary doctor for now
        scheduled_at: scheduledAt.toISOString(),
        notes: formData.notes
      });
      
      showSuccess('Appointment scheduled successfully');
      setShowAddForm(false);
      fetchAppointments();
    } catch (err) {
      showError('Failed to schedule appointment');
    } finally {
      setIsSubmitting(false);
    }
  };

  const upcoming = appointments.filter(a => isAfter(new Date(a.scheduled_at), new Date()));
  const past = appointments.filter(a => isBefore(new Date(a.scheduled_at), new Date()));

  return (
    <Layout title="Appointments">
      <div className="max-w-5xl mx-auto space-y-8 pb-12">
        
        {/* Header */}
        <div className="flex justify-between items-center bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
           <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
                 <Calendar className="w-6 h-6" />
              </div>
              <div>
                 <h2 className="text-xl font-bold text-gray-900">Manage Schedule</h2>
                 <p className="text-sm text-gray-500 font-medium">Coordinate visits with doctors</p>
              </div>
           </div>
           <button 
             onClick={() => setShowAddForm(true)}
             className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-xl font-bold transition-all shadow-md active:scale-95"
           >
              <Plus className="w-5 h-5" /> Schedule New
           </button>
        </div>

        {showAddForm && (
          <div className="bg-white rounded-2xl shadow-xl border border-blue-100 p-8 animate-in fade-in slide-in-from-top-4 duration-300">
             <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-gray-900">Schedule New Appointment</h3>
                <button onClick={() => setShowAddForm(false)} className="text-gray-400 hover:text-gray-600 p-1">
                   <X className="w-6 h-6" />
                </button>
             </div>
             
             <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                   <label className="block text-sm font-bold text-gray-700 mb-2">Primary Doctor</label>
                   <div className="px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-gray-600 flex items-center gap-3">
                      <User className="w-5 h-5" /> 
                      <span className="font-medium">Assigned Primary Physician</span>
                   </div>
                   <p className="mt-1 text-xs text-gray-400">Appointments are currently linked to the assigned doctor.</p>
                </div>

                <div className="grid grid-cols-2 gap-4">
                   <div>
                      <label className="block text-sm font-bold text-gray-700 mb-2">Date</label>
                      <input 
                        type="date" 
                        required
                        value={formData.scheduled_at_date}
                        onChange={(e) => setFormData({...formData, scheduled_at_date: e.target.value})}
                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                      />
                   </div>
                   <div>
                      <label className="block text-sm font-bold text-gray-700 mb-2">Time</label>
                      <input 
                        type="time" 
                        required
                        value={formData.scheduled_at_time}
                        onChange={(e) => setFormData({...formData, scheduled_at_time: e.target.value})}
                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                      />
                   </div>
                </div>

                <div className="md:col-span-2">
                   <label className="block text-sm font-bold text-gray-700 mb-2">Consultation Notes (Optional)</label>
                   <textarea 
                     rows="3"
                     value={formData.notes}
                     onChange={(e) => setFormData({...formData, notes: e.target.value})}
                     placeholder="Mention any symptoms or observations..."
                     className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                   ></textarea>
                </div>

                <div className="md:col-span-2 flex justify-end gap-3 pt-4 border-t border-gray-50">
                   <button 
                     type="button" 
                     onClick={() => setShowAddForm(false)}
                     className="px-6 py-2.5 text-gray-600 font-bold hover:bg-gray-50 rounded-xl"
                   >
                     Cancel
                   </button>
                   <button 
                     type="submit" 
                     disabled={isSubmitting}
                     className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-2.5 rounded-xl font-bold shadow-lg transition-all disabled:opacity-50 flex items-center gap-2"
                   >
                      {isSubmitting ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Confirm Appointment'}
                   </button>
                </div>
             </form>
          </div>
        )}

        {/* Categories */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
           
           {/* Upcoming */}
           <div className="space-y-4">
              <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2 px-2">
                 <div className="w-2 h-2 rounded-full bg-blue-500"></div> Upcoming Visits
              </h3>
              
              {loading ? (
                <div className="space-y-3 animate-pulse">
                   {[1,2].map(i => <div key={i} className="h-32 bg-gray-100 rounded-2xl"></div>)}
                </div>
              ) : upcoming.length === 0 ? (
                <div className="bg-gray-50 rounded-2xl p-12 text-center border border-gray-100">
                   <p className="text-gray-400 font-medium">No upcoming appointments</p>
                </div>
              ) : (
                <div className="space-y-4">
                   {upcoming.map(appt => (
                     <div key={appt.id} className="bg-white p-5 rounded-2xl border-l-4 border-l-blue-500 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
                        <div className="flex justify-between items-start mb-3">
                           <div>
                              <p className="text-xs font-extrabold text-blue-600 uppercase tracking-wider mb-1">Confirmed</p>
                              <h4 className="text-lg font-bold text-gray-900">{appt.doctor_name}</h4>
                           </div>
                           <div className="text-right">
                              <p className="text-sm font-bold text-gray-900">{format(new Date(appt.scheduled_at), 'MMM dd, yyyy')}</p>
                              <p className="text-xs text-gray-500 font-medium">{format(new Date(appt.scheduled_at), 'hh:mm a')}</p>
                           </div>
                        </div>
                        {appt.notes && (
                          <div className="bg-gray-50 p-3 rounded-lg text-sm text-gray-600 italic">
                             "{appt.notes}"
                          </div>
                        )}
                     </div>
                   ))}
                </div>
              )}
           </div>

           {/* Past */}
           <div className="space-y-4">
              <h3 className="text-lg font-bold text-gray-500 flex items-center gap-2 px-2">
                 Past History
              </h3>
              
              {loading ? (
                <div className="space-y-3 animate-pulse">
                   {[1,2].map(i => <div key={i} className="h-24 bg-gray-50 rounded-2xl"></div>)}
                </div>
              ) : past.length === 0 ? (
                <div className="p-8 text-center text-gray-300 italic text-sm">
                   No past records found
                </div>
              ) : (
                <div className="space-y-3 opacity-60">
                   {past.map(appt => (
                     <div key={appt.id} className="bg-gray-50 p-4 rounded-xl border border-gray-100 flex justify-between items-center">
                        <div className="flex items-center gap-3">
                           <CheckCircle className="w-5 h-5 text-gray-400" />
                           <div>
                              <h4 className="text-sm font-bold text-gray-700">{appt.doctor_name}</h4>
                              <p className="text-xs text-gray-500">{format(new Date(appt.scheduled_at), 'MMM dd, yyyy')}</p>
                           </div>
                        </div>
                        <div className="text-xs font-bold text-gray-400">Completed</div>
                     </div>
                   ))}
                </div>
              )}
           </div>

        </div>

      </div>
    </Layout>
  );
};

export default Appointments;
