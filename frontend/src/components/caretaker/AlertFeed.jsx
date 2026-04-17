import React, { useState, useEffect } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { AlertCircle, CheckCircle } from 'lucide-react';
import useWebSocket from '../../hooks/useWebSocket';

const AlertFeed = ({ initialAlerts = [], patientId }) => {
  // ✅ useWebSocket now returns alertFeed (was undefined before)
  const { alertFeed } = useWebSocket(patientId);
  
  // ✅ Ensure state is initialized as an array
  const [alerts, setAlerts] = useState(Array.isArray(initialAlerts) ? initialAlerts : []);

  useEffect(() => {
    // ✅ Use optional chaining and safeguard against null/undefined alertFeed
    if (alertFeed?.length > 0) {
      setAlerts((prev) => {
        const merged = [...alertFeed, ...(Array.isArray(prev) ? prev : [])];
        // Merge and deduplicate by ID or timestamp
        const unique = Array.from(
          new Map(merged.map(item => [item.id || item.timestamp, item])).values()
        );
        return unique.slice(0, 20); // max 20 alerts
      });
    }
  }, [alertFeed]);

  const handleAcknowledge = (alertId) => {
    setAlerts((prev) => 
      prev.map(a => a.id === alertId ? { ...a, acknowledged: true } : a)
    );
  };

  const getSeverityBadge = (severity) => {
    let colorClass = 'bg-gray-100 text-gray-700';
    if (severity >= 5) colorClass = 'bg-red-100 text-red-700 font-black px-2 shadow-sm border border-red-200';
    else if (severity === 4) colorClass = 'bg-orange-100 text-orange-700';
    else if (severity === 3) colorClass = 'bg-yellow-100 text-yellow-700';
    
    return (
      <span className={`px-2 py-0.5 rounded text-xs font-bold transition-all ${colorClass}`}>
        Lvl {severity || 1}
      </span>
    );
  };

  // ✅ Safe check for empty alerts
  if (!alerts || alerts.length === 0) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex flex-col items-center justify-center text-center h-full min-h-[300px]">
        <CheckCircle className="w-12 h-12 text-green-500 mb-3 animate-pulse" />
        <h3 className="text-lg font-semibold text-gray-900">No active alerts</h3>
        <p className="text-gray-500">System monitored and secure.</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 h-full flex flex-col">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <AlertCircle className="w-5 h-5 text-red-500 animate-pulse" /> Alert Feed
        </h3>
        <button className="text-sm text-blue-600 hover:text-blue-800 font-medium">History</button>
      </div>

      <div className="flex-1 overflow-y-auto pr-2 space-y-3 custom-scrollbar">
        {alerts.map((alert, idx) => {
          const isAck = alert.acknowledged;
          return (
            <div 
              key={alert.id || idx} 
              className={`p-3 rounded-lg border flex flex-col ${
                isAck ? 'bg-gray-50 border-gray-100 opacity-60' : 'bg-white border-gray-200 shadow-sm'
              } transition-all duration-300 transform hover:scale-[1.01]`}
            >
              <div className="flex justify-between items-start mb-2 gap-2">
                <div className="flex items-start gap-2">
                  {getSeverityBadge(alert.severity)}
                  <p className={`text-sm ${isAck ? 'text-gray-600 line-through italic' : 'text-gray-900 font-medium'}`}>
                    {alert.message}
                  </p>
                </div>
              </div>
              <div className="flex justify-between items-center mt-3">
                <span className="text-xs text-gray-400">
                  {alert.timestamp ? formatDistanceToNow(new Date(alert.timestamp), { addSuffix: true }) : 'Just now'}
                </span>
                {!isAck ? (
                  <button 
                    onClick={() => handleAcknowledge(alert.id)}
                    className="text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md font-bold transition-colors"
                  >
                    Acknowledge
                  </button>
                ) : (
                  <span className="text-xs font-bold text-green-600 flex items-center gap-1">
                    <CheckCircle className="w-3 h-3" /> OK
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default AlertFeed;
