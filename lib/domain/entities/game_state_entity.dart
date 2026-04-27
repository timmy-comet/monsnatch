import 'package:equatable/equatable.dart';
import 'game_cell_entity.dart';
import 'hand_card_entity.dart';
import 'last_move_entity.dart';

/// Full game state from the server (GameStatePublic).
/// Arrives inside RoomPublic.game via WS or REST response.
class GameStateEntity extends Equatable {
  final List<GameCellEntity?> board;      // 16 slots; null = empty
  final Map<String, List<HandCardEntity>> hands;    // uid → list of cardIds remaining
  final String turn;                     // uid of player whose turn it is
  final int    turnNumber;               // 0-based; 0 = first move
  final DateTime turnDeadline;           // UTC — countdown = deadline - now()
  final DateTime startedAt;
  final String    starUid; 
  final Map<String, int> score;          // uid → cells owned
  final String? winner;                  // null = ongoing or draw
  final LastMoveEntity? lastMove;

  const GameStateEntity({
    required this.board,
    required this.hands,
    required this.turn,
    required this.turnNumber,
    required this.turnDeadline,
    required this.startedAt,
    required this.starUid,
    required this.score,
    this.winner,
    this.lastMove,
  });
 
  /// Active (not-yet-played) card IDs for a given player
  List<int> activeCardIds(String uid) =>
      (hands[uid] ?? []).where((c) => !c.used).map((c) => c.cardId).toList();

  GameStateEntity copyWith({
    List<GameCellEntity?>?              board,
    Map<String, List<HandCardEntity>>?  hands,
    String?                             turn,
    int?                                turnNumber,
    DateTime?                           turnDeadline,
    DateTime?                           startedAt,
    String?                             starUid,
    Map<String, int>?                   score,
    String?                             winner,
    LastMoveEntity?                     lastMove,
  }) =>
      GameStateEntity(
        board:        board        ?? this.board,
        hands:        hands        ?? this.hands,
        turn:         turn         ?? this.turn,
        turnNumber:   turnNumber   ?? this.turnNumber,
        turnDeadline: turnDeadline ?? this.turnDeadline,
        startedAt:    startedAt    ?? this.startedAt,
        starUid:      starUid      ?? this.starUid,
        score:        score        ?? this.score,
        winner:       winner       ?? this.winner,
        lastMove:     lastMove     ?? this.lastMove,
      );

  @override
  List<Object?> get props => [
    board, hands, turn, turnNumber, turnDeadline, score, winner, lastMove, starUid
  ];
}
 