import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_entity.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override List<Object?> get props => [];
}

/// Called once when entering the battle screen.
/// Loads card catalog, fetches opponent username, starts WS listener.
class GameInitialized extends GameEvent {
  final RoomEntity room;
  final String     myUid;
  const GameInitialized({required this.room, required this.myUid});
  @override List<Object> get props => [room, myUid];
}

/// WS pushed a new room state → replace everything.
class GameRoomUpdated extends GameEvent {
  final RoomEntity room;
  const GameRoomUpdated(this.room);
  @override List<Object> get props => [room];
}

/// Player tapped a card in their hand.
class GameCardTapped extends GameEvent {
  final int cardId;
  const GameCardTapped(this.cardId);
  @override List<Object> get props => [cardId];
}

/// Player tapped a valid empty cell.
class GameCellTapped extends GameEvent {
  final int cellIndex;
  const GameCellTapped(this.cellIndex);
  @override List<Object> get props => [cellIndex];
}

/// Internal: every 500 ms — recompute countdown from turnDeadline.
class GameTimerTick extends GameEvent { const GameTimerTick(); }

/// Player left the battle screen.
class GameExited extends GameEvent { const GameExited(); }