import React from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import { format } from 'date-fns';

const StepChart = ({ data, isLoading }) => {
  if (isLoading) {
    return (
      <div className="w-full h-64 bg-gray-100 rounded-xl animate-pulse flex items-center justify-center">
        <span className="text-gray-400 font-medium">Loading steps data...</span>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="w-full h-64 bg-gray-50 rounded-xl border border-gray-100 flex items-center justify-center">
        <span className="text-gray-500 font-medium">No step data available</span>
      </div>
    );
  }

  const formattedData = data.map(item => ({
    ...item,
    formattedDate: format(new Date(item.date), 'MMM d')
  }));

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white p-3 shadow-lg rounded-lg border border-gray-100">
          <p className="text-sm text-gray-500 mb-1">{payload[0].payload.formattedDate}</p>
          <p className="text-base font-bold text-blue-600">
            {payload[0].value.toLocaleString()} steps
          </p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="w-full h-64">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={formattedData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
          <XAxis 
            dataKey="formattedDate" 
            axisLine={false} 
            tickLine={false} 
            tick={{ fill: '#6B7280', fontSize: 12 }} 
            dy={10}
          />
          <YAxis 
            axisLine={false} 
            tickLine={false} 
            tick={{ fill: '#6B7280', fontSize: 12 }}
            tickFormatter={(value) => value.toLocaleString()}
          />
          <Tooltip content={<CustomTooltip />} />
          <Line 
            type="monotone" 
            dataKey="steps" 
            stroke="#1A73E8" 
            strokeWidth={2} 
            dot={false}
            activeDot={{ r: 6, fill: '#1A73E8', stroke: '#fff', strokeWidth: 2 }} 
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default StepChart;
