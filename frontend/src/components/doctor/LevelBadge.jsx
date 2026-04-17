import React from 'react';

const LevelBadge = ({ level }) => {
  let bgColor, textColor, label;

  switch (level) {
    case 1:
    case '1':
      bgColor = 'bg-green-100';
      textColor = 'text-green-700';
      label = 'Level 1 — Early';
      break;
    case 2:
    case '2':
      bgColor = 'bg-amber-100';
      textColor = 'text-amber-700';
      label = 'Level 2 — Moderate';
      break;
    case 3:
    case '3':
      bgColor = 'bg-red-100';
      textColor = 'text-red-700';
      label = 'Level 3 — Severe';
      break;
    default:
      bgColor = 'bg-gray-100';
      textColor = 'text-gray-600';
      label = `Level ${level || '?'}`;
      break;
  }

  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-semibold inline-block ${bgColor} ${textColor}`}>
      {label}
    </span>
  );
};

export default LevelBadge;
