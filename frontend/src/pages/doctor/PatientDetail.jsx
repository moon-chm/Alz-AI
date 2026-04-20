import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import usePatient from '../../hooks/usePatient';
import PatientIDCard from '../../components/doctor/PatientIDCard';
import UrgencyBadge from '../../components/doctor/UrgencyBadge';
import LevelBadge from '../../components/doctor/LevelBadge';
import StepChart from '../../components/doctor/StepChart';
import HeartRateChart from '../../components/doctor/HeartRateChart';
import SleepChart from '../../components/doctor/SleepChart';
import ComplianceGrid from '../../components/caretaker/ComplianceGrid';
import AlertFeed from '../../components/caretaker/AlertFeed';
import { ArrowLeft, Activity, Heart, Moon, Pill, BrainCircuit, FileImage, Video, Plus, Trash2, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import api from '../../services/api';
import doctorService from '../../services/doctor.service';

const PatientDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [activeTab, setActiveTab] = useState(location.state?.tab || 'overview');
  
  const { patient, loading, error, analytics, refetch } = usePatient(id);
  const [medications, setMedications] = useState([]);
  const [showMedForm, setShowMedForm] = useState(false);
  const [medSaving, setMedSaving] = useState(false);
  const [medForm, setMedForm] = useState({ name: '', dosage: '', scheduled_times: '' });

  const [mriHistory, setMriHistory] = useState({ items: [], total: 0, page: 1, pages: 1 });
  const [historyLoading, setHistoryLoading] = useState(false);

  useEffect(() => {
    if (activeTab === 'scans' && id) {
      fetchMRIHistory(1);
    }
  }, [activeTab, id]);

  const fetchMRIHistory = async (page) => {
    setHistoryLoading(true);
    try {
      const res = await doctorService.getMRIHistory(id, 10, (page - 1) * 10);
      const payload = res.data !== undefined && res.success !== undefined ? res.data : res;
      if (payload) setMriHistory(payload);
    } catch (e) {
      console.error(e);
    } finally {
      setHistoryLoading(false);
    }
  };

  useEffect(() => {
    if (id) fetchMedications();
  }, [id]);

  const fetchMedications = async () => {
    try {
      const res = await api.get(`/medications/${id}`);
      setMedications(res.data || []);
    } catch (e) { console.error(e); }
  };

  const handleAddMed = async (e) => {
    e.preventDefault();
    setMedSaving(true);
    try {
      const times = medForm.scheduled_times.split(',').map(t => t.trim()).filter(Boolean);
      await api.post('/medications/', { patient_id: id, name: medForm.name, dosage: medForm.dosage, scheduled_times: times });
      setMedForm({ name: '', dosage: '', scheduled_times: '' });
      setShowMedForm(false);
      fetchMedications();
    } catch (e) { console.error(e); } finally { setMedSaving(false); }
  };

  const handleDeleteMed = async (medId) => {
    try {
      await api.delete(`/medications/${medId}`);
      fetchMedications();
    } catch (e) { console.error(e); }
  };

  if (loading) {
    return (
      <Layout title="Patient Details">
        <div className="flex items-center justify-center h-full min-h-[500px]">
          <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full"></div>
        </div>
      </Layout>
    );
  }

  if (error || !patient) {
    return (
      <Layout title="Patient Details">
        <div className="max-w-4xl mx-auto mt-8 bg-red-50 border border-red-200 rounded-xl p-8 text-center text-red-700">
          <h2 className="text-2xl font-bold mb-2">Error Loading Patient</h2>
          <p className="mb-6">{error?.message || 'Patient not found'}</p>
          <button onClick={() => navigate('/doctor/dashboard')} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium">
            Back to Dashboard
          </button>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title={`Patient: ${patient.full_name}`}>
      <div className="max-w-7xl mx-auto space-y-6 pb-12">
        
        {/* Header Actions */}
        <div className="flex justify-between items-center">
          <button 
            onClick={() => navigate('/doctor/dashboard')}
            className="flex items-center gap-2 text-gray-600 hover:text-blue-600 font-medium transition-colors"
          >
            <ArrowLeft className="w-5 h-5" /> Back to Dashboard
          </button>
          <div className="flex gap-3">
            <button 
              onClick={() => navigate(`/doctor/patient/${id}/mri`)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-50 text-purple-700 hover:bg-purple-100 rounded-lg font-medium transition-colors border border-purple-200 shadow-sm"
            >
              <BrainCircuit className="w-5 h-5" /> Analyze MRI
            </button>
            <button 
              onClick={() => navigate(`/doctor/patient/${id}/appointments`)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg font-medium transition-colors shadow-sm"
            >
              <Video className="w-5 h-5" /> Teleconsult
            </button>
          </div>
        </div>

        {/* Profile Header */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 lg:p-8 flex flex-col md:flex-row gap-6 lg:gap-10 items-start md:items-center relative overflow-hidden">
          {/* subtle decorative background */}
          <div className="absolute -top-24 -right-24 w-64 h-64 bg-blue-50 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
          
          <div className="w-24 h-24 lg:w-32 lg:h-32 rounded-full border-4 border-white shadow-md bg-gray-100 flex-shrink-0 flex items-center justify-center text-gray-400 font-bold text-3xl">
            {patient.photo_url ? (
              <img src={patient.photo_url} alt={patient.full_name} className="w-full h-full object-cover rounded-full" />
            ) : (
              patient.full_name.split(' ').map(n=>n[0]).join('').substring(0,2).toUpperCase()
            )}
          </div>
          
          <div className="flex-1">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
              <div>
                <h1 className="text-3xl font-bold text-gray-900 tracking-tight mb-1">{patient.full_name}</h1>
                <p className="text-gray-500 font-medium">{patient.age} years • {patient.gender}</p>
              </div>
              <PatientIDCard patientId={patient.patient_unique_id} large />
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <UrgencyBadge urgency={patient.urgency} />
              <LevelBadge level={patient.level} />
              {patient.language && (
                <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm font-medium">
                  {patient.language}
                </span>
              )}
            </div>
          </div>
          
          <div className="hidden lg:block w-px h-24 bg-gray-200 mx-4"></div>
          
          <div className="bg-gray-50 p-4 rounded-xl border border-gray-100 w-full md:w-auto md:min-w-[200px]">
             <div className="text-sm text-gray-500 font-medium mb-1">Caretaker</div>
             {patient.caretaker_info && patient.caretaker_info.length > 0 ? (
               patient.caretaker_info.map((ct, i) => (
                 <div key={i} className="font-bold text-gray-900">{ct.full_name}</div>
               ))
             ) : (
               <div className="font-bold text-gray-900">Unassigned</div>
             )}
             <div className="text-sm text-blue-600 font-medium mt-1">
                Last check-in: {patient.last_checkin ? formatDistanceToNow(new Date(patient.last_checkin), { addSuffix: true }) : 'Never'}
             </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="flex space-x-1 bg-gray-100/50 p-1 rounded-xl w-full max-w-sm border border-gray-200">
          <button
            onClick={() => setActiveTab('overview')}
            className={`flex-1 py-2 text-sm font-medium rounded-lg transition-colors ${activeTab === 'overview' ? 'bg-white text-gray-900 shadow-sm border border-gray-200' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'}`}
          >
            Overview
          </button>
          <button
            onClick={() => setActiveTab('vitals')}
            className={`flex-1 py-2 text-sm font-medium rounded-lg transition-colors ${activeTab === 'vitals' ? 'bg-white text-gray-900 shadow-sm border border-gray-200' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'}`}
          >
            Vitals & Meds
          </button>
          <button
            onClick={() => setActiveTab('scans')}
            className={`flex-1 py-2 text-sm font-medium rounded-lg transition-colors ${activeTab === 'scans' ? 'bg-white text-gray-900 shadow-sm border border-gray-200' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'}`}
          >
            MRI Scans
          </button>
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            
            {/* Health Summary Card */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex flex-col h-full">
              <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                <Activity className="w-5 h-5 text-blue-500" /> Health Summary
              </h3>
              <div className="flex-1 space-y-4">
                <div className="bg-blue-50 p-4 rounded-lg border border-blue-100">
                  <span className="text-sm text-blue-800 font-bold block mb-1">Diagnosis Notes</span>
                  <p className="text-gray-800 text-sm">
                    {patient.diagnosis_notes || 'No detailed diagnosis notes available yet. Please update the record.'}
                  </p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="border border-gray-100 p-4 rounded-lg bg-gray-50">
                    <span className="text-xs text-gray-500 font-medium block">Current Mood Status</span>
                    <span className="text-lg font-bold text-gray-900 mt-1 block">
                      {patient.last_mood ? patient.last_mood : 'Unknown'}
                    </span>
                  </div>
                  <div className="border border-gray-100 p-4 rounded-lg bg-gray-50">
                    <span className="text-xs text-gray-500 font-medium block">Geofence Compliance</span>
                    <span className="text-lg font-bold text-green-600 mt-1 block">100%</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Alerts */}
            <div className="flex flex-col h-full h-80">
                 <AlertFeed patientId={id} />
            </div>

          </div>
        ) : activeTab === 'vitals' ? (
          <div className="space-y-6">
            {/* Prescriptions Section */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
              <div className="flex items-center justify-between mb-5">
                <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                  <Pill className="w-5 h-5 text-blue-500" /> Prescriptions ({medications.length})
                </h3>
                <button
                  onClick={() => setShowMedForm(!showMedForm)}
                  className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-lg transition-colors shadow-sm"
                >
                  <Plus className="w-4 h-4" /> Add Medication
                </button>
              </div>

              {showMedForm && (
                <form onSubmit={handleAddMed} className="mb-5 bg-blue-50 border border-blue-100 rounded-xl p-5 space-y-3">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                    <input required value={medForm.name} onChange={e => setMedForm({...medForm, name: e.target.value})}
                      placeholder="Medication name" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
                    <input required value={medForm.dosage} onChange={e => setMedForm({...medForm, dosage: e.target.value})}
                      placeholder="Dosage (10mg)" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
                    <input required value={medForm.scheduled_times} onChange={e => setMedForm({...medForm, scheduled_times: e.target.value})}
                      placeholder="Times: 08:00, 20:00" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
                  </div>
                  <div className="flex gap-2 justify-end">
                    <button type="button" onClick={() => setShowMedForm(false)} className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50">Cancel</button>
                    <button type="submit" disabled={medSaving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg flex items-center gap-2">
                      {medSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />} Prescribe
                    </button>
                  </div>
                </form>
              )}

              {medications.length === 0 ? (
                <div className="text-center py-8 text-gray-400 border-2 border-dashed border-gray-50 rounded-xl">
                  <Pill className="w-10 h-10 mx-auto mb-3 opacity-20" />
                  <p className="font-medium">No active medications.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {medications.map(m => (
                    <div key={m.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-100">
                      <div>
                        <p className="font-bold text-gray-900">{m.name}</p>
                        <p className="text-blue-600 text-xs font-semibold">{m.dosage}</p>
                        <p className="text-[10px] text-gray-500 mt-1 uppercase tracking-tight font-bold">⏰ {Array.isArray(m.scheduled_times) ? m.scheduled_times.join(', ') : m.scheduled_times}</p>
                      </div>
                      <button onClick={() => handleDeleteMed(m.id)} className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Restored Vitals Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Heart className="w-5 h-5 text-red-500" /> Heart Rate (7 Days)
                 </h3>
                 <HeartRateChart data={analytics?.vitals || []} isLoading={loading} />
               </div>
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Moon className="w-5 h-5 text-indigo-500" /> Sleep (7 Days)
                 </h3>
                 <SleepChart data={analytics?.sleep || []} isLoading={loading} />
               </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Activity className="w-5 h-5 text-green-500" /> Steps (7 Days)
                 </h3>
                 <StepChart data={analytics?.steps || []} isLoading={loading} />
               </div>
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Pill className="w-5 h-5 text-blue-500" /> Medication Compliance
                 </h3>
                 <div className="h-64 overflow-y-auto pr-2">
                    <ComplianceGrid data={analytics?.compliance || []} />
                 </div>
               </div>
            </div>
          </div>
        ) : activeTab === 'scans' ? (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <div className="flex items-center justify-between mb-5">
              <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <BrainCircuit className="w-5 h-5 text-purple-500" /> Longitudinal MRI History
              </h3>
              <button 
                onClick={() => navigate(`/doctor/patient/${id}/mri`)}
                className="flex items-center gap-1.5 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-sm font-semibold rounded-lg transition-colors shadow-sm"
              >
                <Plus className="w-4 h-4" /> New Scan
              </button>
            </div>
            
            {historyLoading ? (
              <div className="flex items-center justify-center py-12">
                <Loader2 className="w-8 h-8 text-purple-600 animate-spin" />
              </div>
            ) : mriHistory.items.length === 0 ? (
              <div className="text-center py-12 text-gray-400 border-2 border-dashed border-gray-50 rounded-xl">
                <FileImage className="w-12 h-12 mx-auto mb-3 opacity-20" />
                <p className="font-medium text-gray-500">No MRI scans on record.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                  <thead className="text-xs text-gray-500 uppercase bg-gray-50 rounded-lg">
                    <tr>
                      <th className="px-4 py-3 rounded-tl-lg">Date</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Predicted Level</th>
                      <th className="px-4 py-3">AI Confidence</th>
                      <th className="px-4 py-3">Model</th>
                      <th className="px-4 py-3 rounded-tr-lg text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {mriHistory.items.map((scan) => (
                      <tr key={scan.scan_id} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                        <td className="px-4 py-4 font-medium text-gray-900 whitespace-nowrap">
                          {new Date(scan.created_at).toLocaleDateString()} <span className="text-gray-400 text-xs ml-1">{new Date(scan.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                        </td>
                        <td className="px-4 py-4">
                          {scan.status === 'completed' ? (
                            <span className="px-2.5 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold">Completed</span>
                          ) : scan.status === 'pending' || scan.status === 'processing' ? (
                            <span className="px-2.5 py-1 bg-amber-100 text-amber-700 rounded-full text-xs font-bold capitalize">{scan.status}</span>
                          ) : (
                            <span className="px-2.5 py-1 bg-red-100 text-red-700 rounded-full text-xs font-bold">Failed</span>
                          )}
                        </td>
                        <td className="px-4 py-4">
                          {scan.predicted_level ? (
                            <span className={`px-2 py-1 rounded text-xs font-bold ${scan.predicted_level === 1 ? 'bg-blue-50 text-blue-700' : scan.predicted_level === 2 ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700'}`}>
                              Level {scan.predicted_level}
                            </span>
                          ) : <span className="text-gray-400">-</span>}
                          {scan.predicted_level === 1 ? <div className="text-[10px] text-gray-400 mt-1">Mild Impairment</div> : scan.predicted_level === 2 ? <div className="text-[10px] text-gray-400 mt-1">Moderate Impairment</div> : scan.predicted_level === 3 ? <div className="text-[10px] text-gray-400 mt-1">Severe Impairment</div> : null}
                        </td>
                        <td className="px-4 py-4">
                          {scan.confidence ? (
                            <span className="font-bold text-gray-700">{Math.round(scan.confidence * 100)}%</span>
                          ) : <span className="text-gray-400">-</span>}
                        </td>
                        <td className="px-4 py-4 text-xs text-gray-400 font-mono">
                          {scan.model_version || '-'}
                        </td>
                        <td className="px-4 py-4 text-right">
                          <button 
                            onClick={() => navigate(`/doctor/patient/${id}/mri`)}
                            className="text-purple-600 hover:text-purple-800 font-semibold text-xs transition-colors"
                          >
                            Analyze
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                
                {mriHistory.pages > 1 && (
                  <div className="flex items-center justify-between mt-6 px-2">
                    <span className="text-xs text-gray-500 font-medium tracking-tight">Page {mriHistory.page} of {mriHistory.pages}</span>
                    <div className="flex gap-2">
                      <button 
                        disabled={mriHistory.page <= 1}
                        onClick={() => fetchMRIHistory(mriHistory.page - 1)}
                        className="px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold disabled:opacity-50 hover:bg-gray-50 transition-colors"
                      >
                        Previous
                      </button>
                      <button 
                        disabled={mriHistory.page >= mriHistory.pages}
                        onClick={() => fetchMRIHistory(mriHistory.page + 1)}
                        className="px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold disabled:opacity-50 hover:bg-gray-50 transition-colors"
                      >
                        Next
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ) : null}

      </div>
    </Layout>
  );
};

export default PatientDetail;