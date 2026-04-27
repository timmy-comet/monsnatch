import 'package:equatable/equatable.dart';

/// Matches CardPublic from GET /cards.
/// Directions use the server's 8-compass notation.
class CardEntity extends Equatable {
  final int    id;        // 1..12
  final String name;
  final String element;  // "fire"|"water"|"earth"|"wind"|"light"|"dark"|...
  final int    power;    // 4..7
  final List<String> directions; // "t"|"tr"|"r"|"br"|"b"|"bl"|"l"|"tl"

  const CardEntity({
    required this.id,
    required this.name,
    required this.element,
    required this.power,
    required this.directions,
  });
 
  /// Asset path — bundle cards as assets/images/cards/card_<id>.webp
  String get imageAsset => 'assets/images/cards/card_$id.webp';
 
  @override
  List<Object> get props => [id];
}