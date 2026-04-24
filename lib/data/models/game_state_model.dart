import '../../domain/entities/game_state_entity.dart';
import 'game_cell_model.dart';
import 'last_move_model.dart';

class GameStateModel extends GameStateEntity {
  const GameStateModel({
    required super.board,
    required super.hands,
    required super.turn,
    required super.turnNumber,
    required super.turnDeadline,
    required super.startedAt,
    required super.score,
    super.winner,
    super.lastMove,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    // board: (GameCell | null)[16]
    final rawBoard = json['board'] as List<dynamic>;
    final board = rawBoard.map((cell) {
      if (cell == null) return null;
      return GameCellModel.fromJson(cell as Map<String, dynamic>);
    }).toList();

    // hands: { uid: number[] }
    final rawHands = json['hands'] as Map<String, dynamic>? ?? {};
    final hands = rawHands.map((uid, cardIds) => MapEntry(
      uid,
      (cardIds as List<dynamic>).map((id) => id as int).toList(),
    ));

    // score: { uid: number }
    final rawScore = json['score'] as Map<String, dynamic>? ?? {};
    final score = rawScore.map((uid, s) => MapEntry(uid, s as int));

    return GameStateModel(
      board:        board,
      hands:        hands,
      turn:         json['turn'] as String,
      turnNumber:   json['turnNumber'] as int,
      turnDeadline: DateTime.parse(json['turnDeadline'] as String).toLocal(),
      startedAt:    DateTime.parse(json['startedAt']    as String).toLocal(),
      score:        score,
      winner:       json['winner'] as String?,
      lastMove:     json['lastMove'] == null
          ? null
          : LastMoveModel.fromJson(json['lastMove'] as Map<String, dynamic>),
    );
  }
}