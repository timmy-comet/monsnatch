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
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    code:      json['code']      as String,
    createdBy: json['createdBy'] as String,
    status:    json['status']    as String,
    player1:   json['player1']   as String?,
    player2:   json['player2']   as String?,
    game:      json['game'] == null
        ? null
        : GameStateModel.fromJson(json['game'] as Map<String, dynamic>),
  );
}