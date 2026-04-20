import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import usePatient from '../../hooks/usePatient';
import doctorService from '../../services/doctor.service';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Upload, ArrowLeft, BrainCircuit, Loader2, CheckCircle2, AlertTriangle, ShieldCheck, ClipboardEdit } from 'lucide-react';

const MRIAnalysis = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { patient, loading: patientLoading, refetch: refetchPatient } = usePatient(id);
  
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState(null);
  const [doctorNote, setDoctorNote] = useState('');
  const [isConfirming, setIsConfirming] = useState(false);
  const [isConfirmed, setIsConfirmed] = useState(false);
  const pollingRef = useRef(null);
  const [recentScans, setRecentScans] = useState([]);

  useEffect(() => {
    if (id) {
      doctorService.getMRIHistory(id, 3, 0)
        .then(res => {
          const payload = res.data !== undefined && res.success !== undefined ? res.data : res;
          if (payload && payload.items) setRecentScans(payload.items);
        })
        .catch(err => console.error(err));
    }
  }, [id]);

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, []);

  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    if (selected && selected.type.startsWith('image/')) {
      setFile(selected);
      setPreview(URL.createObjectURL(selected));
      setResult(null);
      setIsConfirmed(false);
    } else {
      showError('Please select a valid image file');
    }
  };

  const getPayload = (res) => {
    if (!res) return null;
    const data = res.data !== undefined ? res.data : res;
    return (data && (data.success === true || data.status === 'success') && data.data) ? data.data : data;
  };

  const pollStatus = async (taskId, scanId) => {
    if (!taskId) return;
    
    try {
      const response = await doctorService.getMRIStatus(taskId);
      const statusData = getPayload(response);
      const status = statusData?.status || statusData?.state;
      
      if (status === 'SUCCESS') {
        try {
          const analysisResponse = await doctorService.getMRIAnalysis(id, scanId);
          const analysisData = getPayload(analysisResponse);
          
          const predictedLevel = analysisData?.predicted_level ?? analysisData?.level;
          
          if (predictedLevel !== undefined && predictedLevel !== null) {
            if (pollingRef.current) clearInterval(pollingRef.current);
            pollingRef.current = null;

            setResult({
              ...analysisData,
              predicted_level: predictedLevel,
              timestamp: analysisData.analyzed_at || analysisData.created_at || new Date()
            });
            setIsAnalyzing(false);
            showSuccess('Analysis complete');
          }
        } catch (fetchErr) {
          // Retry on next poll
        }
      } else if (status === 'FAILURE' || status === 'REVOKED') {
        if (pollingRef.current) clearInterval(pollingRef.current);
        pollingRef.current = null;
        setIsAnalyzing(false);
        showError('AI Analysis failed. Please try again.');
      }
    } catch (err) {
      const isTransient = [404, 502, 504, 202].includes(err.response?.status);
      if (!isTransient) {
        if (pollingRef.current) clearInterval(pollingRef.current);
        pollingRef.current = null;
        setIsAnalyzing(false);
        showError('Analysis connection interrupted.');
      }
    }
  };

  const handleAnalyze = async () => {
    if (!file) return;
    
    setIsAnalyzing(true);
    setResult(null);
    setIsConfirmed(false);

    try {
      const response = await doctorService.uploadMRI(id, file);
      const uploadData = getPayload(response);
      
      const taskId = uploadData?.task_id || uploadData?.taskId;
      const scanId = uploadData?.scan_id || uploadData?.scanId;
      
      if (!taskId) throw new Error('Analysis could not be started');

      if (pollingRef.current) clearInterval(pollingRef.current);
      pollingRef.current = setInterval(() => pollStatus(taskId, scanId), 3000);
      pollStatus(taskId, scanId);
      
    } catch (err) {
      showError(err.response?.data?.detail || err.message || 'Upload failed.');
      setIsAnalyzing(false);
    }
  };

  const handleConfirmAction = async (confirmed) => {
    if (!result?.history_id && !result?.id) {
       // On some flows, the history_id might be nested or we might need to find it
       // But based on app/tasks/mri_tasks.py, the history record is created link to the scan
       // In our MVP, we'll assume result has the info or we fetch generic recent history for scan
    }

    setIsConfirming(true);
    try {
      // In a real scenario, we'd pass result.history_id
      // For this implementation, we'll use result.id if history_id isn't explicitly there
      const historyId = result.severity_history_id || result.history_id || result.id;
      
      await doctorService.confirmMRIAnalysis(historyId, confirmed, doctorNote);
      
      if (confirmed) {
        showSuccess('Patient level updated and decision recorded.');
        setIsConfirmed(true);
        refetchPatient();
      } else {
        showSuccess('AI suggestion rejected. Record updated.');
      }
      
      setResult(prev => ({ ...prev, is_handled: true }));
    } catch (err) {
      showError('Failed to record clinical decision.');
    } finally {
      setIsConfirming(false);
    }
  };

  const getLevelColor = (level) => {
    switch (parseInt(level)) {
      case 1: return { bg: 'bg-green-500', text: 'text-green-700', light: 'bg-green-50', border: 'border-green-100' };
      case 2: return { bg: 'bg-amber-500', text: 'text-amber-700', light: 'bg-amber-50', border: 'border-amber-100' };
      case 3: return { bg: 'bg-red-500', text: 'text-red-700', light: 'bg-red-50', border: 'border-red-100' };
      default: return { bg: 'bg-blue-500', text: 'text-blue-700', light: 'bg-blue-50', border: 'border-blue-100' };
    }
  };

  if (patientLoading) {
    return (
      <Layout title="MRI Analysis">
        <div className="flex items-center justify-center h-full min-h-[400px]">
          <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
        </div>
      </Layout>
    );
  }

  const levelStyles = result ? getLevelColor(result.predicted_level) : null;

  return (
    <Layout title={`MRI Analysis: ${patient?.full_name || ''}`}>
      <div className="max-w-6xl mx-auto pb-12">
        <button 
          onClick={() => navigate(`/doctor/patient/${id}`)}
          className="flex items-center gap-2 text-gray-600 hover:text-blue-600 font-medium transition-colors mb-6"
        >
          <ArrowLeft className="w-5 h-5" /> Back to Patient Profile
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Left Column: Upload */}
          <div className="lg:col-span-5 space-y-6">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
              <h2 className="text-xl font-bold text-gray-900 mb-6 w-full flex items-center gap-2 border-b border-gray-100 pb-4">
                <BrainCircuit className="w-6 h-6 text-purple-600" /> MRI Scan
              </h2>
              
              <div className="w-full flex-1 flex flex-col items-center justify-center">
                {!preview ? (
                  <label className="w-full h-64 border-2 border-dashed border-gray-300 rounded-xl bg-gray-50 hover:bg-gray-100 hover:border-purple-400 transition-colors flex flex-col items-center justify-center cursor-pointer group">
                    <div className="p-4 bg-white rounded-full shadow-sm group-hover:scale-110 transition-transform mb-4">
                      <Upload className="w-8 h-8 text-purple-500" />
                    </div>
                    <span className="font-medium text-gray-700 text-center px-4">Upload clinical MRI scan (DICOM converted to JPEG/PNG)</span>
                    <input type="file" className="hidden" accept="image/*" onChange={handleFileChange} />
                  </label>
                ) : (
                  <div className="w-full space-y-4">
                    <div className="relative w-full h-80 rounded-xl overflow-hidden border border-gray-200 bg-black">
                      <img src={preview} alt="MRI Preview" className="w-full h-full object-contain" />
                    </div>
                    <div className="flex gap-3">
                      <button 
                        onClick={() => { setFile(null); setPreview(null); setResult(null); setIsConfirmed(false); }}
                        className="flex-1 py-2.5 px-4 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors"
                        disabled={isAnalyzing || isConfirming}
                      >
                        Change Scan
                      </button>
                      <button 
                        onClick={handleAnalyze}
                        disabled={isAnalyzing || isConfirming}
                        className="flex-2 w-full py-2.5 px-4 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors shadow-sm disabled:opacity-70 flex justify-center items-center"
                      >
                        {isAnalyzing ? (
                          <><Loader2 className="w-5 h-5 mr-2 animate-spin" /> Processing...</>
                        ) : (
                          'Run AI Inference'
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* AI Warning Box */}
            <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-4">
              <ShieldCheck className="w-6 h-6 text-blue-600 shrink-0" />
              <div>
                <p className="text-sm font-bold text-blue-900 mb-1">Clinical Safety Assurance</p>
                <p className="text-xs text-blue-800 leading-relaxed">
                  Alz-AI ResNet classifier is trained on anonymized clinical datasets but should only be used as a decision-support tool. Always correlate with neuropsychological tests.
                </p>
              </div>
            </div>

            {/* Recent Scans */}
            {recentScans.length > 0 && (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-bold text-gray-900 text-sm">Recent Scans</h3>
                  <button 
                    onClick={() => navigate(`/doctor/patient/${id}`, { state: { tab: 'scans' } })}
                    className="text-xs font-bold text-purple-600 hover:text-purple-700"
                  >
                    View Full History &rarr;
                  </button>
                </div>
                <div className="space-y-3">
                  {recentScans.map(scan => (
                    <div key={scan.scan_id} className="flex justify-between items-center p-3 bg-gray-50 rounded-xl border border-gray-100">
                      <div>
                        <div className="text-xs font-bold text-gray-900">{new Date(scan.created_at).toLocaleDateString()}</div>
                        <div className="text-[10px] text-gray-500 mt-0.5 capitalize">
                           {scan.status === 'completed' ? `Level ${scan.predicted_level}` : scan.status}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className={`text-xs font-bold ${scan.status === 'completed' ? 'text-green-600' : 'text-amber-600'}`}>
                           {scan.status === 'completed' ? `${Math.round(scan.confidence * 100)}%` : scan.status}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            
          </div>

          {/* Right Column: Results & Confirmation */}
          <div className="lg:col-span-7">
            <div className={`bg-white rounded-2xl shadow-sm border ${result?.is_uncertain ? 'border-amber-200' : 'border-gray-100'} p-6 h-full flex flex-col`}>
              <div className="flex justify-between items-center mb-6 border-b border-gray-100 pb-4">
                <h2 className="text-xl font-bold text-gray-900">Analysis Output</h2>
                {result && (
                  <span className="px-2 py-1 bg-gray-100 text-gray-500 rounded text-[10px] font-mono">
                    Model: {result.model_version}
                  </span>
                )}
              </div>
              
              {isAnalyzing ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center py-20">
                  <div className="relative mb-6">
                    <BrainCircuit className="w-16 h-16 text-purple-500 animate-pulse" />
                    <div className="absolute inset-0 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin"></div>
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Analyzing Cortical Structure</h3>
                  <p className="text-gray-500 max-w-xs">Extracting features and calculating severity probabilities...</p>
                </div>
              ) : result ? (
                <div className="space-y-8 flex-1">
                  {/* Top Result Card */}
                  <div className={`p-6 rounded-2xl border ${levelStyles.border} ${levelStyles.light} relative overflow-hidden`}>
                     {/* Decorative background icon */}
                     <BrainCircuit className={`absolute -right-8 -bottom-8 w-32 h-32 ${levelStyles.text} opacity-5 transform rotate-12`} />
                     
                     <div className="flex justify-between items-start mb-6">
                       <div>
                         <p className={`text-xs font-black uppercase tracking-widest ${levelStyles.text} mb-1`}>Top Prediction</p>
                         <h3 className={`text-4xl font-black ${levelStyles.text}`}>
                           Level {result.predicted_level}
                         </h3>
                         <p className="text-gray-600 text-sm mt-1 font-medium">
                           {result.predicted_level === 1 ? 'Early-Stage / Mild Cognitive Impairment' : 
                            result.predicted_level === 2 ? 'Mid-Stage / Moderate Impairment' : 
                            'Late-Stage / Severe Impairment'}
                         </p>
                       </div>
                       <div className="text-right">
                         <p className="text-xs font-bold text-gray-500 uppercase tracking-widest mb-1">AI Confidence</p>
                         <p className={`text-3xl font-black ${levelStyles.text}`}>
                           {Math.round(result.confidence * 100)}%
                         </p>
                       </div>
                     </div>

                     {/* Uncertainty Trigger */}
                     {result.is_uncertain && (
                       <div className="mb-6 p-3 bg-white/60 border border-amber-200 rounded-lg flex items-center gap-3 text-amber-800">
                         <AlertTriangle className="w-5 h-5 text-amber-600" />
                         <span className="text-xs font-bold">Uncertain result: Manual radiologist verification highly recommended.</span>
                       </div>
                     )}

                     {/* Probability Bars */}
                     <div className="space-y-3">
                       <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Probability Distribution</p>
                       {[1, 2, 3].map(lvl => {
                         const probValue = result.probabilities?.[`Level ${lvl}`] || 0;
                         const styles = getLevelColor(lvl);
                         const isBest = lvl === result.predicted_level;
                         
                         return (
                           <div key={lvl} className="space-y-1">
                             <div className="flex justify-between text-[11px] font-bold">
                               <span className={isBest ? styles.text : 'text-gray-500'}>Level {lvl} {isBest && '(Match)'}</span>
                               <span className={isBest ? styles.text : 'text-gray-400'}>{Math.round(probValue * 100)}%</span>
                             </div>
                             <div className="w-full bg-gray-200/50 rounded-full h-2 overflow-hidden">
                               <div 
                                 className={`${styles.bg} h-2 rounded-full transition-all duration-1000 shadow-sm`}
                                 style={{ width: `${probValue * 100}%`, opacity: isBest ? 1 : 0.4 }}
                               ></div>
                             </div>
                           </div>
                         );
                       })}
                     </div>
                  </div>

                  {/* Confirmation Section */}
                  <div className="bg-gray-50 rounded-2xl p-6 border border-gray-100 flex-1">
                    {isConfirmed ? (
                      <div className="flex flex-col items-center justify-center py-8 text-center">
                        <div className="p-3 bg-green-100 rounded-full mb-4">
                          <CheckCircle2 className="w-8 h-8 text-green-600" />
                        </div>
                        <h4 className="text-lg font-bold text-gray-900">Decision Recorded</h4>
                        <p className="text-sm text-gray-500 mt-1 uppercase tracking-tight">Patient level updated to Level {result.predicted_level}</p>
                        <button 
                          onClick={() => navigate(`/doctor/patient/${id}`)}
                          className="mt-6 text-sm font-bold text-blue-600 hover:underline"
                        >
                          View Updated Profile →
                        </button>
                      </div>
                    ) : (
                      <>
                        <div className="flex items-center gap-2 mb-4">
                           <ClipboardEdit className="w-5 h-5 text-gray-400" />
                           <h3 className="font-bold text-gray-900">Clinical Decision Audit</h3>
                        </div>
                        
                        <textarea 
                          className="w-full bg-white border border-gray-200 rounded-xl p-3 text-sm focus:ring-2 focus:ring-purple-200 focus:border-purple-400 outline-none transition-all placeholder:text-gray-300 min-h-[100px]"
                          placeholder="Add clinical observation or reasoning (optional)..."
                          value={doctorNote}
                          onChange={(e) => setDoctorNote(e.target.value)}
                        />

                        <div className="flex gap-4 mt-6">
                           <button 
                              onClick={() => handleConfirmAction(false)}
                              disabled={isConfirming}
                              className="flex-1 py-3 px-4 border border-red-200 text-red-600 rounded-xl text-sm font-bold hover:bg-red-50 transition-colors flex items-center justify-center"
                           >
                              Reject & Flag
                           </button>
                           <button 
                              onClick={() => handleConfirmAction(true)}
                              disabled={isConfirming}
                              className={`flex-2 w-full py-3 px-4 rounded-xl text-sm font-bold text-white transition-all flex items-center justify-center shadow-lg active:scale-95 ${result.is_uncertain ? 'bg-amber-600 hover:bg-amber-700' : 'bg-green-600 hover:bg-green-700'}`}
                           >
                              {isConfirming ? <Loader2 className="w-5 h-5 animate-spin" /> : (
                                result.is_uncertain ? 'Confirm (Override Uncertainty)' : 'Confirm & Apply Change'
                              )}
                           </button>
                        </div>
                        <p className="text-[10px] text-gray-400 text-center mt-4">
                          Your response will be stored in the patient's severity history log for auditability.
                        </p>
                      </>
                    )}
                  </div>
                </div>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-center py-20 text-gray-400">
                  <Upload className="w-16 h-16 mb-4 opacity-10" />
                  <h3 className="text-lg font-medium">Ready for Analysis</h3>
                  <p className="text-sm max-w-xs mx-auto mt-1">Upload a brain MRI scan to the workspace and run the AI ResNet model to proceed.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default MRIAnalysis;
