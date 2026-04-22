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

/// Starts listening for live updates on an existing room via WebSocket.
class WatchRoomStarted extends RoomEvent {
  final String code;
  const WatchRoomStarted(this.code);
  @override List<Object> get props => [code];
}

/// Closes the WebSocket connection.
class WatchRoomStopped extends RoomEvent { const WatchRoomStopped(); }
