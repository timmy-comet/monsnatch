import 'package:flame/components.dart';
import '../../domain/entities/card_entity.dart';
import 'draggable_card_component.dart';
import 'grid_cell.dart';

class HandRow extends PositionComponent {
  static const double _gameHeight = 600;  // Adjust based on actual viewport
  static const double _cardW = 58.0;
  static const double _gap = 10.0;
  static const double _startX = 10.0;
  static const double _bottomOffset = 96.0;
  
  final List<CardEntity> cards;
  final List<GridCell>  cells;

  HandRow({required this.cards, required this.cells});

  @override
  Future<void> onLoad() async {
    // Position cards at the bottom of the game view
    const screenH = _gameHeight - _bottomOffset;

    for (int i = 0; i < cards.length; i++) {
      await add(DraggableCardComponent(
        card:     cards[i],
        cells:    cells,
        position: Vector2(_startX + i * (_cardW + _gap), screenH),
      ));
    }
  }
}