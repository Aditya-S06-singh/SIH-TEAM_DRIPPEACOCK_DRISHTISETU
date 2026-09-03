import React, { useState, useEffect, useRef } from 'react';
import {
  Video,
  Camera,
  AlertTriangle,
  RefreshCw,
  PhoneCall,
  ClipboardCheck,
  Shield,
  Radio,
  Cpu
} from 'lucide-react';
import { useData } from '../../context/DataContext';
import type { EdgeDevice } from '../../types';
import { edgePersonDetector } from '../../ai-models/cctv/personDetector';

interface CctvMonitorProps {
  onLaunchVc: (instId: string) => void;
  onDispatchInspection: (instId: string) => void;
}

export const CctvMonitor: React.FC<CctvMonitorProps> = ({
  onLaunchVc,
  onDispatchInspection,
}) => {
  const { edgeDevices, updateDeviceHeartbeat } = useData();
  const [selectedDevice, setSelectedDevice] = useState<EdgeDevice>(edgeDevices[0]);
  const [snapshotTaken, setSnapshotTaken] = useState<string | null>(null);
  const [analyzingFrame, setAnalyzingFrame] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Draw simulated bounding boxes on the canvas
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationFrameId: number;

    const render = async () => {
      // Clear canvas
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Background room simulation gradient
      const grad = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
      grad.addColorStop(0, '#0f172a');
      grad.addColorStop(1, '#1e293b');
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      if (selectedDevice.status === 'offline') {
        ctx.fillStyle = '#EF4444';
        ctx.font = '16px monospace';
        ctx.fillText('[CAMERA STREAM OFFLINE - HEARTBEAT LOST]', 50, canvas.height / 2);
        return;
      }

      // Draw grid lines simulating digital CCTV overlay
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
      ctx.lineWidth = 1;
      for (let x = 0; x < canvas.width; x += 40) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.stroke();
      }

      // Run edge detector inference
      const result = await edgePersonDetector.detect(selectedDevice.currentPersonCount);

      // Render Bounding Boxes
      result.boxes.forEach(box => {
        const bx = box.x * canvas.width;
        const by = box.y * canvas.height;
        const bw = box.width * canvas.width;
        const bh = box.height * canvas.height;

        // Box border
        ctx.strokeStyle = box.color;
        ctx.lineWidth = 2;
        ctx.strokeRect(bx, by, bw, bh);

        // Label Tag
        ctx.fillStyle = box.color;
        ctx.fillRect(bx, by - 18, 90, 18);
        ctx.fillStyle = '#FFFFFF';
        ctx.font = '10px monospace';
        ctx.fillText(`${box.label} ${(box.confidence * 100).toFixed(0)}%`, bx + 4, by - 5);
      });

      // Camera telemetry watermark
      ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
      ctx.font = '12px monospace';
      ctx.fillText(`CAM: ${selectedDevice.deviceId} | RPI ZERO 2 W | FPS: ${selectedDevice.fps}`, 20, 30);
      ctx.fillText(`OCCUPANCY: ${selectedDevice.currentPersonCount} PERSONS DETECTED`, 20, 50);
      ctx.fillText(`TIME: ${new Date().toLocaleTimeString()} IST`, canvas.width - 200, 30);

      // Animate scanline
      const scanY = (Date.now() / 20) % canvas.height;
      ctx.fillStyle = 'rgba(59, 130, 246, 0.15)';
      ctx.fillRect(0, scanY, canvas.width, 2);
    };

    render();
    const timer = setInterval(render, 1500);

    return () => clearInterval(timer);
  }, [selectedDevice]);

  const handleTakeSnapshot = () => {
    setAnalyzingFrame(true);
    setTimeout(() => {
      setSnapshotTaken(`snap_${Date.now()}_${selectedDevice.deviceId}.jpg`);
      setAnalyzingFrame(false);
    }, 800);
  };

  return (
    <div className="space-y-6">
      
      {/* CCTV Hub Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center space-x-2">
            <Radio className="w-5 h-5 text-emerald-600 animate-pulse" />
            <h1 className="text-xl font-black text-slate-900">Live CCTV & Raspberry Pi Edge Feeds</h1>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Decentralized computer vision streams processing occupancy & compliance directly on Raspberry Pi Zero 2 W devices.
          </p>
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={() => updateDeviceHeartbeat(selectedDevice.deviceId, selectedDevice.status === 'online' ? 'offline' : 'online')}
            className="px-3 py-1.5 text-xs font-semibold bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-lg transition"
          >
            Simulate {selectedDevice.status === 'online' ? 'Offline Outage' : 'Restore Online'}
          </button>
        </div>
      </div>

      {/* Main CCTV Workspace (Large Player + Telemetry Controls) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left 2 Cols: Main Video Canvas */}
        <div className="lg:col-span-2 bg-slate-950 rounded-2xl border border-slate-800 overflow-hidden shadow-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-white text-xs mb-3 px-2">
            <div className="flex items-center space-x-2">
              <span className={`w-2.5 h-2.5 rounded-full ${selectedDevice.status === 'online' ? 'bg-emerald-500 animate-ping' : 'bg-red-500'}`} />
              <span className="font-bold uppercase tracking-wider">{selectedDevice.deviceName}</span>
            </div>
            <span className="font-mono text-slate-400 text-[11px]">{selectedDevice.locationLabel}</span>
          </div>

          <div className="relative w-full aspect-video rounded-xl overflow-hidden bg-slate-900 flex items-center justify-center">
            <canvas
              ref={canvasRef}
              width={640}
              height={360}
              className="w-full h-full object-cover"
            />
          </div>

          {/* Action Bar Below Camera */}
          <div className="mt-4 flex flex-wrap items-center justify-between gap-3 text-xs">
            <div className="flex items-center space-x-2">
              <button
                onClick={handleTakeSnapshot}
                disabled={analyzingFrame}
                className="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg flex items-center shadow transition"
              >
                <Camera className="w-4 h-4 mr-1.5" />
                {analyzingFrame ? 'Capturing...' : 'Request Live Snapshot'}
              </button>

              <button
                onClick={() => onLaunchVc(selectedDevice.instituteId)}
                className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold rounded-lg flex items-center transition"
              >
                <PhoneCall className="w-4 h-4 mr-1.5 text-blue-400" />
                Start Random VC
              </button>

              <button
                onClick={() => onDispatchInspection(selectedDevice.instituteId)}
                className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold rounded-lg flex items-center transition"
              >
                <ClipboardCheck className="w-4 h-4 mr-1.5 text-amber-400" />
                Create Inspection
              </button>
            </div>

            {snapshotTaken && (
              <span className="text-emerald-400 font-mono text-[11px] bg-emerald-950/80 px-2 py-1 rounded border border-emerald-500/30">
                Snapshot Saved: {snapshotTaken}
              </span>
            )}
          </div>
        </div>

        {/* Right 1 Col: Edge Device Telemetry & Camera Switcher */}
        <div className="space-y-4">
          
          {/* Edge Telemetry Card */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
            <div className="flex items-center space-x-2 mb-3">
              <Cpu className="w-4 h-4 text-gov-blue" />
              <h3 className="text-sm font-bold text-slate-900">Edge Device Telemetry</h3>
            </div>

            <div className="space-y-2.5 text-xs">
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Hardware Node</span>
                <span className="font-semibold text-slate-800">{selectedDevice.hardwareLabel}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Stream Status</span>
                <span className={`font-bold uppercase ${selectedDevice.status === 'online' ? 'text-emerald-600' : 'text-red-600'}`}>
                  {selectedDevice.status}
                </span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Live Occupancy</span>
                <span className="font-bold text-blue-700">{selectedDevice.currentPersonCount} Persons</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Safety / Uniform</span>
                <span className={`font-bold uppercase ${selectedDevice.currentSafetyCompliance === 'compliant' ? 'text-emerald-600' : 'text-amber-600'}`}>
                  {selectedDevice.currentSafetyCompliance}
                </span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-slate-100">
                <span className="text-slate-500">Bitrate / FPS</span>
                <span className="font-mono text-slate-700">{selectedDevice.bitrateKbps} kbps / {selectedDevice.fps} fps</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-slate-500">Firmware</span>
                <span className="font-mono text-slate-600 text-[11px]">{selectedDevice.firmwareVersion}</span>
              </div>
            </div>
          </div>

          {/* Camera Grid Switcher */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
            <h3 className="text-sm font-bold text-slate-900 mb-3">Select Active Camera Feed</h3>
            <div className="space-y-2">
              {edgeDevices.map(dev => (
                <button
                  key={dev.deviceId}
                  onClick={() => setSelectedDevice(dev)}
                  className={`w-full text-left p-3 rounded-xl border text-xs transition ${
                    selectedDevice.deviceId === dev.deviceId
                      ? 'border-blue-600 bg-blue-50/50 shadow-sm'
                      : 'border-slate-200 hover:bg-slate-50'
                  }`}
                >
                  <div className="flex justify-between items-center mb-1">
                    <span className="font-bold text-slate-900 truncate">{dev.deviceName}</span>
                    <span className={`w-2 h-2 rounded-full ${dev.status === 'online' ? 'bg-emerald-500' : 'bg-red-500'}`} />
                  </div>
                  <p className="text-[11px] text-slate-500 truncate">{dev.instituteName}</p>
                </button>
              ))}
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};
