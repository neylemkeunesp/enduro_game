import 'package:flutter/material.dart';

class RoadPainter extends CustomPainter {
  final double laneWidth;
  final bool animate;
  final double speed;
  static double _offset = 0;

  RoadPainter({
    required this.laneWidth,
    required this.animate,
    required this.speed,
  }) {
    if (animate) {
      _offset = (_offset + speed * 0.01) % 40;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Define the vanishing point (above the horizon)
    final vanishingPoint = Offset(size.width / 2, -size.height * 0.5);

    // Draw continuous road edge lines
    for (var i = 0; i < 2; i++) {
      final startX = i == 0 ? 0 : laneWidth * 3;  // Left and right edges (total road width = 3 lanes)
      double y = 0;
      
      // Draw a continuous line from top to bottom
      final startPerspective = _calculatePerspective(y, size.height);
      final endPerspective = _calculatePerspective(size.height, size.height);
      
      final startXWithPerspective = vanishingPoint.dx + (startX - vanishingPoint.dx) * startPerspective;
      final endXWithPerspective = vanishingPoint.dx + (startX - vanishingPoint.dx) * endPerspective;
      
      paint.strokeWidth = 3;  // Slightly thicker for edge lines
      canvas.drawLine(
        Offset(startXWithPerspective, y),
        Offset(endXWithPerspective, size.height),
        paint,
      );
    }

    // Draw lane markers with enhanced perspective
    for (var i = 1; i < 3; i++) {
      final startX = laneWidth * i;
      double startY = -20 + _offset;

      while (startY < size.height) {
        final endY = startY + 15;

        // Calculate perspective with exponential falloff
        final perspectiveStart = _calculatePerspective(startY, size.height);
        final perspectiveEnd = _calculatePerspective(endY, size.height);
        
        // Apply perspective to x-coordinates
        final endXStart = vanishingPoint.dx + (startX - vanishingPoint.dx) * perspectiveStart;
        final endXEnd = vanishingPoint.dx + (startX - vanishingPoint.dx) * perspectiveEnd;

        // Adjust line width based on perspective
        paint.strokeWidth = 2 * perspectiveStart;

        canvas.drawLine(
          Offset(endXStart, startY),
          Offset(endXEnd, endY),
          paint,
        );
        startY += 30;
      }
    }
  }

  @override
  double _calculatePerspective(double y, double screenHeight) {
    // Normalize y to a 0-1 range (top = 0, bottom = 1)
    double normalizedY = y / screenHeight;
    // Apply exponential curve for more dramatic perspective
    return 0.1 + (0.9 * normalizedY * normalizedY); // Starts at 0.1 at top, increases to 1.0 at bottom
  }

  @override
  bool shouldRepaint(RoadPainter oldDelegate) =>
      animate || oldDelegate.laneWidth != laneWidth;
}
