import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App.jsx'
import './assets/styles/globals.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Migration Cleanup: Remove legacy token keys once
const legacyToken = localStorage.getItem('alz_token');
if (legacyToken) {
  console.log('Migrating from legacy alz_token...');
  localStorage.removeItem('alz_token');
  // Optional: clear entire storage if we want a total reset
  // localStorage.clear();
  window.location.reload();
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>,
)
