import { Toaster as HotToaster } from 'react-hot-toast';
import toast from 'react-hot-toast';

export const Toaster = HotToaster;

// Helper to safely format API errors into strings
const formatMessage = (msg) => {
  if (!msg) return 'An unknown error occurred';
  if (typeof msg === 'string') return msg;
  
  // Handle FastAPI Validation Error array
  if (Array.isArray(msg)) {
    if (msg.length > 0 && msg[0].msg) {
      return msg.map(err => {
        const field = err.loc && err.loc.length > 1 ? err.loc[err.loc.length - 1] : 'Field';
        return `${field}: ${err.msg}`;
      }).join(', ');
    }
    return msg.map(m => (typeof m === 'object' ? JSON.stringify(m) : String(m))).join(', ');
  }
  
  // Handle other object types
  if (typeof msg === 'object') {
    if (msg.message) return msg.message;
    if (msg.detail) return typeof msg.detail === 'string' ? msg.detail : JSON.stringify(msg.detail);
    return JSON.stringify(msg);
  }
  
  return String(msg);
};

export const showSuccess = (message) => toast.success(formatMessage(message), { duration: 3000 });
export const showError = (message) => toast.error(formatMessage(message), { duration: 5000 });
export const showWarning = (message) => toast(formatMessage(message), { icon: '⚠️', duration: 4000 });
export const showInfo = (message) => toast(formatMessage(message), { icon: 'ℹ️', duration: 3000 });
