import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';

// Context Providers
import { AuthProvider } from './context/AuthContext';
import { PatientProvider } from './context/PatientContext';

// Shared Components
import ErrorBoundary from './components/shared/ErrorBoundary';
import ProtectedRoute from './components/shared/ProtectedRoute';
import RoleRoute from './components/shared/RoleRoute';

// Auth Pages
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';
import OTPVerify from './pages/auth/OTPVerify';

// Doctor Pages
import DoctorDashboard from './pages/doctor/DoctorDashboard';
import PatientDetail from './pages/doctor/PatientDetail';
import PatientForm from './pages/doctor/PatientForm';
import MRIAnalysis from './pages/doctor/MRIAnalysis';
import DoctorAppointments from './pages/doctor/DoctorAppointments';

// Caretaker Pages
import CaretakerDashboard from './pages/caretaker/CaretakerDashboard';
import LocationTracker from './pages/caretaker/LocationTracker';
import MedicationTracker from './pages/caretaker/MedicationTracker';
import MemoryBank from './pages/caretaker/MemoryBank';
import Photos from './pages/caretaker/Photos';
import Appointments from './pages/caretaker/Appointments';
import Reports from './pages/caretaker/Reports';

// Shared Pages
import Settings from './pages/shared/Settings';

const App = () => {
  return (
    <ErrorBoundary>
      <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <AuthProvider>
          <PatientProvider>
            
            <Routes>
              {/* Public Auth Routes */}
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />
              <Route path="/verify-otp" element={<OTPVerify />} />

              {/* Redirect root based on user state via a wrapper or simple redirect */}
              <Route path="/" element={<Navigate to="/login" replace />} />

              {/* Doctor Routes */}
              <Route path="/doctor" element={<RoleRoute requiredRole="doctor" />}>
                <Route path="dashboard" element={<DoctorDashboard />} />
                <Route path="patient/create" element={<PatientForm />} />
                <Route path="appointments" element={<DoctorAppointments />} />
                <Route path="patient/:id" element={<PatientDetail />} />
                <Route path="patient/:id/mri" element={<MRIAnalysis />} />
              </Route>

              {/* Caretaker Routes */}
              <Route path="/caretaker" element={<RoleRoute requiredRole="caretaker" />}>
                <Route path="dashboard" element={<CaretakerDashboard />} />
                <Route path="monitor" element={<LocationTracker />} />
                <Route path="medications" element={<MedicationTracker />} />
                <Route path="data-feeding" element={<MemoryBank />} />
                <Route path="photos" element={<Photos />} />
                <Route path="appointments" element={<Appointments />} />
                <Route path="reports" element={<Reports />} />
              </Route>

              {/* Shared Protected Routes */}
              <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />

              {/* 404 */}
              <Route path="*" element={
                <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
                  <h1 className="text-4xl font-bold text-gray-900 mb-4">404</h1>
                  <p className="text-gray-500 mb-6">Page not found</p>
                  <button onClick={() => window.history.back()} className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                    Go Back
                  </button>
                </div>
              } />
            </Routes>

            {/* Notification Container */}
            <Toaster position="top-right" />
          </PatientProvider>
        </AuthProvider>
      </Router>
    </ErrorBoundary>
  );
};

export default App;
