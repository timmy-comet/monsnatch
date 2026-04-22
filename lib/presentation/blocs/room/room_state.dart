import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_entity.dart';

sealed class RoomState extends Equatable {
  const RoomState();
  @override List<Object?> get props => [];
}

class RoomInitial extends RoomState { const RoomInitial(); }
class RoomLoading extends RoomState { const RoomLoading(); }

/// Room successfully created or joined — navigate to WaitingLobbyPage.
class RoomReady extends RoomState {
  final RoomEntity room;
  const RoomReady(this.room);
  @override List<Object> get props => [room];
}

/// A WebSocket update arrived but no player2 yet — room still waiting.
class RoomWaiting extends RoomState {
  final RoomEntity room;
  const RoomWaiting(this.room);
  @override List<Object> get props => [room];
}

/// player2 just joined — show banner on WaitingLobbyPage.
class RoomPlayerJoined extends RoomState {
  final RoomEntity room;
  const RoomPlayerJoined(this.room);
  @override List<Object> get props => [room];
}

class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);
  @override List<Object> get props => [message];
}