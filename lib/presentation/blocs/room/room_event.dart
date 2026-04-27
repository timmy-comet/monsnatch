import 'package:equatable/equatable.dart';
 
sealed class RoomEvent extends Equatable {
  const RoomEvent();
  @override List<Object> get props => [];
}
 
class CreateRoomRequested extends RoomEvent { const CreateRoomRequested(); }
 
class JoinRoomRequested extends RoomEvent {
  final String code;
  const JoinRoomRequested(this.code);
  @override List<Object> get props => [code];
}
 
/// Host taps "Start Game" (or either player taps "Play Again" after game ends)
class StartGameRequested extends RoomEvent {
  final String code;
  const StartGameRequested(this.code);
  @override List<Object> get props => [code];
}
 
/// Player taps "Leave Room" on the end-of-match screen
class LeaveRoomRequested extends RoomEvent {
  final String code;
  const LeaveRoomRequested(this.code);
  @override List<Object> get props => [code];
}
 
/// Open WebSocket subscription for a room
class WatchRoomStarted extends RoomEvent {
  final String code;
  const WatchRoomStarted(this.code);
  @override List<Object> get props => [code];
}
 
/// Close the WebSocket subscription
class WatchRoomStopped extends RoomEvent { const WatchRoomStopped(); }
