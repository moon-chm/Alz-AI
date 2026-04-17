import React from 'react';
import Sidebar from './Sidebar';
import TopBar from './TopBar';

const Layout = ({ children, title, onSearch }) => {
  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 flex flex-col ml-64 overflow-hidden">
        <TopBar title={title} onSearch={onSearch} />
        <main className="flex-1 overflow-y-auto p-6 relative">
          {children}
        </main>
      </div>
    </div>
  );
};

export default Layout;
