import React, { useState } from 'react';
import Layout from '../../components/layout/Layout';
import useAuth from '../../hooks/useAuth';
import { showSuccess, showError } from '../../components/shared/Toast';
import { User, Lock, Bell, Moon, Smartphone, Shield, Save } from 'lucide-react';

const Settings = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('profile');
  
  // Dummy form state
  const [formData, setFormData] = useState({
    fullName: user?.full_name || '',
    email: user?.email || '',
    phone: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    notificationsEmail: true,
    notificationsSMS: true,
    notificationsApp: true,
    language: 'English',
    darkMode: false,
  });

  const handleChange = (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setFormData({ ...formData, [e.target.name]: value });
  };

  const handleSaveProfile = (e) => {
    e.preventDefault();
    // Simulate API call
    showSuccess('Profile updated successfully');
  };

  const handleSaveSecurity = (e) => {
    e.preventDefault();
    if (formData.newPassword !== formData.confirmPassword) {
      showError('New passwords do not match');
      return;
    }
    showSuccess('Security settings updated');
    setFormData({...formData, currentPassword: '', newPassword: '', confirmPassword: ''});
  };

  // Shared classes
  const tabClass = (tab) => `flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-colors w-full text-left ${activeTab === tab ? 'bg-blue-50 text-blue-700' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'}`;

  return (
    <Layout title="Settings">
      <div className="max-w-6xl mx-auto pb-12 flex flex-col md:flex-row gap-8">
        
        {/* Sidebar Nav */}
        <div className="w-full md:w-64 flex-shrink-0 space-y-1 bg-white p-4 rounded-xl border border-gray-100 shadow-sm h-fit">
          <button onClick={() => setActiveTab('profile')} className={tabClass('profile')}>
            <User className="w-5 h-5" /> Profile Settings
          </button>
          <button onClick={() => setActiveTab('security')} className={tabClass('security')}>
            <Lock className="w-5 h-5" /> Security & Login
          </button>
          <button onClick={() => setActiveTab('notifications')} className={tabClass('notifications')}>
            <Bell className="w-5 h-5" /> Notifications
          </button>
          <button onClick={() => setActiveTab('preferences')} className={tabClass('preferences')}>
            <Smartphone className="w-5 h-5" /> App Preferences
          </button>
        </div>

        {/* Content Area */}
        <div className="flex-1 bg-white rounded-xl shadow-sm border border-gray-100 p-6 md:p-8">
          
          {activeTab === 'profile' && (
            <div className="animate-in fade-in duration-300">
              <h2 className="text-xl font-bold text-gray-900 mb-6 border-b border-gray-100 pb-4">Profile Settings</h2>
              <form onSubmit={handleSaveProfile} className="space-y-6 max-w-2xl">
                <div className="flex items-center gap-6 mb-8">
                  <div className="w-24 h-24 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-3xl font-bold border-4 border-white shadow-md">
                    {user?.full_name?.charAt(0) || 'U'}
                  </div>
                  <div>
                    <button type="button" className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors">
                      Change Avatar
                    </button>
                    <p className="text-xs text-gray-500 mt-2">JPG, GIF or PNG. Max size of 800K</p>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                    <input type="text" name="fullName" value={formData.fullName} onChange={handleChange} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                    <input type="email" name="email" value={formData.email} disabled className="w-full px-4 py-2 border border-gray-300 bg-gray-50 rounded-lg cursor-not-allowed" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                    <input type="tel" name="phone" value={formData.phone} onChange={handleChange} placeholder="+91" className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                    <input type="text" value={user?.role || 'User'} disabled className="w-full px-4 py-2 border border-gray-300 bg-gray-50 rounded-lg cursor-not-allowed capitalize" />
                  </div>
                </div>

                <div className="pt-4 flex justify-end">
                  <button type="submit" className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
                    <Save className="w-4 h-4" /> Save Changes
                  </button>
                </div>
              </form>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="animate-in fade-in duration-300">
              <h2 className="text-xl font-bold text-gray-900 mb-6 border-b border-gray-100 pb-4">Security & Login</h2>
              
              <div className="bg-green-50 text-green-800 p-4 rounded-lg flex items-start gap-3 mb-8 border border-green-100">
                 <Shield className="w-5 h-5 flex-shrink-0 text-green-600 mt-0.5" />
                 <div>
                    <h3 className="font-bold text-sm">Your account is secure</h3>
                    <p className="text-sm mt-1">We use AES-256 encryption for all sensitive health data.</p>
                 </div>
              </div>

              <form onSubmit={handleSaveSecurity} className="space-y-6 max-w-xl">
                <h3 className="font-bold text-gray-900">Change Password</h3>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Current Password</label>
                  <input type="password" name="currentPassword" value={formData.currentPassword} onChange={handleChange} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Password</label>
                  <input type="password" name="newPassword" value={formData.newPassword} onChange={handleChange} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Confirm New Password</label>
                  <input type="password" name="confirmPassword" value={formData.confirmPassword} onChange={handleChange} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none" />
                </div>

                <div className="pt-4 flex justify-end">
                  <button type="submit" className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
                    Update Password
                  </button>
                </div>
              </form>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="animate-in fade-in duration-300">
              <h2 className="text-xl font-bold text-gray-900 mb-6 border-b border-gray-100 pb-4">Notification Preferences</h2>
              
              <div className="space-y-6 max-w-2xl">
                 <div className="flex items-center justify-between py-3 border-b border-gray-50">
                    <div>
                       <h3 className="font-bold text-gray-900">Email Alerts</h3>
                       <p className="text-sm text-gray-500">Receive daily summaries and critical alerts via email.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" name="notificationsEmail" checked={formData.notificationsEmail} onChange={handleChange} className="sr-only peer" />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                 </div>

                 <div className="flex items-center justify-between py-3 border-b border-gray-50">
                    <div>
                       <h3 className="font-bold text-gray-900">SMS Notifications</h3>
                       <p className="text-sm text-gray-500">Immediate SMS alerts for wandering or SOS events.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" name="notificationsSMS" checked={formData.notificationsSMS} onChange={handleChange} className="sr-only peer" />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                 </div>

                 <div className="flex items-center justify-between py-3 border-b border-gray-50">
                    <div>
                       <h3 className="font-bold text-gray-900">In-App Notifications</h3>
                       <p className="text-sm text-gray-500">Show notification dot in the application top bar.</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" name="notificationsApp" checked={formData.notificationsApp} onChange={handleChange} className="sr-only peer" />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                 </div>

                 <div className="pt-6">
                    <button onClick={() => showSuccess('Preferences saved')} className="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
                      Save Preferences
                    </button>
                 </div>
              </div>
            </div>
          )}

          {activeTab === 'preferences' && (
            <div className="animate-in fade-in duration-300">
              <h2 className="text-xl font-bold text-gray-900 mb-6 border-b border-gray-100 pb-4">App Preferences</h2>
              
              <div className="space-y-6 max-w-xl">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Display Language</label>
                  <select 
                    name="language" 
                    value={formData.language} 
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
                  >
                    <option value="English">English</option>
                    <option value="Hindi">Hindi</option>
                    <option value="Marathi">Marathi</option>
                  </select>
                  <p className="text-sm text-gray-500 mt-2">This changes the interface language. Medical notes remain unchanged.</p>
                </div>

                <div className="flex items-center justify-between py-4 border-t border-gray-100">
                   <div>
                      <h3 className="font-bold text-gray-900 flex items-center gap-2"><Moon className="w-4 h-4"/> Dark Mode</h3>
                      <p className="text-sm text-gray-500">Coming soon.</p>
                   </div>
                   <label className="relative inline-flex items-center cursor-not-allowed opacity-50">
                     <input type="checkbox" disabled className="sr-only peer" />
                     <div className="w-11 h-6 bg-gray-200 rounded-full peer"></div>
                   </label>
                </div>
              </div>
            </div>
          )}

        </div>
      </div>
    </Layout>
  );
};

export default Settings;
