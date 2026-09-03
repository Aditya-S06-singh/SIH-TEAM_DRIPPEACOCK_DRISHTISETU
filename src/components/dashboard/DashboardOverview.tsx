import React, { useEffect, useRef } from 'react';
import {
  Building2,
  Users,
  Video,
  AlertTriangle,
  ClipboardList,
  CheckCircle2,
  TrendingUp,
  MapPin,
  Eye,
  ShieldCheck
} from 'lucide-react';
import { useData } from '../../context/DataContext';
import type { Institute } from '../../types';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface DashboardOverviewProps {
  onSelectInstitute: (inst: Institute) => void;
  onNavigateTab: (tab: any) => void;
}

export const DashboardOverview: React.FC<DashboardOverviewProps> = ({
  onSelectInstitute,
  onNavigateTab,
}) => {
  const { institutes, alerts, edgeDevices, attendanceEvents } = useData();
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);

  // Compute live KPIs
  const totalMonitoredSites = institutes.length;
  const sitesOnline = institutes.filter(i => i.cameraStatus === 'online').length;
  const todayAttendance = institutes.reduce((acc, curr) => acc + (curr.verifiedAttendance || 0), 0);
  const activeAlertsCount = alerts.filter(a => a.status === 'open').length;
  const inspectionsDue = 3;
  const pendingActions = 4;

  const greenSites = institutes.filter(i => i.riskLevel === 'green').length;
  const amberSites = institutes.filter(i => i.riskLevel === 'amber').length;
  const redSites = institutes.filter(i => i.riskLevel === 'red').length;

  // Initialize interactive Leaflet Map for Indian Project Sites
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current).setView([22.5937, 78.9629], 5);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
      }).addTo(map);
      mapInstanceRef.current = map;
    }

    const map = mapInstanceRef.current;

    // Clear previous markers
    map.eachLayer(layer => {
      if (layer instanceof L.CircleMarker) {
        map.removeLayer(layer);
      }
    });

    // Add Color-Coded Risk Site Markers
    institutes.forEach(inst => {
      const color =
        inst.riskLevel === 'red'
          ? '#DC2626'
          : inst.riskLevel === 'amber'
          ? '#D97706'
          : '#15803D';

      const circle = L.circleMarker([inst.latitude, inst.longitude], {
        radius: inst.riskLevel === 'red' ? 10 : 8,
        fillColor: color,
        color: '#FFFFFF',
        weight: 2,
        opacity: 1,
        fillOpacity: 0.9,
      }).addTo(map);

      circle.bindPopup(`
        <div style="font-family: sans-serif; min-width: 180px;">
          <h4 style="margin: 0 0 4px; font-weight: 700; font-size: 13px; color: #0F172A;">${inst.name}</h4>
          <p style="margin: 0 0 4px; font-size: 11px; color: #475569;">${inst.scheme}</p>
          <div style="font-size: 11px; margin-bottom: 4px;">
            <strong>Risk Score:</strong> <span style="color: ${color}; font-weight: bold;">${inst.riskScore}/100</span> (${inst.riskLevel.toUpperCase()})
          </div>
          <div style="font-size: 11px; margin-bottom: 6px;">
            <strong>Attendance:</strong> ${inst.verifiedAttendance || 0} / CCTV: ${inst.cctvOccupancy || 0}
          </div>
          <button id="btn-popup-${inst.instituteId}" style="background: #1D4ED8; color: white; border: none; padding: 4px 8px; border-radius: 4px; font-size: 10px; cursor: pointer; width: 100%;">
            Open Command Center
          </button>
        </div>
      `);

      circle.on('popupopen', () => {
        const btn = document.getElementById(`btn-popup-${inst.instituteId}`);
        if (btn) {
          btn.onclick = () => onSelectInstitute(inst);
        }
      });
    });
  }, [institutes, onSelectInstitute]);

  return (
    <div className="space-y-6">
      
      {/* Top Banner with Scheme Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h1 className="text-xl font-black text-slate-900 tracking-tight">
            Central Monitoring Command Center
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time biometric attendance, Raspberry Pi edge vision, and transparent AI risk auditing.
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={() => onNavigateTab('attendance')}
            className="px-3.5 py-2 text-xs font-semibold bg-gov-blue hover:bg-gov-navy text-white rounded-lg transition shadow-sm flex items-center"
          >
            <ShieldCheck className="w-4 h-4 mr-1.5" />
            Launch Gate Entry
          </button>
          <button
            onClick={() => onNavigateTab('cctv')}
            className="px-3.5 py-2 text-xs font-semibold bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-lg transition flex items-center"
          >
            <Video className="w-4 h-4 mr-1.5" />
            Live CCTV Feeds
          </button>
        </div>
      </div>

      {/* 6 Key Performance Metric Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3.5">
        
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Monitored Sites</span>
            <Building2 className="w-4 h-4 text-blue-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{totalMonitoredSites}</div>
          <span className="text-[10px] text-emerald-600 font-medium">12 Districts Active</span>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Sites Online</span>
            <Video className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{sitesOnline}/{totalMonitoredSites}</div>
          <span className="text-[10px] text-slate-500">Raspberry Pi Telemetry</span>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Today's Verified</span>
            <Users className="w-4 h-4 text-indigo-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{todayAttendance}</div>
          <span className="text-[10px] text-emerald-600 font-medium">Consent-Based ID</span>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Active Alerts</span>
            <AlertTriangle className="w-4 h-4 text-red-600" />
          </div>
          <div className="text-2xl font-bold text-red-600">{activeAlertsCount}</div>
          <span className="text-[10px] text-red-500 font-medium">2 Critical Anomalies</span>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Inspections Due</span>
            <ClipboardList className="w-4 h-4 text-amber-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{inspectionsDue}</div>
          <span className="text-[10px] text-amber-600 font-medium">Surprise Audits</span>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between text-slate-400 mb-1.5">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Pending Action</span>
            <CheckCircle2 className="w-4 h-4 text-teal-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{pendingActions}</div>
          <span className="text-[10px] text-slate-500">Corrective Proofs</span>
        </div>

      </div>

      {/* Main Grid: GIS Map + Risk Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Interactive India Site Map (2 Cols) */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm p-4 flex flex-col">
          <div className="flex items-center justify-between mb-3 px-1">
            <div className="flex items-center space-x-2">
              <MapPin className="w-4 h-4 text-gov-blue" />
              <h2 className="text-sm font-bold text-slate-900">National Site Geolocation & Risk Map</h2>
            </div>
            <div className="flex items-center space-x-3 text-xs">
              <span className="flex items-center text-emerald-700">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-600 mr-1" /> Green ({greenSites})
              </span>
              <span className="flex items-center text-amber-700">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500 mr-1" /> Amber ({amberSites})
              </span>
              <span className="flex items-center text-red-700">
                <span className="w-2.5 h-2.5 rounded-full bg-red-600 mr-1" /> Red ({redSites})
              </span>
            </div>
          </div>

          <div
            ref={mapContainerRef}
            className="w-full h-80 rounded-xl overflow-hidden border border-slate-200 shadow-inner"
          />
        </div>

        {/* Site Health & Transparent Risk Breakdown (1 Col) */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between">
          <div>
            <h2 className="text-sm font-bold text-slate-900 mb-1">Site Health & Risk Distribution</h2>
            <p className="text-xs text-slate-500 mb-4">
              Real-time calculation based on CCTV uptime, attendance fidelity, and audit scores.
            </p>

            <div className="space-y-3">
              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span className="text-emerald-700">Low Risk / Highly Compliant (0 - 29)</span>
                  <span className="text-slate-800">{greenSites} Sites ({Math.round((greenSites / totalMonitoredSites) * 100)}%)</span>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div className="bg-emerald-600 h-2 rounded-full" style={{ width: `${(greenSites / totalMonitoredSites) * 100}%` }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span className="text-amber-700">Moderate Risk / Monitored (30 - 59)</span>
                  <span className="text-slate-800">{amberSites} Sites ({Math.round((amberSites / totalMonitoredSites) * 100)}%)</span>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div className="bg-amber-500 h-2 rounded-full" style={{ width: `${(amberSites / totalMonitoredSites) * 100}%` }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span className="text-red-700">High Risk / Action Required (60 - 100)</span>
                  <span className="text-slate-800">{redSites} Sites ({Math.round((redSites / totalMonitoredSites) * 100)}%)</span>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div className="bg-red-600 h-2 rounded-full" style={{ width: `${(redSites / totalMonitoredSites) * 100}%` }} />
                </div>
              </div>
            </div>

            <div className="mt-5 p-3 rounded-xl bg-slate-50 border border-slate-200/80 text-xs">
              <span className="font-semibold text-slate-800">Priority Attention Alert:</span>
              <p className="text-slate-600 mt-1">
                <strong>Prayas Divyangjan Special Institute (DEL)</strong> has a risk score of <strong>82/100</strong> due to 71.4% gate vs CCTV discrepancy and silent edge camera.
              </p>
            </div>
          </div>

          <button
            onClick={() => onNavigateTab('alerts')}
            className="w-full mt-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-xs font-medium transition"
          >
            Review All Flagged Anomalies
          </button>
        </div>

      </div>

      {/* Bottom Row: Recent Anomaly Feed & CCTV Edge Stream Previews */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Recent Anomaly Feed */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-bold text-slate-900">Recent Telemetry Anomalies</h3>
            <span className="text-[11px] text-blue-600 font-semibold cursor-pointer" onClick={() => onNavigateTab('alerts')}>
              View All ({alerts.length})
            </span>
          </div>

          <div className="space-y-3">
            {alerts.slice(0, 3).map(alert => (
              <div
                key={alert.alertId}
                className="p-3.5 rounded-xl border border-slate-200 hover:border-blue-300 transition bg-slate-50/50 flex items-start justify-between gap-3"
              >
                <div>
                  <div className="flex items-center space-x-2">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                      alert.severity === 'critical'
                        ? 'bg-red-100 text-red-800'
                        : alert.severity === 'high'
                        ? 'bg-orange-100 text-orange-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}>
                      {alert.severity}
                    </span>
                    <span className="text-xs font-bold text-slate-800">{alert.instituteName}</span>
                  </div>
                  <p className="text-xs text-slate-600 mt-1">{alert.explanation}</p>
                  <p className="text-[10px] text-slate-400 mt-1">
                    Risk Impact: +{alert.riskImpact} pts • {new Date(alert.createdAt).toLocaleTimeString()}
                  </p>
                </div>

                <button
                  onClick={() => onNavigateTab('alerts')}
                  className="px-2.5 py-1 text-[11px] font-semibold bg-white border border-slate-300 rounded hover:bg-slate-100 text-slate-700 whitespace-nowrap"
                >
                  Inspect
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Live CCTV Preview Cards */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
              <h3 className="text-sm font-bold text-slate-900">Live CCTV Telemetry Previews</h3>
            </div>
            <button
              onClick={() => onNavigateTab('cctv')}
              className="text-[11px] text-blue-600 font-semibold hover:underline"
            >
              Open Full CCTV Grid
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {edgeDevices.slice(0, 2).map(cam => (
              <div key={cam.deviceId} className="rounded-xl border border-slate-200 overflow-hidden bg-slate-950 text-white">
                <div className="relative h-28 bg-slate-900 flex items-center justify-center">
                  <div className="text-center p-2">
                    <Video className="w-6 h-6 mx-auto mb-1 text-slate-400" />
                    <span className="text-[10px] text-slate-400">{cam.hardwareLabel}</span>
                  </div>
                  <span className={`absolute top-2 left-2 px-1.5 py-0.5 rounded text-[9px] font-bold uppercase ${
                    cam.status === 'online' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'
                  }`}>
                    {cam.status}
                  </span>
                  <span className="absolute bottom-2 right-2 text-[10px] font-mono bg-black/60 px-1.5 py-0.5 rounded">
                    Occupancy: {cam.currentPersonCount}
                  </span>
                </div>
                <div className="p-2.5 bg-slate-900 text-xs">
                  <p className="font-semibold truncate text-slate-200">{cam.deviceName}</p>
                  <p className="text-[10px] text-slate-400 truncate">{cam.locationLabel}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
};
