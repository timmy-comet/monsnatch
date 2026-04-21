import 'package:equatable/equatable.dart';

class CardEntity extends Equatable {
  final String id;
  final String name;
  final String imageAsset; // e.g. 'assets/images/cards/rembark.png'
  final int power;
  final bool isStarred;

  const CardEntity({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.power,
    this.isStarred = false,
  });

  @override
  List<Object> get props => [id, name, imageAsset, power, isStarred];
}