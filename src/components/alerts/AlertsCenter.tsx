import React, { useState } from 'react';
import {
  AlertOctagon,
  AlertTriangle,
  Info,
  CheckCircle2,
  Filter,
  ArrowUpRight,
  PhoneCall,
  ClipboardCheck,
  ShieldAlert
} from 'lucide-react';
import { useData } from '../../context/DataContext';
import type { AlertItem, AlertSeverity, AlertStatus } from '../../types';

interface AlertsCenterProps {
  onLaunchVc: (instId: string) => void;
  onDispatchInspection: (instId: string) => void;
}

export const AlertsCenter: React.FC<AlertsCenterProps> = ({
  onLaunchVc,
  onDispatchInspection,
}) => {
  const { alerts, updateAlertStatus } = useData();
  const [severityFilter, setSeverityFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedAlert, setSelectedAlert] = useState<AlertItem | null>(alerts[0] || null);

  const filtered = alerts.filter(a => {
    const matchesSev = severityFilter === 'all' || a.severity === severityFilter;
    const matchesStat = statusFilter === 'all' || a.status === statusFilter;
    return matchesSev && matchesStat;
  });

  return (
    <div className="space-y-6">
      
      {/* Alert Center Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center space-x-2">
            <AlertOctagon className="w-5 h-5 text-red-600" />
            <h1 className="text-xl font-black text-slate-900">Alerts & Operational Anomalies</h1>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Automated intelligence flagging CCTV dropouts, ghost attendance, and inspection anomalies.
          </p>
        </div>

        {/* Filter Toolbar */}
        <div className="flex items-center space-x-2">
          <select
            value={severityFilter}
            onChange={e => setSeverityFilter(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg p-2 font-medium text-slate-700"
          >
            <option value="all">All Severities</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>

          <select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg p-2 font-medium text-slate-700"
          >
            <option value="all">All Statuses</option>
            <option value="open">Open</option>
            <option value="acknowledged">Acknowledged</option>
            <option value="resolved">Resolved</option>
          </select>
        </div>
      </div>

      {/* Main Layout: Alert List + Deep Dive Detail Pane */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left 1.5 Col: Alert List */}
        <div className="lg:col-span-2 space-y-3">
          {filtered.map(alert => {
            const isSelected = selectedAlert?.alertId === alert.alertId;
            const sevBadge =
              alert.severity === 'critical'
                ? 'bg-red-100 text-red-800 border-red-200'
                : alert.severity === 'high'
                ? 'bg-orange-100 text-orange-800 border-orange-200'
                : 'bg-amber-100 text-amber-800 border-amber-200';

            return (
              <div
                key={alert.alertId}
                onClick={() => setSelectedAlert(alert)}
                className={`p-4 rounded-2xl border transition cursor-pointer flex flex-col justify-between ${
                  isSelected
                    ? 'bg-blue-50/50 border-blue-500 shadow-sm'
                    : 'bg-white border-slate-200 hover:border-slate-300'
                }`}
              >
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase border ${sevBadge}`}>
                      {alert.severity} • +{alert.riskImpact} Risk Pts
                    </span>
                    <span className="text-[10px] text-slate-400">
                      {new Date(alert.createdAt).toLocaleString()}
                    </span>
                  </div>

                  <h3 className="text-sm font-bold text-slate-900">{alert.title}</h3>
                  <p className="text-xs text-slate-600 mt-1">{alert.explanation}</p>
                  <p className="text-[11px] font-medium text-blue-700 mt-2">{alert.instituteName}</p>
                </div>

                <div className="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
                  <span className="text-slate-400 capitalize">Status: {alert.status}</span>
                  <span className="text-blue-600 font-semibold flex items-center">
                    Review Evidence <ArrowUpRight className="w-3.5 h-3.5 ml-0.5" />
                  </span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Right 1 Col: Action & Evidence Panel */}
        {selectedAlert && (
          <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4">
            <h2 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-2">
              Anomaly Resolution Center
            </h2>

            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block">Flagged Institute</span>
              <p className="font-bold text-slate-900 text-sm">{selectedAlert.instituteName}</p>
            </div>

            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block">Root Cause Analysis</span>
              <p className="text-xs text-slate-700 mt-1 leading-relaxed bg-slate-50 p-3 rounded-xl border border-slate-200">
                {selectedAlert.explanation}
              </p>
            </div>

            {/* Recommended Protocol Actions */}
            <div>
              <span className="text-[10px] uppercase font-bold text-slate-400 block mb-2">
                Recommended Actions
              </span>
              <div className="space-y-1.5">
                {selectedAlert.recommendedActions.map((act, i) => (
                  <div key={i} className="text-xs p-2 rounded-lg bg-blue-50/60 text-blue-900 border border-blue-100 flex items-center">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-600 mr-2" />
                    {act}
                  </div>
                ))}
              </div>
            </div>

            {/* Resolution Buttons */}
            <div className="pt-3 border-t border-slate-100 space-y-2">
              <button
                onClick={() => onLaunchVc(selectedAlert.instituteId)}
                className="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-xs flex items-center justify-center transition"
              >
                <PhoneCall className="w-4 h-4 mr-1.5" />
                Launch Random Video Call
              </button>

              <button
                onClick={() => onDispatchInspection(selectedAlert.instituteId)}
                className="w-full py-2 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded-xl text-xs flex items-center justify-center transition"
              >
                <ClipboardCheck className="w-4 h-4 mr-1.5" />
                Schedule Surprise Inspection
              </button>

              <div className="flex gap-2">
                <button
                  onClick={() => updateAlertStatus(selectedAlert.alertId, 'acknowledged')}
                  className="flex-1 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-lg text-xs transition"
                >
                  Acknowledge
                </button>
                <button
                  onClick={() => updateAlertStatus(selectedAlert.alertId, 'resolved')}
                  className="flex-1 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-lg text-xs transition"
                >
                  Mark Resolved
                </button>
              </div>
            </div>

          </div>
        )}

      </div>

    </div>
  );
};
