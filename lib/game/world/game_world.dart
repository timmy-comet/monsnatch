import 'package:flame/components.dart';
import '../components/grid_cell.dart';
import '../components/hand_row.dart';
import '../../domain/entities/card_entity.dart';

class GameWorld extends World {
  static const double cellSize = 70;
  static const double cellGap  = 7;
  static const double gridLeft = 14;
  static const double gridTop  = 10;

  final List<GridCell> cells = [];

  @override
  Future<void> onLoad() async {
    // 4×4 grid
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final cell = GridCell(
          index:    row * 4 + col,
          position: Vector2(
            gridLeft + col * (cellSize + cellGap),
            gridTop  + row * (cellSize + cellGap),
          ),
        );
        cells.add(cell);
        await add(cell);
      }
    }

    // 7-card hand using Card.png for all
    final hand = List.generate(7, (i) => CardEntity(
      id:         i + 1,
      name:       'Momon ${i + 1}',
      element:    i % 2 == 0 ? 'fire' : 'water',
      power:      (i + 1) * 10,
      directions: ['t', 'tr', 'r', 'br', 'b', 'bl', 'l', 'tl'],
    ));

    await add(HandRow(cards: hand, cells: cells));
  }
}