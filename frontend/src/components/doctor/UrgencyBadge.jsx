import React from 'react';

const UrgencyBadge = ({ urgency }) => {
  let bgColor, textColor, label;
  
  switch (urgency?.toLowerCase()) {
    case 'red':
      bgColor = 'bg-red-100';
      textColor = 'text-red-700';
      label = 'Critical';
      break;
    case 'amber':
    case 'orange':
      bgColor = 'bg-amber-100';
      textColor = 'text-amber-700';
      label = 'Moderate';
      break;
    case 'green':
      bgColor = 'bg-green-100';
      textColor = 'text-green-700';
      label = 'Stable';
      break;
    default:
      bgColor = 'bg-gray-100';
      textColor = 'text-gray-600';
      label = 'Unknown';
      break;
  }

  return (
    <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium inline-block ${bgColor} ${textColor}`}>
      {label}
    </span>
  );
};

export default UrgencyBadge;
