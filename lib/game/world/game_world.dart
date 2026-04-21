import 'package:flame/components.dart';
import '../components/grid_cell.dart';
import '../components/hand_row.dart';
import '../../domain/entities/card_entity.dart';

class GameWorld extends World {
  static const int    cols      = 4;
  static const int    rows      = 4;
  static const double cellSize  = 72;
  static const double cellGap   = 6;
  static const double gridLeft  = 12;
  static const double gridTop   = 12;

  final List<GridCell> cells = [];

  @override
  Future<void> onLoad() async {
    // Build 4×4 grid
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final index = row * cols + col;
        final cell = GridCell(
          index: index,
          position: Vector2(
            gridLeft + col * (cellSize + cellGap),
            gridTop  + row * (cellSize + cellGap),
          ),
        );
        cells.add(cell);
        await add(cell);
      }
    }

    // Sample hand (replace with real data from BLoC)
    final mockHand = List.generate(
      7,
      (i) => CardEntity(
        id: 'card_$i',
        name: 'Momon $i',
        imageAsset: 'assets/images/cards/card_$i.png',
        power: (i + 1) * 10,
      ),
    );

    await add(HandRow(cards: mockHand, cells: cells));
  }
}