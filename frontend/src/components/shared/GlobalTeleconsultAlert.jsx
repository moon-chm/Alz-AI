import React, { useState, useEffect } from 'react';
import { Video, X } from 'lucide-react';
import useAuth from '../../hooks/useAuth';

const GlobalTeleconsultAlert = () => {
  const [alertData, setAlertData] = useState(null);
  const { user } = useAuth();

  useEffect(() => {
    const handleTeleconsultReady = (e) => {
      // Show to caretakers matching this patient, but here we can just show if they're a caretaker
      if (user?.role === 'caretaker') {
         setAlertData(e.detail);
      }
    };

    window.addEventListener('teleconsult-ready', handleTeleconsultReady);
    return () => window.removeEventListener('teleconsult-ready', handleTeleconsultReady);
  }, [user]);

  if (!alertData) return null;

  return (
    <div className="fixed top-20 right-6 z-50 animate-in fade-in slide-in-from-top-4 duration-300">
      <div className="bg-white rounded-2xl shadow-2xl border border-blue-500 overflow-hidden w-80">
         <div className="bg-blue-600 p-4 flex justify-between items-start">
            <div className="flex items-center gap-3">
               <div className="bg-white/20 p-2 rounded-full">
                  <Video className="w-6 h-6 text-white animate-pulse" />
               </div>
               <div>
                  <h3 className="text-white font-bold text-lg leading-tight">Teleconsult Ready</h3>
                  <p className="text-blue-100 text-xs font-medium">Doctor is waiting for you</p>
               </div>
            </div>
            <button 
              onClick={() => setAlertData(null)}
              className="text-blue-100 hover:text-white transition-colors"
            >
               <X className="w-5 h-5" />
            </button>
         </div>
         <div className="p-5">
            <p className="text-sm text-gray-600 mb-4 font-medium">
               <strong className="text-gray-900">{alertData.doctor_name || 'Your Doctor'}</strong> has initiated the teleconsultation bridge. Please join the session.
            </p>
            <div className="flex gap-3">
               <button 
                 onClick={() => setAlertData(null)}
                 className="flex-1 px-4 py-2 bg-gray-100 text-gray-600 font-bold rounded-xl hover:bg-gray-200 transition-colors"
               >
                 Dismiss
               </button>
               <button 
                 onClick={() => {
                   window.open(alertData.link, '_blank');
                   setAlertData(null);
                 }}
                 className="flex-1 px-4 py-2 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-colors shadow-md active:scale-95 flex items-center justify-center gap-2"
               >
                 Join Now
               </button>
            </div>
         </div>
      </div>
    </div>
  );
};

export default GlobalTeleconsultAlert;
