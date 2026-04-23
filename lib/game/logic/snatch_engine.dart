import '../../domain/entities/faction.dart';
import '../../domain/entities/grid_slot.dart';
import '../../domain/entities/mon_card.dart';
import '../../domain/entities/snatch_direction.dart';
import '../../domain/entities/card_keyword.dart';
import 'element_chart.dart';

class SnatchResult {
  final List<GridSlot> grid;
  final List<int>     flippedIndices; // for flip animation triggers
  const SnatchResult({required this.grid, required this.flippedIndices});
}

class SnatchEngine {

  /// Place [card] at [placedIndex] for [faction] and resolve all snatches.
  static SnatchResult resolve({
    required List<GridSlot> grid,
    required int            placedIndex,
    required MonCard        card,
    required Faction        faction,
  }) {
    final newGrid = List<GridSlot>.from(grid);

    // Place the card
    newGrid[placedIndex] = GridSlot(
      index:           placedIndex,
      card:            card,
      ownerFaction:    faction,
      originalFaction: faction,
    );

    final flipped = <int>[];
    _performSnatch(newGrid, placedIndex, card, faction, flipped, depth: 0);

    return SnatchResult(grid: newGrid, flippedIndices: flipped);
  }

  static void _performSnatch(
    List<GridSlot> grid,
    int            sourceIndex,
    MonCard        sourceCard,
    Faction        attackingFaction,
    List<int>      flipped, {
    required int   depth,
  }) {
    if (depth > 8) return; // safety cap on chain depth

    for (final dir in sourceCard.snatchDirs) {
      final targetIdx = _adjacentIndex(sourceIndex, dir);
      if (targetIdx == null) continue;

      final target = grid[targetIdx];
      if (target.isEmpty) continue;
      if (target.ownerFaction == attackingFaction) continue;
      if (target.hasWard) continue; // Ward blocks snatch

      if (_canSnatch(sourceCard, target.card!)) {
        grid[targetIdx] = target.flipTo(attackingFaction);
        flipped.add(targetIdx);

        // Incite keyword — the newly captured card also snatches
        if (sourceCard.keywords.contains(CardKeyword.incite)) {
          _performSnatch(
            grid, targetIdx, target.card!, attackingFaction, flipped,
            depth: depth + 1,
          );
        }
      }
    }
  }

  static bool _canSnatch(MonCard attacker, MonCard defender) {
    if (ElementChart.hasAdvantage(attacker.element, defender.element)) return true;
    // Same or neutral elements: raw power comparison
    return attacker.power >= defender.power;
  }

  /// Returns the grid index adjacent in [dir], or null if out of bounds.
  static int? _adjacentIndex(int idx, SnatchDir dir) {
    final row = idx ~/ 4;
    final col = idx %  4;
    switch (dir) {
      case SnatchDir.north: return row > 0 ? idx - 4 : null;
      case SnatchDir.south: return row < 3 ? idx + 4 : null;
      case SnatchDir.east:  return col < 3 ? idx + 1 : null;
      case SnatchDir.west:  return col > 0 ? idx - 1 : null;
    }
  }

  /// Score tally at any point.
  static ({int star, int moon}) countScores(List<GridSlot> grid) {
    int star = 0, moon = 0;
    for (final slot in grid) {
      if (slot.ownerFaction == Faction.star) star++;
      else if (slot.ownerFaction == Faction.moon) moon++;
    }
    return (star: star, moon: moon);
  }
}