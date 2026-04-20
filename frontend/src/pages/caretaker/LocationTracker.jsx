import React, { useState, useEffect } from 'react';
import Layout from '../../components/layout/Layout';
import GeofenceMap from '../../components/caretaker/GeofenceMap';
import caretakerService from '../../services/caretaker.service';
import { usePatientContext } from '../../context/PatientContext';
import { showSuccess, showError } from '../../components/shared/Toast';
import { MapPin, Navigation, Map, AlertTriangle, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import useWebSocket from '../../hooks/useWebSocket';

const LocationTracker = () => {
  const { selectedPatient, loading: contextLoading } = usePatientContext();
  const [location, setLocation] = useState(null);
  const [loading, setLoading] = useState(true);
  const [savingGeofence, setSavingGeofence] = useState(false);

  // 1. Real-time WebSocket hook
  const { isConnected } = useWebSocket(selectedPatient?.id, (data) => {
    if (data.event_type === 'location_updated' || data.event_type === 'location_data') {
      console.log('Real-time location received:', data);
      setLocation(data);
    }
  });

  useEffect(() => {
    console.log("Monitor Page Mounted. Context Strategy:", {
       patientId: selectedPatient?.id,
       rehydrating: contextLoading
    });

    if (selectedPatient?.id) {
      fetchLocation();
      
      // 2. Slow heartbeat fallback (60s instead of 10s)
      const interval = setInterval(() => {
        if (!isConnected) {
          fetchLocation(false); 
        }
      }, 60000); 
      
      return () => clearInterval(interval);
    }
  }, [selectedPatient, isConnected, contextLoading]);

  const fetchLocation = async (showLoading = true) => {
    if (showLoading) setLoading(true);
    try {
      const data = await caretakerService.getLocation();
      setLocation(data);
    } catch (err) {
      console.error('Failed to fetch location:', err);
    } finally {
      if (showLoading) setLoading(false);
    }
  };

  const handleSetGeofence = async (coordinates) => {
    if (!selectedPatient?.id) return;
    setSavingGeofence(true);
    try {
      // Map the full polygon array to match backend GeofenceSet schema: List[Dict[str, float]]
      const payload = {
        coordinates: coordinates.map(pt => ({
          lat: parseFloat(pt.lat),
          lng: parseFloat(pt.lng)
        }))
      };
      
      console.log("Saving Safe Zone Polygon:", payload);
      await caretakerService.setGeofence(selectedPatient.id, payload);
      
      showSuccess('Safe zone updated successfully');
      fetchLocation();
    } catch (err) {
      console.error("Geofence Save Error:", err);
      showError('Failed to save safe zone');
    } finally {
      setSavingGeofence(false);
    }
  };

  if (contextLoading && !selectedPatient) {
     return (
       <Layout title="Initializing Monitor">
         <div className="flex flex-col items-center justify-center min-h-[400px]">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mb-4" />
            <p className="text-gray-500 font-medium">Re-establishing clinical monitor context...</p>
         </div>
       </Layout>
     );
  }

  if (!selectedPatient) return <Layout title="Location Tracker"><div className="p-8 text-center bg-white m-8 rounded-xl border border-gray-100 font-medium">No patient selected</div></Layout>;

  const isSafe = location?.geofence_status === 'inside';

  return (
    <Layout title="Live Location">
      <div className="max-w-6xl mx-auto space-y-6 pb-12">
        
        {/* Header Panel */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
           <div className="flex items-center gap-4">
              <div className={`p-4 rounded-full ${isSafe ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600 animate-pulse'}`}>
                 <MapPin className="w-8 h-8" />
              </div>
              <div>
                 <h2 className="text-xl font-bold text-gray-900 mb-1">
                   {selectedPatient.full_name}'s Location
                 </h2>
                 <div className="flex items-center gap-2">
                   <div className={`w-2 h-2 rounded-full ${location ? 'bg-green-500' : 'bg-gray-300'}`}></div>
                   <span className="text-sm font-medium text-gray-500">
                     {location ? `Updated ${formatDistanceToNow(new Date(location.timestamp), { addSuffix: true })}` : 'Waiting for GPS fix...'}
                   </span>
                 </div>
              </div>
           </div>

           <div className="flex gap-3 w-full md:w-auto">
             <button 
               onClick={fetchLocation}
               className="flex-1 md:flex-none flex justify-center items-center gap-2 px-4 py-2 border border-blue-200 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 font-medium transition-colors"
             >
               <Navigation className="w-4 h-4" /> Refresh Ping
             </button>
           </div>
        </div>

        {/* Warning Banner */}
        {!isSafe && location && (
           <div className="bg-red-50 border-2 border-red-200 p-4 rounded-xl flex items-start md:items-center gap-4 shadow-sm">
             <div className="p-2 bg-red-100 rounded-full text-red-600">
               <AlertTriangle className="w-6 h-6" />
             </div>
             <div className="flex-1">
               <h3 className="font-bold text-red-800">Alert: Wandering Detected</h3>
               <p className="text-red-700 text-sm font-medium">{selectedPatient.full_name} has left the designated safe zone!</p>
             </div>
             <button className="whitespace-nowrap px-4 py-2 bg-red-600 text-white rounded-lg font-bold hover:bg-red-700 transition-colors shadow-sm">
               Get Directions
             </button>
           </div>
        )}

        {/* Map Container */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-2 overflow-hidden relative min-h-[500px]">
           {loading && !location ? (
              <div className="absolute inset-0 bg-white/90 z-10 flex flex-col items-center justify-center p-8">
                 <Loader2 className="w-10 h-10 text-blue-600 animate-spin mb-4" />
                 <p className="font-medium text-gray-600">Connecting to SAATHI wearable GPS...</p>
              </div>
           ) : (
              <>
                {savingGeofence && (
                  <div className="absolute top-4 left-1/2 -translate-x-1/2 bg-gray-900 text-white px-4 py-2 rounded-full font-medium z-[1000] flex items-center gap-2 shadow-lg">
                    <Loader2 className="w-4 h-4 animate-spin" /> Saving safe zone...
                  </div>
                )}
                <div className="p-4 border-b border-gray-50 flex items-center gap-2 text-gray-700 font-medium">
                  <Map className="w-5 h-5 text-gray-400" /> Draw a shape on the map to automatically update the Safe Zone.
                </div>
                <GeofenceMap 
                  lastLocation={location}
                  onGeofenceSet={handleSetGeofence}
                />
              </>
           )}
        </div>

      </div>
    </Layout>
  );
};

export default LocationTracker;
