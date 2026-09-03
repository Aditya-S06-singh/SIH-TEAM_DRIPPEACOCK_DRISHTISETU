import React from 'react';
import {
  LayoutDashboard,
  Building2,
  ScanFace,
  Video,
  AlertOctagon,
  PhoneCall,
  ClipboardCheck,
  BarChart3,
  Settings,
  Tablet
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useData } from '../../context/DataContext';

export type TabType =
  | 'overview'
  | 'institutes'
  | 'attendance'
  | 'cctv'
  | 'alerts'
  | 'vc'
  | 'inspections'
  | 'analytics'
  | 'settings';

interface SidebarProps {
  activeTab: TabType;
  setActiveTab: (tab: TabType) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const { currentRole } = useAuth();
  const { alerts } = useData();

  const openAlertsCount = alerts.filter(a => a.status === 'open').length;

  // Role-based visibility logic
  const navItems = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard, roles: ['dosje_official', 'pmu_supervisor', 'inspector', 'institute_admin'] },
    { id: 'institutes', label: 'Institutes & Projects', icon: Building2, roles: ['dosje_official', 'pmu_supervisor', 'inspector', 'institute_admin'] },
    { id: 'attendance', label: 'Gate Attendance', icon: ScanFace, roles: ['dosje_official', 'pmu_supervisor', 'institute_admin', 'entry_operator'], badge: currentRole === 'entry_operator' ? 'Gate Mode' : undefined },
    { id: 'cctv', label: 'CCTV & Edge Devices', icon: Video, roles: ['dosje_official', 'pmu_supervisor', 'inspector', 'institute_admin'] },
    { id: 'alerts', label: 'Alerts & Anomalies', icon: AlertOctagon, roles: ['dosje_official', 'pmu_supervisor', 'inspector', 'institute_admin'], count: openAlertsCount },
    { id: 'vc', label: 'Random Video Call', icon: PhoneCall, roles: ['dosje_official', 'pmu_supervisor', 'institute_admin'] },
    { id: 'inspections', label: 'Inspections & Field', icon: ClipboardCheck, roles: ['dosje_official', 'pmu_supervisor', 'inspector', 'institute_admin'] },
    { id: 'analytics', label: 'Reports & Analytics', icon: BarChart3, roles: ['dosje_official', 'pmu_supervisor'] },
    { id: 'settings', label: 'System Settings', icon: Settings, roles: ['dosje_official', 'pmu_supervisor'] },
  ];

  const visibleItems = navItems.filter(item => item.roles.includes(currentRole));

  return (
    <aside className="w-64 bg-slate-900 text-slate-300 flex flex-col justify-between shrink-0 min-h-[calc(100vh-5.5rem)] border-r border-slate-800">
      <div className="py-4 px-3">
        <div className="px-3 mb-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">
          Operation Hub
        </div>

        <nav className="space-y-1">
          {visibleItems.map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;

            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as TabType)}
                className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-xs font-medium transition-all ${
                  isActive
                    ? 'bg-blue-600 text-white font-semibold shadow-sm'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <div className="flex items-center space-x-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>

                {item.count !== undefined && item.count > 0 && (
                  <span className={`px-1.5 py-0.5 text-[10px] font-bold rounded-full ${
                    isActive ? 'bg-white text-blue-700' : 'bg-red-600 text-white'
                  }`}>
                    {item.count}
                  </span>
                )}

                {item.badge && (
                  <span className="px-1.5 py-0.5 text-[9px] font-bold tracking-wider uppercase rounded bg-purple-500/30 text-purple-200 border border-purple-400/30">
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Edge Telemetry Mini Status Card in Sidebar */}
      <div className="p-3 m-3 rounded-xl bg-slate-800/80 border border-slate-700/60 text-xs">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-slate-300 font-medium">Edge Nodes (RPi)</span>
          <span className="flex items-center text-emerald-400 text-[11px]">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse mr-1" />
            3/4 Live
          </span>
        </div>
        <p className="text-[11px] text-slate-400 leading-tight">
          Heartbeats reporting via Zero 2 W modules with local inference.
        </p>
      </div>
    </aside>
  );
};
