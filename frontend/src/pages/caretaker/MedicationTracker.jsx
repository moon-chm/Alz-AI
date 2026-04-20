import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import caretakerService from '../../services/caretaker.service';
import { usePatientContext } from '../../context/PatientContext';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Pill, Check, Clock, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';

const MedicationTracker = () => {
  const { selectedPatient, loading: contextLoading } = usePatientContext();
  const [schedule, setSchedule] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    console.log("Medications Page Mounted. Context Strategy:", {
       patientId: selectedPatient?.id,
       rehydrating: contextLoading
    });
    if (selectedPatient?.id) fetchSchedule();
  }, [selectedPatient, contextLoading]);

  const fetchSchedule = async () => {
    setLoading(true);
    try {
      const data = await caretakerService.getMedications();
      setSchedule(data);
    } catch (err) {
      showError('Failed to load medication schedule');
    } finally {
      setLoading(false);
    }
  };

  const handleTakeMed = async (medId) => {
    try {
      await caretakerService.updateMedication(medId, { status: 'taken' });
      showSuccess('Medication marked as taken');
      fetchSchedule();
    } catch (err) {
      showError('Failed to update status');
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'taken': return 'bg-green-100 text-green-700 border-green-200';
      case 'missed': return 'bg-red-100 text-red-700 border-red-200';
      case 'pending': return 'bg-amber-100 text-amber-700 border-amber-200';
      default: return 'bg-gray-100 text-gray-600 border-gray-200';
    }
  };

  // --- Guards (Before Return) ---
  if (contextLoading && !selectedPatient) {
    return (
      <Layout title="Initializing Medications">
        <div className="flex flex-col items-center justify-center min-h-[400px]">
           <div className="animate-spin w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full mb-4"></div>
           <p className="text-gray-500 font-medium">Synchronizing clinical prescription context...</p>
        </div>
      </Layout>
    );
  }

  if (!selectedPatient) {
    return (
      <Layout title="Medication Tracker">
        <div className="p-8 text-center bg-white m-8 rounded-xl border border-gray-100 font-medium text-gray-500">
          No patient linked to this account.
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Medication Tracker">
      <div className="max-w-5xl mx-auto space-y-6 pb-12">
        
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm flex justify-between items-center">
           <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-100 text-blue-600 rounded-full">
                <Pill className="w-6 h-6" />
               </div>
               <div>
                 <h2 className="text-xl font-bold text-gray-900">Today's Schedule</h2>
                 <p className="text-gray-500 font-medium">{format(new Date(), 'EEEE, MMMM do, yyyy')}</p>
               </div>
            </div>
         </div>

        {loading ? (
          <div className="flex justify-center p-12"><div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full"></div></div>
        ) : schedule.length === 0 ? (
          <div className="bg-white p-12 rounded-xl text-center border border-gray-100">
            <Pill className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">No medications assigned</h3>
            <p className="text-gray-500">The doctor has not prescribed any medications to track today.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {schedule.map((med) => {
              const isTaken = med.status === 'taken';
              const isPending = med.status === 'pending';

              return (
                <div key={med.id} className={`bg-white rounded-xl shadow-sm border ${isTaken ? 'border-green-200 bg-green-50/10 opacity-75' : 'border-gray-100'} p-6 transition-colors`}>
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                    
                    <div className="flex items-start gap-4">
                      <div className={`p-3 rounded-xl border ${getStatusColor(med.status)}`}>
                        {isTaken ? <Check className="w-6 h-6" /> : <Clock className="w-6 h-6" />}
                      </div>
                      <div>
                        <h3 className={`text-xl font-bold ${isTaken ? 'text-gray-600 line-through' : 'text-gray-900'}`}>
                          {med.medication_name}
                        </h3>
                        <div className="flex gap-3 text-sm text-gray-500 font-medium mt-1">
                          <span className="flex items-center gap-1 bg-gray-100 px-2 py-0.5 rounded">
                            {med.dosage}
                          </span>
                          <span className="flex items-center gap-1 text-blue-600 font-bold">
                            {med.time}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0">
                      <div className="text-right hidden md:block">
                        <span className={`text-xs font-bold uppercase tracking-wider ${isTaken ? 'text-green-600' : isPending ? 'text-amber-600' : 'text-gray-500'}`}>
                          Status: {med.status}
                        </span>
                      </div>
                      <button 
                        onClick={() => handleTakeMed(med.id)}
                        disabled={isTaken}
                        className={`flex items-center gap-2 px-6 py-2.5 rounded-lg font-bold transition-all ${
                          isTaken 
                          ? 'bg-green-100 text-green-700 cursor-not-allowed border border-green-200'
                          : 'bg-blue-600 hover:bg-blue-700 text-white shadow-sm'
                        }`}
                      >
                        {isTaken ? (
                          <><Check className="w-5 h-5"/> Verified</>
                        ) : (
                          'Mark as Taken'
                        )}
                      </button>
                    </div>

                  </div>
                  
                  {med.instructions && (
                    <div className="mt-4 bg-yellow-50 text-yellow-800 p-3 rounded-lg border border-yellow-100 flex items-start gap-2 text-sm font-medium">
                      <AlertCircle className="w-5 h-5 flex-shrink-0 text-yellow-600" />
                      <p>{med.instructions}</p>
                    </div>
                  )}

                </div>
              );
            })}
          </div>
        )}

      </div>
    </Layout>
  );
};

export default MedicationTracker;
