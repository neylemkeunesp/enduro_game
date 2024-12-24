import 'dart:math';
import 'package:flutter/material.dart';

class DashboardPainter extends CustomPainter {
  final double speed;
  final int distance;
  final int level;

  DashboardPainter({
    required this.speed,
    required this.distance,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw dashboard background
    final backgroundPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw game title
    final titleText = TextPainter(
      text: TextSpan(
        text: 'ENDURO',
        style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    titleText.layout(minWidth: size.width);
    titleText.paint(
      canvas,
      Offset((size.width - titleText.width) / 2, 20),
    );

    // Draw speedometer background
    final speedometerBg = Paint()
      ..color = Colors.grey[850]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy + 20),
      radius * 0.8,
      speedometerBg,
    );

    // Draw metallic rim
    final rimPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      Offset(center.dx, center.dy + 20),
      radius * 0.8,
      rimPaint,
    );

    // Draw speed markings
    final markingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final speedCenter = Offset(center.dx, center.dy + 20);
    for (int i = 0; i <= 300; i += 30) {
      final angle = (i / 300) * pi * 1.5 - (pi * 0.75);
      final markerStart = Offset(
        speedCenter.dx + cos(angle) * (radius * 0.7),
        speedCenter.dy + sin(angle) * (radius * 0.7),
      );
      final markerEnd = Offset(
        speedCenter.dx + cos(angle) * (radius * 0.8),
        speedCenter.dy + sin(angle) * (radius * 0.8),
      );
      canvas.drawLine(markerStart, markerEnd, markingPaint);

      // Draw speed numbers
      if (i % 60 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final numberPos = Offset(
          speedCenter.dx + cos(angle) * (radius * 0.55) - textPainter.width / 2,
          speedCenter.dy + sin(angle) * (radius * 0.55) - textPainter.height / 2,
        );
        textPainter.paint(canvas, numberPos);
      }
    }

    // Draw speed needle
    final needleAngle = (speed / 300) * pi * 1.5 - (pi * 0.75);
    final needlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      speedCenter,
      Offset(
        speedCenter.dx + cos(needleAngle) * (radius * 0.65),
        speedCenter.dy + sin(needleAngle) * (radius * 0.65),
      ),
      needlePaint,
    );

    // Draw needle center
    final centerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(speedCenter, 5, centerPaint);

    // Draw odometer
    final odometerRect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.85,
      size.width * 0.6,
      size.height * 0.1,
    );
    final odometerBg = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(odometerRect, odometerBg);

    // Draw odometer border
    final odometerBorder = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(odometerRect, odometerBorder);

    // Draw distance text
    final distanceText = TextPainter(
      text: TextSpan(
        text: '${distance.toString().padLeft(6, '0')} km',
        style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    distanceText.layout(minWidth: odometerRect.width);
    distanceText.paint(
      canvas,
      Offset(odometerRect.left, odometerRect.center.dy - distanceText.height / 2),
    );

    // Draw "KM/H" text
    final speedText = TextPainter(
      text: TextSpan(
        text: 'KM/H',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    speedText.layout();
    speedText.paint(
      canvas,
      Offset(
        speedCenter.dx - speedText.width / 2,
        speedCenter.dy + radius * 0.3,
      ),
    );

    // Draw level indicator
    final levelText = TextPainter(
      text: TextSpan(
        text: 'LEVEL $level',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    levelText.layout();
    levelText.paint(
      canvas,
      Offset(
        size.width - levelText.width - 10,
        10,
      ),
    );
  }

  @override
  bool shouldRepaint(DashboardPainter oldDelegate) =>
      oldDelegate.speed != speed ||
      oldDelegate.distance != distance ||
      oldDelegate.level != level;
}
