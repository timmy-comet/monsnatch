import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/card_entity.dart';
import 'grid_cell.dart';

class DraggableCard extends PositionComponent with DragCallbacks {
  final CardEntity card;
  final List<GridCell> cells;

  Vector2 _originalPos = Vector2.zero();
  bool _isDragging = false;
  GridCell? _hoveredCell;

  static const double _w = 60, _h = 84;

  DraggableCard({required this.card, required this.cells, required Vector2 position})
      : super(position: position, size: Vector2(_w, _h));

  @override
  void onDragStart(DragStartEvent event) {
    _originalPos = position.clone();
    _isDragging = true;
    priority = 10; // Lift above grid cells
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    // Highlight nearest empty cell
    final center = position + size / 2;
    for (final cell in cells) {
      final inBounds = cell.toRect().contains(center.toOffset());
      if (inBounds && cell.isEmpty) {
        if (_hoveredCell != cell) { _hoveredCell?.highlight(false); _hoveredCell = cell; cell.highlight(true); }
      }
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _isDragging = false;
    priority = 0;
    _hoveredCell?.highlight(false);

    final center = position + size / 2;
    bool placed = false;
    for (final cell in cells) {
      if (cell.toRect().contains(center.toOffset()) && cell.isEmpty) {
        placed = cell.acceptDrop(this);
        break;
      }
    }
    if (!placed) position.setFrom(_originalPos); // snap back
    _hoveredCell = null;
    super.onDragEnd(event);
  }

  void snapTo(GridCell cell) {
    position.setFrom(cell.position + (Vector2(72, 72) - size) / 2);
  }

  @override
  void render(Canvas canvas) {
    final cardPaint = Paint()..color = const Color(0xFFFFFFFF);
    final shadow = Paint()..color = const Color(0x33000000);
    if (_isDragging) canvas.drawRRect(RRect.fromLTRBR(2, 4, _w + 2, _h + 4, const Radius.circular(8)), shadow);
    canvas.drawRRect(RRect.fromLTRBR(0, 0, _w, _h, const Radius.circular(8)), cardPaint);

    // Card name label
    final tp = TextPaint(style: const TextStyle(fontSize: 9, color: Colors.black87));
    tp.render(canvas, card.name, Vector2(_w / 2, _h - 12), anchor: Anchor.center);

    // Power badge
    final badge = Paint()..color = const Color(0xFF6A1B9A);
    canvas.drawCircle(Offset(_w - 10, 10), 9, badge);
    final pw = TextPaint(style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold));
    pw.render(canvas, '${card.power}', Vector2(_w - 10, 10), anchor: Anchor.center);
  }
}