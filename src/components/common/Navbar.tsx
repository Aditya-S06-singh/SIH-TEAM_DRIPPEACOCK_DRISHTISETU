import React from 'react';
import {
  Bell,
  Search,
  UserCheck,
  Building2,
  Shield,
  LogOut,
  ChevronDown,
  Lock
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useData } from '../../context/DataContext';
import type { UserRole } from '../../types';

interface NavbarProps {
  onSearch?: (term: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onSearch }) => {
  const { currentUser, currentRole, switchRole, signOut } = useAuth();
  const { alerts } = useData();
  const [roleMenuOpen, setRoleMenuOpen] = React.useState(false);

  const openAlertsCount = alerts.filter(a => a.status === 'open').length;

  const roleLabels: Record<UserRole, { title: string; badgeColor: string }> = {
    dosje_official: { title: 'DoSJE Official (HQ)', badgeColor: 'bg-indigo-100 text-indigo-800 border-indigo-200' },
    pmu_supervisor: { title: 'PMU Supervisor', badgeColor: 'bg-blue-100 text-blue-800 border-blue-200' },
    inspector: { title: 'PMU Field Inspector', badgeColor: 'bg-emerald-100 text-emerald-800 border-emerald-200' },
    institute_admin: { title: 'Institute / NGO Admin', badgeColor: 'bg-amber-100 text-amber-800 border-amber-200' },
    entry_operator: { title: 'Gate Entry Operator', badgeColor: 'bg-purple-100 text-purple-800 border-purple-200' },
  };

  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        
        {/* Brand & National Emblem Header */}
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded bg-gov-navy flex items-center justify-center text-white font-bold text-lg tracking-wider shadow-inner">
            DS
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-extrabold text-slate-900 tracking-tight text-lg">DrishtiSetu</span>
              <span className="text-[10px] uppercase font-bold tracking-widest bg-gov-light text-gov-blue px-2 py-0.5 rounded border border-gov-blue/20">
                DoSJE Portal
              </span>
            </div>
            <p className="text-[11px] text-slate-500 hidden sm:block">
              Centralized Real-Time Scheme Monitoring & AI Inspection Gateway
            </p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="hidden md:flex items-center flex-1 max-w-md mx-8">
          <div className="relative w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search institute, NGO, scheme, registration ID..."
              onChange={e => onSearch?.(e.target.value)}
              className="w-full bg-slate-100 hover:bg-slate-200/70 focus:bg-white text-sm text-slate-800 pl-10 pr-4 py-2 rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
            />
          </div>
        </div>

        {/* Right Action Icons & Persona Switcher */}
        <div className="flex items-center space-x-4">
          
          {/* Notification Bell with Badge */}
          <div className="relative">
            <button
              title="View Alerts"
              className="p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900 transition relative"
            >
              <Bell className="w-5 h-5" />
              {openAlertsCount > 0 && (
                <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-red-600 text-white text-[10px] font-bold flex items-center justify-center animate-bounce">
                  {openAlertsCount}
                </span>
              )}
            </button>
          </div>

          {/* Persona Role Switcher dropdown */}
          <div className="relative">
            <button
              onClick={() => setRoleMenuOpen(!roleMenuOpen)}
              className="flex items-center space-x-2 p-1.5 rounded-lg border border-slate-200 hover:border-slate-300 hover:bg-slate-50 transition"
            >
              <div className="w-8 h-8 rounded-full bg-slate-800 text-white flex items-center justify-center font-semibold text-xs">
                {currentUser.name.charAt(0)}
              </div>
              <div className="text-left hidden lg:block">
                <p className="text-xs font-semibold text-slate-800 leading-tight truncate max-w-[140px]">
                  {currentUser.name}
                </p>
                <span className={`inline-block text-[10px] font-medium px-1.5 py-0.2 rounded border ${roleLabels[currentRole].badgeColor}`}>
                  {roleLabels[currentRole].title}
                </span>
              </div>
              <ChevronDown className="w-4 h-4 text-slate-500" />
            </button>

            {/* Dropdown Menu */}
            {roleMenuOpen && (
              <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-xl border border-slate-200 py-2 z-50 animate-in fade-in slide-in-from-top-2 duration-150">
                <div className="px-3 py-2 border-b border-slate-100">
                  <p className="text-[11px] uppercase tracking-wider text-slate-400 font-bold">
                    Switch Demo Persona (RBAC)
                  </p>
                  <p className="text-xs text-slate-600 mt-0.5">
                    Select a role to preview role-specific permissions and navigation:
                  </p>
                </div>

                <div className="py-1">
                  {(Object.keys(roleLabels) as UserRole[]).map(role => (
                    <button
                      key={role}
                      onClick={() => {
                        switchRole(role);
                        setRoleMenuOpen(false);
                      }}
                      className={`w-full text-left px-3 py-2 flex items-center justify-between hover:bg-slate-50 text-xs transition ${
                        currentRole === role ? 'bg-blue-50/70 font-semibold text-blue-900' : 'text-slate-700'
                      }`}
                    >
                      <span>{roleLabels[role].title}</span>
                      {currentRole === role && (
                        <span className="w-2 h-2 rounded-full bg-blue-600" />
                      )}
                    </button>
                  ))}
                </div>

                <div className="px-3 py-2 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                  <span className="flex items-center">
                    <Lock className="w-3.5 h-3.5 mr-1 text-slate-400" /> DPDP Compliant
                  </span>
                  <button
                    onClick={() => signOut()}
                    className="text-red-600 hover:text-red-700 font-medium flex items-center"
                  >
                    <LogOut className="w-3.5 h-3.5 mr-1" /> Reset
                  </button>
                </div>
              </div>
            )}
          </div>

        </div>

      </div>
    </header>
  );
};
