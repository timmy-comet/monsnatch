import '../../domain/entities/game_cell_entity.dart';

class GameCellModel extends GameCellEntity {
  const GameCellModel({
    required super.cardId,
    required super.ownerUid,
    required super.placedBy,
  });

  factory GameCellModel.fromJson(Map<String, dynamic> json) => GameCellModel(
    cardId:   json['cardId'] as int,
    ownerUid: json['ownerUid'] as String,
    placedBy: json['placedBy'] as String,
  );
}