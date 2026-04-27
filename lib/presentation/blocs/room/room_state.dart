import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_entity.dart';
 
sealed class RoomState extends Equatable {
  const RoomState();
  @override List<Object?> get props => [];
}
 
class RoomInitial       extends RoomState { const RoomInitial(); }
class RoomLoading       extends RoomState { const RoomLoading(); }
 
/// Created or joined successfully — navigate to WaitingLobbyPage
class RoomReady extends RoomState {
  final RoomEntity room;
  const RoomReady(this.room);
  @override List<Object> get props => [room];
}
 
/// WS update: still waiting for player2
class RoomWaiting extends RoomState {
  final RoomEntity room;
  const RoomWaiting(this.room);
  @override List<Object> get props => [room];
}
 
/// WS update: player2 joined but game not started yet
class RoomPlayerJoined extends RoomState {
  final RoomEntity room;
  const RoomPlayerJoined(this.room);
  @override List<Object> get props => [room];
}
 
/// WS update contains a game → navigate to GamePage (or update GameBloc)
class RoomGameStarted extends RoomState {
  final RoomEntity room;
  const RoomGameStarted(this.room);
  @override List<Object> get props => [room];
}
 
/// WS update: opponent called /leave
class RoomOpponentLeft extends RoomState {
  final RoomEntity room;
  const RoomOpponentLeft(this.room);
  @override List<Object> get props => [room];
}
 
/// Current player left — navigate back to home
class RoomLeft extends RoomState { const RoomLeft(); }
 
class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);
  @override List<Object> get props => [message];
}