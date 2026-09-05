import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/zone_model.dart';
import '../providers/audit_providers.dart';

class LiveInspectionScreen extends ConsumerStatefulWidget {
  final String zoneId;

  const LiveInspectionScreen({super.key, required this.zoneId});

  @override
  ConsumerState<LiveInspectionScreen> createState() => _LiveInspectionScreenState();
}

class _LiveInspectionScreenState extends ConsumerState<LiveInspectionScreen>
    with SingleTickerProviderStateMixin {
  final _findingsController = TextEditingController();
  final _manualCountController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _findingsController.dispose();
    _manualCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoneAsync = ref.watch(zoneDetailStreamProvider(widget.zoneId));

    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131920),
        elevation: 0,
        title: Text(
          'Live Inspection Console',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Connect Phone Camera Stream',
            icon: const Icon(Icons.settings_remote_rounded, color: Colors.cyanAccent),
            onPressed: () => _showStreamUrlDialog(context, widget.zoneId),
          ),
          IconButton(
            tooltip: 'Simulate Camera Feed Status',
            icon: const Icon(Icons.sync_alt_rounded, color: Colors.cyanAccent),
            onPressed: () {
              ref.read(inspectionActionControllerProvider.notifier).toggleCamera(widget.zoneId);
            },
          )
        ],
      ),
      body: zoneAsync.when(
        data: (zone) {
          if (zone == null) {
            return const Center(child: Text('Zone records unavailable', style: TextStyle(color: Colors.white)));
          }
          return _buildConsoleContent(context, zone);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
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
                        const Icon(Icons.videocam_off_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        Text('CAMERA NOT WORKING',
                            style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Feed Offline • Hardware Unresponsive • Anomaly Logged',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Re-initialize Pipeline'),
                          onPressed: () {
                            ref
                                .read(inspectionActionControllerProvider.notifier)
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: zone.discrepancy > 5 ? Colors.redAccent : Colors.teal,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Audit Form
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Physical Audit Verification Form',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131920),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF26303D)),
                      ),
                      child: Text(
                        zone.floor,
                        style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manualCountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Manual Headcount Verified by Auditor',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.pin, color: Colors.cyanAccent),
                    hintText: 'e.g. ${zone.expectedCount}',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF131920),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF26303D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _findingsController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Auditor Observation & Field Findings',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.notes, color: Colors.cyanAccent),
                    hintText: 'e.g. Turnstile tailgating observed near entry point...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF131920),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF26303D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Verify & Clear Discrepancy Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final manualCount = int.tryParse(_manualCountController.text) ?? zone.detectedCount;
                    await ref.read(inspectionActionControllerProvider.notifier).submitInspectionLog(
                          zoneId: zone.id,
                          findings: _findingsController.text.isNotEmpty
                              ? _findingsController.text
                              : 'Manual audit performed. Counts reconciled.',
                          manualCountVerified: manualCount,
                          status: 'resolved',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Discrepancy verified and marked resolved.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.notification_important_outlined, color: Colors.redAccent),
                  label: const Text('Trigger Urgent Authority Escalation', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await ref.read(inspectionActionControllerProvider.notifier).triggerManualEscalation(
                          zone.id,
                          _findingsController.text.isNotEmpty
                              ? _findingsController.text
                              : 'Immediate physical discrepancy detected by field auditor.',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Discrepancy escalated to Police and Security dispatch.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSimulatedLiveFeed(ZoneModel zone) {
    final streamUrl = zone.cctvStreamUrl.startsWith('http') ? zone.cctvStreamUrl : null;

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

          // Live YOLO bounding box indicators
          Positioned(
            top: 70,
            left: 40,
            child: Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 1.5),
                color: Colors.greenAccent.withOpacity(0.08),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Text(' person 0.94', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 140,
            child: Container(
              width: 75,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 1.5),
                color: Colors.greenAccent.withOpacity(0.08),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Text(' person 0.91', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
              ),
            ),
          ),
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
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStreamUrlDialog(BuildContext context, String zoneId) {
    final textController = TextEditingController(text: 'http://127.0.0.1:8088/stream');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131920),
        title: Text(
          'Connect Phone Camera Stream',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'http://<phone-ip>:8088/stream',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E2630),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text('Connect'),
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                ref.read(inspectionActionControllerProvider.notifier).setStreamUrl(zoneId, url);
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
  bool _isLoading = true;

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

    // Continuous smooth frame polling at ~15-20 fps
    _poller = Timer.periodic(const Duration(milliseconds: 65), (_) {
      _fetchSnapshot(snapshotUrl);
    });
  }

  Future<void> _fetchSnapshot(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 500));
      if (res.statusCode == 200 && mounted && res.bodyBytes.isNotEmpty) {
        setState(() {
          _frameBytes = res.bodyBytes;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frameBytes != null) {
      return Image.memory(
        _frameBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
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
