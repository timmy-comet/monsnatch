import 'package:equatable/equatable.dart';
import '../../../domain/entities/mon_card.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override List<Object?> get props => [];
}

/// User taps a card in the hand carousel to select it.
class CardSelected extends GameEvent {
  final int handIndex;
  const CardSelected(this.handIndex);
  @override List<Object> get props => [handIndex];
}

/// User drags or taps a grid cell after selecting a card.
class CardPlacedOnGrid extends GameEvent {
  final int     cellIndex;
  final MonCard card;
  const CardPlacedOnGrid(this.cellIndex, this.card);
  @override List<Object> get props => [cellIndex, card];
}

/// Fired every second by the timer subscription.
class TimerTicked extends GameEvent { const TimerTicked(); }

/// Timer hit 0 — auto-place the focused card.
class AutoPlayTriggered extends GameEvent { const AutoPlayTriggered(); }

/// User swipes hand carousel left/right.
class HandSwipedTo extends GameEvent {
  final int focusIndex;
  const HandSwipedTo(this.focusIndex);
  @override List<Object> get props => [focusIndex];
}

/// Tap the lens icon on the enlarged card.
class LensToggled extends GameEvent { const LensToggled(); }