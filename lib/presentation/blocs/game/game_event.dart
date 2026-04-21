import 'package:equatable/equatable.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override List<Object> get props => [];
}

class CardDropped extends GameEvent {
  final String cardId;
  final int    cellIndex;
  const CardDropped(this.cardId, this.cellIndex);
  @override List<Object> get props => [cardId, cellIndex];
}
