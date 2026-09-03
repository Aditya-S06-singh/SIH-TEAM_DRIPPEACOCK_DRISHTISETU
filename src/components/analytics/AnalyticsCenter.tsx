import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { BarChart3, Download, TrendingUp, Award } from 'lucide-react';
import { useData } from '../../context/DataContext';

export const AnalyticsCenter: React.FC = () => {
  const { institutes } = useData();

  // 7-day attendance vs CCTV occupancy trends
  const trendData = [
    { day: 'Mon', attendance: 580, cctv: 540 },
    { day: 'Tue', attendance: 610, cctv: 575 },
    { day: 'Wed', attendance: 590, cctv: 560 },
    { day: 'Thu', attendance: 640, cctv: 620 },
    { day: 'Fri', attendance: 630, cctv: 610 },
    { day: 'Sat', attendance: 490, cctv: 470 },
    { day: 'Sun', attendance: 320, cctv: 310 },
  ];

  const stateData = [
    { state: 'Delhi', compliance: 71 },
    { state: 'Rajasthan', compliance: 91 },
    { state: 'Maharashtra', compliance: 87 },
    { state: 'Uttar Pradesh', compliance: 59 },
    { state: 'Karnataka', compliance: 74 },
    { state: 'Odisha', compliance: 93 },
    { state: 'Gujarat', compliance: 96 },
  ];

  const anomalyCategories = [
    { name: 'CCTV Dropout', value: 35, color: '#EF4444' },
    { name: 'Occupancy Mismatch', value: 40, color: '#F59E0B' },
    { name: 'Liveness Bypass', value: 15, color: '#8B5CF6' },
    { name: 'Overdue Audit', value: 10, color: '#3B82F6' },
  ];

  return (
    <div className="space-y-6">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <div className="flex items-center space-x-2">
            <BarChart3 className="w-5 h-5 text-gov-blue" />
            <h1 className="text-xl font-black text-slate-900">Scheme Analytics & Compliance Intelligence</h1>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Cross-scheme comparative indices, camera uptime trends, and recurring anomaly categories.
          </p>
        </div>

        <button
          onClick={() => alert('Exporting Official DoSJE Audit Digest (PDF)...')}
          className="px-3.5 py-2 text-xs font-semibold bg-slate-900 hover:bg-slate-800 text-white rounded-lg transition flex items-center shadow-sm"
        >
          <Download className="w-4 h-4 mr-1.5" />
          Export DoSJE Compliance Digest
        </button>
      </div>

      {/* Grid: 7-Day Attendance vs CCTV Chart + Top Recurring Anomalies */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* 7-Day Trend (2 Cols) */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900">7-Day Attendance vs CCTV Occupancy Alignment</h3>
              <p className="text-xs text-slate-500">Continuous check for ghost attendance variances</p>
            </div>
            <div className="flex items-center space-x-4 text-xs">
              <span className="flex items-center text-blue-600 font-semibold">
                <span className="w-3 h-3 bg-blue-600 rounded mr-1.5" /> Verified Gate Attendance
              </span>
              <span className="flex items-center text-indigo-500 font-semibold">
                <span className="w-3 h-3 bg-indigo-500 rounded mr-1.5" /> CCTV Visible Occupancy
              </span>
            </div>
          </div>

          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="day" stroke="#94a3b8" fontSize={12} />
                <YAxis stroke="#94a3b8" fontSize={12} />
                <Tooltip />
                <Line type="monotone" dataKey="attendance" stroke="#2563EB" strokeWidth={3} dot={{ r: 4 }} />
                <Line type="monotone" dataKey="cctv" stroke="#6366F1" strokeWidth={3} dot={{ r: 4 }} strokeDasharray="4 4" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Anomaly Distribution Donut (1 Col) */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900 mb-1">Top Recurring Anomaly Categories</h3>
            <p className="text-xs text-slate-500 mb-4">Breakdown of triggers in the past 30 days</p>

            <div className="h-48 w-full flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={anomalyCategories}
                    innerRadius={50}
                    outerRadius={75}
                    paddingAngle={4}
                    dataKey="value"
                  >
                    {anomalyCategories.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>

            <div className="space-y-1.5 mt-2 text-xs">
              {anomalyCategories.map(cat => (
                <div key={cat.name} className="flex justify-between items-center">
                  <div className="flex items-center space-x-2">
                    <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: cat.color }} />
                    <span className="text-slate-700">{cat.name}</span>
                  </div>
                  <span className="font-bold text-slate-900">{cat.value}%</span>
                </div>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* State-Level Compliance Bar Chart */}
      <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
        <h3 className="text-sm font-bold text-slate-900 mb-1">State / UT Compliance Index Leaderboard</h3>
        <p className="text-xs text-slate-500 mb-4">Calculated based on verified audit records and camera uptime</p>

        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={stateData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="state" stroke="#94a3b8" fontSize={12} />
              <YAxis stroke="#94a3b8" fontSize={12} domain={[0, 100]} />
              <Tooltip />
              <Bar dataKey="compliance" fill="#1D4ED8" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

    </div>
  );
};
