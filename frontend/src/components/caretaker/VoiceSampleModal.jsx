import React, { useState, useEffect, useRef } from 'react';
import { X, Mic, Square, UploadCloud, Trash2, CheckCircle, Loader2 } from 'lucide-react';
import { showSuccess, showError } from '../shared/Toast';

const VoiceSampleModal = ({ patientId, onClose }) => {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const [recordedBlob, setRecordedBlob] = useState(null);
  const [selectedFile, setSelectedFile] = useState(null);
  const [showConfirmDelete, setShowConfirmDelete] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  const mediaRecorderRef = useRef(null);
  const timerRef = useRef(null);
  const audioChunksRef = useRef([]);

  useEffect(() => {
    fetchStatus();
    return () => {
      stopTimer();
      if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
        mediaRecorderRef.current.stop();
      }
    };
  }, []);

  const fetchStatus = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/patient/voice-sample?patient_id=${patientId}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();
      if (response.ok) {
        setStatus(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const startTimer = () => {
    setRecordingDuration(0);
    timerRef.current = setInterval(() => {
      setRecordingDuration(prev => prev + 1);
    }, 1000);
  };

  const stopTimer = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
  };

  const formatDuration = (seconds) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const handleStartRecording = async () => {
    setErrorMsg("");
    setRecordedBlob(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.addEventListener("dataavailable", event => {
        audioChunksRef.current.push(event.data);
      });

      mediaRecorder.addEventListener("stop", () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/mp3' });
        setRecordedBlob(audioBlob);
        stream.getTracks().forEach(track => track.stop());
      });

      mediaRecorder.start();
      setIsRecording(true);
      startTimer();
    } catch (err) {
      setErrorMsg("Failed to access microphone.");
    }
  };

  const handleStopRecording = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
      mediaRecorderRef.current.stop();
    }
    setIsRecording(false);
    stopTimer();
  };

  const handleFileSelect = (e) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      if (file.size > 10 * 1024 * 1024) {
        setErrorMsg("File too large. Maximum size is 10MB.");
        return;
      }
      setSelectedFile(file);
      setRecordedBlob(null);
      setErrorMsg("");
    }
  };

  const handleUpload = async (blobToUpload, filename) => {
    setErrorMsg("");
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('patient_id', patientId);
      formData.append('audio', blobToUpload, filename);

      const token = localStorage.getItem('token');
      const response = await fetch('/api/patient/voice-sample', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.detail || "Upload failed");
      }

      showSuccess("Voice sample updated successfully!");
      await fetchStatus();
      setSelectedFile(null);
      setRecordedBlob(null);
      setTimeout(onClose, 2000);
    } catch (err) {
      setErrorMsg(err.message || "Failed to upload file.");
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/patient/voice-sample?patient_id=${patientId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        showSuccess("Voice sample deleted.");
        fetchStatus();
      }
    } catch (err) {
      setErrorMsg("Failed to delete voice sample.");
    } finally {
      setShowConfirmDelete(false);
      setLoading(false);
    }
  };

  if (loading && !status) return null; // Or skeleton

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm transition-opacity">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <h2 className="text-xl font-bold font-display text-gray-900">Set SAATHI Voice</h2>
          <button onClick={onClose} className="p-2 bg-white border border-gray-200 text-gray-500 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 overflow-y-auto">
          {errorMsg && (
            <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-xl border border-red-100 text-sm font-medium">
              {errorMsg}
            </div>
          )}

          {/* Status Section */}
          <div className="mb-8 p-5 rounded-2xl bg-gray-50 border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className={`w-3 h-3 rounded-full ${status?.has_voice ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-gray-400'}`}></div>
                <div>
                  <p className="font-semibold text-gray-900">{status?.has_voice ? 'Voice Active' : 'No voice set'}</p>
                  {status?.has_voice && status.uploaded_at && (
                    <p className="text-xs text-gray-500">Uploaded {new Date(status.uploaded_at).toLocaleDateString()}</p>
                  )}
                </div>
              </div>
              
              {status?.has_voice && !showConfirmDelete && (
                <button onClick={() => setShowConfirmDelete(true)} className="text-red-500 hover:bg-red-50 px-3 py-1.5 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors">
                  <Trash2 className="w-4 h-4" /> Delete Voice
                </button>
              )}

              {showConfirmDelete && (
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500">Sure?</span>
                  <button onClick={handleDelete} className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-medium transition-colors">Yes</button>
                  <button onClick={() => setShowConfirmDelete(false)} className="bg-gray-200 hover:bg-gray-300 text-gray-700 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors">No</button>
                </div>
              )}
            </div>

            {status?.has_voice && (
              <div className="mt-2 pt-4 border-t border-gray-200">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Current Voice Sample Preview</p>
                <audio src={status.voice_sample_url} controls className="w-full h-10" />
              </div>
            )}
          </div>

          {!showConfirmDelete && (
            <div className="space-y-6">
              {/* Upload Section */}
              <div className="border border-dashed border-blue-200 bg-blue-50/50 rounded-2xl p-6 text-center">
                <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-3">
                  <UploadCloud className="w-6 h-6" />
                </div>
                <h3 className="font-semibold text-gray-900">Upload Recording</h3>
                <p className="text-xs text-gray-500 mt-1 mb-4">
                  Upload a voice recording of the patient's favourite person. <br/>
                  30s - 2m works best. MP3, WAV, M4A, OGG (Max 10MB)
                </p>
                
                <input type="file" id="voice-upload" accept="audio/*" className="hidden" onChange={handleFileSelect} />
                
                <label htmlFor="voice-upload" className="cursor-pointer inline-block w-full text-sm py-2.5 px-4 bg-white border border-blue-300 text-blue-700 font-semibold rounded-xl hover:bg-blue-50 transition-colors shadow-sm">
                  {selectedFile ? selectedFile.name : 'Select File'}
                </label>

                {selectedFile && (
                  <button 
                    onClick={() => handleUpload(selectedFile, selectedFile.name)}
                    disabled={uploading}
                    className="w-full mt-3 flex items-center justify-center gap-2 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition-colors shadow-md disabled:bg-blue-400"
                  >
                    {uploading ? <Loader2 className="w-5 h-5 animate-spin" /> : <CheckCircle className="w-5 h-5" />}
                    {uploading ? 'Uploading...' : 'Confirm Upload'}
                  </button>
                )}
              </div>

              <div className="relative flex items-center pt-2">
                <div className="flex-grow border-t border-gray-200"></div>
                <span className="flex-shrink-0 mx-4 text-sm text-gray-400 font-medium">Or</span>
                <div className="flex-grow border-t border-gray-200"></div>
              </div>

              {/* Record Directly Section */}
              <div className="border border-gray-200 bg-white rounded-2xl p-6 text-center shadow-sm">
                <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Mic className="w-6 h-6" />
                </div>
                <h3 className="font-semibold text-gray-900">Record Directly</h3>
                <p className="text-xs text-gray-500 mt-1 mb-4">Uses your microphone to capture the voice directly.</p>

                {isRecording ? (
                  <div className="space-y-4">
                    <div className="text-2xl font-mono text-red-500 font-bold animate-pulse">
                      {formatDuration(recordingDuration)}
                    </div>
                    <button 
                      onClick={handleStopRecording}
                      className="w-full inline-flex items-center justify-center gap-2 py-3 px-4 bg-red-100 text-red-700 font-bold rounded-xl hover:bg-red-200 transition-colors"
                    >
                      <Square className="w-5 h-5" /> Stop Recording
                    </button>
                  </div>
                ) : recordedBlob ? (
                  <div className="space-y-4">
                    <audio src={URL.createObjectURL(recordedBlob)} controls className="w-full h-10" />
                    <div className="flex gap-2">
                      <button 
                        onClick={handleStartRecording}
                        className="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-xl text-sm transition-colors"
                      >
                        Re-record
                      </button>
                      <button 
                        onClick={() => handleUpload(recordedBlob, "recorded_voice.mp3")}
                        disabled={uploading}
                        className="flex-1 flex items-center justify-center gap-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-sm shadow-md transition-colors disabled:bg-blue-400"
                      >
                        {uploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <UploadCloud className="w-4 h-4" />}
                        {uploading ? 'Uploading...' : 'Upload This'}
                      </button>
                    </div>
                  </div>
                ) : (
                  <button 
                    onClick={handleStartRecording}
                    className="w-full inline-flex items-center justify-center gap-2 py-3 px-4 bg-gray-900 text-white font-bold rounded-xl hover:bg-gray-800 transition-colors shadow-md"
                  >
                    <Mic className="w-5 h-5" /> Start Recording
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default VoiceSampleModal;
