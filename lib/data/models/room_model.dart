import '../../domain/entities/room_entity.dart';
import 'game_state_model.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.code,
    required super.createdBy,
    required super.status,
    super.player1,
    super.player2,
    super.game,
    super.playAgainVotes,
    super.leftBy,
  });
 
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    GameStateModel? game;
    final rawGame = json['game'];
    if (rawGame is Map<String, dynamic>) {
      game = GameStateModel.fromJson(rawGame);
    }

    final rawVotes = json['playAgainVotes'] as List<dynamic>?;
 
    return RoomModel(
      code:             json['code']      as String,
      createdBy:        json['createdBy'] as String,
      status:           json['status']    as String,
      player1:          json['player1']   as String?,
      player2:          json['player2']   as String?,
      game:             game,
      playAgainVotes:   rawVotes?.cast<String>(),
      leftBy:           json['leftBy']    as String?,
    );
  }
}