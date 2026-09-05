import 'package:flutter/material.dart';
import '../models/detection_models.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBox> boxes;
  final bool isDeficitCritical;

  BoundingBoxPainter({
    required this.boxes,
    required this.isDeficitCritical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    final boxPaint = Paint()
      ..color = const Color(0xFF00FFA6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF00FFA6).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(
      color: Color(0xFF00FFA6),
      fontSize: 10,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );

    for (final box in boxes) {
      final rect = Rect.fromLTRB(
        box.rect.left * size.width,
        box.rect.top * size.height,
        box.rect.right * size.width,
        box.rect.bottom * size.height,
      );

      // Draw bounding box & translucent fill
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);

      // Draw label & confidence tag inside corner
      final textSpan = TextSpan(
        text: '${box.label} ${box.confidence.toStringAsFixed(2)}',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final tagOffset = Offset(rect.left + 4, rect.top + 4);
      textPainter.paint(canvas, tagOffset);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes || oldDelegate.isDeficitCritical != isDeficitCritical;
  }
}
