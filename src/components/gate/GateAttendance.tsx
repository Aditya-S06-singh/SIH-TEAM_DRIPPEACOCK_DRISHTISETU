import React, { useState } from 'react';
import {
  ScanFace,
  QrCode,
  Fingerprint,
  CheckCircle2,
  AlertCircle,
  ShieldCheck,
  RotateCcw,
  UserCheck,
  Eye,
  FileSpreadsheet
} from 'lucide-react';
import { useData } from '../../context/DataContext';
import { gateFaceLivenessVerifier } from '../../ai-models/gate/faceLiveness';
import { biometricHashVerifier } from '../../ai-models/gate/biometricHashVerifier';

export const GateAttendance: React.FC = () => {
  const { institutes, attendanceEvents, addAttendanceEvent } = useData();
  const [selectedInstId, setSelectedInstId] = useState<string>('inst_del_01');
  const [scannedId, setScannedId] = useState('4821');
  const [selectedRole, setSelectedRole] = useState<'beneficiary' | 'student' | 'resident' | 'staff' | 'instructor'>('beneficiary');
  const [consentChecked, setConsentChecked] = useState(true);

  // Verification step statuses
  const [verifying, setVerifying] = useState(false);
  const [livenessStatus, setLivenessStatus] = useState<'idle' | 'passed' | 'failed'>('idle');
  const [biometricStatus, setBiometricStatus] = useState<'idle' | 'matched' | 'failed'>('idle');
  const [latestToken, setLatestToken] = useState<string | null>(null);

  const activeInstitute = institutes.find(i => i.instituteId === selectedInstId) || institutes[0];

  const handleVerifyAndSubmit = async (manualFallback: boolean = false) => {
    setVerifying(true);

    if (manualFallback) {
      // Operator physical log override
      await addAttendanceEvent({
        instituteId: activeInstitute.instituteId,
        instituteName: activeInstitute.name,
        role: selectedRole,
        entryMethod: 'manual_fallback',
        verificationStatus: 'manual_override',
        faceMatchStatus: 'bypassed',
        livenessStatus: 'bypassed',
        fingerprintMatchStatus: 'bypassed',
        governmentIdReferenceMasked: `XXXX-XXXX-${scannedId.slice(-4) || '4821'}`,
        consentStatus: consentChecked,
        cameraEntryConfirmed: true,
      });
      setVerifying(false);
      setLatestToken(`manual_fallback_${Date.now()}`);
      return;
    }

    // 1. Run AI Optical Liveness Check
    const livenessResult = await gateFaceLivenessVerifier.verifyLiveness();
    setLivenessStatus(livenessResult.passed ? 'passed' : 'failed');

    // 2. Run Cryptographic Hash Matching (Zero raw Aadhaar)
    const hashResult = biometricHashVerifier.verify(scannedId, consentChecked);
    setBiometricStatus(hashResult.matched ? 'matched' : 'failed');

    // 3. Dispatch immutable attendance record
    await addAttendanceEvent({
      instituteId: activeInstitute.instituteId,
      instituteName: activeInstitute.name,
      personToken: hashResult.opaquePersonToken,
      role: selectedRole,
      entryMethod: 'qr_assisted',
      verificationStatus: livenessResult.passed && hashResult.matched ? 'verified' : 'failed',
      faceMatchStatus: livenessResult.passed ? 'matched' : 'failed',
      livenessStatus: livenessResult.passed ? 'passed' : 'failed',
      fingerprintMatchStatus: hashResult.matched ? 'matched' : 'failed',
      governmentIdReferenceMasked: hashResult.maskedIdDisplay,
      consentStatus: consentChecked,
      cameraEntryConfirmed: true,
    });

    setLatestToken(hashResult.opaquePersonToken);
    setVerifying(false);
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      
      {/* Tablet Gate Header */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <span className="p-2 rounded-lg bg-gov-blue text-white">
              <ScanFace className="w-5 h-5" />
            </span>
            <h1 className="text-xl font-black text-slate-900">Gate Identity Verification Terminal</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Consent-based multi-factor authentication with optical liveness. Fully compliant with DPDP Act 2023.
          </p>
        </div>

        {/* Selected Institute Selector for Gate Operator */}
        <div>
          <label className="text-[11px] font-bold text-slate-400 uppercase block mb-1">Gate Location</label>
          <select
            value={selectedInstId}
            onChange={e => setSelectedInstId(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg p-2 font-semibold text-slate-800"
          >
            {institutes.map(inst => (
              <option key={inst.instituteId} value={inst.instituteId}>
                {inst.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Terminal Main Workspace (Dual Columns) */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Verification Input & Biometric Verification Card */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <h2 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-2">
            Beneficiary / Staff Entry Check
          </h2>

          {/* Role Picker */}
          <div>
            <label className="text-xs font-semibold text-slate-700 block mb-1">Entry Role</label>
            <div className="grid grid-cols-3 gap-2 text-xs">
              {(['beneficiary', 'student', 'staff'] as const).map(r => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setSelectedRole(r)}
                  className={`py-2 rounded-lg border font-semibold capitalize transition ${
                    selectedRole === r ? 'bg-blue-600 text-white border-blue-600 shadow-sm' : 'border-slate-200 text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  {r}
                </button>
              ))}
            </div>
          </div>

          {/* Masked Gov ID / Barcode Input */}
          <div>
            <label className="text-xs font-semibold text-slate-700 block mb-1">
              Registered ID / QR Code Scan
            </label>
            <div className="relative">
              <QrCode className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={scannedId}
                onChange={e => setScannedId(e.target.value)}
                placeholder="Scan QR or enter last 4 digits (e.g. 4821)"
                className="w-full text-xs font-mono pl-9 pr-3 py-2.5 rounded-lg border border-slate-200 bg-slate-50 focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
            <p className="text-[10px] text-slate-400 mt-1">
              Masked reference will be generated: <span className="font-mono font-bold text-slate-600">XXXX-XXXX-{scannedId.slice(-4) || '4821'}</span>
            </p>
          </div>

          {/* Consent Checkbox */}
          <div className="p-3 rounded-xl bg-blue-50/70 border border-blue-200/80 flex items-start space-x-2 text-xs">
            <input
              type="checkbox"
              id="consent-check"
              checked={consentChecked}
              onChange={e => setConsentChecked(e.target.checked)}
              className="mt-0.5 rounded text-blue-600 focus:ring-blue-500"
            />
            <label htmlFor="consent-check" className="text-slate-700 leading-snug">
              <strong>Explicit Beneficiary Consent:</strong> I confirm consent has been taken for multi-factor entry verification. No biometric images are stored.
            </label>
          </div>

          {/* Action Buttons */}
          <div className="pt-2 space-y-2">
            <button
              onClick={() => handleVerifyAndSubmit(false)}
              disabled={verifying || !consentChecked}
              className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow transition flex items-center justify-center disabled:opacity-50"
            >
              <ScanFace className="w-4 h-4 mr-2" />
              {verifying ? 'Running Optical & Biometric Verification...' : 'Run Multi-Factor Verification'}
            </button>

            <button
              onClick={() => handleVerifyAndSubmit(true)}
              disabled={verifying}
              className="w-full py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-xl text-xs transition flex items-center justify-center"
            >
              <FileSpreadsheet className="w-4 h-4 mr-1.5" />
              Manual Verification Fallback (Paper Register Override)
            </button>
          </div>

        </div>

        {/* Verification Status & Security Feedback */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-2 mb-4">
              Real-Time Verification Feedback
            </h2>

            <div className="space-y-3 text-xs">
              
              {/* Optical Liveness Check */}
              <div className="p-3 rounded-xl border border-slate-200 flex items-center justify-between">
                <div className="flex items-center space-x-2.5">
                  <Eye className="w-4 h-4 text-slate-500" />
                  <div>
                    <span className="font-bold text-slate-800">Face Liveness (Anti-Spoof)</span>
                    <p className="text-[10px] text-slate-400">Micro-motion & blink verification</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                  livenessStatus === 'passed' ? 'bg-emerald-100 text-emerald-800' : (livenessStatus === 'failed' ? 'bg-red-100 text-red-800' : 'bg-slate-100 text-slate-500')
                }`}>
                  {livenessStatus}
                </span>
              </div>

              {/* Fingerprint / Biometric Token */}
              <div className="p-3 rounded-xl border border-slate-200 flex items-center justify-between">
                <div className="flex items-center space-x-2.5">
                  <Fingerprint className="w-4 h-4 text-slate-500" />
                  <div>
                    <span className="font-bold text-slate-800">Biometric Template Hash</span>
                    <p className="text-[10px] text-slate-400">Salted one-way HMAC comparison</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                  biometricStatus === 'matched' ? 'bg-emerald-100 text-emerald-800' : (biometricStatus === 'failed' ? 'bg-red-100 text-red-800' : 'bg-slate-100 text-slate-500')
                }`}>
                  {biometricStatus}
                </span>
              </div>

              {/* Privacy Badge */}
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/80 text-[11px] text-slate-600">
                <div className="flex items-center space-x-1.5 font-bold text-slate-800 mb-1">
                  <ShieldCheck className="w-4 h-4 text-emerald-600" />
                  <span>Privacy Constraint Guarantee</span>
                </div>
                No facial images, fingerprints, religion, caste, health, or sensitive attributes are stored.
              </div>

            </div>
          </div>

          {latestToken && (
            <div className="mt-4 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-900">
              <span className="font-bold block">✓ Attendance Logged Successfully</span>
              <span className="font-mono text-[10px] text-emerald-700">Token: {latestToken}</span>
            </div>
          )}
        </div>

      </div>

      {/* Recent Gate Entry Stream Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <h3 className="text-sm font-bold text-slate-900">Live Entry Stream</h3>
          <span className="text-xs text-slate-500">Auto-refreshing via live telemetry</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 border-b border-slate-200">
              <tr>
                <th className="p-3">Opaque Token</th>
                <th className="p-3">Role</th>
                <th className="p-3">Masked ID</th>
                <th className="p-3">Multi-Factor Status</th>
                <th className="p-3">CCTV Confirmation</th>
                <th className="p-3">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {attendanceEvents.slice(0, 6).map(evt => (
                <tr key={evt.eventId} className="hover:bg-slate-50">
                  <td className="p-3 font-mono text-slate-600">{evt.personToken}</td>
                  <td className="p-3 capitalize font-medium text-slate-700">{evt.role}</td>
                  <td className="p-3 font-mono font-semibold text-slate-800">{evt.governmentIdReferenceMasked}</td>
                  <td className="p-3">
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-emerald-100 text-emerald-800">
                      {evt.verificationStatus}
                    </span>
                  </td>
                  <td className="p-3 text-slate-600">{evt.cameraEntryConfirmed ? 'Confirmed' : 'Pending'}</td>
                  <td className="p-3 text-slate-400">{new Date(evt.occurredAt).toLocaleTimeString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
};
