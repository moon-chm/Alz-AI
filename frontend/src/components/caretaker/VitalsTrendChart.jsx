import React, { useState, useEffect } from 'react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid, Legend, BarChart, Bar, Cell } from 'recharts';
import { format as dfFormat } from 'date-fns';
import api from '../../services/api';
import doctorService from '../../services/doctor.service';

const VitalsTrendChart = ({ patientId }) => {
  const [data, setData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await doctorService.getAnalytics(patientId);
        setData(data);
      } catch (err) {
        console.error('Failed to fetch vitals analytics:', err);
      } finally {
        setIsLoading(false);
      }
    };

    if (patientId) {
      fetchData();
    }
  }, [patientId]);

  if (isLoading) {
    return (
      <div className="w-full grid grid-cols-1 md:grid-cols-2 gap-6">
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="h-64 bg-white rounded-2xl border border-gray-100 p-6 flex flex-col gap-4 animate-pulse">
            <div className="h-4 w-32 bg-gray-100 rounded"></div>
            <div className="flex-1 bg-gray-50 rounded-xl"></div>
          </div>
        ))}
      </div>
    );
  }

  // Pre-process data
  const hasVitals = data?.vitals && data.vitals.length > 0;
  const hasSteps = data?.steps && data.steps.length > 0;
  const hasSleep = data?.sleep && data.sleep.length > 0;

  if (!hasVitals && !hasSteps && !hasSleep) {
    return (
      <div className="w-full bg-white rounded-2xl border border-dashed border-gray-200 p-12 text-center">
        <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-6">
           <span className="text-3xl">📈</span>
        </div>
        <h3 className="text-lg font-bold text-gray-900 mb-2">Analyzing Health Trends...</h3>
        <p className="text-gray-500 max-w-sm mx-auto">Once the patient's sensors begin syncing data, your AI-powered longitudinal health insights will appear here.</p>
      </div>
    );
  }

  // Formatting helper
  const formatDate = (dateStr) => {
    try {
      return dfFormat(new Date(dateStr), 'MMM d');
    } catch {
      return dateStr;
    }
  };

  const processedVitals = (data.vitals || [])
    .filter(v => v.hr > 0) // Filter out noise
    .map(v => ({
      ...v,
      time: formatDate(v.date),
      normalizedSpo2: v.spo2 > 100 ? v.spo2 / 100 : v.spo2
    }));

  const processedSteps = (data.steps || []).map(s => ({
    ...s,
    time: formatDate(s.date)
  }));

  const processedSleep = (data.sleep || []).map(s => ({
    ...s,
    time: formatDate(s.date)
  }));

  const ChartWrapper = ({ title, icon, color, gradientId, children }) => (
    <div className="bg-slate-50/50 p-6 rounded-3xl border border-slate-200/50 shadow-sm hover:shadow-md transition-all duration-300 group">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] flex items-center gap-2">
          <span className={`w-2 h-2 rounded-full ${color} shadow-[0_0_10px_rgba(0,0,0,0.1)]`}></span>
          {title}
        </h3>
        <span className="text-xl group-hover:scale-125 transition-transform duration-500">{icon}</span>
      </div>
      <div className="h-48 relative">
        {children}
      </div>
    </div>
  );

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="glass-dark p-4 rounded-2xl border-white/10 shadow-2xl">
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">{label}</p>
          {payload.map((p, i) => (
            <div key={i} className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full" style={{ backgroundColor: p.color }}></div>
              <span className="text-white font-bold">{p.value}</span>
              <span className="text-slate-400 text-xs">{p.name}</span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Heart Rate Area Chart */}
        <ChartWrapper title="Neural Heart Rhythm" icon="❤️" color="bg-rose-500">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={processedVitals}>
              <defs>
                <linearGradient id="colorHr" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FB7185" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#FB7185" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" strokeOpacity={0.5} />
              <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 800, fill: '#94A3B8' }} />
              <YAxis domain={['dataMin - 10', 'dataMax + 10']} hide />
              <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#F43F5E', strokeWidth: 1, strokeDasharray: '4 4' }} />
              <Area type="monotone" dataKey="hr" name="BPM" stroke="#F43F5E" strokeWidth={4} fill="url(#colorHr)" isAnimationActive={false} />
            </AreaChart>
          </ResponsiveContainer>
        </ChartWrapper>

        {/* SpO2 Oxygenation Chart */}
        <ChartWrapper title="Oxygen Saturation" icon="🌬️" color="bg-cyan-500">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={processedVitals}>
              <defs>
                <linearGradient id="colorOxygen" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#22D3EE" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#22D3EE" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" strokeOpacity={0.5} />
              <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 800, fill: '#94A3B8' }} />
              <YAxis domain={[90, 100]} hide />
              <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#0891B2', strokeWidth: 1, strokeDasharray: '4 4' }} />
              <Area type="monotone" dataKey="spo2" name="SpO2 %" stroke="#0891B2" strokeWidth={4} fill="url(#colorOxygen)" isAnimationActive={false} />
            </AreaChart>
          </ResponsiveContainer>
        </ChartWrapper>

        {/* Steps Bar Chart */}
        <ChartWrapper title="Mobility Quotient" icon="👟" color="bg-emerald-500">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={processedSteps}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" strokeOpacity={0.5} />
              <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 800, fill: '#94A3B8' }} />
              <YAxis hide />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'transparent' }} />
              <Bar dataKey="steps" name="Steps" fill="#10B981" radius={[8, 8, 0, 0]} barSize={32} isAnimationActive={false}>
                {processedSteps.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={index === processedSteps.length - 1 ? '#059669' : '#10B981'} fillOpacity={0.8} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartWrapper>

        {/* Sleep Sessions Chart */}
        <ChartWrapper title="Circadian Recovery" icon="🌙" color="bg-indigo-500">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={processedSleep}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" strokeOpacity={0.5} />
              <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 800, fill: '#94A3B8' }} />
              <YAxis hide />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'transparent' }} />
              <Bar dataKey="hours" name="Hours" fill="#6366F1" radius={[8, 8, 0, 0]} barSize={32} isAnimationActive={false}>
                {processedSleep.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={index === processedSleep.length - 1 ? '#4F46E5' : '#6366F1'} fillOpacity={0.8} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartWrapper>
      </div>
    </div>
  );
};

export default VitalsTrendChart;
