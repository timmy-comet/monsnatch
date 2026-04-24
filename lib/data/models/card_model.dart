import '../../domain/entities/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.name,
    required super.element,
    required super.power,
    required super.directions,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id:         json['id']      as int,
    name:       json['name']    as String,
    element:    json['element'] as String,
    power:      json['power']   as int,
    directions: (json['directions'] as List<dynamic>)
        .map((d) => d as String)
        .toList(),
  );
}