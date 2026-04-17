import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
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
import { ArrowLeft, Activity, Heart, Moon, Pill, BrainCircuit, FileImage, Video } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const PatientDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  
  const { patient, loading, error, analytics, refetch } = usePatient(id);

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
             <div className="font-bold text-gray-900">{patient.caretaker_name || 'Unassigned'}</div>
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
        ) : (
          <div className="space-y-6">
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
               {/* Heart Rate */}
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Heart className="w-5 h-5 text-red-500" /> Heart Rate (7 Days)
                 </h3>
                 <HeartRateChart data={analytics?.vitals || []} isLoading={loading} />
               </div>

               {/* Sleep */}
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Moon className="w-5 h-5 text-indigo-500" /> Sleep (7 Days)
                 </h3>
                 <SleepChart data={analytics?.sleep || []} isLoading={loading} />
               </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
               {/* Steps */}
               <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                 <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                   <Activity className="w-5 h-5 text-green-500" /> Steps (7 Days)
                 </h3>
                 <StepChart data={analytics?.steps || []} isLoading={loading} />
               </div>

               {/* Med Compliance */}
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
        )}

      </div>
    </Layout>
  );
};

export default PatientDetail;