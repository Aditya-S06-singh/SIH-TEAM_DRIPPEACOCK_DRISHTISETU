import React, { useState } from 'react';
import {
  PhoneCall,
  Video,
  CheckCircle2,
  XCircle,
  Camera,
  ShieldCheck,
  AlertTriangle,
  UserCheck
} from 'lucide-react';
import type { VideoVerification, VcResult } from '../../types';
import { useData } from '../../context/DataContext';

interface RandomVcModalProps {
  vc: VideoVerification;
  onClose: () => void;
}

export const RandomVcModal: React.FC<RandomVcModalProps> = ({ vc, onClose }) => {
  const { setActiveVc } = useData();
  const [callState, setCallState] = useState<'connecting' | 'connected' | 'ended'>('connecting');
  const [checklist, setChecklist] = useState({
    activityAreaVerified: false,
    staffPresenceConfirmed: false,
    beneficiariesPresentConfirmed: false,
    amenitiesAndFoodChecked: false,
  });
  const [capturedSnapshot, setCapturedSnapshot] = useState<string | null>(null);
  const [outcome, setOutcome] = useState<VcResult | null>(null);

  // Auto-connect simulation
  React.useEffect(() => {
    const timer = setTimeout(() => {
      setCallState('connected');
    }, 1500);
    return () => clearTimeout(timer);
  }, []);

  const handleToggleChecklist = (key: keyof typeof checklist) => {
    setChecklist(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleCaptureEvidence = () => {
    setCapturedSnapshot(`vc_evidence_${Date.now()}.jpg`);
  };

  const handleCompleteCall = (result: VcResult) => {
    setOutcome(result);
    setCallState('ended');
    setTimeout(() => {
      setActiveVc(null);
      onClose();
    }, 2000);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl max-w-4xl w-full border border-slate-200 shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        
        {/* Call Header */}
        <div className="bg-slate-950 text-white p-4 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <span className="p-2 rounded-xl bg-blue-600">
              <Video className="w-5 h-5" />
            </span>
            <div>
              <h2 className="text-sm font-bold">{vc.instituteName}</h2>
              <p className="text-[11px] text-slate-400">
                Random Video Call Audit • Reason: <span className="uppercase font-semibold text-blue-400">{vc.selectedReason}</span>
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
              callState === 'connected' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
            }`}>
              {callState === 'connected' ? '● Call In Progress' : 'Connecting to Project Incharge...'}
            </span>
            <button
              onClick={onClose}
              className="text-slate-400 hover:text-white text-sm p-1 ml-2"
            >
              ✕
            </button>
          </div>
        </div>

        {/* Video Simulation + Guided Checklist */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 p-6">
          
          {/* Simulated Video Stream Canvas (2 Cols) */}
          <div className="md:col-span-2 bg-slate-950 rounded-2xl overflow-hidden aspect-video relative flex flex-col justify-between p-4 shadow-inner">
            <div className="flex items-center justify-between text-white text-xs z-10">
              <span className="font-mono bg-black/60 px-2 py-0.5 rounded">
                LIVE SECURE STREAM (WebRTC)
              </span>
              <span className="font-mono bg-black/60 px-2 py-0.5 rounded">
                {new Date().toLocaleTimeString()}
              </span>
            </div>

            {/* Video Placeholder Content */}
            <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-400">
              {callState === 'connecting' ? (
                <div className="text-center">
                  <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
                  <p className="text-xs">Ringing Project Incharge mobile terminal...</p>
                </div>
              ) : (
                <div className="text-center">
                  <div className="w-20 h-20 rounded-full bg-slate-800 border-2 border-slate-700 flex items-center justify-center mx-auto mb-2 text-white font-bold text-xl">
                    NGO
                  </div>
                  <p className="text-xs text-slate-200 font-semibold">Ananya Deshmukh (Project Incharge)</p>
                  <p className="text-[11px] text-slate-400">Front Camera Feed • Active Hall Inspection</p>
                </div>
              )}
            </div>

            {/* In-Call Controls */}
            <div className="flex items-center justify-between z-10">
              <button
                onClick={handleCaptureEvidence}
                className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold flex items-center shadow transition"
              >
                <Camera className="w-3.5 h-3.5 mr-1.5" />
                Capture Consent-Based Snapshot
              </button>

              {capturedSnapshot && (
                <span className="text-[11px] text-emerald-400 bg-black/70 px-2 py-1 rounded">
                  Snapshot Saved!
                </span>
              )}
            </div>
          </div>

          {/* Guided Verification Checklist (1 Col) */}
          <div className="space-y-4 flex flex-col justify-between">
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
                Mandatory Audit Checklist
              </h3>

              <div className="space-y-2.5">
                {[
                  { key: 'activityAreaVerified', label: 'Show Current Activity Area' },
                  { key: 'staffPresenceConfirmed', label: 'Confirm Staff Physical Presence' },
                  { key: 'beneficiariesPresentConfirmed', label: 'Beneficiaries Present Count Match' },
                  { key: 'amenitiesAndFoodChecked', label: 'Verify Meal/Amenities Status' },
                ].map(item => (
                  <label
                    key={item.key}
                    className="flex items-start space-x-2.5 p-2.5 rounded-xl border border-slate-200 hover:bg-slate-50 cursor-pointer text-xs"
                  >
                    <input
                      type="checkbox"
                      checked={checklist[item.key as keyof typeof checklist]}
                      onChange={() => handleToggleChecklist(item.key as keyof typeof checklist)}
                      className="mt-0.5 rounded text-blue-600"
                    />
                    <span className="text-slate-700 font-medium">{item.label}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Call Outcome Actions */}
            <div className="pt-4 border-t border-slate-100 space-y-2">
              <p className="text-[11px] font-bold text-slate-400 uppercase">Submit Audit Finding</p>
              
              <button
                onClick={() => handleCompleteCall('verified')}
                className="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition flex items-center justify-center"
              >
                <CheckCircle2 className="w-4 h-4 mr-1.5" />
                Verified Compliant
              </button>

              <button
                onClick={() => handleCompleteCall('suspicious_escalated')}
                className="w-full py-2 bg-red-600 hover:bg-red-700 text-white rounded-xl text-xs font-bold transition flex items-center justify-center"
              >
                <AlertTriangle className="w-4 h-4 mr-1.5" />
                Suspicious / Escalate Audit
              </button>

              <button
                onClick={() => handleCompleteCall('no_response')}
                className="w-full py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition"
              >
                No Response / Disconnected
              </button>
            </div>

          </div>

        </div>

        {outcome && (
          <div className="bg-blue-50 border-t border-blue-200 p-3 text-center text-xs font-bold text-blue-900">
            Call Recorded: {outcome.toUpperCase()} • Site risk score dynamically adjusted.
          </div>
        )}

      </div>
    </div>
  );
};
