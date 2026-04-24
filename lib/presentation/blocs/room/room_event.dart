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

/// Host taps "Start Game" on the waiting lobby.
class StartGameRequested extends RoomEvent {
  final String code;
  const StartGameRequested(this.code);
  @override List<Object> get props => [code];
}

class WatchRoomStarted extends RoomEvent {
  final String code;
  const WatchRoomStarted(this.code);
  @override List<Object> get props => [code];
}

class WatchRoomStopped extends RoomEvent { const WatchRoomStopped(); }