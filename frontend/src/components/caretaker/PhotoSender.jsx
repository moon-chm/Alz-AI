import React, { useState, useRef, useCallback } from 'react';
import { Upload, X, Check, Image as ImageIcon } from 'lucide-react';
import caretakerService from '../../services/caretaker.service';

const PhotoSender = ({ onUploadSuccess }) => {
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [caption, setCaption] = useState('');
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  
  const fileInputRef = useRef(null);

  const handleFile = (selectedFile) => {
    setError(null);
    setSuccess(false);
    
    if (!selectedFile) return;
    
    if (!selectedFile.type.startsWith('image/')) {
      setError('Please select an image file (JPG, PNG).');
      return;
    }
    
    if (selectedFile.size > 5 * 1024 * 1024) {
      setError('File size exceeds 5MB limit. Please choose a smaller image.');
      return;
    }

    setFile(selectedFile);
    setPreview(URL.createObjectURL(selectedFile));
  };

  const handleDragOver = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(false);
    const droppedFile = e.dataTransfer.files[0];
    handleFile(droppedFile);
  }, []);

  const resetForm = () => {
    setFile(null);
    if (preview) URL.revokeObjectURL(preview);
    setPreview(null);
    setCaption('');
    setSuccess(false);
    setError(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return;

    setIsUploading(true);
    setError(null);
    setSuccess(false);

    try {
      await caretakerService.sendPhoto(file, caption);
      
      setSuccess(true);
      setTimeout(() => {
        resetForm();
        if (onUploadSuccess) onUploadSuccess();
      }, 2000);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to upload photo. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 mb-6">
      <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
        <ImageIcon className="w-5 h-5 text-blue-600" /> Send a Photo
      </h3>

      {error && (
        <div className="bg-red-50 text-red-600 p-3 rounded-lg border border-red-100 text-sm mb-4">
          {error}
        </div>
      )}

      {success && (
        <div className="bg-green-50 text-green-700 p-4 rounded-lg border border-green-200 flex items-center gap-2 mb-4">
          <Check className="w-5 h-5" />
          <span className="font-medium">Photo sent! ✓</span>
        </div>
      )}

      {!file && !success && (
        <div 
          className={`border-2 border-dashed rounded-xl p-8 text-center transition-colors cursor-pointer ${isDragOver ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400 bg-gray-50'}`}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          onClick={() => fileInputRef.current?.click()}
        >
          <Upload className={`w-10 h-10 mx-auto mb-3 ${isDragOver ? 'text-blue-500' : 'text-gray-400'}`} />
          <p className="text-gray-700 font-medium mb-1">Click to select or drag and drop</p>
          <p className="text-sm text-gray-500">JPG, PNG up to 5MB</p>
          <input 
            type="file" 
            ref={fileInputRef} 
            onChange={(e) => handleFile(e.target.files[0])} 
            accept="image/*" 
            className="hidden" 
          />
        </div>
      )}

      {file && !success && (
        <form onSubmit={handleUpload} className="space-y-4 border rounded-xl p-4 bg-gray-50">
          <div className="flex items-start gap-4">
            <div className="w-32 h-32 rounded-lg overflow-hidden border border-gray-200 bg-black/5 flex-shrink-0 relative">
              <img src={preview} alt="Preview" className="w-full h-full object-cover" />
              <button 
                type="button" 
                onClick={resetForm}
                className="absolute top-1 right-1 bg-black/50 text-white rounded-full p-1 hover:bg-black/70"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <div className="flex-1 flex flex-col space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Caption (Optional)</label>
                <input 
                  type="text"
                  value={caption}
                  onChange={(e) => setCaption(e.target.value)}
                  placeholder="E.g., Missing you!"
                  disabled={isUploading}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <p className="text-xs text-gray-500 truncate">{file.name} ({(file.size / 1024 / 1024).toFixed(2)} MB)</p>
            </div>
          </div>

          <div className="flex justify-end pt-2 border-t border-gray-200 mt-4">
            <button
              type="submit"
              disabled={isUploading}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors disabled:opacity-50 flex items-center justify-center min-w-[140px]"
            >
              {isUploading ? (
                <>
                  <span className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                  Sending...
                </>
              ) : 'Send Photo'}
            </button>
          </div>
        </form>
      )}
    </div>
  );
};

export default PhotoSender;
