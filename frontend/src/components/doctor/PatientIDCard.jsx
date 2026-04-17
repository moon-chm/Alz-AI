import React, { useState } from 'react';
import { Copy, Check } from 'lucide-react';

const PatientIDCard = ({ patientId, large = false }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = (e) => {
    e.stopPropagation();
    if (!patientId) return;
    navigator.clipboard.writeText(patientId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const sizeClass = large ? 'text-xl py-3 px-4 shadow-sm' : 'text-sm py-2 px-3';
  const iconSize = large ? 'w-5 h-5' : 'w-4 h-4';

  return (
    <div className={`inline-flex items-center justify-between gap-3 bg-gray-100 border border-gray-200 rounded-lg ${sizeClass}`}>
      <span className="font-mono font-bold tracking-wider text-gray-800">
        {patientId || 'NO-ID-GENERATED'}
      </span>
      <button 
        type="button"
        onClick={handleCopy}
        className="p-1.5 hover:bg-white rounded-md transition-colors border border-transparent hover:border-gray-200 focus:outline-none"
        title="Copy ID"
      >
        {copied ? (
          <Check className={`${iconSize} text-green-600`} />
        ) : (
          <Copy className={`${iconSize} text-gray-500 hover:text-blue-600`} />
        )}
      </button>
    </div>
  );
};

export default PatientIDCard;
