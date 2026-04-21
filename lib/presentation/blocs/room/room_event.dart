import 'package:equatable/equatable.dart';

sealed class RoomEvent extends Equatable {
  const RoomEvent();
  @override List<Object> get props => [];
}

class CreateRoomRequested extends RoomEvent {
  const CreateRoomRequested();
}

class JoinRoomRequested extends RoomEvent {
  final String code;
  const JoinRoomRequested(this.code);
  @override List<Object> get props => [code];
}
