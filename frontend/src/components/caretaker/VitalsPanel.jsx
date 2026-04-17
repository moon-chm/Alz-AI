import React from 'react';
import useVitals from '../../hooks/useVitals';
import { Heart, Activity, ActivitySquare, Moon, Loader } from 'lucide-react';
import { format } from 'date-fns';

const VitalsPanel = () => {
  const { vitals, isLoading, error, lastUpdated } = useVitals();

  if (error) {
    return (
      <div className="bg-red-50 text-red-600 p-4 rounded-xl border border-red-100">
        Failed to load vitals: {error.message}
      </div>
    );
  }

  const safeVitals = vitals || { hr: 0, spo2: 0, steps: 0, sleep: 0 };
  
  const hrColor = (safeVitals.hr > 100 || safeVitals.hr < 50) ? 'text-red-600' : 'text-gray-900';
  const spo2Color = safeVitals.spo2 < 95 ? 'text-red-600' : 'text-gray-900';
  const stepsColor = safeVitals.steps > 8000 ? 'text-green-600' : 'text-gray-900';
  
  let sleepColor = 'text-gray-900';
  if (safeVitals.sleep < 5) sleepColor = 'text-red-600';
  else if (safeVitals.sleep >= 5 && safeVitals.sleep <= 7) sleepColor = 'text-amber-600';
  else if (safeVitals.sleep > 7) sleepColor = 'text-green-600';

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 relative">
      {isLoading && !lastUpdated && (
        <div className="absolute inset-0 bg-white/80 z-10 flex items-center justify-center rounded-xl">
          <Loader className="w-8 h-8 animate-spin text-blue-600" />
        </div>
      )}

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* Heart Rate */}
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-100 flex items-center gap-4">
          <div className="bg-red-100 p-3 rounded-full">
            <Heart className="w-6 h-6 text-red-500" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Heart Rate</p>
            <p className={`text-2xl font-bold ${hrColor}`}>{safeVitals.hr} <span className="text-sm font-normal text-gray-500">bpm</span></p>
          </div>
        </div>

        {/* SpO2 */}
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-100 flex items-center gap-4">
          <div className="bg-blue-100 p-3 rounded-full">
            <Activity className="w-6 h-6 text-blue-500" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">SpO2</p>
            <p className={`text-2xl font-bold ${spo2Color}`}>{safeVitals.spo2}<span className="text-sm font-normal text-gray-500">%</span></p>
          </div>
        </div>

        {/* Steps */}
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-100 flex items-center gap-4">
          <div className="bg-green-100 p-3 rounded-full">
            <ActivitySquare className="w-6 h-6 text-green-500" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Steps</p>
            <p className={`text-2xl font-bold ${stepsColor}`}>{safeVitals.steps}</p>
          </div>
        </div>

        {/* Sleep */}
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-100 flex items-center gap-4">
          <div className="bg-indigo-100 p-3 rounded-full">
            <Moon className="w-6 h-6 text-indigo-500" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Sleep</p>
            <p className={`text-2xl font-bold ${sleepColor}`}>{safeVitals.sleep} <span className="text-sm font-normal text-gray-500">h</span></p>
          </div>
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
        <span>{isLoading ? 'Refreshing...' : 'Live data'}</span>
        {lastUpdated ? (
          <span>Last refresh: {format(lastUpdated, 'h:mm:ss a')}</span>
        ) : (
          <span>-</span>
        )}
      </div>
    </div>
  );
};

export default VitalsPanel;
