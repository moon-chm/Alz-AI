import React from 'react';
import { NavLink } from 'react-router-dom';
import { Home, UserPlus, Users, Calendar, Activity, Pill, Camera, Brain, FileText, LogOut } from 'lucide-react';
import useAuth from '../../hooks/useAuth';

const Sidebar = () => {
  const { user, logout } = useAuth();
  
  if (!user) return null;

  const isDoctor = user.role === 'doctor';
  const roleColor = isDoctor ? 'bg-blue-600' : 'bg-green-600';
  
  const getInitials = (name) => {
    if (!name) return 'U';
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
  };

  const activeLinkStyle = ({ isActive }) =>
    `flex items-center gap-3 px-4 py-3 text-gray-300 hover:text-white transition-colors ${
      isActive ? 'border-l-4 border-blue-500 bg-gray-800 text-white' : ''
    }`;

  return (
    <div className="w-64 fixed left-0 top-0 h-screen bg-[#1a2332] flex flex-col justify-between">
      <div>
        <div className="flex items-center justify-center py-6 border-b border-gray-800">
          <h1 className="text-white text-2xl font-bold tracking-wider">Alz-AI</h1>
        </div>
        
        <div className="px-4 py-6 border-b border-gray-800">
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold ${roleColor}`}>
              {getInitials(user.full_name)}
            </div>
            <div className="overflow-hidden">
              <p className="text-white font-medium truncate">{user.full_name}</p>
              <span className={`inline-block px-2 text-xs font-semibold rounded-full mt-1 text-white ${roleColor}`}>
                {isDoctor ? 'Doctor' : 'Caretaker'}
              </span>
            </div>
          </div>
        </div>

        <nav className="mt-6 flex flex-col gap-1">
          {isDoctor ? (
            <>
              <NavLink to="/doctor/dashboard" className={activeLinkStyle} end>
                <Home className="w-5 h-5" /> Dashboard
              </NavLink>
              <NavLink to="/doctor/patient/create" className={activeLinkStyle}>
                <UserPlus className="w-5 h-5" /> Add Patient
              </NavLink>
              <NavLink to="/doctor/appointments" className={activeLinkStyle}>
                <Calendar className="w-5 h-5" /> Appointments
              </NavLink>
            </>
          ) : (
            <>
              <NavLink to="/caretaker/dashboard" className={activeLinkStyle}>
                <Home className="w-5 h-5" /> Dashboard
              </NavLink>
              <NavLink to="/caretaker/monitor" className={activeLinkStyle}>
                <Activity className="w-5 h-5" /> Monitor
              </NavLink>
              <NavLink to="/caretaker/medications" className={activeLinkStyle}>
                <Pill className="w-5 h-5" /> Medications
              </NavLink>
              <NavLink to="/caretaker/photos" className={activeLinkStyle}>
                <Camera className="w-5 h-5" /> Photos
              </NavLink>
              <NavLink to="/caretaker/data-feeding" className={activeLinkStyle}>
                <Brain className="w-5 h-5" /> Data Feeding
              </NavLink>
              <NavLink to="/caretaker/appointments" className={activeLinkStyle}>
                <Calendar className="w-5 h-5" /> Appointments
              </NavLink>
              <NavLink to="/caretaker/reports" className={activeLinkStyle}>
                <FileText className="w-5 h-5" /> Reports
              </NavLink>
            </>
          )}
        </nav>
      </div>

      <div className="p-4">
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
        >
          <LogOut className="w-5 h-5" /> Logout
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
