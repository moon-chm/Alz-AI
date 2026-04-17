import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import MemoryCard from '../../components/caretaker/MemoryCard';
import MemoryForm from '../../components/caretaker/MemoryForm';
import memoryService from '../../services/memory.service';
import { usePatientContext } from '../../context/PatientContext';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Search, Plus, Filter, Type } from 'lucide-react';

const MemoryBank = () => {
  const { selectedPatient } = usePatientContext();
  const [memories, setMemories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingMemory, setEditingMemory] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCat, setFilterCat] = useState('All');

  useEffect(() => {
    if (selectedPatient?.id) fetchMemories();
  }, [selectedPatient]);

  const fetchMemories = async () => {
    setLoading(true);
    try {
      const data = await memoryService.getMemories(selectedPatient.id);
      setMemories(data);
    } catch (err) {
      showError('Failed to fetch memories');
    } finally {
      setLoading(false);
    }
  };

  const handleAddSubmit = async (formData) => {
    if (!selectedPatient?.id) return;
    try {
      if (editingMemory) {
        await memoryService.updateMemory(editingMemory.id, formData);
        showSuccess('Memory updated successfully');
      } else {
        await memoryService.addMemory(selectedPatient.id, formData);
        showSuccess('Memory added to the bank');
      }
      setShowForm(false);
      setEditingMemory(null);
      fetchMemories();
    } catch (err) {
      throw err;
    }
  };

  const handleDelete = async (id) => {
    try {
      await memoryService.deleteMemory(id);
      showSuccess('Memory deleted');
      fetchMemories();
    } catch (err) {
      showError('Failed to delete memory');
    }
  };

  const categories = ['All', ...new Set(memories.map(m => m.category ? m.category.charAt(0).toUpperCase() + m.category.slice(1) : 'General'))];

  const filteredMemories = memories.filter(m => {
    const matchSearch = m.content?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchCat = filterCat === 'All' || (m.category && m.category.toLowerCase() === filterCat.toLowerCase() || (!m.category && filterCat === 'General'));
    return matchSearch && matchCat;
  });

  return (
    <Layout title="Memory Bank">
      <div className="max-w-7xl mx-auto space-y-6 pb-12">
        
        {/* Header Options */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="w-full md:w-auto relative group flex-1 max-w-md">
            <input 
              type="text" 
              placeholder="Search memories..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 hover:bg-white transition-colors"
            />
            <Search className="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          </div>

          <div className="flex gap-3 w-full md:w-auto overflow-x-auto pb-2 md:pb-0 hide-scrollbar">
            {categories.map(cat => (
              <button
                key={cat}
                onClick={() => setFilterCat(cat)}
                className={`px-4 py-2 rounded-lg font-medium whitespace-nowrap transition-colors ${filterCat === cat ? 'bg-blue-600 text-white shadow-sm' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
              >
                {cat}
              </button>
            ))}
          </div>

          <button 
            onClick={() => { setShowForm(true); setEditingMemory(null); }}
            className="w-full md:w-auto bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg font-bold transition-colors shadow-sm flex items-center justify-center gap-2"
          >
            <Plus className="w-5 h-5" /> Add Memory
          </button>
        </div>

        {showForm && (
          <div className="mb-8 animate-in fade-in slide-in-from-top-4 duration-300 relative z-20">
            <MemoryForm 
              type="memory"
              initialData={editingMemory}
              onSubmit={handleAddSubmit}
              onCancel={() => { setShowForm(false); setEditingMemory(null); }}
            />
          </div>
        )}

        {/* Content Area */}
        {loading ? (
           <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
             {[1,2,3,4,5,6].map(i => (
               <div key={i} className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 h-48 animate-pulse flex flex-col">
                 <div className="h-6 w-24 bg-gray-200 rounded-full mb-4"></div>
                 <div className="flex-1 space-y-2">
                   <div className="h-4 bg-gray-200 rounded w-full"></div>
                   <div className="h-4 bg-gray-200 rounded w-5/6"></div>
                   <div className="h-4 bg-gray-200 rounded w-4/6"></div>
                 </div>
               </div>
             ))}
           </div>
        ) : filteredMemories.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-16 text-center">
            <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 border border-gray-100">
               <Type className="w-10 h-10 text-gray-300" />
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-2">No Memories Found</h3>
            <p className="text-gray-500 font-medium mb-6">
              {searchTerm ? "No memories match your search." : "Start building a rich profile to help in cognitive therapy."}
            </p>
            {!searchTerm && !showForm && (
              <button 
                onClick={() => setShowForm(true)}
                className="text-blue-600 font-bold hover:underline"
              >
                + Create the first memory
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredMemories.map(memory => (
              <MemoryCard 
                key={memory.id} 
                memory={memory} 
                onEdit={(mem) => { setEditingMemory(mem); setShowForm(true); window.scrollTo({top: 0}); }}
                onDelete={handleDelete}
              />
            ))}
          </div>
        )}

      </div>
    </Layout>
  );
};

export default MemoryBank;
