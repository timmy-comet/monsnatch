import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_room.dart';
import '../../../domain/usecases/join_room.dart';
import '../../../domain/usecases/watch_room.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final CreateRoom _createRoom;
  final JoinRoom   _joinRoom;
  final WatchRoom  _watchRoom;

  RoomBloc({
    required CreateRoom createRoom,
    required JoinRoom   joinRoom,
    required WatchRoom  watchRoom,
  })  : _createRoom = createRoom,
        _joinRoom   = joinRoom,
        _watchRoom  = watchRoom,
        super(const RoomInitial()) {
    on<CreateRoomRequested>(_onCreate);
    on<JoinRoomRequested>(_onJoin);
    on<WatchRoomStarted>(_onWatchStarted);
    on<WatchRoomStopped>(_onWatchStopped);
  }

  Future<void> _onCreate(
      CreateRoomRequested _, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    final result = await _createRoom(const NoParams());
    result.fold(
      (f) => emit(RoomError(_mapFailure(f))),
      (r) => emit(RoomReady(r)),
    );
  }

  Future<void> _onJoin(
      JoinRoomRequested event, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    final result = await _joinRoom(event.code);
    result.fold(
      (f) => emit(RoomError(_mapFailure(f))),
      (r) => emit(RoomReady(r)),
    );
  }

  /// Opens the WebSocket stream. emit.forEach keeps the subscription alive
  /// until the stream closes (server disconnects) or the bloc is closed.
  Future<void> _onWatchStarted(
      WatchRoomStarted event, Emitter<RoomState> emit) async {
    await emit.forEach(
      _watchRoom(event.code),
      onData: (result) => result.fold(
        (f) => RoomError(_mapFailure(f)),
        (room) => room.hasOpponent
            ? RoomPlayerJoined(room)
            : RoomWaiting(room),
      ),
      onError: (e, _) => RoomError(e.toString()),
    );
  }

  void _onWatchStopped(
      WatchRoomStopped _, Emitter<RoomState> emit) {
    _watchRoom.stop();
  }

  String _mapFailure(Failure f) => switch (f) {
    AuthFailure()    => '${f.message} Please re-open the app.',
    NetworkFailure() => 'No connection. Check your network.',
    _                => f.message,
  };

  @override
  Future<void> close() {
    _watchRoom.stop();
    return super.close();
  }
}