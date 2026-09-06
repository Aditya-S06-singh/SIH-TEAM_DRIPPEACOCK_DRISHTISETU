import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/zone_model.dart';

class WhatsAppCallService {
  /// Opens WhatsApp chat with the Site Incharge, pre-filling an official surprise inspection notice.
  /// The user can then tap the WhatsApp Video icon in 1 tap to ring the Site Incharge.
  static Future<bool> startWhatsAppInspectionCall({
    required BuildContext context,
    required ZoneModel zone,
    String auditorName = 'Lead Auditor',
  }) async {
    final rawPhone = zone.inchargePhone ?? '+919876543210';
    final inchargeName = zone.inchargeName ?? 'Site Incharge';

    final message = '''*🚨 URGENT: DoSJE Surprise Inspection Notice*
*Auditor:* $auditorName
*Monitored Zone:* ${zone.name} (${zone.floor})
*Live Discrepancy:* ${zone.discrepancy} (Enrolled: ${zone.expectedCount}, AI Cam: ${zone.detectedCount})

Please answer the incoming WhatsApp video call immediately for physical site verification.''';

    return _launchWhatsApp(
      context: context,
      rawPhone: rawPhone,
      inchargeName: inchargeName,
      message: message,
    );
  }

  /// Direct 1-tap call helper with raw phone and name
  static Future<bool> startWhatsAppVideoCall({
    required BuildContext context,
    required String phoneNumber,
    required String inchargeName,
    required String centerName,
  }) async {
    final message = '''*🚨 URGENT: DoSJE Surprise Inspection Video Call*
*Facility:* $centerName
*Incharge:* $inchargeName

Incoming DoSJE Video Audit. Please answer the incoming WhatsApp video call immediately for live inspection.''';

    return _launchWhatsApp(
      context: context,
      rawPhone: phoneNumber,
      inchargeName: inchargeName,
      message: message,
    );
  }

  static Future<bool> _launchWhatsApp({
    required BuildContext context,
    required String rawPhone,
    required String inchargeName,
    required String message,
  }) async {
    // Strip all non-numeric characters for WhatsApp deep links
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = Uri.encodeComponent(message);

    // Primary: WhatsApp URI scheme
    final whatsappSchemeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage');
    // Fallback: Web/Universal API link
    final waMeUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappSchemeUri)) {
        return await launchUrl(whatsappSchemeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waMeUri)) {
        return await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WhatsApp is not installed on this device.\nTarget: $inchargeName ($rawPhone)',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text('Could not launch WhatsApp: $e'),
          ),
        );
      }
      return false;
    }
  }
}
