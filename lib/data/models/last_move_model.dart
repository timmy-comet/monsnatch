import '../../domain/entities/last_move_entity.dart';

class LastMoveModel extends LastMoveEntity {
  const LastMoveModel({
    required super.cellIndex,
    required super.cardId,
    required super.placedBy,
    required super.captures,
  });

  factory LastMoveModel.fromJson(Map<String, dynamic> json) => LastMoveModel(
    cellIndex: json['cellIndex'] as int,
    cardId:    json['cardId']    as int,
    placedBy:  json['placedBy']  as String,
    captures:  (json['captures'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList(),
  );
}