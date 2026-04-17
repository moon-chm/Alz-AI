import React, { useState, useRef, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, FeatureGroup } from 'react-leaflet';
import L from 'leaflet';
import { EditControl } from 'react-leaflet-draw';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';

// Fix leaflet icons path issues in React
const customMarkerIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const GeofenceMap = ({ lastLocation, onGeofenceSet }) => {
  // Mumbai default
  const defaultCenter = [19.0760, 72.8777];
  const center = lastLocation ? [lastLocation.lat, lastLocation.lng] : defaultCenter;
  
  const [map, setMap] = useState(null);
  const fgRef = useRef();

  const handleCreated = (e) => {
    const { layer } = e;
    const latlngs = layer.getLatLngs()[0].map(pt => ({ lat: pt.lat, lng: pt.lng }));
    if (onGeofenceSet) {
      onGeofenceSet(latlngs);
    }
  };

  const isSafe = lastLocation?.geofence_status === 'inside';
  const badgeColor = lastLocation ? (isSafe ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700') : 'bg-gray-100 text-gray-700';
  const badgeText = lastLocation ? (isSafe ? 'Inside safe zone ✓' : 'Outside! ⚠️') : 'Location unknown';

  return (
    <div className="relative border border-gray-200 rounded-xl overflow-hidden">
      <div className="absolute top-4 left-4 z-[400] shadow-md">
        <div className={`px-4 py-2 font-bold rounded-lg ${badgeColor}`}>
          {badgeText}
        </div>
      </div>
      <MapContainer 
        center={center} 
        zoom={15} 
        style={{ height: '400px', width: '100%' }}
        ref={setMap}
      >
        <TileLayer
          attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {lastLocation && (
          <Marker position={[lastLocation.lat, lastLocation.lng]} icon={customMarkerIcon} />
        )}
        <FeatureGroup ref={fgRef}>
          <EditControl
            position="topright"
            onCreated={handleCreated}
            draw={{
              rectangle: false,
              circle: false,
              circlemarker: false,
              marker: false,
              polyline: false,
              polygon: {
                metric: false,
                shapeOptions: {
                  color: '#0F9D58',
                  fillOpacity: 0.2
                }
              }
            }}
          />
        </FeatureGroup>
      </MapContainer>
    </div>
  );
};

export default GeofenceMap;
