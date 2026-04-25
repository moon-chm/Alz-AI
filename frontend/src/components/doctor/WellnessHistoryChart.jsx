import React from 'react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid, Legend } from 'recharts';
import { format as dfFormat } from 'date-fns';

const WellnessHistoryChart = ({ data, isLoading }) => {
  if (isLoading) {
    return (
      <div className="w-full h-80 bg-gray-100 rounded-xl animate-pulse flex items-center justify-center">
        <span className="text-gray-400 font-medium">Loading wellness history...</span>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="w-full h-80 bg-gray-50 rounded-xl border border-gray-100 flex items-center justify-center">
        <span className="text-gray-500 font-medium">No history data available</span>
      </div>
    );
  }

  const formattedData = data.map(item => ({
    ...item,
    formattedDate: dfFormat(new Date(item.date), 'MMM d')
  }));

  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white p-4 shadow-xl rounded-xl border border-gray-100 min-w-[180px]">
          <p className="text-xs text-gray-400 font-bold uppercase tracking-wider mb-3">{payload[0].payload.formattedDate}</p>
          <div className="space-y-2">
            {payload.map((entry, index) => (
              <div key={index} className="flex justify-between items-center gap-4">
                <span className="text-xs font-medium text-gray-600">{entry.name}</span>
                <span className="text-sm font-bold" style={{ color: entry.color }}>{entry.value}%</span>
              </div>
            ))}
          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="w-full h-80">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={formattedData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <defs>
            <linearGradient id="colorWellness" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#2563EB" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#2563EB" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="colorMeds" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#10B981" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#10B981" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="colorCognitive" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#8B5CF6" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#8B5CF6" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="colorExercise" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#F59E0B" stopOpacity={0}/>
            </linearGradient>
            <linearGradient id="colorDiet" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#EC4899" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#EC4899" stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
          <XAxis 
            dataKey="formattedDate" 
            axisLine={false} 
            tickLine={false} 
            tick={{ fill: '#94A3B8', fontSize: 11, fontWeight: 600 }} 
            dy={10}
          />
          <YAxis 
            axisLine={false} 
            tickLine={false} 
            tick={{ fill: '#94A3B8', fontSize: 11, fontWeight: 600 }}
            domain={[0, 100]}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend 
            verticalAlign="top" 
            align="right"
            iconType="circle" 
            wrapperStyle={{ fontSize: '11px', fontWeight: 600, paddingBottom: '20px', textTransform: 'uppercase', letterSpacing: '0.05em' }} 
          />
          <Area 
            type="monotone" 
            name="Wellness" 
            dataKey="wellness_score" 
            stroke="#2563EB" 
            strokeWidth={3}
            fillOpacity={1} 
            fill="url(#colorWellness)" 
          />
          <Area 
            type="monotone" 
            name="Compliance" 
            dataKey="adherence" 
            stroke="#10B981" 
            strokeWidth={3}
            fillOpacity={1} 
            fill="url(#colorMeds)" 
          />
          <Area 
            type="monotone" 
            name="Cognitive" 
            dataKey="cognitive" 
            stroke="#8B5CF6" 
            strokeWidth={3}
            fillOpacity={1} 
            fill="url(#colorCognitive)" 
          />
          <Area 
            type="monotone" 
            name="Exercise" 
            dataKey="exercise" 
            stroke="#F59E0B" 
            strokeWidth={2}
            fillOpacity={1} 
            fill="url(#colorExercise)" 
          />
          <Area 
            type="monotone" 
            name="Diet" 
            dataKey="diet" 
            stroke="#EC4899" 
            strokeWidth={2}
            fillOpacity={1} 
            fill="url(#colorDiet)" 
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};

export default WellnessHistoryChart;
