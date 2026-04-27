import 'package:equatable/equatable.dart';
 
class HandCardEntity extends Equatable {
  final int  cardId; // 1..12
  final bool used;   // true once played this match — do NOT show in active hand
 
  const HandCardEntity({required this.cardId, required this.used});
 
  @override
  List<Object> get props => [cardId, used];
}