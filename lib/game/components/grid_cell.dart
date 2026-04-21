import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'draggable_card.dart';

class GridCell extends PositionComponent {
  final int index;
  DraggableCard? occupant;
  bool _isHighlighted = false;

  static const double _size = 72;

  GridCell({required this.index, required Vector2 position})
      : super(position: position, size: Vector2.all(_size));

  bool get isEmpty => occupant == null;

  void highlight(bool v) { _isHighlighted = v; }

  bool acceptDrop(DraggableCard card) {
    if (!isEmpty) return false;
    occupant = card;
    card.snapTo(this);
    _isHighlighted = false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = _isHighlighted
          ? const Color(0x556A1B9A)
          : const Color(0x22000000)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = _isHighlighted
          ? const Color(0xFF6A1B9A)
          : const Color(0xFFAAAAAA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isHighlighted ? 2.5 : 1.5;

    // Dashed border via path effect isn't available in Flame Canvas — we draw short dashes manually
    final rect = RRect.fromLTRBR(2, 2, _size - 2, _size - 2, const Radius.circular(10));
    canvas.drawRRect(rect, paint);

    const dashLen = 8.0, gap = 6.0;
    final dashPaint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;
    _drawDashedRect(canvas, dashPaint, 2, 2, _size - 4, _size - 4, dashLen, gap, 10);
  }

  void _drawDashedRect(Canvas c, Paint p, double x, double y,
      double w, double h, double dashLen, double gap, double r) {
    double drawn = 0;
    bool drawing = true;
    final path = Path()
      ..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)));
    for (final metric in path.computeMetrics()) {
      drawn = 0;
      drawing = true;
      while (drawn < metric.length) {
        final len = drawing ? dashLen : gap;
        if (drawing) {
          c.drawPath(metric.extractPath(drawn, drawn + len), p);
        }
        drawn += len;
        drawing = !drawing;
      }
    }
  }
}