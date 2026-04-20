import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import PhotoSender from '../../components/caretaker/PhotoSender';
import caretakerService from '../../services/caretaker.service';
import { usePatientContext } from '../../context/PatientContext';
import { Image as ImageIcon, Calendar, User, Clock, Loader2, Trash2 } from 'lucide-react';
import { format } from 'date-fns';

const Photos = () => {
  const { selectedPatient, loading: contextLoading } = usePatientContext();
  const [photos, setPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [photoToDelete, setPhotoToDelete] = useState(null);

  useEffect(() => {
    console.log("Photos Page Mounted. Context Strategy:", {
       patientId: selectedPatient?.id,
       rehydrating: contextLoading
    });
    if (selectedPatient?.id) {
      fetchPhotos();
    }
  }, [selectedPatient, contextLoading]);

  const fetchPhotos = async () => {
    setLoading(true);
    try {
      const data = await caretakerService.getPhotos();
      setPhotos(data);
    } catch (err) {
      console.error('Failed to fetch photos:', err);
    } finally {
      setLoading(false);
    }
  };

  const openDeleteModal = (photoId) => {
    setPhotoToDelete(photoId);
  };

  const confirmDelete = async () => {
    if (!photoToDelete) return;
    try {
      await caretakerService.deletePhoto(photoToDelete);
      setPhotos(photos.filter(p => p.id !== photoToDelete));
    } catch (err) {
      console.error('Failed to delete photo:', err);
    } finally {
      setPhotoToDelete(null);
    }
  };

  if (contextLoading && !selectedPatient) {
    return (
      <Layout title="Initializing Gallery">
        <div className="flex flex-col items-center justify-center min-h-[400px]">
           <Loader2 className="w-12 h-12 text-blue-600 animate-spin mb-4" />
           <p className="text-gray-500 font-medium">Synchronizing clinical memory gallery...</p>
        </div>
      </Layout>
    );
  }

  if (!selectedPatient) {
    return (
      <Layout title="Memory Gallery">
        <div className="p-8 text-center bg-white m-8 rounded-xl border border-gray-100 font-medium text-gray-500">
          No patient linked to this account.
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Memory Gallery">
      <div className="max-w-7xl mx-auto space-y-8 pb-12">
        
        {/* Upload Section */}
        <div className="max-w-2xl">
           <PhotoSender onUploadSuccess={fetchPhotos} />
        </div>

        {/* Gallery Section */}
        <div className="space-y-4">
           <div className="flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                <ImageIcon className="w-6 h-6 text-blue-600" /> 
                Recent Memories ({photos.length})
              </h2>
           </div>

           {loading ? (
             <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
               {[1, 2, 3, 4].map(i => (
                 <div key={i} className="aspect-square bg-gray-100 rounded-2xl animate-pulse"></div>
               ))}
             </div>
           ) : photos.length === 0 ? (
             <div className="bg-white rounded-2xl border-2 border-dashed border-gray-200 p-20 text-center">
                <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                   <ImageIcon className="w-8 h-8 text-gray-300" />
                </div>
                <h3 className="text-lg font-bold text-gray-900 mb-1">No photos yet</h3>
                <p className="text-gray-500">Upload the first memory to help your patient recognize faces and places.</p>
             </div>
           ) : (
             <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {photos.map(photo => (
                  <div key={photo.id} className="group bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1">
                    <div className="aspect-square overflow-hidden relative group/image">
                       <img 
                         src={photo.cloudinary_url} 
                         alt={photo.caption || 'Memory'} 
                         className="w-full h-full object-cover group-hover/image:scale-105 transition-transform duration-500"
                       />
                       <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-4 opacity-0 group-hover/image:opacity-100 transition-opacity">
                          <p className="text-white text-sm font-medium line-clamp-2">{photo.caption}</p>
                       </div>
                       <button 
                         onClick={(e) => {
                           e.stopPropagation();
                           openDeleteModal(photo.id);
                         }}
                         className="absolute top-3 right-3 p-2 bg-black/40 backdrop-blur-md rounded-full text-white/90 hover:bg-red-500 hover:text-white shadow-sm opacity-0 group-hover/image:opacity-100 scale-90 group-hover/image:scale-100 transition-all duration-300 z-10"
                         title="Delete Photo"
                       >
                         <Trash2 className="w-4 h-4" />
                       </button>
                    </div>
                    <div className="p-4 space-y-3">
                       <div className="flex items-center gap-2 text-xs text-gray-500">
                          <Clock className="w-3.5 h-3.5" />
                          <span>{format(new Date(photo.sent_at), 'MMM d, yyyy • h:mm a')}</span>
                       </div>
                       <div className="flex items-center gap-2 text-xs font-semibold text-gray-700">
                          <div className="w-5 h-5 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-[10px]">
                             {photo.sender_name.charAt(0)}
                          </div>
                          <span className="truncate">Sent by {photo.sender_name}</span>
                       </div>
                    </div>
                  </div>
                ))}
             </div>
           )}
        </div>
      </div>

      {photoToDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/40 backdrop-blur-sm transition-opacity">
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-sm overflow-hidden transform transition-all duration-300 scale-100 translate-y-0">
            <div className="p-8 text-center border-b border-gray-100">
              <div className="w-14 h-14 rounded-full bg-red-50 flex items-center justify-center mx-auto mb-5 shadow-inner">
                <Trash2 className="w-6 h-6 text-red-500" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">Delete Memory</h3>
              <p className="text-gray-500 text-sm leading-relaxed px-2">
                Are you sure you want to permanently delete this memory? This action cannot be undone.
              </p>
            </div>
            <div className="px-6 py-5 bg-gray-50/80 flex items-center gap-3 justify-center">
              <button 
                onClick={() => setPhotoToDelete(null)}
                className="px-5 py-2.5 text-sm font-semibold text-gray-600 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 hover:text-gray-900 transition-colors flex-1"
              >
                Cancel
              </button>
              <button 
                onClick={confirmDelete}
                className="px-5 py-2.5 text-sm font-semibold text-white bg-red-500 rounded-xl hover:bg-red-600 active:bg-red-700 transition-colors shadow-sm shadow-red-200 flex-1"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
};

export default Photos;
