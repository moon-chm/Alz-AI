import React from 'react';
import { Edit2, Trash2 } from 'lucide-react';
import { format } from 'date-fns';

const MemoryCard = ({ memory, onEdit, onDelete }) => {
  const getCategoryTheme = (category) => {
    switch (category?.toLowerCase()) {
      case 'personal': return 'bg-blue-100 text-blue-700';
      case 'family': return 'bg-purple-100 text-purple-700';
      case 'place': return 'bg-green-100 text-green-700';
      case 'event': return 'bg-orange-100 text-orange-700';
      case 'habit': return 'bg-teal-100 text-teal-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const handleDelete = () => {
    onDelete(memory.id);
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 flex flex-col h-full hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start mb-3">
        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getCategoryTheme(memory.category)}`}>
          {memory.category ? memory.category.charAt(0).toUpperCase() + memory.category.slice(1) : 'General'}
        </span>
        <span className="text-xs text-gray-400 font-medium">
          {memory.date_added ? format(new Date(memory.date_added), 'MMM d, yyyy') : 'Unknown date'}
        </span>
      </div>

      <div className="flex-1 mb-4">
        <p className="text-gray-800 line-clamp-3 leading-relaxed">
          {memory.content}
        </p>
      </div>

      <div className="flex items-center justify-between mt-auto pt-3 border-t border-gray-50">
        <span className="text-xs text-gray-500 font-medium">
          Added by <span className="text-gray-700">{memory.added_by || 'Unknown'}</span>
        </span>
        <div className="flex gap-2">
          <button 
            onClick={() => onEdit(memory)}
            className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
          >
            <Edit2 className="w-4 h-4" />
          </button>
          <button 
            onClick={handleDelete}
            className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default MemoryCard;
