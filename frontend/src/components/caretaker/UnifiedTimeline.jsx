import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import caretakerService from '../../services/caretaker.service';
import { Calendar, Clock, Pill, User, Video, Info, ChevronRight, Loader2, AlertCircle } from 'lucide-react';
import { format, parseISO, isAfter } from 'date-fns';

const UnifiedTimeline = ({ patientId }) => {
  const navigate = useNavigate();
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (patientId) {
      fetchTimelineData();
    }
  }, [patientId]);

  const fetchTimelineData = async () => {
    setLoading(true);
    try {
      // Fetch both in parallel
      const [medSchedule, appointments] = await Promise.all([
        caretakerService.getDailySchedule(patientId),
        caretakerService.getUpcomingAppointments()
      ]);

      // Normalize appointments to match the event format
      const apptEvents = appointments.map(appt => ({
        id: `appt-${appt.id}`,
        type: 'appointment',
        title: 'Doctor Consultation',
        subtitle: `with ${appt.doctor_name || 'Primary Physician'}`,
        time: format(new Date(appt.scheduled_at), 'HH:mm'),
        fullTime: new Date(appt.scheduled_at),
        status: appt.status,
        raw: appt
      }));

      // Merge and sort
      const merged = [...medSchedule, ...apptEvents].sort((a, b) => {
        return a.time.localeCompare(b.time);
      });

      setEvents(merged);
    } catch (err) {
      console.error('Timeline fetch error:', err);
      setError('Could not sync daily agenda');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 h-[450px] flex flex-col items-center justify-center">
         <Loader2 className="w-8 h-8 text-blue-500 animate-spin mb-4" />
         <p className="text-gray-400 font-medium">Syncing daily agenda...</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 h-[450px] flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <div>
           <h3 className="text-xl font-bold text-gray-900">Today's Agenda</h3>
           <p className="text-xs text-gray-500 font-medium tracking-tight">Consolidated medications & appointments</p>
        </div>
        <button 
          onClick={() => navigate('/caretaker/medications')}
          className="text-xs font-bold text-blue-600 hover:text-blue-800 bg-blue-50 px-3 py-1.5 rounded-lg transition-colors"
        >
          Manage All
        </button>
      </div>

      <div className="flex-1 overflow-y-auto pr-2 space-y-4 custom-scrollbar">
        {error ? (
          <div className="flex flex-col items-center justify-center h-full text-center p-4">
             <AlertCircle className="w-8 h-8 text-amber-500 mb-2" />
             <p className="text-sm text-gray-500">{error}</p>
             <button onClick={fetchTimelineData} className="mt-4 text-sm text-blue-600 font-bold">Retry Sync</button>
          </div>
        ) : events.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center opacity-60">
             <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mb-4">
                <Calendar className="w-8 h-8 text-gray-300" />
             </div>
             <p className="text-gray-500 font-medium">Your schedule is clear for today.</p>
          </div>
        ) : (
          events.map((event, idx) => (
            <div key={event.id} className="relative pl-8 group">
              {/* Vertical line connector */}
              {idx !== events.length - 1 && (
                <div className="absolute left-[11px] top-6 bottom-[-20px] w-0.5 bg-gray-100 group-hover:bg-blue-100 transition-colors"></div>
              )}
              
              {/* Dot indicator */}
              <div className={`absolute left-0 top-1.5 w-6 h-6 rounded-full border-4 border-white shadow-sm flex items-center justify-center ${
                event.type === 'medication' ? 'bg-blue-500' : 'bg-purple-500'
              }`}>
                {event.type === 'medication' ? <Pill className="w-3 h-3 text-white" /> : <Video className="w-3 h-3 text-white" />}
              </div>

              <div className="flex justify-between items-start bg-gray-50/50 hover:bg-white p-3 rounded-xl border border-transparent hover:border-gray-100 hover:shadow-md transition-all">
                <div>
                   <div className="flex items-center gap-2">
                      <span className="text-xs font-bold text-gray-400 font-mono tracking-tighter">{event.time}</span>
                      <h4 className="text-sm font-bold text-gray-900 leading-none">{event.title}</h4>
                   </div>
                   <p className="text-xs text-gray-500 mt-1 font-medium">{event.subtitle}</p>
                </div>
                {event.type === 'appointment' && (
                  <button 
                    onClick={() => navigate('/caretaker/appointments')}
                    className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  >
                     <ChevronRight className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>
      
      <div className="mt-4 pt-4 border-t border-gray-50 flex items-center justify-between text-[10px] font-bold text-gray-400 uppercase tracking-widest">
         <div className="flex items-center gap-4">
            <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-blue-500"></div> Meds</span>
            <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-purple-500"></div> Appts</span>
         </div>
         <span>Today, {format(new Date(), 'MMM dd')}</span>
      </div>
    </div>
  );
};

export default UnifiedTimeline;
