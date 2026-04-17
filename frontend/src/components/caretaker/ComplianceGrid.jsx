import React from 'react';

const ComplianceGrid = ({ data }) => {
  if (!data || data.length === 0) {
    return (
      <div className="w-full h-64 bg-gray-50 rounded-xl border border-gray-100 flex items-center justify-center">
        <span className="text-gray-500 font-medium">No medication compliance data available</span>
      </div>
    );
  }

  const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const getCompliancePercent = (days) => {
    const scheduledDays = days.filter(d => d.scheduled);
    if (scheduledDays.length === 0) return 0;
    const takenDays = scheduledDays.filter(d => d.taken);
    return Math.round((takenDays.length / scheduledDays.length) * 100);
  };

  const renderCell = (dayData) => {
    if (!dayData?.scheduled) {
      return <div className="w-4 h-4 bg-gray-200 rounded-full mx-auto" title="Not scheduled"></div>;
    }
    if (dayData.taken) {
      return (
        <div className="w-5 h-5 bg-green-500 rounded-full flex items-center justify-center mx-auto text-white" title="Taken">
          <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7"></path></svg>
        </div>
      );
    }
    return (
      <div className="w-5 h-5 bg-red-500 rounded-full flex items-center justify-center mx-auto text-white" title="Missed">
        <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M6 18L18 6M6 6l12 12"></path></svg>
      </div>
    );
  };

  return (
    <div className="w-full bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="p-4 border-b border-gray-100">
        <h3 className="font-semibold text-gray-900 text-lg">7-Day Medication Compliance</h3>
      </div>
      
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="bg-gray-50 text-gray-600 font-medium">
            <tr>
              <th className="px-4 py-3 whitespace-nowrap w-1/3">Medication</th>
              <th className="px-4 py-3 whitespace-nowrap text-center">Compliance</th>
              {daysOfWeek.map(day => (
                <th key={day} className="px-2 py-3 text-center whitespace-nowrap">{day}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {data.map((item, index) => {
              const compliance = getCompliancePercent(item.days);
              let compColor = 'text-green-600';
              if (compliance < 80 && compliance >= 50) compColor = 'text-amber-600';
              else if (compliance < 50) compColor = 'text-red-600';

              return (
                <tr key={index} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3 font-medium text-gray-900">
                    {item.medication_name}
                  </td>
                  <td className={`px-4 py-3 text-center font-bold ${compColor}`}>
                    {compliance}%
                  </td>
                  {item.days.map((dayData, dIdx) => (
                    <td key={dIdx} className="px-2 py-3 align-middle text-center">
                      {renderCell(dayData)}
                    </td>
                  ))}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="bg-gray-50 p-3 border-t border-gray-100 flex items-center justify-end gap-6 text-xs text-gray-600">
        <div className="flex items-center gap-1.5"><div className="w-3 h-3 bg-green-500 rounded-full"></div> Taken</div>
        <div className="flex items-center gap-1.5"><div className="w-3 h-3 bg-red-500 rounded-full"></div> Missed</div>
        <div className="flex items-center gap-1.5"><div className="w-3 h-3 bg-gray-200 rounded-full"></div> Not Scheduled</div>
      </div>
    </div>
  );
};

export default ComplianceGrid;
