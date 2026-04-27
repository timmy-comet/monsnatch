import '../../domain/entities/hand_card_entity.dart';
 
class HandCardModel extends HandCardEntity {
  const HandCardModel({required super.cardId, required super.used});
 
  factory HandCardModel.fromJson(Map<String, dynamic> json) => HandCardModel(
    cardId: json['cardId'] as int,
    used:   json['used']   as bool,
  );
}