import React, { useState } from 'react';
import { SandboxBanner } from './components/common/SandboxBanner';
import { Navbar } from './components/common/Navbar';
import { Sidebar, type TabType } from './components/common/Sidebar';
import { DashboardOverview } from './components/dashboard/DashboardOverview';
import { InstituteList } from './components/institutes/InstituteList';
import { InstituteDetails } from './components/institutes/InstituteDetails';
import { CctvMonitor } from './components/cctv/CctvMonitor';
import { GateAttendance } from './components/gate/GateAttendance';
import { AlertsCenter } from './components/alerts/AlertsCenter';
import { InspectionsHub } from './components/inspections/InspectionsHub';
import { AnalyticsCenter } from './components/analytics/AnalyticsCenter';
import { RandomVcModal } from './components/vc/RandomVcModal';
import { useData } from './context/DataContext';
import { useAuth } from './context/AuthContext';
import type { Institute } from './types';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const { institutes, isLiveFirebase, activeVc, setActiveVc, triggerRandomVc } = useData();
  const { currentRole } = useAuth();
  const [selectedInstitute, setSelectedInstitute] = useState<Institute | null>(null);

  // Auto-switch to gate mode if logged in as Entry Operator
  React.useEffect(() => {
    if (currentRole === 'entry_operator') {
      setActiveTab('attendance');
    }
  }, [currentRole]);

  const handleSelectInstitute = (inst: Institute) => {
    setSelectedInstitute(inst);
    setActiveTab('institutes');
  };

  const handleLaunchVc = async (instId: string) => {
    const vc = await triggerRandomVc(instId);
    setActiveVc(vc);
  };

  const handleDispatchInspection = (instId: string) => {
    setActiveTab('inspections');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans text-slate-900 selection:bg-blue-100 selection:text-blue-900">
      
      {/* Top Sandbox Notice & Firebase Connectivity State */}
      <SandboxBanner isLiveFirebase={isLiveFirebase} />

      {/* Main Government Portal Header */}
      <Navbar onSearch={(term) => console.log('Global search:', term)} />

      {/* Portal Workspace Body (Sidebar + Content Workspace) */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* Navigation Sidebar */}
        <Sidebar activeTab={activeTab} setActiveTab={(tab) => {
          setActiveTab(tab);
          if (tab !== 'institutes') setSelectedInstitute(null);
        }} />

        {/* Dynamic Workspace Container */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full">
          
          {activeTab === 'overview' && (
            <DashboardOverview
              onSelectInstitute={handleSelectInstitute}
              onNavigateTab={(tab) => setActiveTab(tab)}
            />
          )}

          {activeTab === 'institutes' && (
            selectedInstitute ? (
              <InstituteDetails
                institute={selectedInstitute}
                onBack={() => setSelectedInstitute(null)}
                onLaunchVc={handleLaunchVc}
                onNavigateTab={(tab) => setActiveTab(tab)}
              />
            ) : (
              <InstituteList onSelectInstitute={setSelectedInstitute} />
            )
          )}

          {activeTab === 'attendance' && (
            <GateAttendance />
          )}

          {activeTab === 'cctv' && (
            <CctvMonitor
              onLaunchVc={handleLaunchVc}
              onDispatchInspection={handleDispatchInspection}
            />
          )}

          {activeTab === 'alerts' && (
            <AlertsCenter
              onLaunchVc={handleLaunchVc}
              onDispatchInspection={handleDispatchInspection}
            />
          )}

          {activeTab === 'vc' && (
            <div className="space-y-4">
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
                <h1 className="text-xl font-black text-slate-900">Random Video Verification Engine</h1>
                <p className="text-xs text-slate-500 mt-1">
                  Automated random video call scheduler for live unannounced project audit checks.
                </p>
                <div className="mt-4 flex gap-3">
                  <button
                    onClick={() => handleLaunchVc(institutes[1]?.instituteId || institutes[0]?.instituteId)}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow transition"
                  >
                    Trigger Routine Random Audit Call
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'inspections' && (
            <InspectionsHub />
          )}

          {activeTab === 'analytics' && (
            <AnalyticsCenter />
          )}

          {activeTab === 'settings' && (
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm max-w-2xl text-xs space-y-4">
              <h2 className="text-sm font-bold text-slate-900">System Configuration & Thresholds</h2>
              <div className="space-y-3 text-slate-700">
                <div className="flex justify-between py-2 border-b border-slate-100">
                  <span>CCTV Heartbeat Timeout Alert</span>
                  <span className="font-semibold text-slate-900">300 seconds</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-100">
                  <span>Attendance vs Occupancy Discrepancy Threshold</span>
                  <span className="font-semibold text-slate-900">&gt; 25% Variance</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-100">
                  <span>Random VC Daily Sample Target</span>
                  <span className="font-semibold text-slate-900">10% of Active Sites</span>
                </div>
                <div className="flex justify-between py-2 border-b border-slate-100">
                  <span>Data Protection Compliance Mode</span>
                  <span className="font-semibold text-emerald-700 font-bold">DPDP Act (Strict Masking)</span>
                </div>
              </div>
            </div>
          )}

        </main>
      </div>

      {/* Random VC Verification In-Call Modal */}
      {activeVc && (
        <RandomVcModal
          vc={activeVc}
          onClose={() => setActiveVc(null)}
        />
      )}

    </div>
  );
};

export default App;
