import React from 'react';
import Layout from '../../components/layout/Layout';
import { LifeBuoy, Mail, Phone, Book, MessageSquare, ExternalLink, ShieldCheck } from 'lucide-react';

const Support = () => {
  const supportCategories = [
    {
      title: 'Contact Medical Officer',
      description: 'Reach out directly to the primary doctor assigned to the patient.',
      icon: <Phone className="w-6 h-6 text-emerald-500" />,
      action: 'Call Now',
      color: 'bg-emerald-50 border-emerald-100',
    },
    {
      title: 'Technical Support',
      description: 'Having issues with the neural link or wearable sync? Let us know.',
      icon: <Mail className="w-6 h-6 text-blue-500" />,
      action: 'Submit Ticket',
      color: 'bg-blue-50 border-blue-100',
    },
    {
      title: 'Knowledge Base',
      description: 'Read the manual on how to interpret vitals and respond to alerts.',
      icon: <Book className="w-6 h-6 text-amber-500" />,
      action: 'Read Articles',
      color: 'bg-amber-50 border-amber-100',
    },
    {
      title: 'Community Forum',
      description: 'Connect with other primary caretakers in the SAATHI network.',
      icon: <MessageSquare className="w-6 h-6 text-purple-500" />,
      action: 'Join Forum',
      color: 'bg-purple-50 border-purple-100',
    }
  ];

  return (
    <Layout title="Help & Support">
      <div className="max-w-[1200px] mx-auto pb-20 px-4 animate-slide-up">
        {/* Header */}
        <header className="mb-10 text-center space-y-4">
           <div className="w-20 h-20 bg-cyan-50 rounded-[2rem] flex items-center justify-center mx-auto mb-6 shadow-inner border border-cyan-100">
              <LifeBuoy className="w-10 h-10 text-cyan-500" />
           </div>
           <h1 className="text-4xl font-black text-slate-900 tracking-tight">How can we assist you?</h1>
           <p className="text-slate-500 font-medium max-w-lg mx-auto">
             Whether you need emergency medical contact details or technical help with the command center, we've got you covered.
           </p>
        </header>

        {/* Support Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
          {supportCategories.map((category, idx) => (
             <div key={idx} className={`p-8 rounded-[2rem] border transition-all hover:scale-[1.02] cursor-pointer group flex flex-col h-full bg-white shadow-xl shadow-slate-200/20`}>
                <div className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-6 shadow-sm ${category.color}`}>
                   {category.icon}
                </div>
                <h2 className="text-xl font-black text-slate-900 mb-2">{category.title}</h2>
                <p className="text-sm text-slate-500 font-medium mb-8 flex-1">{category.description}</p>
                <div className="flex items-center gap-2 text-sm font-bold text-slate-900 hover:text-cyan-600 transition-colors">
                   {category.action} <ExternalLink className="w-4 h-4" />
                </div>
             </div>
          ))}
        </div>

        {/* Secure Message */}
        <div className="bg-slate-900 text-white p-8 rounded-[2rem] shadow-2xl relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-6">
           <div className="absolute top-0 right-0 w-64 h-64 bg-cyan-500/20 blur-[100px] -mr-32 -mt-32 rounded-full pointer-events-none"></div>
           <div className="flex items-center gap-4 relative z-10">
              <div className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center backdrop-blur-sm border border-white/20">
                 <ShieldCheck className="w-6 h-6 text-cyan-400" />
              </div>
              <div>
                 <h3 className="text-lg font-black tracking-tight">Enterprise-Grade Security Active</h3>
                 <p className="text-sm text-slate-400 font-medium mt-1">All support communications are end-to-end encrypted under HIPAA guidelines.</p>
              </div>
           </div>
        </div>
      </div>
    </Layout>
  );
};

export default Support;
