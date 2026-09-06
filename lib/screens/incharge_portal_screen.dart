import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/zone_model.dart';
import '../providers/audit_providers.dart';
import 'login_screen.dart';
import 'video_conferencing_screen.dart';

class InchargePortalScreen extends ConsumerStatefulWidget {
  final String assignedZoneId;
  final String inchargeName;

  const InchargePortalScreen({
    super.key,
    required this.assignedZoneId,
    required this.inchargeName,
  });

  @override
  ConsumerState<InchargePortalScreen> createState() => _InchargePortalScreenState();
}

class _InchargePortalScreenState extends ConsumerState<InchargePortalScreen> {
  bool _isCallDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final zoneAsync = ref.watch(zoneDetailStreamProvider(widget.assignedZoneId));

    // Listen for incoming call events in real-time
    ref.listen<AsyncValue<ZoneModel?>>(zoneDetailStreamProvider(widget.assignedZoneId), (prev, next) {
      next.whenData((zone) {
        if (zone != null && zone.callStatus == 'ringing' && !_isCallDialogShowing) {
          _showIncomingCallDialog(zone);
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131920),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site Incharge Dashboard',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'DoSJE NGO Facility Portal • ${widget.inchargeName}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: zoneAsync.when(
        data: (zone) {
          if (zone == null) {
            return const Center(child: Text('Facility records not found', style: TextStyle(color: Colors.white)));
          }
          return _buildInchargeContent(zone);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildInchargeContent(ZoneModel zone) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Center Banner Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF26303D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Text(
                        zone.floor.toUpperCase(),
                        style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: zone.isCameraOnline ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          zone.isCameraOnline ? 'CCTV SENTINEL ACTIVE' : 'CCTV OFFLINE',
                          style: TextStyle(
                            color: zone.isCameraOnline ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  zone.name,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DoSJE Grant Scheme: Deendayal Disabled Rehabilitation Centre (DDRC)',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Real-Time Occupancy Summary
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'ENROLLED BENEFICIARIES',
                  value: '${zone.expectedCount}',
                  subtitle: 'Registered in DoSJE Portal',
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'AI CAMERA HEADCOUNT',
                  value: '${zone.detectedCount}',
                  subtitle: 'Live YOLO11n Detection',
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Inspection Standby Alert Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Colors.cyanAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surprise Inspection Standby',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ministry Officials can initiate a surprise video call anytime. Keep app open during inspection hours.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Test Video Call Trigger (Self Test)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.video_call, size: 20),
            label: const Text('JOIN / TEST VIDEO CONFERENCING ROOM'),
            onPressed: () {
              final room = zone.activeRoomUrl ?? 'https://meet.jit.si/dosje_audit_${zone.id.replaceAll('-', '_')}';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoConferencingScreen(
                    roomUrl: room,
                    centerName: zone.name,
                    callerRole: 'incharge',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131920),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF26303D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  void _showIncomingCallDialog(ZoneModel zone) {
    _isCallDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.phone_in_talk, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('SURPRISE INSPECTION CALL', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caller: ${zone.callerName ?? 'MoSJE Lead Auditor'}',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'A surprise video inspection is being initiated for ${zone.name}. Please connect your front camera immediately.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('DECLINE', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              ref.read(inspectionActionControllerProvider.notifier).endVideoCall(zone.id);
              _isCallDialogShowing = false;
              Navigator.pop(ctx);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.videocam, size: 16),
            label: const Text('ACCEPT & CONNECT'),
            onPressed: () {
              ref.read(inspectionActionControllerProvider.notifier).acceptVideoCall(zone.id);
              _isCallDialogShowing = false;
              Navigator.pop(ctx);
              final room = zone.activeRoomUrl ?? 'https://meet.jit.si/dosje_audit_${zone.id.replaceAll('-', '_')}';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoConferencingScreen(
                    roomUrl: room,
                    centerName: zone.name,
                    callerRole: 'incharge',
                    onCallEnded: () {
                      ref.read(inspectionActionControllerProvider.notifier).endVideoCall(zone.id);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
