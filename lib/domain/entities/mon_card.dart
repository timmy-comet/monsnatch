import 'package:equatable/equatable.dart';
import 'card_element.dart';
import 'snatch_direction.dart';
import 'card_keyword.dart';

class MonCard extends Equatable {
  final String              id;
  final String              name;
  final String              imageAsset;
  final CardElement         element;
  final int                 power;         // 1–10 white number in circle
  final int                 rarityStars;   // 1–5, sum must ≤ 25 per deck
  final int                 level;         // displayed bottom-left on card
  final List<SnatchDir>     snatchDirs;    // edges with red triangles
  final List<CardKeyword>  keywords;
  final String              abilityText;
  final int                 defense;
  final int                 attack;

  const MonCard({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.element,
    required this.power,
    this.rarityStars = 2,
    this.level       = 1,
    this.snatchDirs  = const [],
    this.keywords    = const [],
    this.abilityText = '',
    this.defense     = 5,
    this.attack      = 5,
  });

  @override
  List<Object> get props => [id];
}