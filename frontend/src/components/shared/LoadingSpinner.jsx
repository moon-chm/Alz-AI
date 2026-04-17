import React from 'react';

const LoadingSpinner = ({ message, fullScreen = true }) => {
  const containerClasses = fullScreen
    ? "fixed inset-0 bg-white/80 z-50 flex flex-col items-center justify-center"
    : "flex flex-col items-center justify-center p-8";

  return (
    <div className={containerClasses}>
      <div className="animate-spin h-10 w-10 border-4 border-blue-600 border-t-transparent rounded-full mb-4"></div>
      {message && <p className="text-gray-500 font-medium">{message}</p>}
    </div>
  );
};

export default LoadingSpinner;
