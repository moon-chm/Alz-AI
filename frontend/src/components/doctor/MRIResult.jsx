import React from 'react';
import { format } from 'date-fns';

const MRIResult = ({ result, confidence, timestamp }) => {
  if (!result) return null;

  const confPercent = Math.round(confidence * 100);
  
  let barColor, confTextColor;
  if (confidence > 0.8) {
    barColor = 'bg-green-500';
    confTextColor = 'text-green-700';
  } else if (confidence >= 0.6) {
    barColor = 'bg-amber-500';
    confTextColor = 'text-amber-700';
  } else {
    barColor = 'bg-red-500';
    confTextColor = 'text-red-700';
  }

  const formattedTime = timestamp ? format(new Date(timestamp), 'MMM d, yyyy h:mm a') : 'Unknown time';

  return (
    <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
      <h3 className="text-xl font-bold text-gray-900 mb-4 truncate">Result: {result}</h3>
      
      <div className="mb-4">
        <div className="flex justify-between items-end mb-1">
          <span className="text-sm font-medium text-gray-700">AI Confidence</span>
          <span className={`text-sm font-bold ${confTextColor}`}>{confPercent}%</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2.5">
          <div 
            className={`h-2.5 rounded-full ${barColor}`} 
            style={{ width: `${confPercent}%` }}
          ></div>
        </div>
      </div>

      <div className="flex flex-col gap-2 mt-4 text-sm">
        <div className="text-gray-500">
          <span className="font-medium">Analyzed on:</span> {formattedTime}
        </div>
        <div className="bg-blue-50 text-blue-800 px-3 py-2 rounded border border-blue-100 flex items-start gap-2">
          <span className="font-bold">ⓘ</span>
          <p>AI analysis — please confirm with a qualified radiologist.</p>
        </div>
      </div>
    </div>
  );
};

export default MRIResult;
