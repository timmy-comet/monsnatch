import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';
import 'grid_cell.dart';

class DraggableCardComponent extends PositionComponent with DragCallbacks {
  final CardEntity        card;
  final List<GridCell>   cells;
  final VoidCallback?     onPlaced;

  Vector2    _origin    = Vector2.zero();
  bool       _dragging  = false;
  GridCell?  _hovered;

  // Sprite loaded lazily
  Sprite? _sprite;

  static const double _w = 58, _h = 80;

  DraggableCardComponent({
    required this.card,
    required this.cells,
    required Vector2 position,
    this.onPlaced,
  }) : super(position: position, size: Vector2(_w, _h));

  @override
  Future<void> onLoad() async {
    try {
      _sprite = await Sprite.load(card.imageAsset);
    } catch (_) {
      // fallback: render placeholder rectangle
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    _origin   = position.clone();
    _dragging = true;
    priority  = 20;
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    final center = position + size / 2;
    GridCell? next;
    for (final cell in cells) {
      if (cell.isEmpty && cell.toRect().contains(center.toOffset())) {
        next = cell; break;
      }
    }
    if (next != _hovered) {
      _hovered?.setHighlight(false);
      _hovered = next;
      _hovered?.setHighlight(true);
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _dragging = false;
    priority  = 0;
    _hovered?.setHighlight(false);

    final center = position + size / 2;
    bool placed = false;
    for (final cell in cells) {
      if (cell.isEmpty && cell.toRect().contains(center.toOffset())) {
        placed = cell.tryAccept(this);
        if (placed) { onPlaced?.call(); break; }
      }
    }
    if (!placed) position.setFrom(_origin);
    _hovered = null;
    super.onDragEnd(event);
  }

  void snapToCell(GridCell cell) {
    position.setFrom(cell.position + (Vector2(70, 70) - size) / 2);
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromLTRBR(0, 0, _w, _h, const Radius.circular(9));

    // Shadow when dragging
    if (_dragging) {
      canvas.drawRRect(
        RRect.fromLTRBR(3, 5, _w + 3, _h + 5, const Radius.circular(9)),
        Paint()..color = const Color(0x44000000),
      );
    }

    // Card face
    if (_sprite != null) {
      // Clip to rounded rect, then draw sprite
      canvas.save();
      canvas.clipRRect(rrect);
      _sprite!.render(canvas, size: Vector2(_w, _h));
      canvas.restore();
    } else {
      // Fallback: white card with name
      canvas.drawRRect(rrect, Paint()..color = Colors.white);
      final tp = TextPaint(
        style: const TextStyle(fontSize: 9, color: AppColors.primaryText),
      );
      tp.render(canvas, card.name, Vector2(_w / 2, _h / 2), anchor: Anchor.center);
    }

    // Rounded border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.cellBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // TODO: Faction badge (★ or 🌙) computed from room.createdBy vs cell.ownerUid
    // Moved to presentation layer for clean separation
  }
}