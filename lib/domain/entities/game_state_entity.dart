import 'package:equatable/equatable.dart';
import 'game_cell_entity.dart';
import 'last_move_entity.dart';

/// Full game state from the server (GameStatePublic).
/// Arrives inside RoomPublic.game via WS or REST response.
class GameStateEntity extends Equatable {
  final List<GameCellEntity?> board;      // 16 slots; null = empty
  final Map<String, List<int>> hands;    // uid → list of cardIds remaining
  final String turn;                     // uid of player whose turn it is
  final int    turnNumber;               // 0-based; 0 = first move
  final DateTime turnDeadline;           // UTC — countdown = deadline - now()
  final DateTime startedAt;
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
    required this.score,
    this.winner,
    this.lastMove,
  });

  @override
  List<Object?> get props => [
    board, hands, turn, turnNumber, turnDeadline, score, winner, lastMove,
  ];
}
