import React from 'react';
import { formatDistanceToNow } from 'date-fns';
import { AlertTriangle, CheckCircle, Info } from 'lucide-react';

const StatusCard = ({ status, patientName, lastUpdated }) => {
  let bgColor, borderColor, textColor, title, Icon, pulseClass;

  switch (status?.toLowerCase()) {
    case 'green':
      bgColor = 'bg-green-50';
      borderColor = 'border-green-200';
      textColor = 'text-green-800';
      title = 'Patient is Safe';
      Icon = CheckCircle;
      pulseClass = '';
      break;
    case 'amber':
    case 'orange':
      bgColor = 'bg-amber-50';
      borderColor = 'border-amber-200';
      textColor = 'text-amber-800';
      title = 'Needs Attention';
      Icon = Info;
      pulseClass = '';
      break;
    case 'red':
      bgColor = 'bg-red-50';
      borderColor = 'border-red-200';
      textColor = 'text-red-800';
      title = 'Critical — Check Now';
      Icon = AlertTriangle;
      pulseClass = 'animate-pulse';
      break;
    default:
      bgColor = 'bg-gray-50';
      borderColor = 'border-gray-200';
      textColor = 'text-gray-600';
      title = 'Status Unknown';
      Icon = Info;
      pulseClass = '';
      break;
  }

  const timeString = lastUpdated 
    ? formatDistanceToNow(new Date(lastUpdated), { addSuffix: true }) 
    : 'Unknown time';

  return (
    <div className={`rounded-2xl border-2 ${borderColor} ${bgColor} p-6 h-full flex flex-col justify-between`}>
      <div className="flex items-start gap-4">
        <div className={`p-3 rounded-full bg-white shadow-sm border ${borderColor} ${pulseClass}`}>
          <Icon className={`w-8 h-8 ${textColor}`} />
        </div>
        <div>
          <h2 className={`text-2xl font-bold ${textColor} mb-1`}>{title}</h2>
          <p className="text-gray-700 text-lg font-medium">{patientName}</p>
        </div>
      </div>
      <div className="mt-6 text-sm text-gray-500 font-medium">
        Last updated: {timeString}
      </div>
    </div>
  );
};

export default StatusCard;
