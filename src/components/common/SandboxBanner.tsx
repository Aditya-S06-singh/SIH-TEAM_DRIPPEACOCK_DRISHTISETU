import React from 'react';
import {
  ShieldAlert,
  Database,
  CheckCircle2,
  AlertTriangle,
  Server,
  Sparkles,
  Info
} from 'lucide-react';
import { seedService } from '../../services/seedService';

interface SandboxBannerProps {
  isLiveFirebase: boolean;
}

export const SandboxBanner: React.FC<SandboxBannerProps> = ({ isLiveFirebase }) => {
  const [seeding, setSeeding] = React.useState(false);
  const [seedMsg, setSeedMsg] = React.useState<string | null>(null);

  const handleSeed = async () => {
    setSeeding(true);
    const res = await seedService.seedFirestoreDatabase();
    setSeedMsg(res.message);
    setSeeding(false);
    setTimeout(() => setSeedMsg(null), 5000);
  };

  return (
    <div className="bg-gradient-to-r from-gov-navy via-gov-blue to-slate-900 text-white px-4 py-2 text-xs border-b border-blue-900/40 shadow-sm flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center space-x-2">
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold tracking-wider bg-amber-500/20 text-amber-300 border border-amber-500/30">
          <ShieldAlert className="w-3 h-3 mr-1" />
          GOVERNMENT SANDBOX ENVIRONMENT
        </span>
        <span className="text-slate-300 hidden md:inline">
          Department of Social Justice & Empowerment (DoSJE) • SIH Problem Statement 26095
        </span>
      </div>

      <div className="flex items-center space-x-3">
        {isLiveFirebase ? (
          <div className="flex items-center text-emerald-400 bg-emerald-950/60 px-2.5 py-0.5 rounded-full border border-emerald-500/30">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse mr-1.5" />
            <span className="font-medium">Firebase Firestore Connected</span>
            <button
              onClick={handleSeed}
              disabled={seeding}
              className="ml-2 text-[10px] bg-emerald-700 hover:bg-emerald-600 text-white px-2 py-0.5 rounded transition disabled:opacity-50"
            >
              {seeding ? 'Seeding...' : 'Seed Data'}
            </button>
          </div>
        ) : (
          <div className="flex items-center text-blue-300 bg-blue-950/70 px-2.5 py-0.5 rounded-full border border-blue-600/30">
            <Server className="w-3 h-3 mr-1.5 text-blue-400" />
            <span>Simulated Seed Mode (12 Institutes, 100+ Events)</span>
            <span className="text-slate-400 ml-2 hidden sm:inline">| Set .env.local to activate Firebase</span>
          </div>
        )}

        {seedMsg && (
          <span className="text-emerald-300 bg-emerald-900/80 px-2 py-0.5 rounded border border-emerald-500/30">
            {seedMsg}
          </span>
        )}
      </div>
    </div>
  );
};
