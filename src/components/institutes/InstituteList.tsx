import React, { useState } from 'react';
import {
  Building2,
  Search,
  Filter,
  MapPin,
  ExternalLink,
  ShieldCheck,
  AlertTriangle
} from 'lucide-react';
import type { Institute } from '../../types';
import { useData } from '../../context/DataContext';

interface InstituteListProps {
  onSelectInstitute: (inst: Institute) => void;
}

export const InstituteList: React.FC<InstituteListProps> = ({ onSelectInstitute }) => {
  const { institutes } = useData();
  const [searchTerm, setSearchTerm] = useState('');
  const [schemeFilter, setSchemeFilter] = useState('all');
  const [riskFilter, setRiskFilter] = useState('all');

  const schemes = Array.from(new Set(institutes.map(i => i.scheme)));

  const filtered = institutes.filter(inst => {
    const matchesSearch =
      inst.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inst.ngoName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inst.state.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inst.registrationId.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesScheme = schemeFilter === 'all' || inst.scheme === schemeFilter;
    const matchesRisk = riskFilter === 'all' || inst.riskLevel === riskFilter;

    return matchesSearch && matchesScheme && matchesRisk;
  });

  return (
    <div className="space-y-5">
      
      {/* List Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h1 className="text-xl font-black text-slate-900">Institutes & Project Sites</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Directory of DoSJE residential homes, de-addiction centers, and PM-DAKSH skill clusters.
          </p>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-2">
          <input
            type="text"
            placeholder="Search institute, state, NGO..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />

          <select
            value={schemeFilter}
            onChange={e => setSchemeFilter(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none"
          >
            <option value="all">All Schemes</option>
            {schemes.map(s => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>

          <select
            value={riskFilter}
            onChange={e => setRiskFilter(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none"
          >
            <option value="all">All Risk Levels</option>
            <option value="green">Green (0 - 29)</option>
            <option value="amber">Amber (30 - 59)</option>
            <option value="red">Red (60 - 100)</option>
          </select>
        </div>
      </div>

      {/* Grid of Institute Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(inst => {
          const riskColor =
            inst.riskLevel === 'red'
              ? 'bg-red-100 text-red-800 border-red-200'
              : inst.riskLevel === 'amber'
              ? 'bg-amber-100 text-amber-800 border-amber-200'
              : 'bg-emerald-100 text-emerald-800 border-emerald-200';

          return (
            <div
              key={inst.instituteId}
              onClick={() => onSelectInstitute(inst)}
              className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:border-blue-400 hover:shadow-md transition cursor-pointer flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-2 mb-2">
                  <span className="text-[10px] font-bold text-gov-blue uppercase bg-blue-50 px-2 py-0.5 rounded border border-blue-200">
                    {inst.scheme}
                  </span>
                  <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full border ${riskColor}`}>
                    {inst.riskLevel} • {inst.riskScore}
                  </span>
                </div>

                <h3 className="text-sm font-bold text-slate-900 leading-snug">{inst.name}</h3>
                <p className="text-xs text-slate-500 mt-1">{inst.ngoName}</p>

                <div className="flex items-center text-slate-400 text-xs mt-3">
                  <MapPin className="w-3.5 h-3.5 mr-1 text-slate-400 shrink-0" />
                  <span className="truncate">{inst.district}, {inst.state}</span>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <div>
                  <span className="text-slate-400 text-[10px] block">Verified / CCTV</span>
                  <span className="font-bold text-slate-800">{inst.verifiedAttendance || 0} / {inst.cctvOccupancy || 0}</span>
                </div>
                <button
                  className="px-2.5 py-1 text-blue-600 bg-blue-50 hover:bg-blue-100 rounded text-xs font-semibold flex items-center"
                >
                  Open Hub <ExternalLink className="w-3 h-3 ml-1" />
                </button>
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
};
