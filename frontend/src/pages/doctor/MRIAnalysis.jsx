import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Layout from '../../components/layout/Layout';
import usePatient from '../../hooks/usePatient';
import MRIResult from '../../components/doctor/MRIResult';
import doctorService from '../../services/doctor.service';
import { showSuccess, showError } from '../../components/shared/Toast';
import { Upload, ArrowLeft, BrainCircuit, Loader2 } from 'lucide-react';

const MRIAnalysis = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { patient, loading: patientLoading } = usePatient(id);
  
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState(null);
  
  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    if (selected && selected.type.startsWith('image/')) {
      setFile(selected);
      setPreview(URL.createObjectURL(selected));
      setResult(null);
    } else {
      showError('Please select a valid image file');
    }
  };

  const handleAnalyze = async () => {
    if (!file) return;
    
    setIsAnalyzing(true);
    setResult(null);

    try {
      const analysisResult = await doctorService.uploadMRI(id, file);
      setResult(analysisResult);
      showSuccess('Analysis complete');
    } catch (err) {
      showError(err.response?.data?.detail || 'Analysis failed. Please try again.');
    } finally {
      setIsAnalyzing(false);
    }
  };

  if (patientLoading) {
    return (
      <Layout title="MRI Analysis">
        <div className="flex items-center justify-center h-full">
          <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
        </div>
      </Layout>
    );
  }

  return (
    <Layout title={`MRI Analysis: ${patient?.full_name || ''}`}>
      <div className="max-w-4xl mx-auto pb-12">
        <button 
          onClick={() => navigate(`/doctor/patient/${id}`)}
          className="flex items-center gap-2 text-gray-600 hover:text-blue-600 font-medium transition-colors mb-6"
        >
          <ArrowLeft className="w-5 h-5" /> Back to Patient Profile
        </button>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Upload Section */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center">
            <h2 className="text-xl font-bold text-gray-900 mb-6 w-full flex items-center gap-2 border-b border-gray-100 pb-4">
              <BrainCircuit className="w-6 h-6 text-purple-600" /> Upload Scan
            </h2>
            
            <div className="w-full flex-1 flex flex-col items-center justify-center">
              {!preview ? (
                <label className="w-full h-64 border-2 border-dashed border-gray-300 rounded-xl bg-gray-50 hover:bg-gray-100 hover:border-purple-400 transition-colors flex flex-col items-center justify-center cursor-pointer group">
                  <div className="p-4 bg-white rounded-full shadow-sm group-hover:scale-110 transition-transform mb-4">
                    <Upload className="w-8 h-8 text-purple-500" />
                  </div>
                  <span className="font-medium text-gray-700">Click to upload MRI scan</span>
                  <span className="text-sm text-gray-500 mt-1">JPG, PNG (Max 10MB)</span>
                  <input type="file" className="hidden" accept="image/*" onChange={handleFileChange} />
                </label>
              ) : (
                <div className="w-full space-y-4">
                  <div className="relative w-full h-64 rounded-xl overflow-hidden border border-gray-200 bg-black">
                    <img src={preview} alt="MRI Preview" className="w-full h-full object-contain" />
                  </div>
                  <div className="flex gap-3">
                    <button 
                      onClick={() => { setFile(null); setPreview(null); setResult(null); }}
                      className="flex-1 py-2 px-4 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors"
                      disabled={isAnalyzing}
                    >
                      Clear
                    </button>
                    <button 
                      onClick={handleAnalyze}
                      disabled={isAnalyzing}
                      className="flex-2 w-full py-2 px-4 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors shadow-sm disabled:opacity-70 flex justify-center items-center"
                    >
                      {isAnalyzing ? (
                        <><Loader2 className="w-5 h-5 mr-2 animate-spin" /> Analyzing Model...</>
                      ) : (
                        'Run AI Analysis'
                      )}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Result Section */}
          <div className="flex flex-col">
             <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex-1">
               <h2 className="text-xl font-bold text-gray-900 mb-6 border-b border-gray-100 pb-4">
                 Analysis Results
               </h2>
               
               {isAnalyzing ? (
                 <div className="flex flex-col items-center justify-center h-48 text-center px-4">
                   <BrainCircuit className="w-12 h-12 text-purple-500 animate-pulse mb-4" />
                   <h3 className="text-lg font-bold text-gray-900 mb-2">Processing Scan</h3>
                   <p className="text-gray-500 text-sm">Our ResNet model is analyzing the image for early signs of Alzheimer's...</p>
                 </div>
               ) : result ? (
                 <MRIResult 
                   result={result.classification || result.result} 
                   confidence={result.confidence} 
                   timestamp={result.timestamp || new Date()} 
                 />
               ) : (
                 <div className="flex flex-col items-center justify-center h-48 text-center px-4">
                   <div className="w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center mb-3">
                     <svg className="w-6 h-6 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                   </div>
                   <p className="text-gray-500 font-medium">Upload a scan and run analysis to view results here.</p>
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
