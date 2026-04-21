import 'package:flutter/material.dart';
import 'dart:math';

class BubblyBackground extends StatelessWidget {
  final Widget child;
  const BubblyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF0D47A1), Color(0xFF00838F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      const _BubblesPainter(),
      child,
    ]);
  }
}

class _BubblesPainter extends StatelessWidget {
  const _BubblesPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainterImpl(),
      child: const SizedBox.expand(),
    );
  }
}

class _BubblePainterImpl extends CustomPainter {
  final _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.07);
    for (int i = 0; i < 22; i++) {
      final r = _rng.nextDouble() * 60 + 10;
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}