import React, { useState } from 'react';
import {
  Building2,
  AlertTriangle,
  Users,
  Video,
  ClipboardCheck,
  PhoneCall,
  Calendar,
  CheckCircle2,
  FileText,
  Clock,
  ArrowRight,
  ShieldAlert
} from 'lucide-react';
import type { Institute } from '../../types';
import { useData } from '../../context/DataContext';

interface InstituteDetailsProps {
  institute: Institute;
  onBack: () => void;
  onLaunchVc: (instId: string) => void;
  onNavigateTab: (tab: any) => void;
}

export const InstituteDetails: React.FC<InstituteDetailsProps> = ({
  institute,
  onBack,
  onLaunchVc,
  onNavigateTab,
}) => {
  const { alerts, edgeDevices, attendanceEvents, inspections } = useData();
  const [activeTab, setActiveTab] = useState<'overview' | 'cctv' | 'attendance' | 'inspections' | 'audit'>('overview');

  const siteAlerts = alerts.filter(a => a.instituteId === institute.instituteId);
  const siteDevices = edgeDevices.filter(d => d.instituteId === institute.instituteId);
  const siteEvents = attendanceEvents.filter(e => e.instituteId === institute.instituteId);
  const siteInspections = inspections.filter(i => i.instituteId === institute.instituteId);

  const riskBadgeColor =
    institute.riskLevel === 'red'
      ? 'bg-red-100 text-red-800 border-red-200'
      : institute.riskLevel === 'amber'
      ? 'bg-amber-100 text-amber-800 border-amber-200'
      : 'bg-emerald-100 text-emerald-800 border-emerald-200';

  return (
    <div className="space-y-6">
      
      {/* Back Button & Command Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className="text-xs font-semibold text-slate-600 hover:text-slate-900 flex items-center bg-white px-3 py-1.5 rounded-lg border border-slate-200 shadow-sm"
        >
          ← Back to All Institutes
        </button>

        <div className="flex items-center space-x-2">
          <button
            onClick={() => onLaunchVc(institute.instituteId)}
            className="px-3 py-1.5 text-xs font-semibold bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition shadow-sm flex items-center"
          >
            <PhoneCall className="w-3.5 h-3.5 mr-1.5" />
            Initiate Random VC Audit
          </button>
          <button
            onClick={() => onNavigateTab('inspections')}
            className="px-3 py-1.5 text-xs font-semibold bg-slate-900 hover:bg-slate-800 text-white rounded-lg transition flex items-center"
          >
            <ClipboardCheck className="w-3.5 h-3.5 mr-1.5" />
            Dispatch Surprise Inspection
          </button>
        </div>
      </div>

      {/* Main Institute Identity Card */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-3">
              <h1 className="text-xl font-black text-slate-900">{institute.name}</h1>
              <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold uppercase border ${riskBadgeColor}`}>
                {institute.riskLevel} Risk • {institute.riskScore}/100
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Scheme: <span className="font-semibold text-slate-700">{institute.scheme}</span> • Managed by: <span className="font-semibold text-slate-700">{institute.ngoName}</span>
            </p>
            <p className="text-xs text-slate-500">
              Registration ID: <span className="font-mono text-slate-700">{institute.registrationId}</span> • Location: <span className="text-slate-700">{institute.address}</span>
            </p>
          </div>

          {/* Project Incharge Contact Block */}
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-3 text-xs min-w-[240px]">
            <p className="text-[10px] uppercase font-bold text-slate-400">Project Incharge</p>
            <p className="font-bold text-slate-800 mt-0.5">{institute.projectInchargeName || 'Project Head'}</p>
            <p className="text-slate-600">{institute.contactNumber || '+91 98000 00000'}</p>
          </div>
        </div>

        {/* 3-Way Cross-Check Reconciliation Bar */}
        <div className="mt-6 p-4 rounded-xl bg-gradient-to-r from-slate-50 to-blue-50/40 border border-slate-200">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-800 uppercase tracking-wider">
              3-Way Attendance vs Occupancy Cross-Check
            </span>
            <span className="text-[11px] text-slate-500">Real-Time Continuous Reconciliation</span>
          </div>

          <div className="grid grid-cols-3 gap-4 text-center">
            <div className="bg-white p-3 rounded-lg border border-slate-200 shadow-sm">
              <p className="text-[10px] text-slate-400 font-bold uppercase">Expected Sanction</p>
              <p className="text-2xl font-black text-slate-700">{institute.expectedAttendance}</p>
              <span className="text-[10px] text-slate-500">Approved Beneficiaries</span>
            </div>

            <div className="bg-white p-3 rounded-lg border border-slate-200 shadow-sm">
              <p className="text-[10px] text-blue-600 font-bold uppercase">Verified Gate Attendance</p>
              <p className="text-2xl font-black text-blue-700">{institute.verifiedAttendance || 0}</p>
              <span className="text-[10px] text-emerald-600 font-medium">Multi-Factor Biometric Log</span>
            </div>

            <div className="bg-white p-3 rounded-lg border border-slate-200 shadow-sm">
              <p className="text-[10px] text-indigo-600 font-bold uppercase">CCTV Visible Occupancy</p>
              <p className="text-2xl font-black text-indigo-700">{institute.cctvOccupancy || 0}</p>
              <span className="text-[10px] text-slate-500">Edge AI Camera Headcount</span>
            </div>
          </div>

          {/* Variance Warning if mismatch */}
          {Math.abs((institute.verifiedAttendance || 0) - (institute.cctvOccupancy || 0)) > 10 && (
            <div className="mt-3 p-2.5 rounded-lg bg-red-50 border border-red-200 text-xs text-red-800 flex items-center">
              <ShieldAlert className="w-4 h-4 mr-2 shrink-0 text-red-600" />
              <span>
                <strong>Attendance Mismatch Anomaly:</strong> Difference of {Math.abs((institute.verifiedAttendance || 0) - (institute.cctvOccupancy || 0))} individuals between gate scans and camera visible density.
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Tabs Navigation */}
      <div className="flex border-b border-slate-200 space-x-6 text-xs font-semibold">
        {(['overview', 'cctv', 'attendance', 'inspections', 'audit'] as const).map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`pb-3 capitalize transition-all border-b-2 ${
              activeTab === tab
                ? 'border-blue-600 text-blue-600 font-bold'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            {tab === 'cctv' ? 'Live CCTV Feeds' : tab === 'audit' ? 'Audit Trail' : tab}
          </button>
        ))}
      </div>

      {/* Tab Contents */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="text-sm font-bold text-slate-900 mb-3">Site Risk Assessment Breakdown</h3>
            <p className="text-xs text-slate-600 mb-4">{institute.riskExplanation}</p>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Overall Compliance Index</span>
                <span className="font-bold text-slate-800">{institute.complianceScore}%</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Last On-Site Inspection</span>
                <span className="font-bold text-slate-800">{institute.lastInspectionAt ? new Date(institute.lastInspectionAt).toLocaleDateString() : 'None'}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Last Inspection Score</span>
                <span className="font-bold text-slate-800">{institute.lastInspectionScore || 0} / 100</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">Last Random Video Call</span>
                <span className="font-bold text-slate-800 uppercase">{institute.lastVcStatus || 'Pending'}</span>
              </div>
            </div>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="text-sm font-bold text-slate-900 mb-3">Active Alerts for this Site</h3>
            {siteAlerts.length === 0 ? (
              <p className="text-xs text-slate-400 py-6 text-center">No active alerts for this site.</p>
            ) : (
              <div className="space-y-2.5">
                {siteAlerts.map(alert => (
                  <div key={alert.alertId} className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs">
                    <span className="font-bold text-slate-800">{alert.title}</span>
                    <p className="text-slate-600 text-[11px] mt-0.5">{alert.explanation}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {activeTab === 'cctv' && (
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <h3 className="text-sm font-bold text-slate-900 mb-4">Installed Edge Devices & Cameras</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {siteDevices.map(dev => (
              <div key={dev.deviceId} className="p-4 rounded-xl border border-slate-200 bg-slate-50 text-xs">
                <div className="flex justify-between items-center mb-2">
                  <span className="font-bold text-slate-800">{dev.deviceName}</span>
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                    dev.status === 'online' ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {dev.status}
                  </span>
                </div>
                <p className="text-slate-500">Hardware: {dev.hardwareLabel}</p>
                <p className="text-slate-500">Location: {dev.locationLabel}</p>
                <p className="text-slate-500">Live Occupancy: {dev.currentPersonCount} persons</p>
                <p className="text-slate-400 text-[10px] mt-2">Last Heartbeat: {new Date(dev.lastHeartbeatAt).toLocaleTimeString()}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'attendance' && (
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-slate-200 flex justify-between items-center">
            <h3 className="text-sm font-bold text-slate-900">Recent Biometric Attendance Logs</h3>
            <span className="text-xs text-slate-500">{siteEvents.length} events logged</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 border-b border-slate-200">
                <tr>
                  <th className="p-3">Opaque Token</th>
                  <th className="p-3">Masked ID</th>
                  <th className="p-3">Role</th>
                  <th className="p-3">Verification</th>
                  <th className="p-3">Consent</th>
                  <th className="p-3">Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {siteEvents.slice(0, 10).map(evt => (
                  <tr key={evt.eventId} className="hover:bg-slate-50/80">
                    <td className="p-3 font-mono text-slate-600">{evt.personToken}</td>
                    <td className="p-3 font-mono font-semibold text-slate-800">{evt.governmentIdReferenceMasked}</td>
                    <td className="p-3 capitalize">{evt.role}</td>
                    <td className="p-3">
                      <span className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded font-semibold text-[10px]">
                        {evt.verificationStatus}
                      </span>
                    </td>
                    <td className="p-3 text-slate-600">{evt.consentStatus ? 'Recorded' : 'Denied'}</td>
                    <td className="p-3 text-slate-400">{new Date(evt.occurredAt).toLocaleTimeString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === 'inspections' && (
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <h3 className="text-sm font-bold text-slate-900 mb-3">Field Inspection Audit History</h3>
          {siteInspections.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">No past inspection reports on record for this site.</p>
          ) : (
            <div className="space-y-4">
              {siteInspections.map(rep => (
                <div key={rep.reportId} className="p-4 rounded-xl border border-slate-200 bg-slate-50 text-xs">
                  <div className="flex justify-between items-center mb-2">
                    <span className="font-bold text-slate-800">Inspector: {rep.inspectorName}</span>
                    <span className="font-semibold text-blue-700">Checklist Score: {rep.checklistScore}/100</span>
                  </div>
                  <p className="text-slate-500">Date: {new Date(rep.submittedAt).toLocaleDateString()} • Geofence: {rep.gpsValidationStatus}</p>
                  <div className="mt-2 space-y-1.5">
                    {rep.findings.map(f => (
                      <div key={f.findingId} className="p-2 bg-white rounded border border-slate-200">
                        <span className="font-bold text-red-700 uppercase text-[10px] mr-2">[{f.severity}]</span>
                        <span className="text-slate-700">{f.description}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeTab === 'audit' && (
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm text-xs text-slate-600">
          <h3 className="text-sm font-bold text-slate-900 mb-3">Immutable System Audit Log</h3>
          <p className="text-slate-500 mb-4">Every configuration edit, inspection submission, and verification check is cryptographically hashed.</p>
          <div className="space-y-2 font-mono text-[11px]">
            <div className="p-2 bg-slate-50 rounded border border-slate-200">
              [2026-09-03 15:45:00] SYSTEM: Automated risk score elevated to {institute.riskScore} following CCTV discrepancy trigger.
            </div>
            <div className="p-2 bg-slate-50 rounded border border-slate-200">
              [2026-09-02 11:00:00] VIDEO_AUDIT: Random VC requested by PMU Central Engine. Result: {institute.lastVcStatus}.
            </div>
            <div className="p-2 bg-slate-50 rounded border border-slate-200">
              [2026-08-20 12:15:00] INSPECTION: Report rep_del_01 signed with SHA256 digest and geofence lock.
            </div>
          </div>
        </div>
      )}

    </div>
  );
};
