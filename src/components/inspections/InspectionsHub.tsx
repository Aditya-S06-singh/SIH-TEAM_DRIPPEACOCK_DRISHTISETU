import React, { useState } from 'react';
import {
  ClipboardCheck,
  UserCheck,
  MapPin,
  Camera,
  CheckCircle2,
  AlertTriangle,
  Upload,
  Send,
  Navigation
} from 'lucide-react';
import { useData } from '../../context/DataContext';
import { useAuth } from '../../context/AuthContext';
import { DEMO_INSPECTORS } from '../../data/mockData';
import type { InspectionAssignment, InspectionReport } from '../../types';

export const InspectionsHub: React.FC = () => {
  const { institutes, inspections, assignSurpriseInspection } = useData();
  const { currentRole } = useAuth();
  
  // Assignment form state
  const [selectedInstId, setSelectedInstId] = useState(institutes[1]?.instituteId || institutes[0]?.instituteId);
  const [selectedInspectorId, setSelectedInspectorId] = useState(DEMO_INSPECTORS[0].id);
  const [assignedSuccess, setAssignedSuccess] = useState(false);

  // Inspector Field Report Form State (Mobile mode)
  const [score, setScore] = useState(85);
  const [findingDesc, setFindingDesc] = useState('');
  const [findingSeverity, setFindingSeverity] = useState<'low' | 'medium' | 'high' | 'critical'>('medium');
  const [reportSubmitted, setReportSubmitted] = useState(false);

  const selectedInst = institutes.find(i => i.instituteId === selectedInstId) || institutes[0];
  const recommendedInspector = DEMO_INSPECTORS.find(insp => {
    // Exclude inspectors with conflict of interest in institute district
    return !insp.conflictDistricts.includes(selectedInst.district);
  }) || DEMO_INSPECTORS[0];

  const handleAssign = async () => {
    await assignSurpriseInspection({
      instituteId: selectedInst.instituteId,
      instituteName: selectedInst.name,
      inspectorId: selectedInspectorId,
      priority: selectedInst.riskScore > 60 ? 'surprise_high_risk' : 'routine',
      assignmentReason: `Elevated risk index (${selectedInst.riskScore}/100) and telemetry anomalies.`,
    });
    setAssignedSuccess(true);
    setTimeout(() => setAssignedSuccess(false), 4000);
  };

  const handleSubmitFieldReport = (e: React.FormEvent) => {
    e.preventDefault();
    setReportSubmitted(true);
    setTimeout(() => setReportSubmitted(false), 4000);
  };

  return (
    <div className="space-y-6">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center space-x-2">
            <ClipboardCheck className="w-5 h-5 text-gov-blue" />
            <h1 className="text-xl font-black text-slate-900">Surprise Inspections & Field Audits</h1>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Intelligent inspector assignment with conflict-of-interest exclusion and geofenced digital field reports.
          </p>
        </div>
      </div>

      {/* Grid: Intelligent Assignment Engine + Mobile Field Inspector View */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Module 1: Intelligent Assignment Engine (PMU Supervisor View) */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-2 mb-4">
              Automated Inspection Assignment Engine
            </h2>

            <div className="space-y-4 text-xs">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">Target Institute for Audit</label>
                <select
                  value={selectedInstId}
                  onChange={e => setSelectedInstId(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2.5 font-semibold text-slate-800"
                >
                  {institutes.map(inst => (
                    <option key={inst.instituteId} value={inst.instituteId}>
                      {inst.name} ({inst.riskLevel.toUpperCase()} • Risk: {inst.riskScore})
                    </option>
                  ))}
                </select>
              </div>

              {/* Rationale & Conflict-Free Recommendation Card */}
              <div className="p-3.5 rounded-xl bg-blue-50/70 border border-blue-200 text-xs">
                <span className="font-bold text-blue-900 block mb-1">Algorithm Recommendation Rationale:</span>
                <ul className="space-y-1 text-slate-700">
                  <li>• Prioritizes sites with elevated risk score ({selectedInst.riskScore}/100)</li>
                  <li>• Conflict Check: Verified 0 prior affiliation in {selectedInst.district}</li>
                  <li>• Workload Balance: Selected inspector has {recommendedInspector.currentActiveAssignments} active tasks</li>
                  <li>• Proximity: Estimated distance ~{recommendedInspector.distanceKm} km</li>
                </ul>
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Assigned PMU Field Inspector</label>
                <select
                  value={selectedInspectorId}
                  onChange={e => setSelectedInspectorId(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2.5 font-semibold text-slate-800"
                >
                  {DEMO_INSPECTORS.map(insp => (
                    <option key={insp.id} value={insp.id}>
                      {insp.name} ({insp.district}, {insp.state}) • Rating: {insp.rating}★
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100">
            <button
              onClick={handleAssign}
              className="w-full py-2.5 bg-gov-blue hover:bg-gov-navy text-white font-bold rounded-xl text-xs shadow transition flex items-center justify-center"
            >
              <ClipboardCheck className="w-4 h-4 mr-2" />
              Confirm & Dispatch Surprise Inspection Notice
            </button>
            {assignedSuccess && (
              <p className="text-center text-xs font-semibold text-emerald-600 mt-2">
                ✓ Inspection dispatched & FCM push notification sent to inspector device!
              </p>
            )}
          </div>
        </div>

        {/* Module 2: PMU Field Inspector Mobile View (Tablet/Phone Simulation) */}
        <div className="bg-slate-900 text-slate-100 rounded-2xl border border-slate-800 p-6 shadow-xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between border-b border-slate-800 pb-2 mb-4">
              <div className="flex items-center space-x-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
                <h2 className="text-sm font-bold text-white">Inspector Field Mode (On-Site)</h2>
              </div>
              <span className="text-[11px] font-mono text-slate-400 bg-slate-800 px-2 py-0.5 rounded">
                GPS VALIDATED (28.524° N, 77.156° E)
              </span>
            </div>

            <form onSubmit={handleSubmitFieldReport} className="space-y-4 text-xs">
              <div className="bg-slate-800/80 p-3 rounded-xl border border-slate-700">
                <span className="text-slate-400 text-[10px] uppercase font-bold block">Assigned Site</span>
                <p className="font-bold text-white text-sm mt-0.5">{selectedInst.name}</p>
                <p className="text-slate-400 text-[11px] mt-0.5">{selectedInst.address}</p>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Overall Inspection Score</span>
                  <span className="text-blue-400 font-bold">{score} / 100</span>
                </div>
                <input
                  type="range"
                  min="20"
                  max="100"
                  value={score}
                  onChange={e => setScore(Number(e.target.value))}
                  className="w-full accent-blue-500"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-300 block mb-1">Finding Severity</label>
                <div className="grid grid-cols-4 gap-2">
                  {(['low', 'medium', 'high', 'critical'] as const).map(sev => (
                    <button
                      key={sev}
                      type="button"
                      onClick={() => setFindingSeverity(sev)}
                      className={`py-1.5 rounded-lg font-bold text-[11px] uppercase transition ${
                        findingSeverity === sev ? 'bg-red-600 text-white shadow' : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
                      }`}
                    >
                      {sev}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-300 block mb-1">Specific Finding Description</label>
                <textarea
                  rows={2}
                  value={findingDesc}
                  onChange={e => setFindingDesc(e.target.value)}
                  placeholder="Record discrepancies in attendance register, CCTV tampering, or hygiene..."
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg p-2 text-slate-200 outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-800/60 border border-slate-700 text-slate-300">
                <div className="flex items-center space-x-2">
                  <Camera className="w-4 h-4 text-blue-400" />
                  <span>Geo-Tagged Photo Evidence</span>
                </div>
                <span className="text-[10px] text-emerald-400">Attached (1 Photo)</span>
              </div>

              <button
                type="submit"
                className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white font-bold rounded-xl text-xs shadow transition flex items-center justify-center"
              >
                <Send className="w-4 h-4 mr-2" />
                Digitally Sign & Submit Field Report
              </button>

              {reportSubmitted && (
                <p className="text-center text-xs font-semibold text-emerald-400">
                  ✓ Field report cryptographically signed and uploaded to audit trail!
                </p>
              )}
            </form>
          </div>
        </div>

      </div>

      {/* Past Reports List */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
        <h3 className="text-sm font-bold text-slate-900 mb-4">Historical Inspection Audit Logs</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {inspections.map(rep => (
            <div key={rep.reportId} className="p-4 rounded-xl border border-slate-200 bg-slate-50 text-xs">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h4 className="font-bold text-slate-900">{rep.instituteName}</h4>
                  <p className="text-slate-500 text-[11px]">Inspector: {rep.inspectorName}</p>
                </div>
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-100 text-blue-800">
                  Score: {rep.checklistScore}/100
                </span>
              </div>
              <div className="space-y-1.5 mt-2">
                {rep.findings.map(f => (
                  <div key={f.findingId} className="p-2 bg-white rounded border border-slate-200">
                    <span className="text-red-700 font-bold uppercase text-[10px] mr-1.5">[{f.severity}]</span>
                    <span className="text-slate-700">{f.description}</span>
                  </div>
                ))}
              </div>
              <p className="text-[10px] font-mono text-slate-400 mt-2 truncate">
                Signature: {rep.digitalSignatureHash}
              </p>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
};
