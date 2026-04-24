import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_entity.dart';

sealed class RoomState extends Equatable {
  const RoomState();
  @override List<Object?> get props => [];
}

class RoomInitial       extends RoomState { const RoomInitial(); }
class RoomLoading       extends RoomState { const RoomLoading(); }

class RoomReady extends RoomState {
  final RoomEntity room;
  const RoomReady(this.room);
  @override List<Object> get props => [room];
}

class RoomWaiting extends RoomState {
  final RoomEntity room;
  const RoomWaiting(this.room);
  @override List<Object> get props => [room];
}

class RoomPlayerJoined extends RoomState {
  final RoomEntity room;
  const RoomPlayerJoined(this.room);
  @override List<Object> get props => [room];
}

/// Emitted when WS update contains room.game != null (host called /start).
class RoomGameStarted extends RoomState {
  final RoomEntity room;
  const RoomGameStarted(this.room);
  @override List<Object> get props => [room];
}

class RoomError extends RoomState {
  final String message;
  const RoomError(this.message);
  @override List<Object> get props => [message];
}