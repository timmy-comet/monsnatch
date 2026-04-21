import 'package:flame/components.dart';
import '../../domain/entities/card_entity.dart';
import 'draggable_card.dart';
import 'grid_cell.dart';

class HandRow extends PositionComponent {
  final List<CardEntity> cards;
  final List<GridCell> cells;

  HandRow({required this.cards, required this.cells});

  @override
  Future<void> onLoad() async {
    const cardW = 60.0, cardGap = 8.0;
    // Get screen height from parent game instance
    final screenHeight = (parent as HasGameRef).gameRef.size.y;
    for (int i = 0; i < cards.length; i++) {
      await add(DraggableCard(
        card: cards[i],
        cells: cells,
        position: Vector2(i * (cardW + cardGap) + 8, screenHeight - 100),
      ));
    }
  }
}