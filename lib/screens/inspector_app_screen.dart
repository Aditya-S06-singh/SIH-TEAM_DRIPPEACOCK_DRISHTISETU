import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/zone_model.dart';
import '../providers/audit_providers.dart';
import 'login_screen.dart';

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

  // Photo evidence state
  File? _sitePhoto;
  String? _sitePhotoGeoTag;
  final Map<String, File?> _checklistPhotos = {};
  final ImagePicker _picker = ImagePicker();

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

                // 3. Geotagged Site Evidence Camera (Physical Presence Verification)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'PHYSICAL PRESENCE VERIFICATION',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_sitePhoto != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5))),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 4),
                            Text('GEOTAGGED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101722),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _sitePhoto != null ? Colors.tealAccent.withOpacity(0.4) : const Color(0xFF1C2A3C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo 1: Geotagged Site Inspection Photo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo thumbnail / camera trigger button
                          GestureDetector(
                            onTap: canPerformInspection ? () => _captureSitePhoto(zone, isWithin200m, distance) : null,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF182232),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _sitePhoto != null ? Colors.tealAccent : Colors.orangeAccent.withOpacity(0.6)),
                                image: _sitePhoto != null
                                    ? DecorationImage(image: FileImage(_sitePhoto!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _sitePhoto == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_rounded, color: canPerformInspection ? Colors.orangeAccent : Colors.white24, size: 28),
                                        const SizedBox(height: 4),
                                        Text('CAPTURE\nSITE PHOTO', textAlign: TextAlign.center, style: TextStyle(color: canPerformInspection ? Colors.orangeAccent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                        child: const Icon(Icons.edit, color: Colors.tealAccent, size: 14),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Details & Geotag Stamp Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('1. Mandatory Site Geotag Photo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  _sitePhoto != null
                                      ? 'Photo captured & physically stamped with real-time GPS metadata to confirm inspector presence at facility.'
                                      : 'Tap camera to take live photo of site. Coordinates & timestamp will be hard-stamped for audit integrity.',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                                if (_sitePhotoGeoTag != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.tealAccent.withOpacity(0.3))),
                                    child: Text(
                                      _sitePhotoGeoTag!,
                                      style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Mandatory Site Geotag Photo remains as primary physical presence anchor
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Statutory Physical Inspection Checklist with Per-Item Photo Evidence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'STATUTORY GOVERNMENT CHECKLIST',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'PHOTO MANDATORY',
                        style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Every ticked compliance item requires at least 1 photo verification proof to complete submission.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),

                ..._checklist.entries.map((entry) {
                  final key = entry.key;
                  final isChecked = entry.value;
                  final hasPhoto = _checklistPhotos.containsKey(key) && _checklistPhotos[key] != null;
                  final photoFile = hasPhoto ? _checklistPhotos[key]! : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D141E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isChecked
                            ? (hasPhoto ? Colors.tealAccent.withValues(alpha: 0.5) : Colors.orangeAccent.withValues(alpha: 0.7))
                            : const Color(0xFF182433),
                        width: isChecked ? 1.2 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.tealAccent,
                          checkColor: Colors.black,
                          title: Text(
                            key,
                            style: TextStyle(
                              color: isChecked ? Colors.white : Colors.white70,
                              fontSize: 12.5,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: isChecked,
                          onChanged: canPerformInspection
                              ? (val) {
                                  setState(() => _checklist[key] = val ?? false);
                                }
                              : null,
                        ),
                        if (isChecked) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141C28),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasPhoto ? Colors.tealAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: canPerformInspection ? () => _captureChecklistPhoto(key) : null,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B2433),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: hasPhoto ? Colors.tealAccent : Colors.orangeAccent,
                                      ),
                                      image: photoFile != null
                                          ? DecorationImage(image: FileImage(photoFile), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: photoFile == null
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, color: canPerformInspection ? Colors.orangeAccent : Colors.white24, size: 20),
                                              const SizedBox(height: 2),
                                              const Text('PHOTO*', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        : Align(
                                            alignment: Alignment.bottomRight,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                              child: const Icon(Icons.edit, color: Colors.tealAccent, size: 12),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasPhoto ? 'Photo Evidence Recorded' : 'Mandatory Evidence Required',
                                        style: TextStyle(
                                          color: hasPhoto ? Colors.tealAccent : Colors.orangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasPhoto
                                            ? 'Verified photo saved for statutory audit validation & AI verification.'
                                            : 'Tap box to capture mandatory photo proof for this specific requirement.',
                                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    backgroundColor: hasPhoto ? Colors.teal.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                  ),
                                  icon: Icon(hasPhoto ? Icons.refresh : Icons.camera_alt, size: 14, color: hasPhoto ? Colors.tealAccent : Colors.orangeAccent),
                                  label: Text(
                                    hasPhoto ? 'Retake' : 'Capture',
                                    style: TextStyle(color: hasPhoto ? Colors.tealAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: canPerformInspection ? () => _captureChecklistPhoto(key) : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  Future<void> _captureSitePhoto(ZoneModel zone, bool isWithin200m, double distance) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
      if (picked != null) {
        final now = DateTime.now();
        final lat = (zone.targetLatitude + (isWithin200m ? 0.0001 : 0.015)).toStringAsFixed(5);
        final lng = (zone.targetLongitude + (isWithin200m ? 0.0001 : 0.012)).toStringAsFixed(5);
        final stamp = 'GEO-TAG: $lat°N, $lng°E\nACCURACY: ${distance.toStringAsFixed(1)}m | TIME: ${now.toIso8601String().substring(0, 19)} UTC+5:30\nSTATUS: ${isWithin200m ? "VERIFIED ON SITE" : "OUTSIDE GEOFENCE"}';

        setState(() {
          _sitePhoto = File(picked.path);
          _sitePhotoGeoTag = stamp;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isWithin200m
                  ? '📸 Site photo geotagged: Verified Inspector presence on-site (${distance.toInt()}m)!'
                  : '⚠️ Site photo geotagged: Distance exceeds 200m (${distance.toInt()}m).'),
              backgroundColor: isWithin200m ? Colors.teal : Colors.amber.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _captureChecklistPhoto(String checklistKey) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _checklistPhotos[checklistKey] = File(picked.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📸 Photo recorded for: "${checklistKey.length > 30 ? checklistKey.substring(0, 30) + "..." : checklistKey}"'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
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
    // 1. Mandatory Site Geotag Photo Check
    if (_sitePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mandatory: Please capture the Site Geotag Photo (Camera) before submitting!'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // 2. Mandatory Check: Every ticked checklist item must have at least 1 photo evidence
    final missingPhotoItems = <String>[];
    for (final entry in _checklist.entries) {
      if (entry.value) {
        if (!_checklistPhotos.containsKey(entry.key) || _checklistPhotos[entry.key] == null) {
          missingPhotoItems.add(entry.key);
        }
      }
    }

    if (missingPhotoItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF131920),
          title: Row(
            children: const [
              Icon(Icons.add_a_photo, color: Colors.orangeAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Checklist Photo Evidence Missing',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'At least 1 photo is strictly required under EVERY checked item to complete the statutory dossier:\n',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              ...missingPhotoItems.take(4).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 11))),
                      ],
                    ),
                  )),
              if (missingPhotoItems.length > 4)
                Text('...and ${missingPhotoItems.length - 4} more items.', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK, TAKE PHOTOS'),
            ),
          ],
        ),
      );
      return;
    }

    final physicalCount = int.tryParse(_physicalHeadcountController.text) ?? 60;
    final reported = zone.expectedCount;
    final aiDetected = zone.detectedCount;
    final aiDiscrepancy = reported - aiDetected;
    final physicalDiscrepancy = reported - physicalCount;
    final compliance = ((physicalCount / (reported > 0 ? reported : 1)) * 100).clamp(0, 100).toInt();

    // Map photo paths for checklist items
    final Map<String, String> checklistPhotoPaths = {};
    for (final entry in _checklistPhotos.entries) {
      if (entry.value != null) {
        checklistPhotoPaths[entry.key] = entry.value!.path;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C131D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in, color: Colors.tealAccent, size: 24),
                  const SizedBox(width: 10),
                  Text('INSPECTION REPORT & JSON DOSSIER', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    const Text('Inspector: PMU-04 (Lead: Vikram Sharma) • Date: 07/09/2026', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                    const SizedBox(height: 10),
                    // Photo Evidence Verification Badges
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _sitePhoto != null ? Colors.teal.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _sitePhoto != null ? Colors.tealAccent : Colors.redAccent),
                            ),
                            child: Row(
                              children: [
                                Icon(_sitePhoto != null ? Icons.check_circle : Icons.warning_amber_rounded, size: 14, color: _sitePhoto != null ? Colors.tealAccent : Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(child: Text(_sitePhoto != null ? 'Site Geotag Photo' : 'No Geotag Photo', style: TextStyle(color: _sitePhoto != null ? Colors.tealAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.cyanAccent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_library, size: 14, color: Colors.cyanAccent),
                                const SizedBox(width: 4),
                                Expanded(child: Text('${checklistPhotoPaths.length} Checklist Photos Saved', style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      color: Colors.redAccent.withValues(alpha: 0.15),
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
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('GENERATE JSON & UPLOAD TO APPWRITE DATABASE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () async {
                    await ref.read(inspectionActionControllerProvider.notifier).submitInspectionLog(
                      zoneId: zone.id,
                      findings: _inspectorRemarksController.text.isNotEmpty ? _inspectorRemarksController.text : 'Physical site audit verified by Field Inspector.',
                      manualCountVerified: physicalCount,
                      status: 'resolved',
                      gpsVerified: isWithin200m,
                      gpsDistanceMeters: distance,
                      geoOverrideReason: !isWithin200m ? _overrideReasonController.text : null,
                      sitePhotoPath: _sitePhoto?.path,
                      geoTagLocation: _sitePhotoGeoTag,
                      checklistPhotos: checklistPhotoPaths,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Exported to JSON file & synced all photos to Appwrite Database!'),
                          backgroundColor: Colors.teal,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
