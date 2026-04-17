import React from 'react';
import { Bell, Search } from 'lucide-react';
import useAuth from '../../hooks/useAuth';
import useWebSocket from '../../hooks/useWebSocket';
import { usePatientContext } from '../../context/PatientContext';

const TopBar = ({ title, onSearch }) => {
  const { user } = useAuth();
  const { selectedPatient } = usePatientContext(); 
  const { notificationCount, setNotificationCount } = useWebSocket(selectedPatient?.id || null);

  const isDoctor = user?.role === 'doctor';
  const roleColor = isDoctor ? 'bg-blue-600' : 'bg-green-600';

  const getInitials = (name) => {
    if (!name) return 'U';
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
  };

  return (
    <div className="h-16 border-b border-gray-200 bg-white px-6 flex items-center justify-between z-10 w-full relative">
      <div className="flex-1">
        <h1 className="font-semibold text-gray-900 text-lg">{title}</h1>
      </div>

      <div className="flex items-center gap-4">
        {isDoctor && (
          <div className="relative w-72">
            <input
              type="text"
              placeholder="Search patients by name or ALZ ID..."
              onChange={(e) => onSearch && onSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm bg-gray-50 hover:bg-white transition-colors"
            />
            <Search className="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          </div>
        )}

        <button 
          onClick={() => setNotificationCount(0)}
          className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-full transition-colors"
        >
          <Bell className="w-6 h-6" />
          {notificationCount > 0 && (
            <span className="absolute top-1 right-1 w-4 h-4 bg-red-600 border-2 border-white rounded-full flex items-center justify-center text-[10px] font-bold text-white">
              {notificationCount > 9 ? '9+' : notificationCount}
            </span>
          )}
        </button>

        <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold ml-2 shadow-sm ${roleColor}`}>
          {getInitials(user?.full_name)}
        </div>
      </div>
    </div>
  );
};

export default TopBar;
