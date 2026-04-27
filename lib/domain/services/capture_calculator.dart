import '../entities/card_entity.dart';
import '../entities/game_cell_entity.dart';

/// Pure Dart port of the backend's capture rule (`backend/src/game/capture.ts`
/// + `directions.ts` + `elements.ts`). Used to apply captures optimistically
/// on the client so the UI doesn't have to wait for the WS echo.
///
/// Server is still the authority — if a WS update arrives with a different
/// captures list, the WS state simply overwrites the optimistic one.
class CaptureCalculator {
  /// Row-delta, column-delta per compass direction.
  static const _dirOffsets = <String, List<int>>{
    't' : [-1,  0],
    'tr': [-1,  1],
    'r' : [ 0,  1],
    'br': [ 1,  1],
    'b' : [ 1,  0],
    'bl': [ 1, -1],
    'l' : [ 0, -1],
    'tl': [-1, -1],
  };

  /// Used when Player 2 (Moon side) places a card — their card is
  /// conceptually flipped 180° relative to the catalog orientation, so
  /// every direction inverts.
  static const _opposite = <String, String>{
    't' : 'b',
    'tr': 'bl',
    'r' : 'l',
    'br': 'tl',
    'b' : 't',
    'bl': 'tr',
    'l' : 'r',
    'tl': 'br',
  };

  /// 12-element rock-paper-scissors tree. Each attacker beats 3 defenders.
  static const _elementBeats = <String, List<String>>{
    'earth':     ['wind',  'fire',      'lightning'],
    'water':     ['fire',  'poison',    'ghost'],
    'wind':      ['water', 'ghost',     'dark'],
    'fire':      ['plant', 'ice',       'steel'],
    'lightning': ['water', 'ghost',     'light'],
    'ice':       ['earth', 'wind',      'steel'],
    'plant':     ['earth', 'water',     'light'],
    'poison':    ['plant', 'ice',       'light'],
    'steel':     ['wind',  'lightning', 'poison'],
    'ghost':     ['earth', 'ice',       'dark'],
    'light':     ['fire',  'steel',     'dark'],
    'dark':      ['plant', 'lightning', 'poison'],
  };

  static const int boardSize = 4;

  /// Returns the cell indices that the placed card captures. The board
  /// passed in must already reflect the placement (or any state where
  /// `board[cellIndex]` itself is irrelevant — only neighbours are read).
  ///
  /// [isPlayer2] should be `true` when the placer's uid equals
  /// `room.player2`, regardless of star/moon assignment. This mirrors
  /// `service.ts:368` exactly.
  static List<int> compute({
    required CardEntity        placedCard,
    required int               cellIndex,
    required List<GameCellEntity?> board,
    required Map<int, CardEntity> catalog,
    required bool              isPlayer2,
  }) {
    final dirs = isPlayer2
        ? placedCard.directions.map((d) => _opposite[d] ?? d).toList()
        : placedCard.directions;
    final captured = <int>[];
    for (final dir in dirs) {
      final n = _neighborIndex(cellIndex, dir);
      if (n == null) continue;
      final defenderCell = board[n];
      if (defenderCell == null) continue;
      final defender = catalog[defenderCell.cardId];
      if (defender == null) continue;
      final wins = placedCard.power > defender.power
          || _beats(placedCard.element, defender.element);
      if (wins) captured.add(n);
    }
    return captured;
  }

  static int? _neighborIndex(int idx, String dir) {
    final offset = _dirOffsets[dir];
    if (offset == null) return null;
    final r = idx ~/ boardSize + offset[0];
    final c = idx % boardSize + offset[1];
    if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) return null;
    return r * boardSize + c;
  }

  static bool _beats(String attacker, String defender) =>
      _elementBeats[attacker]?.contains(defender) ?? false;
}
