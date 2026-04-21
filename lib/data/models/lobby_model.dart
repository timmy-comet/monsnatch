import '../../domain/entities/lobby_entity.dart';
import 'card_model.dart';

class LobbyModel extends LobbyEntity {
  const LobbyModel({
    required super.lobbyId,
    required super.player1Score,
    required super.player2Score,
    required super.timerSeconds,
    required super.isPlayer1Turn,
    required super.grid,
    required super.hand,
  });

  factory LobbyModel.fromMap(String id, Map<String, dynamic> map) {
    final scoresMap = (map['scores'] as Map?) ?? {};
    final gridMap   = (map['grid']   as Map?) ?? {};
    final handMap   = (map['hand']   as Map?) ?? {};

    final grid = List<CardModel?>.generate(16, (i) {
      final cell = gridMap['cell_$i'];
      if (cell == null) return null;
      return CardModel.fromMap('cell_$i', Map<String, dynamic>.from(cell));
    });

    final hand = handMap.entries
        .map((e) => CardModel.fromMap(e.key, Map<String, dynamic>.from(e.value)))
        .toList();

    return LobbyModel(
      lobbyId:       id,
      player1Score:  (scoresMap['p1'] as int?) ?? 0,
      player2Score:  (scoresMap['p2'] as int?) ?? 0,
      timerSeconds:  (map['timer'] as int?) ?? 30,
      isPlayer1Turn: (map['isPlayer1Turn'] as bool?) ?? true,
      grid:          grid,
      hand:          hand,
    );
  }
}