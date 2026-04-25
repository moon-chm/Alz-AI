import React, { useState, useEffect } from 'react';
import doctorService from '../../services/doctor.service';
import { Plus, Trash2, Loader2, Activity, Coffee } from 'lucide-react';

const ClinicalPlansSection = ({ patientId }) => {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ type: 'exercise', title: '', description: '', scheduled_times: '' });

  useEffect(() => {
    console.log('ClinicalPlansSection patientId:', patientId);
    if (patientId) fetchPlans();
  }, [patientId]);

  const fetchPlans = async () => {
    try {
      const res = await doctorService.getClinicalPlans(patientId);
      setPlans(res || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const times = form.scheduled_times.split(',').map(t => t.trim()).filter(Boolean);
      await doctorService.createClinicalPlan({
        patient_id: patientId,
        type: form.type,
        title: form.title,
        description: form.description,
        scheduled_times: times
      });
      setForm({ type: 'exercise', title: '', description: '', scheduled_times: '' });
      setShowForm(false);
      fetchPlans();
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return null;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 mt-6">
      <div className="flex items-center justify-between mb-5">
        <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <Activity className="w-5 h-5 text-green-500" /> Clinical Suggestions & Plans ({plans.length})
        </h3>
        <button
          onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-1.5 px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-semibold rounded-lg transition-colors shadow-sm"
        >
          <Plus className="w-4 h-4" /> Add Suggestion
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleAdd} className="mb-5 bg-green-50 border border-green-100 rounded-xl p-5 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
             <select 
               value={form.type} 
               onChange={e => setForm({...form, type: e.target.value})}
               className="px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white"
             >
               <option value="exercise">Exercise</option>
               <option value="diet">Diet</option>
               <option value="therapy">Therapy</option>
             </select>
            <input required value={form.title} onChange={e => setForm({...form, title: e.target.value})}
              placeholder="e.g. Walking, Low sodium diet" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
            <input required value={form.description} onChange={e => setForm({...form, description: e.target.value})}
              placeholder="Detailed instructions" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
            <input required value={form.scheduled_times} onChange={e => setForm({...form, scheduled_times: e.target.value})}
              placeholder="Times: 07:00, 18:00" className="px-3 py-2 border border-gray-300 rounded-lg text-sm" />
          </div>
          <div className="flex gap-2 justify-end">
            <button type="button" onClick={() => setShowForm(false)} className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={saving} className="px-5 py-2 bg-green-600 text-white text-sm font-semibold rounded-lg flex items-center gap-2">
              {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />} Save Plan
            </button>
          </div>
        </form>
      )}

      {plans.length === 0 ? (
        <div className="text-center py-8 text-gray-400 border-2 border-dashed border-gray-50 rounded-xl">
          <Activity className="w-10 h-10 mx-auto mb-3 opacity-20" />
          <p className="font-medium">No active clinical plans or suggestions.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {plans.map(p => (
            <div key={p.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-100">
              <div className="flex gap-3">
                <div className={`mt-1 w-8 h-8 rounded-lg flex items-center justify-center ${p.type === 'exercise' ? 'bg-orange-100 text-orange-600' : p.type === 'diet' ? 'bg-emerald-100 text-emerald-600' : 'bg-purple-100 text-purple-600'}`}>
                   {p.type === 'diet' ? <Coffee className="w-4 h-4" /> : <Activity className="w-4 h-4" />}
                </div>
                <div>
                  <p className="font-bold text-gray-900">{p.title}</p>
                  <p className="text-gray-600 text-xs font-medium">{p.description}</p>
                  <p className="text-[10px] text-gray-500 mt-1 uppercase tracking-tight font-bold">⏰ {Array.isArray(p.scheduled_times) ? p.scheduled_times.join(', ') : p.scheduled_times}</p>
                </div>
              </div>
              <button className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors">
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default ClinicalPlansSection;
