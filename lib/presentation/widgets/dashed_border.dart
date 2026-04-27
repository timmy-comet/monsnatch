import 'package:flutter/material.dart';

/// Rounded-rect container outlined with a dashed stroke. Used for empty
/// board cells in the game UI. Ported from `fix-config-game-page` so the
/// look stays consistent.
class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color  borderColor;
  final double borderWidth;
  final double radius;
  final double dashLength;
  final double gapLength;
  final Color? backgroundColor;

  const DashedBorderBox({
    super.key,
    required this.child,
    this.borderColor = Colors.black,
    this.borderWidth = 1.5,
    this.radius      = 12,
    this.dashLength  = 4,
    this.gapLength   = 4,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color:       borderColor,
        strokeWidth: borderWidth,
        radius:      radius,
        dashLength:  dashLength,
        gapLength:   gapLength,
      ),
      child: Container(
        decoration: BoxDecoration(
          color:        backgroundColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color  color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path  = Path()..addRRect(rrect);
    final paint = Paint()
      ..color       = color
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double d = 0;
      bool   draw = true;
      while (d < metric.length) {
        final next = (d + (draw ? dashLength : gapLength))
            .clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(d, next), paint);
        d    = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color       != color       ||
      old.strokeWidth != strokeWidth ||
      old.radius      != radius      ||
      old.dashLength  != dashLength  ||
      old.gapLength   != gapLength;
}
