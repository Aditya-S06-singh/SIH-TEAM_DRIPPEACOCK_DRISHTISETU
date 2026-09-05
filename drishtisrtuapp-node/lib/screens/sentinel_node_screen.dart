import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/detection_models.dart';
import '../services/vision_pipeline_service.dart';
import '../services/local_stream_server.dart';
import '../widgets/bounding_box_painter.dart';

class SentinelNodeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SentinelNodeScreen({super.key, required this.cameras});

  @override
  State<SentinelNodeScreen> createState() => _SentinelNodeScreenState();
}

class _SentinelNodeScreenState extends State<SentinelNodeScreen> {
  CameraController? _cameraController;
  final VisionPipelineService _pipeline = VisionPipelineService();
  final LocalStreamServer _streamServer = LocalStreamServer();
  bool _isCameraReady = false;
  bool _isFaceLoginMode = false;
  String? _lastAttendeeLog;
  String? _streamUrl;

  @override
  void initState() {
    super.initState();
    _startStreamingServer();
    _initializeCamera();
    _pipeline.startInferencePipeline();
  }

  Future<void> _startStreamingServer() async {
    final url = await _streamServer.start();
    if (mounted) setState(() => _streamUrl = url);
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    try {
      final controller = CameraController(
        widget.cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      if (mounted) {
        setState(() => _isCameraReady = controller.value.isInitialized);
        _startFrameStreamingLoop();
      }
    } catch (e) {
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  Timer? _frameStreamTimer;
  bool _isCapturingFrame = false;

  void _startFrameStreamingLoop() {
    _frameStreamTimer?.cancel();
    // Capture and push frame every 500ms to avoid camera locking
    _frameStreamTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isCameraReady || _cameraController == null || _isCapturingFrame) return;
      if (!mounted) return;
      try {
        _isCapturingFrame = true;
        final xFile = await _cameraController!.takePicture();
        final bytes = await xFile.readAsBytes();
        _streamServer.updateFrame(bytes);
      } catch (_) {
      } finally {
        _isCapturingFrame = false;
      }
    });
  }

  @override
  void dispose() {
    _frameStreamTimer?.cancel();
    _streamServer.stop();
    _cameraController?.dispose();
    _pipeline.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometricGateLogin() async {
    setState(() => _isFaceLoginMode = true);
    final record = await _pipeline.processFaceLogin();
    if (mounted) {
      setState(() {
        _lastAttendeeLog = 'LOGGED: ${record.name} (${record.personId})';
        _isFaceLoginMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF131920),
          content: Text(
            '✓ DeepFace Verified: ${record.name} (Gate count: ${_pipeline.gateExpectedCount})',
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = _pipeline.deficit > 5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Hardware Camera Feed or Ultra-lean Cyber Grid Background
          if (_isCameraReady && _cameraController != null)
            ClipRect(
              child: SizedOverflowBox(
                size: MediaQuery.of(context).size,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                    height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            _buildSimulationBackground(),

          // 2. Real-Time YOLO11n Bounding Box Overlay
          StreamBuilder<List<BoundingBox>>(
            stream: _pipeline.boxesStream,
            initialData: const [],
            builder: (context, snapshot) {
              return CustomPaint(
                painter: BoundingBoxPainter(
                  boxes: snapshot.data ?? [],
                  isDeficitCritical: isCritical,
                ),
              );
            },
          ),

          // 3. Ultra-Minimal HUD (Top Status Bar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _buildMinimalTopHUD(isCritical),
          ),

          // 4. Biometric Face Match Status / Notification
          if (_lastAttendeeLog != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 74,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                ),
                child: Text(
                  _lastAttendeeLog!,
                  style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // 5. Minimal Quick-Action & Telemetry Bottom Bar
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              top: false,
              child: _buildMinimalBottomControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTopHUD(bool isCritical) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090D12).withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'YOLO11n HEADCOUNT: ${_pipeline.detectedHeadcount}',
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'GATE SCANNED: ${_pipeline.gateExpectedCount}',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCritical ? Colors.redAccent : const Color(0xFF009688),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'DEFICIT: ${_pipeline.deficit == 0 ? '-0' : '-${_pipeline.deficit}'}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top sub-row: Camera status & Stream URL badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.80),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
              Expanded(
                child: Text(
                  _streamUrl != null ? 'STREAM: $_streamUrl' : 'LIVE CCTV • 1080P 30FPS',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _streamUrl != null ? Colors.cyanAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Bottom sub-row: Simulation and Scan controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Simulate Person Exit (Headcount -1)',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.person_remove_outlined, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _pipeline.adjustCounts(detected: _pipeline.detectedHeadcount - 1);
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Simulate Person Entry (Headcount +1)',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _pipeline.adjustCounts(detected: _pipeline.detectedHeadcount + 1);
                    });
                  },
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: _isFaceLoginMode
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.face_retouching_natural, size: 16),
              label: Text(
                'SCAN FACE',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: _isFaceLoginMode ? null : _triggerBiometricGateLogin,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimulationBackground() {
    return Container(
      color: const Color(0xFF061017),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GridLinesPainter(),
          ),
        ],
      ),
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D2533)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
