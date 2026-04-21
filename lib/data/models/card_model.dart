import '../../domain/entities/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.name,
    required super.imageAsset,
    required super.power,
    super.isStarred,
  });

  factory CardModel.fromMap(String id, Map<String, dynamic> map) => CardModel(
        id: id,
        name: map['name'] as String,
        imageAsset: map['imageAsset'] as String,
        power: (map['power'] as int?) ?? 0,
        isStarred: (map['isStarred'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageAsset': imageAsset,
        'power': power,
        'isStarred': isStarred,
      };
}