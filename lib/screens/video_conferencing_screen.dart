import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/whatsapp_call_service.dart';

class VideoConferencingScreen extends StatefulWidget {
  final String roomUrl;
  final String centerName;
  final String callerRole;
  final String? inchargeName;
  final String? inchargePhone;
  final VoidCallback? onCallEnded;

  const VideoConferencingScreen({
    super.key,
    required this.roomUrl,
    required this.centerName,
    required this.callerRole,
    this.inchargeName,
    this.inchargePhone,
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
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isConnecting = false);
    });
  }

  Future<void> _launchExternalRoom() async {
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
            content: Text('Room URL: ${widget.roomUrl}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetPhone = widget.inchargePhone ?? '+919876543210';
    final targetName = widget.inchargeName ?? 'Site Incharge';

    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Main Remote Participant View / Virtual Room Canvas
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F1722),
                    Color(0xFF0A1017),
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
                            'Initializing Secure Inspection Stream...',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF131F2E),
                                border: Border.all(color: const Color(0xFF25D366), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF25D366).withOpacity(0.35),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                size: 54,
                                color: Color(0xFF25D366),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              targetName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Encrypted Gov Directory • Protected ID',
                              style: GoogleFonts.robotoMono(
                                color: const Color(0xFF25D366),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified DoSJE Facility Incharge',
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Prominent WhatsApp Action Card
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101B14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF25D366).withOpacity(0.1),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '1-Tap WhatsApp Inspection Call',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Instantly dispatches surprise video inspection notice & launches WhatsApp video dialer.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.video_call_rounded, size: 22),
                                    label: Text(
                                      'START WHATSAPP VIDEO CALL',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    onPressed: () {
                                      WhatsAppCallService.startWhatsAppVideoCall(
                                        context: context,
                                        phoneNumber: targetPhone,
                                        inchargeName: targetName,
                                        centerName: widget.centerName,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                            if (widget.roomUrl.isNotEmpty)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white54,
                                ),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Secondary WebRTC Room Link', style: TextStyle(fontSize: 11)),
                                onPressed: _launchExternalRoom,
                              ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
              ),
            ),

            // 2. Picture-in-Picture Self Preview (Front Camera Simulation)
            Positioned(
              top: 70,
              right: 16,
              child: Container(
                width: 95,
                height: 130,
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
                                    size: 28,
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
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () {
                        widget.onCallEnded?.call();
                        Navigator.pop(context);
                      },
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
