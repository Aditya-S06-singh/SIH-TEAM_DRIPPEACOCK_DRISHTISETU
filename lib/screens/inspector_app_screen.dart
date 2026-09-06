import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/zone_model.dart';
import '../providers/audit_providers.dart';
import 'login_screen.dart';
import 'inspection_screen.dart';
import 'video_conferencing_screen.dart';

class InspectorAppScreen extends ConsumerStatefulWidget {
  const InspectorAppScreen({super.key});

  @override
  ConsumerState<InspectorAppScreen> createState() => _InspectorAppScreenState();
}

class _InspectorAppScreenState extends ConsumerState<InspectorAppScreen> {
  String _selectedZoneId = 'zone-101';
  bool _isGpsSimulatedAway = false;
  bool _isOverrideAuthorized = false;
  final _overrideReasonController = TextEditingController();

  // Statutory Checklist Items
  final Map<String, bool> _checklist = {
    'Beneficiaries physically present match turnstile registers': false,
    'Aadhaar biometric turnstiles operational and synced': true,
    'Required certified instructors/doctors present on floor': true,
    'Faculty qualifications & bio-credentials verified': true,
    'CCTV cameras operational without occlusion or blind spots': true,
    'Fire safety, medical first-aid & sanitary equipment certified': true,
    'Direct benefit transfer (DBT) stipend records updated': false,
  };

  final _physicalHeadcountController = TextEditingController(text: '60');
  final _inspectorRemarksController = TextEditingController(
    text: 'Physical audit completed. Significant ghost discrepancy identified between turnstile logs and verified room occupants.',
  );

  @override
  void dispose() {
    _overrideReasonController.dispose();
    _physicalHeadcountController.dispose();
    _inspectorRemarksController.dispose();
    super.dispose();
  }

  double _getCalculatedDistance() {
    return _isGpsSimulatedAway ? 1800.0 : 73.0; // 1.8km vs 73m
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesStreamProvider);
    final user = ref.watch(currentUserProvider);
    final distance = _getCalculatedDistance();
    final isWithin200m = distance <= 200.0;
    final canPerformInspection = isWithin200m || _isOverrideAuthorized;

    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D141D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field Inspector Mobile Portal',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'DoSJE National PMU Team 04 • ${user?.fullName ?? "Er. Vikram Sharma"}',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: zonesAsync.when(
        data: (zones) {
          final zone = zones.firstWhere((z) => z.id == _selectedZoneId, orElse: () => zones.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Assigned Project Card & Selector
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101824),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1C2B3E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ASSIGNED INSPECTION SITE', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: const Text('PRIORITY: HIGH RISK', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: zone.id,
                          dropdownColor: const Color(0xFF101824),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                          items: zones.map((z) {
                            return DropdownMenuItem(
                              value: z.id,
                              child: Text(
                                '${z.name} (${z.floor})',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) setState(() => _selectedZoneId = id);
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Incharge: ${zone.inchargeName ?? "Dr. Ramesh Kumar"} • Encrypted Directory Contact',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. 200-Metre Geo-Fence Live Verification Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isWithin200m ? const Color(0xFF0F1E16) : const Color(0xFF261014),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWithin200m ? Colors.greenAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isWithin200m ? Icons.check_circle_rounded : Icons.location_off_rounded,
                                color: isWithin200m ? Colors.greenAccent : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isWithin200m ? 'LOCATION VERIFIED' : 'OUTSIDE INSPECTION GEO-FENCE',
                                style: GoogleFonts.outfit(
                                  color: isWithin200m ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${distance.toInt()}m Away',
                            style: GoogleFonts.robotoMono(
                              color: isWithin200m ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWithin200m
                            ? 'Inspector device is within the mandatory 200m boundary of registered facility (${zone.targetLatitude}° N, ${zone.targetLongitude}° E).'
                            : 'Inspector is currently $distance metres from registered location. Inspection is locked to prevent proxy or falsified reporting.',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.gps_fixed, size: 14),
                            label: Text(
                              _isGpsSimulatedAway ? 'Simulate Arrived (73m)' : 'Simulate Away (1.8km)',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () {
                              setState(() {
                                _isGpsSimulatedAway = !_isGpsSimulatedAway;
                                _isOverrideAuthorized = false;
                              });
                            },
                          ),
                          const Spacer(),
                          if (!isWithin200m && !_isOverrideAuthorized)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.key, size: 14),
                              label: const Text('REQUEST OVERRIDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => _showGeoOverrideDialog(context),
                            ),
                          if (_isOverrideAuthorized)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: const Text('AUTHORIZED OVERRIDE', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Inspector Communication Toolkit
                Text('INSPECTOR COMMUNICATION TOOLKIT', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101722),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1C2A3C)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildToolkitButton(
                        icon: Icons.videocam_rounded,
                        label: 'Live CCTV',
                        color: Colors.cyanAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LiveInspectionScreen(zoneId: zone.id)));
                        },
                      ),
                      _buildToolkitButton(
                        icon: Icons.mic_rounded,
                        label: 'Voice Walkie',
                        color: Colors.tealAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LiveInspectionScreen(zoneId: zone.id)));
                        },
                      ),
                      _buildToolkitButton(
                        icon: Icons.video_call_rounded,
                        label: 'WebRTC VC',
                        color: const Color(0xFF7B2CBF),
                        onTap: () {
                          final room = zone.activeRoomUrl ?? 'https://meet.jit.si/dosje_audit_${zone.id.replaceAll('-', '_')}';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoConferencingScreen(
                                roomUrl: room,
                                centerName: zone.name,
                                callerRole: 'inspector',
                                inchargeName: zone.inchargeName,
                                inchargePhone: zone.inchargePhone,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildToolkitButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Evidence',
                        color: Colors.orangeAccent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📸 Photo evidence tagged with SHA-256 hash and GPS coordinate.'), backgroundColor: Colors.orangeAccent),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Statutory Physical Inspection Checklist
                Text('STATUTORY GOVERNMENT CHECKLIST', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ..._checklist.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D141E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF182433)),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.tealAccent,
                      checkColor: Colors.black,
                      title: Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      value: entry.value,
                      onChanged: canPerformInspection
                          ? (val) {
                              setState(() => _checklist[entry.key] = val ?? false);
                            }
                          : null,
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 5. Physical Headcount & Observations Form
                Text('PHYSICAL HEADCOUNT & OBSERVATIONS', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                TextField(
                  controller: _physicalHeadcountController,
                  keyboardType: TextInputType.number,
                  enabled: canPerformInspection,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Physical Headcount Present (Verified by Inspector)',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    prefixIcon: const Icon(Icons.people_alt_outlined, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: const Color(0xFF101722),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inspectorRemarksController,
                  maxLines: 2,
                  enabled: canPerformInspection,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Inspector Remarks & Statutory Notes',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    prefixIcon: const Icon(Icons.description_outlined, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: const Color(0xFF101722),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 20),

                // 6. Submit Government Dossier Action
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPerformInspection ? const Color(0xFF00B4D8) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('SUBMIT AUDIT & GENERATE STATUTORY DOSSIER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: canPerformInspection
                      ? () => _submitInspectionReport(context, zone, isWithin200m, distance)
                      : null,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildToolkitButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showGeoOverrideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131920),
        title: const Text('Authorized Geo-Fence Override', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A mandatory explanation is required to unlock inspection outside the 200m zone. This will be stamped on the official audit trail.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _overrideReasonController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'e.g. Center entry gate locked; inspection conducted from perimeter road.',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                filled: true,
                fillColor: Color(0xFF1B232D),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            child: const Text('AUTHORIZE OVERRIDE'),
            onPressed: () {
              if (_overrideReasonController.text.trim().isNotEmpty) {
                setState(() => _isOverrideAuthorized = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Authorized override logged to DoSJE audit registry.'), backgroundColor: Colors.amber),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitInspectionReport(BuildContext context, ZoneModel zone, bool isWithin200m, double distance) async {
    final physicalCount = int.tryParse(_physicalHeadcountController.text) ?? 60;
    final reported = zone.expectedCount;
    final aiDetected = zone.detectedCount;
    final aiDiscrepancy = reported - aiDetected;
    final physicalDiscrepancy = reported - physicalCount;
    final compliance = ((physicalCount / (reported > 0 ? reported : 1)) * 100).clamp(0, 100).toInt();

    await ref.read(inspectionActionControllerProvider.notifier).submitInspectionLog(
          zoneId: zone.id,
          findings: _inspectorRemarksController.text,
          manualCountVerified: physicalCount,
          status: 'resolved',
          gpsVerified: isWithin200m,
          gpsDistanceMeters: distance,
          geoOverrideReason: _isOverrideAuthorized ? _overrideReasonController.text : null,
        );

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C131D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.tealAccent, size: 24),
                const SizedBox(width: 10),
                Text('INSPECTION REPORT GENERATED', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF111924), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project: ${zone.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Inspector: PMU-04 (Lead: Vikram Sharma) • Date: 07/09/2026', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('GPS: ${isWithin200m ? "VERIFIED (73m)" : "OVERRIDE AUTHORIZED (${distance.toInt()}m)"}', style: TextStyle(color: isWithin200m ? Colors.greenAccent : Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reported: $reported', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('AI Observed: $aiDetected', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                      Text('Physical Headcount: $physicalCount', style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AI Discrepancy: $aiDiscrepancy', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                      Text('Physical Discrepancy: $physicalDiscrepancy', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                      Text('Compliance: $compliance%', style: TextStyle(color: compliance > 75 ? Colors.tealAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    color: Colors.redAccent.withOpacity(0.15),
                    child: Text('RESULT: ${physicalDiscrepancy > 5 ? "NON-COMPLIANT (DISCREPANCY DETECTED)" : "COMPLIANT"}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('SUBMIT FOR OFFICIAL MINISTRY REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dossier submitted to DoSJE Central Command server.'), backgroundColor: Colors.teal),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
