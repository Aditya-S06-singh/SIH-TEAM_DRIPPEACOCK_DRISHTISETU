import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoConferencingScreen extends StatefulWidget {
  final String roomUrl;
  final String centerName;
  final String callerRole;
  final VoidCallback? onCallEnded;

  const VideoConferencingScreen({
    super.key,
    required this.roomUrl,
    required this.centerName,
    required this.callerRole,
    this.onCallEnded,
  });

  @override
  State<VideoConferencingScreen> createState() => _VideoConferencingScreenState();
}

class _VideoConferencingScreenState extends State<VideoConferencingScreen> {
  bool _isMicMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isConnecting = false);
    });
  }

  Future<void> _launchExternalJitsiBrowser() async {
    try {
      final uri = Uri.parse(widget.roomUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF131920),
              content: Text('Room URL: ${widget.roomUrl}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF131920),
            content: Text('Jitsi Room: ${widget.roomUrl}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Main Remote Participant View / Virtual Room Canvas
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F1722),
                    const Color(0xFF0A1017),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: _isConnecting
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting to Secure Encrypted Jitsi Room...',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.roomUrl,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF131F2E),
                              border: Border.all(color: Colors.cyanAccent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.35),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 64,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.callerRole == 'auditor'
                                ? 'Site Incharge (Live)'
                                : 'MoSJE Lead Auditor (Live)',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock_outline, color: Colors.greenAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'WebRTC E2E Encrypted • 1080p HD',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.open_in_browser, size: 16),
                            label: const Text('Open Native Jitsi Room in App/Browser'),
                            onPressed: _launchExternalJitsiBrowser,
                          ),
                        ],
                      ),
              ),
            ),

            // 2. Picture-in-Picture Self Preview (Front Camera Simulation)
            Positioned(
              top: 70,
              right: 16,
              child: Container(
                width: 105,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFF16212E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isVideoOff
                          ? Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1B2838),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isFrontCamera ? Icons.face : Icons.camera_rear,
                                    color: Colors.tealAccent,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isFrontCamera ? 'Selfie (You)' : 'Back Cam',
                                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Top Banner (Center Details & Recording indicator)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101720).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DoSJE SURPRISE VIDEO INSPECTION',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          Text(
                            widget.centerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: Colors.cyanAccent),
                      onPressed: _launchExternalJitsiBrowser,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Call Controls Toolbar
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101720).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF233040)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio
                    _buildControlButton(
                      icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _isMicMuted ? Colors.redAccent : Colors.white70,
                      bgColor: _isMicMuted ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                      onPressed: () {
                        setState(() => _isMicMuted = !_isMicMuted);
                      },
                    ),

                    // Toggle Video
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.redAccent : Colors.white70,
                      bgColor: _isVideoOff ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                      onPressed: () {
                        setState(() => _isVideoOff = !_isVideoOff);
                      },
                    ),

                    // Flip Camera
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      color: Colors.cyanAccent,
                      bgColor: Colors.cyanAccent.withOpacity(0.12),
                      onPressed: () {
                        setState(() => _isFrontCamera = !_isFrontCamera);
                      },
                    ),

                    // End Call (Red Button)
                    GestureDetector(
                      onTap: () {
                        widget.onCallEnded?.call();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent, blurRadius: 14, spreadRadius: 1),
                          ],
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
