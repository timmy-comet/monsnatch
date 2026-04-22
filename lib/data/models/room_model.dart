import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.code,
    super.status,
    super.player1,
    super.player2,
    super.createdBy,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        code:      json['code']      as String,
        status:    json['status']    as String? ?? 'available',
        player1:   json['player1']   as String?,
        player2:   json['player2']   as String?,
        createdBy: json['createdBy'] as String?,
      );
}