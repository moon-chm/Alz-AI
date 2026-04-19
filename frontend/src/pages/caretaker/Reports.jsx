import React, { useState } from 'react';
import Layout from '../../components/layout/Layout';
import caretakerService from '../../services/caretaker.service';
import { FileText, Download, Calendar, Activity, Shield, Loader2, Link as LinkIcon } from 'lucide-react';
import { showSuccess, showError } from '../../components/shared/Toast';

const Reports = () => {
  const [generating, setGenerating] = useState(false);
  const [selectedPeriod, setSelectedPeriod] = useState(30);
  const [downloadBlobUrl, setDownloadBlobUrl] = useState(null);
  const [downloadFilename, setDownloadFilename] = useState('');

  const handleGenerate = async () => {
    setGenerating(true);
    setDownloadBlobUrl(null);
    try {
      const filename = `AlzAI_Patient_Report_${selectedPeriod}days_${new Date().toISOString().slice(0,10)}.pdf`;
      const response = await fetch(`/api/caretaker/reports/pdf`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('access_token')}`
        },
        body: JSON.stringify({ period_days: selectedPeriod })
      });

      if (!response.ok) throw new Error(`Server error: ${response.status}`);

      const blob = await response.blob();
      const blobUrl = window.URL.createObjectURL(blob);
      
      // Trigger immediate download
      const link = document.createElement('a');
      link.href = blobUrl;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Keep blob URL in state for re-download
      setDownloadBlobUrl(blobUrl);
      setDownloadFilename(filename);
      showSuccess('PDF downloaded to your computer!');
    } catch (err) {
      showError('Failed to generate report. Please try again.');
      console.error(err);
    } finally {
      setGenerating(false);
    }
  };

  const handleReDownload = () => {
    if (!downloadBlobUrl) return;
    const link = document.createElement('a');
    link.href = downloadBlobUrl;
    link.download = downloadFilename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showSuccess('Downloading again!');
  };

  return (
    <Layout title="Clinical Reports">
      <div className="max-w-4xl mx-auto space-y-8 pb-12">
        
        {/* Generator Card */}
        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden">
           <div className="bg-blue-600 p-8 text-white">
              <div className="flex items-center gap-4 mb-4">
                 <div className="p-3 bg-white/20 rounded-2xl backdrop-blur-md">
                    <FileText className="w-8 h-8" />
                 </div>
                 <div>
                    <h2 className="text-2xl font-bold">Generate Health Summary</h2>
                    <p className="text-blue-100 opacity-90">Comprehensive PDF report for doctor consultations.</p>
                 </div>
              </div>
           </div>
           
           <div className="p-8 space-y-8">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                 {[7, 14, 30].map(days => (
                   <button
                     key={days}
                     onClick={() => setSelectedPeriod(days)}
                     className={`p-4 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${selectedPeriod === days ? 'border-blue-600 bg-blue-50 text-blue-700' : 'border-gray-100 bg-gray-50 text-gray-500 hover:border-gray-200'}`}
                   >
                      <Calendar className="w-6 h-6" />
                      <span className="font-bold text-lg">{days} Days</span>
                      <span className="text-xs opacity-80 font-medium">Full history</span>
                   </button>
                 ))}
              </div>

              <div className="bg-blue-50/50 rounded-2xl p-6 border border-blue-100 flex items-start gap-4">
                 <Shield className="w-6 h-6 text-blue-600 flex-shrink-0 mt-1" />
                 <div className="space-y-1">
                    <h4 className="font-bold text-blue-900">What's included in this report?</h4>
                    <ul className="text-sm text-blue-800/80 space-y-1 font-medium list-disc list-inside">
                       <li>Medication Adherence trends</li>
                       <li>Vitals history (Heart Rate, SpO2)</li>
                       <li>Cognitive mood analysis via Saathi</li>
                       <li>Critical SOS & geofence alerts</li>
                    </ul>
                 </div>
              </div>

              <div className="flex flex-col items-center gap-4 pt-4">
                 <button 
                   onClick={handleGenerate}
                   disabled={generating}
                   className="w-full max-w-sm bg-blue-600 hover:bg-blue-700 text-white py-4 rounded-2xl font-bold text-lg shadow-lg shadow-blue-200 transition-all flex justify-center items-center gap-3 disabled:bg-gray-300 disabled:shadow-none active:scale-95"
                 >
                    {generating ? (
                      <>
                        <Loader2 className="w-6 h-6 animate-spin" />
                        Analyzing Health Data...
                      </>
                    ) : (
                      <>
                        <Activity className="w-6 h-6" />
                        Compile {selectedPeriod}-Day Report
                      </>
                    )}
                 </button>
                 <p className="text-sm text-gray-400 font-medium italic">High confidence level analysis powered by Smaran AI</p>
              </div>
           </div>
        </div>

        {/* Result Card */}
        {downloadBlobUrl && (
          <div className="bg-green-50 border-2 border-green-200 rounded-2xl p-6 flex items-center gap-4">
             <div className="bg-green-100 text-green-600 p-3 rounded-full">
                <Download className="w-6 h-6" />
             </div>
             <div>
                <h3 className="text-lg font-bold text-green-900">✅ Report Downloaded!</h3>
                <p className="text-sm text-green-700 font-medium">Saved as <span className="font-mono text-xs bg-green-100 px-1 rounded">{downloadFilename}</span></p>
             </div>
          </div>
        )}

      </div>
    </Layout>
  );
};

export default Reports;
