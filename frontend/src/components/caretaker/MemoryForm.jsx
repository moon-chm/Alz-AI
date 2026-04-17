import React, { useState } from 'react';
import { Loader2 } from 'lucide-react';

const MemoryForm = ({ type, onSubmit, onCancel, initialData }) => {
  const [formData, setFormData] = useState(initialData || {});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await onSubmit(formData);
    } catch (err) {
      setError(err.response?.data?.detail || err.message || 'Failed to submit form');
    } finally {
      setLoading(false);
    }
  };

  const renderField = (name, label, typeField = 'text', required = false, options = [], props = {}) => {
    return (
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          {label} {required && <span className="text-red-500">*</span>}
        </label>
        {typeField === 'select' ? (
          <select
            name={name}
            value={formData[name] || ''}
            onChange={handleChange}
            required={required}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
            {...props}
          >
            <option value="">Select option</option>
            {options.map((opt) => (
              <option key={opt} value={opt.toLowerCase()}>{opt}</option>
            ))}
          </select>
        ) : typeField === 'textarea' ? (
          <textarea
            name={name}
            value={formData[name] || ''}
            onChange={handleChange}
            required={required}
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            {...props}
          ></textarea>
        ) : typeField === 'rating' ? (
          <input
            type="number"
            min="1"
            max="5"
            name={name}
            value={formData[name] || ''}
            onChange={handleChange}
            required={required}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            {...props}
          />
        ) : (
          <input
            type={typeField}
            name={name}
            value={formData[name] || ''}
            onChange={handleChange}
            required={required}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            {...props}
          />
        )}
      </div>
    );
  };

  const renderFieldsByType = () => {
    switch (type) {
      case 'memory':
        return (
          <>
            {renderField('content', 'Memory Content', 'textarea', true, [], { minLength: 10, placeholder: 'Describe the memory...' })}
            {renderField('category', 'Category', 'select', true, ['Personal', 'Family', 'Place', 'Event'])}
          </>
        );
      case 'family':
        return (
          <>
            {renderField('name', 'Full Name', 'text', true)}
            {renderField('relationship', 'Relationship', 'select', true, ['Son', 'Daughter', 'Spouse', 'Sibling', 'Friend', 'Carer', 'Other'])}
            {renderField('phone', 'Phone Number', 'tel', false, [], { pattern: "^[6-9]\\d{9}$", placeholder: "e.g., 9876543210" })}
          </>
        );
      case 'habit':
        return (
          <>
            {renderField('description', 'Habit Description', 'text', true, [], { placeholder: 'e.g., Drinks tea reading newspaper' })}
            {renderField('time_of_day', 'Time of Day', 'select', true, ['Morning', 'Afternoon', 'Evening', 'Night'])}
            {renderField('frequency', 'Frequency', 'select', true, ['Daily', 'Weekly', 'Occasional'])}
          </>
        );
      case 'trigger':
        return (
          <>
            {renderField('trigger', 'The Trigger', 'text', true, [], { placeholder: 'e.g., Loud sudden noises' })}
            {renderField('effect', 'Emotional Effect', 'select', true, ['Anxiety', 'Sadness', 'Confusion', 'Agitation', 'Happiness'])}
            {renderField('response_strategy', 'How to Respond (Strategy)', 'textarea', false, [], { placeholder: 'e.g., Hold hand and play soft music' })}
          </>
        );
      case 'song':
        return (
          <>
            {renderField('title', 'Song Title', 'text', true)}
            {renderField('language', 'Language', 'select', true, ['Hindi', 'Marathi', 'Tamil', 'Telugu', 'Kannada', 'English', 'Other'])}
            {renderField('url', 'Song URL', 'url', false, [], { placeholder: 'e.g., YouTube or Spotify link' })}
          </>
        );
      case 'food':
        return (
          <>
            {renderField('food', 'Food Item', 'text', true)}
            {renderField('preference_level', 'Preference (1-5 Stars)', 'rating', true)}
            {renderField('notes', 'Notes', 'textarea', false, [], { placeholder: 'e.g., Needs to be pureed' })}
          </>
        );
      default:
        return <p className="text-red-500">Form type not defined.</p>;
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
      <h3 className="text-xl font-bold text-gray-900 mb-4 capitalize">
        {initialData ? 'Edit' : 'Add'} {type}
      </h3>
      
      {error && (
        <div className="bg-red-50 text-red-600 p-3 rounded-lg mb-4 text-sm border border-red-100">
          {error}
        </div>
      )}

      {renderFieldsByType()}

      <div className="mt-6 flex justify-end gap-3 border-t border-gray-100 pt-4">
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            disabled={loading}
            className="px-4 py-2 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-lg font-medium transition-colors"
          >
            Cancel
          </button>
        )}
        <button
          type="submit"
          disabled={loading}
          className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors flex items-center justify-center min-w-[120px] shadow-sm disabled:opacity-50"
        >
          {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Save'}
        </button>
      </div>
    </form>
  );
};

export default MemoryForm;
