import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/zone_model.dart';
import '../providers/audit_providers.dart';
import 'inspection_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesStreamProvider);
    final selectedZoneId = ref.watch(selectedZoneProvider);
    final criticalAlertsCount = ref.watch(criticalAlertsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131920),
        elevation: 0,
        title: zonesAsync.when(
          data: (zones) {
            if (zones.isEmpty) {
              return const Text('No Zones Configured',
                  style: TextStyle(fontSize: 15));
            }
            final currentZoneId = selectedZoneId ?? zones.first.id;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2630),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF333E4D)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: zones.any((z) => z.id == currentZoneId)
                        ? currentZoneId
                        : zones.first.id,
                    dropdownColor: const Color(0xFF1F2630),
                    isDense: true,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.cyanAccent),
                    items: zones.map((zone) {
                      return DropdownMenuItem<String>(
                        value: zone.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: zone.discrepancy > 5
                                  ? Colors.redAccent
                                  : Colors.cyanAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${zone.name} (${zone.floor})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        ref.read(selectedZoneProvider.notifier).state = newId;
                      }
                    },
                  ),
                ),
              ),
            );
          },
          loading: () => const Text('Loading audit zones...'),
          error: (_, __) => const Text('Error loading zones'),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white70, size: 26),
                onPressed: () {
                  _showAlertsBottomSheet(context, ref);
                },
              ),
              if (criticalAlertsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$criticalAlertsCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: selectedZoneId == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : ref.watch(zoneDetailStreamProvider(selectedZoneId)).when(
                data: (zone) {
                  if (zone == null) {
                    return const Center(
                        child: Text('Zone data not found',
                            style: TextStyle(color: Colors.white)));
                  }
                  return _buildDashboardContent(context, zone, ref);
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent)),
                error: (err, _) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, ZoneModel zone, WidgetRef ref) {
    final isCritical = zone.discrepancy > 5;
    final deficitVal = -zone.discrepancy;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SURVEILLANCE TELEMETRY',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Synced: ${DateFormat('HH:mm:ss').format(zone.lastAuditTimestamp)}',
                      style: GoogleFonts.inter(
                          color: Colors.cyanAccent.shade200, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2x2 Responsive Metric Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Card 1: Critical Discrepancy Metric
                        _buildMetricCard(
                          width: itemWidth,
                          height: 185,
                          bgColor: isCritical
                              ? const Color(0xFF330C12)
                              : const Color(0xFF131920),
                          borderColor: isCritical
                              ? Colors.redAccent
                              : const Color(0xFF26303D),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCritical
                                      ? Colors.redAccent
                                      : Colors.teal.shade700,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCritical
                                              ? Colors.redAccent
                                              : Colors.teal)
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  deficitVal == 0 ? '0' : '$deficitVal',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'HEADCOUNT DEFICIT',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gate: ${zone.expectedCount}  |  Camera: ${zone.detectedCount}',
                                style: GoogleFonts.inter(
                                  color: isCritical
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Card 2: Camera Health Indicator
                        _buildMetricCard(
                          width: itemWidth,
                          height: 185,
                          bgColor: const Color(0xFF131920),
                          borderColor: zone.isCameraOnline
                              ? const Color(0xFF26303D)
                              : Colors.redAccent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                zone.isCameraOnline
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                size: 40,
                                color: zone.isCameraOnline
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                zone.isCameraOnline
                                    ? 'FEED ONLINE'
                                    : 'FEED OFFLINE',
                                style: GoogleFonts.outfit(
                                  color: zone.isCameraOnline
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                zone.isCameraOnline
                                    ? 'Ping: 12ms | Drops: 0%'
                                    : 'No Signal Received',
                                style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RTSP H.265 HW-Dec',
                                style: GoogleFonts.inter(
                                    color: Colors.white24, fontSize: 9),
                              ),
                            ],
                          ),
                        ),

                        // Card 3: Anomaly Classification & Severity Rate
                        _buildMetricCard(
                          width: itemWidth,
                          height: 185,
                          bgColor: const Color(0xFF131920),
                          borderColor: const Color(0xFF26303D),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : Colors.cyanAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCritical
                                        ? Colors.redAccent
                                        : Colors.cyanAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isCritical
                                      ? 'GHOST ATTENDANCE'
                                      : (zone.discrepancy > 0
                                          ? 'DEFICIT HIGH'
                                          : 'OPTIMAL SYNC'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: isCritical
                                        ? Colors.redAccent
                                        : Colors.cyanAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Anomaly Risk Index',
                                style: GoogleFonts.inter(
                                    color: Colors.white60, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCritical
                                    ? 'CRITICAL (9.4/10)'
                                    : 'STABLE (0.5/10)',
                                style: GoogleFonts.outfit(
                                  color: isCritical
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Card 4: Action / Live Inspection
                        _buildMetricCard(
                          width: itemWidth,
                          height: 185,
                          bgColor: const Color(0xFF131920),
                          borderColor: Colors.cyanAccent.withOpacity(0.4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  color: Colors.cyanAccent, size: 36),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: 135,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LiveInspectionScreen(
                                            zoneId: zone.id),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent.shade700,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Live Inspection',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Audit Status Banner
                if (zone.escalated)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Zone escalated to Police & Authority Dispatch due to unresolved attendance deficit.',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom Expandable Sheet
        _buildAllZonesBottomSheet(context),
      ],
    );
  }

  Widget _buildMetricCard({
    required double width,
    required double height,
    required Color bgColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAllZonesBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.70,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131920),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 16)],
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final zonesAsync = ref.watch(zonesStreamProvider);
              return ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show All Monitored Zones',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_up_rounded,
                          color: Colors.cyanAccent),
                    ],
                  ),
                  const Divider(color: Color(0xFF26303D), height: 18),
                  zonesAsync.when(
                    data: (zones) => Column(
                      children: zones.map((z) {
                        Color statusColor = Colors.greenAccent;
                        if (z.discrepancy > 5) {
                          statusColor = Colors.redAccent;
                        } else if (z.discrepancy > 0) {
                          statusColor = Colors.amberAccent;
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${z.name} (${z.floor})',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Gate: ${z.expectedCount} | YOLO: ${z.detectedCount} | Deficit: ${z.expectedCount - z.detectedCount}',
                            style: GoogleFonts.inter(
                                color: Colors.white60, fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              border: Border.all(color: statusColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              z.severity.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            ref.read(selectedZoneProvider.notifier).state =
                                z.id;
                          },
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent),
                    ),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAlertsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131920),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final alerts = ref.watch(criticalAlertsStreamProvider);
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unacknowledged Anomaly Alerts',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: alerts.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return const Center(
                            child: Text('No unacknowledged alerts.',
                                style: TextStyle(color: Colors.white54)),
                          );
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Color(0xFF26303D)),
                          itemBuilder: (c, idx) {
                            final alert = list[idx];
                            return ListTile(
                              leading: const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent),
                              title: Text(alert.zoneName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              subtitle: Text(
                                '${alert.type.replaceAll('_', ' ').toUpperCase()} • ${DateFormat('HH:mm').format(alert.timestamp)}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              trailing: TextButton(
                                child: const Text('Clear',
                                    style: TextStyle(color: Colors.cyanAccent)),
                                onPressed: () {
                                  ref
                                      .read(inspectionActionControllerProvider
                                          .notifier)
                                      .acknowledgeAlert(alert.id);
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent)),
                      error: (e, _) =>
                          Text('$e', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
