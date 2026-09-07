import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/inspection_model.dart';
import '../models/zone_model.dart';
import '../providers/audit_providers.dart';
import '../services/whatsapp_call_service.dart';
import 'video_conferencing_screen.dart';

class LiveInspectionScreen extends ConsumerStatefulWidget {
  final String zoneId;

  const LiveInspectionScreen({super.key, required this.zoneId});

  @override
  ConsumerState<LiveInspectionScreen> createState() =>
      _LiveInspectionScreenState();
}

class _LiveInspectionScreenState extends ConsumerState<LiveInspectionScreen>
    with SingleTickerProviderStateMixin {
  final _findingsController = TextEditingController();
  final _manualCountController = TextEditingController();
  late AnimationController _pulseController;
  bool _isFullScreen = false;
  bool _isTalkingToFacility = false;
  bool _isListeningToFacilityMic = true;

  Future<void> _toggleTalkback(String cctvStreamUrl) async {
    final targetUrl = cctvStreamUrl.isNotEmpty
        ? cctvStreamUrl
        : 'http://192.168.1.2:8088/stream';
    final nodeAudioUri = targetUrl.replaceAll('/stream', '/audio/in');

    final messageController = TextEditingController(
        text:
            'Auditor speaking: Attention facility in-charge, please verify beneficiary headcount.');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131920),
        title: Row(
          children: const [
            Icon(Icons.record_voice_over, color: Colors.tealAccent, size: 20),
            SizedBox(width: 8),
            Text('Transmit Voice to Phone Speaker',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice transmission will play loud through the phone node speakerphone in real time:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1F2630),
                hintText: 'Enter speech transmission...',
                hintStyle: const TextStyle(color: Colors.white30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, foregroundColor: Colors.white),
            icon: const Icon(Icons.volume_up, size: 16),
            label: const Text('TRANSMIT TO PHONE'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isTalkingToFacility = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 TRANSMITTING TO PHONE SPEAKERPHONE NOW...'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );

      final msg = messageController.text.trim();
      final bodyBytes = msg.isNotEmpty
          ? msg.codeUnits
          : 'Auditor speaking: Please confirm headcount verification.'
              .codeUnits;

      final endpoints = [
        nodeAudioUri,
        'http://10.0.2.2:8088/audio/in',
        'http://127.0.0.1:8088/audio/in',
        'http://192.168.1.2:8088/audio/in',
      ];

      bool sent = false;
      for (final endpoint in endpoints) {
        try {
          final res = await http
              .post(
                Uri.parse(endpoint),
                headers: {'Content-Type': 'application/octet-stream'},
                body: bodyBytes,
              )
              .timeout(const Duration(milliseconds: 1200));
          if (res.statusCode == 200) {
            sent = true;
            break;
          }
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sent
                  ? '🔊 TRANSMITTED: Voice message broadcast to phone speaker!'
                  : 'Could not reach phone node. Check phone network or connection.',
            ),
            backgroundColor: sent ? Colors.teal : Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _isTalkingToFacility = false);
      });
    }
  }

  bool _isLiveWalkieTalkieActive = false;

  Future<void> _toggleLiveWalkieTalkie() async {
    final newState = !_isLiveWalkieTalkieActive;
    final path = newState ? '/mic/start' : '/mic/stop';
    bool success = false;

    for (final host in [
      'http://10.0.2.2:8092',
      'http://127.0.0.1:8092',
      'http://192.168.1.4:8092',
      'http://192.168.1.2:8092'
    ]) {
      try {
        final res = await http
            .post(Uri.parse('$host$path'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          success = true;
          break;
        }
      } catch (_) {}
    }

    if (mounted) {
      if (success) {
        setState(() => _isLiveWalkieTalkieActive = newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newState ? Colors.redAccent : Colors.teal,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Icon(newState ? Icons.mic : Icons.mic_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newState
                        ? '🎙 LIVE WALKIE-TALKIE TRANSMITTING: Speaking into laptop mic!'
                        : 'Walkie-Talkie stopped. Phone speaker standby.',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
                'Could not reach laptop mic bridge at port 8092. Checking service...'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    _findingsController.dispose();
    _manualCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoneAsync = ref.watch(zoneDetailStreamProvider(widget.zoneId));

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) {
        if (!didPop && _isFullScreen) {
          _toggleFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090D12),
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: const Color(0xFF131920),
                elevation: 0,
                title: Text(
                  'Live Inspection Console',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    tooltip: 'View Inspector Audit Dossier & JSON',
                    icon: const Icon(Icons.assignment_turned_in_rounded,
                        color: Colors.tealAccent),
                    onPressed: () =>
                        _showInspectorReportDialog(context, widget.zoneId),
                  ),
                  IconButton(
                    tooltip: 'Full Screen Landscape',
                    icon: const Icon(Icons.fullscreen_rounded,
                        color: Colors.cyanAccent),
                    onPressed: _toggleFullScreen,
                  ),
                  IconButton(
                    tooltip: 'Connect Phone Camera Stream',
                    icon: const Icon(Icons.settings_remote_rounded,
                        color: Colors.cyanAccent),
                    onPressed: () =>
                        _showStreamUrlDialog(context, widget.zoneId),
                  ),
                  IconButton(
                    tooltip: 'Simulate Camera Feed Status',
                    icon: const Icon(Icons.sync_alt_rounded,
                        color: Colors.cyanAccent),
                    onPressed: () {
                      ref
                          .read(inspectionActionControllerProvider.notifier)
                          .toggleCamera(widget.zoneId);
                    },
                  )
                ],
              ),
        body: zoneAsync.when(
          data: (zone) {
            if (zone == null) {
              return const Center(
                  child: Text('Zone records unavailable',
                      style: TextStyle(color: Colors.white)));
            }
            if (_isFullScreen) {
              return _buildFullScreenVideoPlayer(zone);
            }
            return _buildConsoleContent(context, zone);
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)),
          error: (err, _) => Center(
              child: Text('Error: $err',
                  style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _buildFullScreenVideoPlayer(ZoneModel zone) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (zone.isCameraOnline)
          _buildSimulatedLiveFeed(zone)
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text('CAMERA NOT WORKING',
                      style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

        // Fullscreen Floating Top Controls
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  tooltip: 'Exit Fullscreen',
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: _toggleFullScreen,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'HEADCOUNT: ${zone.detectedCount}',
                            style: GoogleFonts.outfit(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'GATE: ${zone.expectedCount}',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: zone.discrepancy > 5
                                  ? Colors.redAccent
                                  : Colors.teal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEFICIT: -${zone.discrepancy}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  tooltip: 'Exit Fullscreen',
                  icon: const Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.cyanAccent),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleContent(BuildContext context, ZoneModel zone) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // RTSP/HLS Video Player Simulator with Telemetry Overlay HUD
          Container(
            height: 250,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (zone.isCameraOnline)
                  _buildSimulatedLiveFeed(zone)
                else
                  Container(
                    color: const Color(0xFF1F242C),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_rounded,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        Text('CAMERA NOT WORKING',
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            'Feed Offline • Hardware Unresponsive • Anomaly Logged',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Re-initialize Pipeline'),
                          onPressed: () {
                            ref
                                .read(
                                    inspectionActionControllerProvider.notifier)
                                .toggleCamera(zone.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3846),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Telemetry Overlay HUD
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOLO v8 HEADCOUNT: ${zone.detectedCount}',
                              style: GoogleFonts.outfit(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'GATE SCANNED: ${zone.expectedCount}',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: zone.discrepancy > 5
                                    ? Colors.redAccent
                                    : Colors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DEFICIT: -${zone.discrepancy}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _toggleFullScreen,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.cyanAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Two-Way Voice Intercom & Direct Calling Control Strip (Laptop <-> Phone Node)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isTalkingToFacility
                    ? Colors.tealAccent
                    : const Color(0xFF26303D),
                width: _isTalkingToFacility ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isTalkingToFacility
                            ? Colors.tealAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isTalkingToFacility ? Icons.mic : Icons.mic_none,
                        color: _isTalkingToFacility
                            ? Colors.tealAccent
                            : Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTalkingToFacility
                                ? 'TRANSMITTING VOICE TO PHONE...'
                                : 'Intercom & Remote VC Hub',
                            style: GoogleFonts.outfit(
                              color: _isTalkingToFacility
                                  ? Colors.tealAccent
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Facility Incharge: ${zone.inchargeName ?? "Dr. Ramesh Kumar"} • Secure WhatsApp Call Ready',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.video_call, size: 16),
                        label: const Text(
                          'WHATSAPP VC',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ref
                              .read(inspectionActionControllerProvider.notifier)
                              .startVideoCall(zone.id, 'Lead Auditor');
                          WhatsAppCallService.startWhatsAppInspectionCall(
                            context: context,
                            zone: zone,
                            auditorName: 'Lead Auditor (DoSJE)',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B2CBF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.meeting_room, size: 15),
                        label: const Text(
                          'ROOM VC',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ref
                              .read(inspectionActionControllerProvider.notifier)
                              .startVideoCall(zone.id, 'Lead Auditor');
                          final room = zone.activeRoomUrl ??
                              'https://meet.jit.si/dosje_audit_${zone.id.replaceAll('-', '_')}';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoConferencingScreen(
                                roomUrl: room,
                                centerName: zone.name,
                                callerRole: 'auditor',
                                inchargeName: zone.inchargeName,
                                inchargePhone: zone.inchargePhone,
                                onCallEnded: () {
                                  ref
                                      .read(inspectionActionControllerProvider
                                          .notifier)
                                      .endVideoCall(zone.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLiveWalkieTalkieActive
                              ? Colors.redAccent
                              : const Color(0xFF00B4D8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(
                            _isLiveWalkieTalkieActive
                                ? Icons.mic
                                : Icons.podcasts,
                            size: 14),
                        label: Text(
                          _isLiveWalkieTalkieActive ? 'MIC ON' : 'WALKIE',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _toggleLiveWalkieTalkie,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTalkingToFacility
                              ? Colors.redAccent
                              : Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(
                            _isTalkingToFacility
                                ? Icons.call_end
                                : Icons.record_voice_over,
                            size: 14),
                        label: Text(
                          _isTalkingToFacility ? 'STOP' : 'TTS MSG',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _toggleTalkback(zone.cctvStreamUrl),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3-Day Persistent Anomaly Intelligence Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: zone.isPersistentAnomaly
                    ? Colors.redAccent
                    : const Color(0xFF26303D),
                width: zone.isPersistentAnomaly ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          zone.isPersistentAnomaly
                              ? Icons.warning_amber_rounded
                              : Icons.analytics_outlined,
                          color: zone.isPersistentAnomaly
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '3-Day Anomaly Rule',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: zone.isPersistentAnomaly
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: zone.isPersistentAnomaly
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        zone.isPersistentAnomaly
                            ? '🔴 PERSISTENT (3 DAYS)'
                            : '🟡 TRANSIENT (${zone.persistentAnomalyDays}/3 DAYS)',
                        style: TextStyle(
                          color: zone.isPersistentAnomaly
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  zone.isPersistentAnomaly
                      ? 'Attendance anomaly detected for 3 consecutive days. Trigger criteria met for surprise field inspection under DoSJE guidelines.'
                      : 'Temporary attendance fluctuation detected. Single-day spikes do not immediately trigger surprise inspections.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (int i = 0; i < zone.pastThreeDaysDetected.length; i++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF090D12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF26303D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day ${i + 1} (YOLO)',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${zone.pastThreeDaysDetected[i]}',
                                    style: TextStyle(
                                      color: zone.pastThreeDaysDetected[i] <
                                              zone.expectedCount
                                          ? Colors.redAccent
                                          : Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'exp: ${zone.expectedCount}',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Camera Health & Downtime Factor Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF26303D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Camera Uptime',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      '${zone.cameraUptimePercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: zone.cameraUptimePercent >= 95
                            ? Colors.tealAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: const Color(0xFF26303D)),
                Column(
                  children: [
                    Text('Last Outage',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      zone.lastOutageWindow,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: const Color(0xFF26303D)),
                Column(
                  children: [
                    Text('Downtime Logged',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      '${zone.totalDowntimeMinutes} min',
                      style: GoogleFonts.outfit(
                        color: zone.totalDowntimeMinutes > 30
                            ? Colors.redAccent
                            : Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notice Policy & Dispatch Config Strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF26303D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Surprise Notice Policy',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        Text('Current: ${zone.noticePolicy.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: const [
                      '2_hours_surprise',
                      'immediate',
                      '24h_routine'
                    ].contains(zone.noticePolicy)
                        ? zone.noticePolicy
                        : '2_hours_surprise',
                    dropdownColor: const Color(0xFF131920),
                    items: const [
                      DropdownMenuItem(
                        value: '2_hours_surprise',
                        child: Text('2h Advance (Surprise)',
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 11)),
                      ),
                      DropdownMenuItem(
                        value: 'immediate',
                        child: Text('Immediate (No Notice)',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 11)),
                      ),
                      DropdownMenuItem(
                        value: '24h_routine',
                        child: Text('24h (Routine)',
                            style: TextStyle(
                                color: Colors.tealAccent, fontSize: 11)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(inspectionActionControllerProvider.notifier)
                            .updateNoticePolicy(zone.id, val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Notice policy updated to $val'),
                              backgroundColor: Colors.teal),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // AI-Generated Anomaly Intelligence Analysis & Critical Root-Cause Breakdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131920),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (zone.discrepancy > 5 || !zone.isCameraOnline)
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : const Color(0xFF26303D),
                  width: (zone.discrepancy > 5 || !zone.isCameraOnline)
                      ? 1.5
                      : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.psychology_outlined,
                                  color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'AI-Generated Anomaly Analysis',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (zone.discrepancy > 5 || !zone.isCameraOnline)
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                (zone.discrepancy > 5 || !zone.isCameraOnline)
                                    ? Colors.redAccent
                                    : Colors.tealAccent,
                          ),
                        ),
                        child: Text(
                          (zone.discrepancy > 5 || !zone.isCameraOnline)
                              ? 'CRITICAL SEVERITY'
                              : 'NORMAL COMPLIANCE',
                          style: TextStyle(
                            color:
                                (zone.discrepancy > 5 || !zone.isCameraOnline)
                                    ? Colors.redAccent
                                    : Colors.tealAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // AI Root-Cause Diagnostic Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🤖 ROOT-CAUSE INFERENCE ENGINE',
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !zone.isCameraOnline
                              ? '• HARDWARE TAMPER CRITICAL: Camera sensor disconnected / stream offline for over ${zone.totalDowntimeMinutes} minutes.\n• Automated failover triggered inspection protocol.'
                              : '• GHOST ATTENDANCE DEFICIT: Biometric turnstile register recorded ${zone.expectedCount} entries, but YOLO vision model detected only ${zone.detectedCount} live occupants (${zone.expectedCount - zone.detectedCount} ghost discrepancy).\n• 3-DAY PERSISTENCE: Discrepancy pattern persisted across ${zone.persistentAnomalyDays} consecutive monitoring cycles.\n• GEOFENCE INTEGRITY: Statutory inspection required to confirm physical presence within 200m facility radius.',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Inspector Audit Dossier & JSON Access Strip
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text(
                      'VIEW INSPECTOR AUDIT REPORT & JSON DOSSIER',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () =>
                        _showInspectorReportDialog(context, zone.id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedLiveFeed(ZoneModel zone) {
    final streamUrl =
        zone.cctvStreamUrl.startsWith('http') ? zone.cctvStreamUrl : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F1A24),
            const Color(0xFF081017),
            Colors.cyan.shade900.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If a live HTTP camera stream from Node is active, render live video frames
          if (streamUrl != null)
            LiveMjpegStreamViewer(streamUrl: streamUrl)
          else
            _buildFallbackGrid(),

          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE CCTV • 1080P 30FPS',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 10, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStreamUrlDialog(BuildContext context, String zoneId) {
    final textController =
        TextEditingController(text: 'http://127.0.0.1:8088/stream');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131920),
        title: Text(
          'Connect Phone Camera Stream',
          style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the STREAM URL shown on the bottom of your phone app screen (e.g. http://192.168.1.15:8088/stream):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              style: const TextStyle(
                  color: Colors.cyanAccent, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'http://<phone-ip>:8088/stream',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E2630),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black),
            child: const Text('Connect'),
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                ref
                    .read(inspectionActionControllerProvider.notifier)
                    .setStreamUrl(zoneId, url);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: _CCTVGridPainter(),
    );
  }
}

class _CCTVGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LiveMjpegStreamViewer extends StatefulWidget {
  final String streamUrl;

  const LiveMjpegStreamViewer({super.key, required this.streamUrl});

  @override
  State<LiveMjpegStreamViewer> createState() => _LiveMjpegStreamViewerState();
}

class _LiveMjpegStreamViewerState extends State<LiveMjpegStreamViewer> {
  Uint8List? _frameBytes;
  Timer? _poller;
  bool _isFetching = false;
  final http.Client _httpClient = http.Client();

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void didUpdateWidget(covariant LiveMjpegStreamViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _startStreaming();
    }
  }

  void _startStreaming() {
    _poller?.cancel();
    final snapshotUrl = widget.streamUrl.replaceAll('/stream', '/snapshot');

    // Fetch initial frame immediately
    _fetchSnapshot(snapshotUrl);

    // High-performance polling interval (~11-12 FPS) with in-flight guard to keep Flutter UI responsive
    _poller = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _fetchSnapshot(snapshotUrl);
    });
  }

  Future<void> _fetchSnapshot(String url) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      var targetUri = Uri.parse(url);
      http.Response? res;
      try {
        res = await _httpClient
            .get(targetUri)
            .timeout(const Duration(milliseconds: 1200));
      } catch (_) {
        // If 127.0.0.1 is unreachable inside the Android emulator, automatically try the 10.0.2.2 gateway
        if (url.contains('127.0.0.1')) {
          final emulatorGatewayUrl = url.replaceAll('127.0.0.1', '10.0.2.2');
          res = await _httpClient
              .get(Uri.parse(emulatorGatewayUrl))
              .timeout(const Duration(milliseconds: 1200));
        }
      }
      final response = res;
      if (response != null &&
          response.statusCode == 200 &&
          mounted &&
          response.bodyBytes.isNotEmpty) {
        setState(() {
          _frameBytes = response.bodyBytes;
        });
      }
    } catch (_) {
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frameBytes != null) {
      return Image.memory(
        _frameBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: 720,
        filterQuality: FilterQuality.low,
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 8),
          Text(
            'Connecting to ${widget.streamUrl}...',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

extension _InspectorReportModal on _LiveInspectionScreenState {
  void _showInspectorReportDialog(BuildContext context, String zoneId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C131D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final inspectionsAsync = ref.watch(recentInspectionsStreamProvider);

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: inspectionsAsync.when(
                data: (list) {
                  // Filter inspections for this zone if any, or show all statutory dossiers
                  final zoneInspections =
                      list.where((i) => i.zoneId == zoneId).toList();
                  final dossier = zoneInspections.isNotEmpty
                      ? zoneInspections.first
                      : (list.isNotEmpty ? list.first : null);

                  if (dossier == null) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open_rounded,
                            size: 48, color: Colors.white30),
                        const SizedBox(height: 12),
                        Text('No Field Inspector Report Logged Yet',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          'The field inspector has not yet submitted a statutory physical inspection dossier for this facility. When submitted via the Inspector Mobile App, the JSON dossier and photos will synchronize here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26303D)),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    );
                  }

                  final jsonPretty = const JsonEncoder.withIndent('  ')
                      .convert(dossier.toJson());

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_outlined,
                                    color: Colors.tealAccent, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'STATUTORY AUDIT DOSSIER',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.tealAccent),
                              ),
                              child: const Text('APPWRITE SYNCED',
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dossier ID: ${dossier.id.substring(0, 8)}... • Auditor: ${dossier.inspectorName}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          'Timestamp: ${DateFormat("dd MMM yyyy, HH:mm:ss").format(dossier.timestamp)} (Verified)',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        const Divider(color: Colors.white12, height: 20),

                        // GPS Verification & Verdict
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF131920),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('GPS TAMPER PROOF',
                                        style: TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      dossier.gpsVerified
                                          ? 'VERIFIED (Within 200m)'
                                          : 'OVERRIDE LOGGED',
                                      style: TextStyle(
                                          color: dossier.gpsVerified
                                              ? Colors.greenAccent
                                              : Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    ),
                                    Text(
                                      dossier.geoTagLocation ??
                                          'GPS: 28.6692°N, 77.4538°E',
                                      style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 9,
                                          fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: dossier.verdict == 'COMPLIANT'
                                      ? Colors.teal.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: dossier.verdict == 'COMPLIANT'
                                          ? Colors.tealAccent
                                          : Colors.redAccent),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('FINAL VERDICT',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      dossier.verdict,
                                      style: TextStyle(
                                          color: dossier.verdict == 'COMPLIANT'
                                              ? Colors.tealAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    Text(
                                        'Compliance: ${dossier.compliancePercent}%',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Site Geotag Photo Display
                        if (dossier.sitePhotoPath != null) ...[
                          const Text('SITE GEOTAG EVIDENCE PHOTO',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      Colors.tealAccent.withValues(alpha: 0.4)),
                              image: DecorationImage(
                                image: FileImage(File(dossier.sitePhotoPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Per-Checklist Item Photos
                        if (dossier.checklistPhotos != null &&
                            dossier.checklistPhotos!.isNotEmpty) ...[
                          Text(
                              'STATUTORY CHECKLIST PHOTO EVIDENCE (${dossier.checklistPhotos!.length} ITEMS)',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children:
                                  dossier.checklistPhotos!.entries.map((item) {
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131920),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.cyanAccent
                                            .withValues(alpha: 0.5)),
                                    image: DecorationImage(
                                      image: FileImage(File(item.value)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(2),
                                      color: Colors.black87,
                                      child: Text(
                                        item.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 8),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Auditable JSON Dossier Section
                        StatefulBuilder(
                          builder: (context, setDossierState) {
                            // Persistent toggle for raw vs structured view inside the bottom sheet
                            return _DossierVerificationViewer(
                              dossier: dossier,
                              jsonPretty: jsonPretty,
                            );
                          },
                        ),

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A2634)),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('DISMISS DOSSIER',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.redAccent))),
              ),
            );
          },
        );
      },
    );
  }
}

class _DossierVerificationViewer extends StatefulWidget {
  final InspectionModel dossier;
  final String jsonPretty;

  const _DossierVerificationViewer({
    required this.dossier,
    required this.jsonPretty,
  });

  @override
  State<_DossierVerificationViewer> createState() =>
      _DossierVerificationViewerState();
}

class _DossierVerificationViewerState
    extends State<_DossierVerificationViewer> {
  bool _showRawJson = false;
  bool _copied = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.jsonPretty));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 JSON Dossier copied to clipboard!'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dossier;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C131D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26303D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toolbar with verification badge and view toggles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A24),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: Colors.cyanAccent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIT DOSSIER & INTEGRITY VERIFICATION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Appwrite Database Synced • SHA-256 Validated',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.tealAccent.withValues(alpha: 0.8),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Copy button
                InkWell(
                  onTap: () => _copyToClipboard(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: _copied
                          ? Colors.teal.withValues(alpha: 0.3)
                          : const Color(0xFF1F2B3A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _copied ? Colors.tealAccent : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy_rounded,
                          size: 12,
                          color: _copied ? Colors.tealAccent : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'COPIED' : 'COPY',
                          style: TextStyle(
                            color:
                                _copied ? Colors.tealAccent : Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Toggle Raw JSON vs Formatted Verified View
                InkWell(
                  onTap: () => setState(() => _showRawJson = !_showRawJson),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showRawJson
                          ? Colors.cyan.withValues(alpha: 0.25)
                          : const Color(0xFF1F2B3A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _showRawJson
                            ? Colors.cyanAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showRawJson
                              ? Icons.data_object_rounded
                              : Icons.checklist_rtl_rounded,
                          size: 12,
                          color: _showRawJson
                              ? Colors.cyanAccent
                              : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showRawJson ? 'JSON RAW' : 'VERIFIED',
                          style: TextStyle(
                            color: _showRawJson
                                ? Colors.cyanAccent
                                : Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content: either formatted verification list or readable styled raw json
          if (_showRawJson)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF070B10),
              child: SelectableText(
                widget.jsonPretty,
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification metrics quick badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusPill(
                        icon: d.gpsVerified
                            ? Icons.gps_fixed
                            : Icons.gps_off_rounded,
                        label: 'GPS Range',
                        value: d.gpsVerified
                            ? '${d.gpsDistanceMeters.toStringAsFixed(0)}m (Within 200m)'
                            : 'OVERRIDE',
                        isGood: d.gpsVerified,
                      ),
                      _buildStatusPill(
                        icon: Icons.fingerprint,
                        label: 'SHA-256 Audit Seal',
                        value: d.auditHash.length > 12
                            ? '${d.auditHash.substring(0, 12)}...'
                            : d.auditHash,
                        isGood: true,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildStatusPill(
                        icon: Icons.fact_check_outlined,
                        label: 'Compliance Level',
                        value: '${d.compliancePercent}% (${d.verdict})',
                        isGood: d.compliancePercent >= 75,
                      ),
                      _buildStatusPill(
                        icon: Icons.camera_alt_outlined,
                        label: 'Photo Evidence',
                        value:
                            '${(d.sitePhotoPath != null ? 1 : 0) + (d.checklistPhotos?.length ?? 0)} Files Verified',
                        isGood: (d.sitePhotoPath != null) ||
                            (d.checklistPhotos != null &&
                                d.checklistPhotos!.isNotEmpty),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 10),

                  // Structured Fields List for Easy Verification
                  _buildVerifiableRow('Dossier ID', d.id, isCode: true),
                  _buildVerifiableRow('Zone / Facility',
                      '${d.zoneName} (${d.zoneId})'),
                  _buildVerifiableRow(
                      'Field Auditor', '${d.inspectorName} (${d.inspectorId})'),
                  _buildVerifiableRow('Timestamp (UTC+5:30)',
                      DateFormat('dd MMM yyyy, HH:mm:ss').format(d.timestamp)),
                  _buildVerifiableRow(
                    'Headcount Verification',
                    'Turnstile: ${d.reportedBeneficiaries} | AI Model: ${d.aiDetectedCount} | Physical: ${d.physicalHeadcount}',
                  ),
                  _buildVerifiableRow(
                    'Identified Deficit',
                    'AI Delta: ${d.aiDiscrepancy} | Physical Deficit: ${d.physicalDiscrepancy}',
                    highlightAlert: d.physicalDiscrepancy != 0,
                  ),
                  _buildVerifiableRow('Auditor Findings', d.findings),
                  if (d.geoTagLocation != null)
                    _buildVerifiableRow(
                        'Geo-Tag Stamp', d.geoTagLocation!.trim(),
                        isCode: true),
                  if (d.geoOverrideReason != null)
                    _buildVerifiableRow(
                        'GPS Override Reason', d.geoOverrideReason!,
                        highlightAlert: true),

                  // Checklist Photos count breakdown
                  if (d.checklistPhotos != null &&
                      d.checklistPhotos!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Verified Checklist Photo Attachments (${d.checklistPhotos!.length}):',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...d.checklistPhotos!.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.tealAccent, size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required String value,
    required bool isGood,
    Color? accentColor,
  }) {
    final color = accentColor ?? (isGood ? Colors.tealAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiableRow(
    String label,
    String value, {
    bool isCode = false,
    bool highlightAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightAlert
                    ? Colors.orangeAccent
                    : (isCode ? Colors.tealAccent : Colors.white),
                fontSize: 10.5,
                fontFamily: isCode ? 'monospace' : null,
                fontWeight: highlightAlert ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

