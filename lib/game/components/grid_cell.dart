import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'draggable_card_component.dart';

class GridCell extends PositionComponent {
  final int index;
  DraggableCardComponent? occupant;
  bool _highlight = false;

  GridCell({required this.index, required Vector2 position})
      : super(position: position, size: Vector2.all(70));

  bool get isEmpty => occupant == null;
  void setHighlight(bool v) => _highlight = v;

  bool tryAccept(DraggableCardComponent card) {
    if (!isEmpty) return false;
    occupant = card;
    card.snapToCell(this);
    _highlight = false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    final bg = Paint()
      ..color = _highlight
          ? AppColors.cellHighlight.withOpacity(0.25)
          : Colors.white.withOpacity(0.7);

    const r = Radius.circular(10);
    final rRect = RRect.fromLTRBR(2, 2, 68, 68, r);
    canvas.drawRRect(rRect, bg);

    // Dashed border
    final dashPaint = Paint()
      ..color = _highlight ? AppColors.cellHighlight : AppColors.cellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedRRect(canvas, dashPaint, rRect);
  }

  void _drawDashedRRect(Canvas c, Paint p, RRect rr) {
    const dash = 7.0, gap = 5.0;
    final path = Path()..addRRect(rr);
    bool draw = true;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final len = draw ? dash : gap;
        if (draw) c.drawPath(m.extractPath(d, d + len), p);
        d += len; draw = !draw;
      }
    }
  }
}