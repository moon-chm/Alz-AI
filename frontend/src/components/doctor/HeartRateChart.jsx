import React from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, Legend } from 'recharts';
import { format } from 'date-fns';

const HeartRateChart = ({ data, isLoading }) => {
  if (isLoading) {
    return (
      <div className="w-full h-64 bg-gray-100 rounded-xl animate-pulse flex items-center justify-center">
        <span className="text-gray-400 font-medium">Loading heart rate data...</span>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="w-full h-64 bg-gray-50 rounded-xl border border-gray-100 flex items-center justify-center">
        <span className="text-gray-500 font-medium">No heart rate data available</span>
      </div>
    );
  }

  const formattedData = data.map(item => ({
    ...item,
    formattedDate: format(new Date(item.date), 'MMM d')
  }));

  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white p-3 shadow-lg rounded-lg border border-gray-100">
          <p className="text-sm text-gray-500 mb-2">{payload[0].payload.formattedDate}</p>
          {payload.map((entry, index) => (
            <p key={index} className="text-sm font-semibold" style={{ color: entry.color }}>
              {entry.name}: {entry.value} bpm
            </p>
          ))}
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
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend iconType="circle" wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
          <Line type="monotone" name="Avg HR" dataKey="avg_hr" stroke="#1A73E8" strokeWidth={2} dot={false} />
          <Line type="monotone" name="Max HR" dataKey="max_hr" stroke="#E53935" strokeWidth={2} dot={false} />
          <Line type="monotone" name="Min HR" dataKey="min_hr" stroke="#0F9D58" strokeWidth={2} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default HeartRateChart;
