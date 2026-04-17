import React from 'react';
import { ResponsiveContainer, BarChart, Bar, Cell, XAxis, YAxis, Tooltip, CartesianGrid, ReferenceLine } from 'recharts';
import { format } from 'date-fns';

const SleepChart = ({ data, isLoading }) => {
  if (isLoading) {
    return (
      <div className="w-full h-64 bg-gray-100 rounded-xl animate-pulse flex items-center justify-center">
        <span className="text-gray-400 font-medium">Loading sleep data...</span>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="w-full h-64 bg-gray-50 rounded-xl border border-gray-100 flex items-center justify-center">
        <span className="text-gray-500 font-medium">No sleep data available</span>
      </div>
    );
  }

  const formattedData = data.map(item => ({
    ...item,
    formattedDate: format(new Date(item.date), 'MMM d')
  }));

  const getBarColor = (hours) => {
    if (hours < 5) return '#E53935'; 
    if (hours >= 5 && hours <= 7) return '#F57C00'; 
    return '#0F9D58'; 
  };

  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      const hours = payload[0].value;
      const color = getBarColor(hours);
      return (
        <div className="bg-white p-3 shadow-lg rounded-lg border border-gray-100">
          <p className="text-sm text-gray-500 mb-1">{payload[0].payload.formattedDate}</p>
          <p className="text-base font-bold" style={{ color }}>
            {hours} hours
          </p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="w-full h-64">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={formattedData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
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
            domain={[0, 12]}
          />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: '#F3F4F6' }} />
          <ReferenceLine y={5} stroke="#E53935" strokeDasharray="3 3" opacity={0.5} />
          <ReferenceLine y={7} stroke="#0F9D58" strokeDasharray="3 3" opacity={0.5} />
          <Bar dataKey="hours" radius={[4, 4, 0, 0]}>
            {formattedData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={getBarColor(entry.hours)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default SleepChart;
