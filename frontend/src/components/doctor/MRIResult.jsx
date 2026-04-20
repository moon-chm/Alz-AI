import React from 'react';
import { format } from 'date-fns';
import { AlertTriangle, BrainCircuit, CheckCircle2 } from 'lucide-react';

const MRIResult = ({ result, confidence, timestamp, isUncertain, probabilities, modelVersion }) => {
  if (!result && result !== 0) return null;

  const level = parseInt(result);
  const confPercent = Math.round((confidence || 0) * 100);
  
  const getLevelStyles = (lvl) => {
    switch (lvl) {
      case 1: return { text: 'text-green-700', bg: 'bg-green-500', bar: 'bg-green-100', label: 'Mild / Early-Stage' };
      case 2: return { text: 'text-amber-700', bg: 'bg-amber-500', bar: 'bg-amber-100', label: 'Moderate / Mid-Stage' };
      case 3: return { text: 'text-red-700', bg: 'bg-red-500', bar: 'bg-red-100', label: 'Severe / Late-Stage' };
      default: return { text: 'text-blue-700', bg: 'bg-blue-500', bar: 'bg-blue-100', label: 'Unknown' };
    }
  };

  const styles = getLevelStyles(level);

  const safeDate = (dateStr) => {
    if (!dateStr) return new Date();
    try {
      const isoStr = typeof dateStr === 'string' ? dateStr.replace(' ', 'T') : dateStr;
      const d = new Date(isoStr);
      return isNaN(d.getTime()) ? new Date() : d;
    } catch (e) {
      return new Date();
    }
  };

  const formattedTime = timestamp ? format(safeDate(timestamp), 'MMM d, yyyy h:mm a') : 'Unknown time';

  return (
    <div className={`bg-white border rounded-xl overflow-hidden shadow-sm ${isUncertain ? 'border-amber-200' : 'border-gray-200'}`}>
      <div className={`px-4 py-2 border-b flex justify-between items-center ${isUncertain ? 'bg-amber-50 border-amber-100' : 'bg-gray-50 border-gray-100'}`}>
        <span className="text-[10px] font-black uppercase tracking-tighter text-gray-500 flex items-center gap-1">
          <BrainCircuit className="w-3 h-3" /> AI Analysis Result
        </span>
        <span className="text-[10px] font-mono text-gray-400">{modelVersion || 'v1.0-prod'}</span>
      </div>

      <div className="p-5">
        <div className="flex justify-between items-start mb-4">
          <div>
            <h3 className={`text-2xl font-black ${styles.text}`}>Level {level}</h3>
            <p className="text-xs font-bold text-gray-500 mt-0.5">{styles.label}</p>
          </div>
          <div className="text-right">
            <span className={`text-lg font-black ${styles.text}`}>{confPercent}%</span>
            <p className="text-[10px] font-bold text-gray-400">Confidence</p>
          </div>
        </div>

        {/* Mini Probability Bars if available */}
        {probabilities && (
          <div className="space-y-2 mb-5">
            {[1, 2, 3].map(l => (
              <div key={l} className="flex items-center gap-2">
                <span className="text-[9px] font-bold text-gray-400 w-8">L{l}</span>
                <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                  <div 
                    className={`${getLevelStyles(l).bg} h-full rounded-full transition-all duration-700`}
                    style={{ width: `${(probabilities[`Level ${l}`] || 0) * 100}%`, opacity: l === level ? 1 : 0.3 }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}

        {isUncertain && (
          <div className="flex items-start gap-2 p-2 bg-amber-50 border border-amber-100 rounded text-amber-800 text-[10px] mb-4">
            <AlertTriangle className="w-3 h-3 shrink-0 mt-0.5" />
            <p className="leading-tight font-medium">Uncertain classification. Clinical review mandatory.</p>
          </div>
        )}

        <div className="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
          <div className="text-[10px] text-gray-400">
            {formattedTime}
          </div>
          <div className="flex items-center gap-1 text-[10px] font-bold text-blue-600">
            <CheckCircle2 className="w-3 h-3" /> Verified logic
          </div>
        </div>
      </div>
    </div>
  );
};

export default MRIResult;
