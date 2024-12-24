import 'package:flutter/material.dart';

class EnduroCar extends StatelessWidget {
  final bool isPlayer;
  final double screenPosition; // 0.0 = top, 1.0 = bottom

  const EnduroCar({
    super.key,
    required this.isPlayer,
    required this.screenPosition,
  });

  double _calculateScale(double position) {
    // Use quadratic scaling for more dramatic size change
    // Start at 0.4 at top, go up to 1.2 at bottom for larger appearance
    return 0.4 + (0.8 * position * position);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _calculateScale(screenPosition);
    // Define base dimensions with larger base size
    final baseWidth = 80.0;
    final baseHeight = 120.0;

    return SizedBox(
      width: baseWidth * scale,
      height: baseHeight * scale,
      child: Transform.rotate(
        angle: isPlayer ? 0 : 0, // No rotation needed for enemy cars
        child: Image.asset(
          isPlayer ? 'assets/images/player_car.png' : 'assets/images/enemy_car.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
