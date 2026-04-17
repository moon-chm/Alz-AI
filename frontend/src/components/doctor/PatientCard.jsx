import React from 'react';
import { useNavigate } from 'react-router-dom';
import { formatDistanceToNow } from 'date-fns';
import UrgencyBadge from './UrgencyBadge';
import LevelBadge from './LevelBadge';
import PatientIDCard from './PatientIDCard';

const PatientCard = ({ patient }) => {
  const navigate = useNavigate();

  const getBorderColor = (urgency) => {
    switch (urgency?.toLowerCase()) {
      case 'red': return 'border-l-red-500';
      case 'amber':
      case 'orange': return 'border-l-amber-500';
      case 'green': return 'border-l-green-500';
      default: return 'border-l-gray-300';
    }
  };

  const borderClass = getBorderColor(patient?.urgency);

  return (
    <div 
      onClick={() => navigate(`/doctor/patient/${patient.id}`)}
      className={`bg-white rounded-xl shadow-sm border border-gray-100 border-l-4 ${borderClass} p-5 hover:shadow-md transition-shadow cursor-pointer flex flex-col gap-3 h-full justify-between group`}
    >
      <div>
        <div className="flex justify-between items-start mb-3">
          <h3 className="font-semibold text-gray-900 text-lg truncate pr-2 group-hover:text-blue-600 transition-colors">
            {patient?.full_name}
          </h3>
          <UrgencyBadge urgency={patient?.urgency} />
        </div>
        
        <div className="mb-3">
          <PatientIDCard patientId={patient?.patient_unique_id} />
        </div>

        <div className="flex items-center gap-2 flex-wrap mb-4">
          <LevelBadge level={patient?.level} />
          {patient?.language && (
            <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700">
              {patient.language}
            </span>
          )}
        </div>
      </div>

      <div className="flex items-end justify-between mt-auto">
        <div className="flex flex-col gap-1">
          {patient?.last_mood && (
            <span className="text-sm text-gray-600 flex items-center gap-1.5 font-medium">
              <span>{patient.last_mood}</span> Mood Status
            </span>
          )}
          {patient?.last_checkin && (
            <span className="text-xs text-gray-500">
              Check-in: {formatDistanceToNow(new Date(patient.last_checkin), { addSuffix: true })}
            </span>
          )}
        </div>
        <span className="text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors flex items-center">
          View <span className="ml-1 opacity-0 group-hover:opacity-100 transition-opacity">&rarr;</span>
        </span>
      </div>
    </div>
  );
};

export default PatientCard;
