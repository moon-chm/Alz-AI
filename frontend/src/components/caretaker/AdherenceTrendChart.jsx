import React from 'react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  Area, 
  AreaChart,
  ReferenceLine
} from 'recharts';
import { format, parseISO } from 'date-fns';
import { Pill, TrendingUp, AlertCircle } from 'lucide-react';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="bg-white p-4 border border-gray-100 shadow-xl rounded-xl">
        <p className="text-sm font-bold text-gray-900 mb-1">
          {format(parseISO(data.date), 'EEEE, MMM d')}
        </p>
        <div className="space-y-1">
          <div className="flex justify-between gap-4 text-xs font-medium">
            <span className="text-gray-500 text-nowrap">Doses Taken</span>
            <span className="text-blue-600 font-bold">{data.taken} / {data.scheduled}</span>
          </div>
          <div className="flex justify-between gap-4 text-xs font-medium">
            <span className="text-gray-500">Adherence</span>
            <span className={`font-bold ${data.adherence >= 80 ? 'text-green-600' : 'text-orange-600'}`}>
              {data.adherence}%
            </span>
          </div>
        </div>
      </div>
    );
  }
  return null;
};

const AdherenceTrendChart = ({ data, average }) => {
  if (!data || data.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center p-6 bg-gray-50 rounded-xl border border-dashed border-gray-200">
        <Pill className="w-10 h-10 text-gray-300 mb-2" />
        <p className="text-gray-500 font-medium">No adherence data available for this period.</p>
      </div>
    );
  }

  // Helper to format X-Axis dates to short labels (Mon, Tue, etc.)
  const formatXAxis = (tickItem) => {
    return format(parseISO(tickItem), 'EEE');
  };

  const isPositiveTrend = average >= 75;

  return (
    <div className="flex flex-col h-full">
      {/* Header Info */}
      <div className="flex justify-between items-end mb-6">
        <div>
          <span className="text-xs font-bold text-blue-600 uppercase tracking-wider mb-1 block">7-Day Analysis</span>
          <div className="flex items-center gap-2">
            <h4 className="text-2xl font-black text-gray-900">{average}%</h4>
            <div className={`flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
              isPositiveTrend ? 'bg-green-50 text-green-700 border border-green-100' : 'bg-orange-50 text-orange-700 border border-orange-100'
            }`}>
              <TrendingUp className={`w-3 h-3 mr-1 ${isPositiveTrend ? '' : 'rotate-180'}`} />
              Avg Compliance
            </div>
          </div>
        </div>
        
        {/* Adherence Legend */}
        <div className="flex gap-4">
          <div className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-blue-500"></span>
            <span className="text-[10px] font-bold text-gray-500 uppercase">Trend</span>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="flex-1 min-h-0 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={data}
            margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
          >
            <defs>
              <linearGradient id="colorAdherence" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid 
              strokeDasharray="3 3" 
              vertical={false} 
              stroke="#f1f5f9" 
            />
            <XAxis 
              dataKey="date" 
              tickFormatter={formatXAxis}
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 600 }}
              dy={10}
            />
            <YAxis 
              domain={[0, 100]}
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 600 }}
              ticks={[0, 25, 50, 75, 100]}
              tickFormatter={(v) => `${v}%`}
            />
            <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#e2e8f0', strokeWidth: 1 }} />
            
            {/* Target Line at 80% */}
            <ReferenceLine 
              y={80} 
              stroke="#cbd5e1" 
              strokeDasharray="5 5"
              label={{ position: 'right', value: 'Target', fill: '#94a3b8', fontSize: 9, fontWeight: 700 }} 
            />

            <Area
              type="monotone"
              dataKey="adherence"
              stroke="#3b82f6"
              strokeWidth={3}
              fillOpacity={1}
              fill="url(#colorAdherence)"
              connectNulls={true}
              animationDuration={1500}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Insight Section */}
      {average < 70 && (
        <div className="mt-4 flex items-center gap-2 p-2 bg-orange-50 rounded-lg border border-orange-100">
          <AlertCircle className="w-4 h-4 text-orange-600" />
          <p className="text-[11px] font-semibold text-orange-700">
            Adherence is below target. Consider setting up extra reminders.
          </p>
        </div>
      )}
    </div>
  );
};

export default AdherenceTrendChart;
