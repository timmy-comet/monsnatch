import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_room.dart';
import '../../../domain/usecases/join_room.dart';
import '../../../domain/usecases/start_room.dart';
import '../../../domain/usecases/watch_room.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final CreateRoom _createRoom;
  final JoinRoom   _joinRoom;
  final StartRoom  _startRoom;
  final WatchRoom  _watchRoom;

  RoomBloc({
    required CreateRoom createRoom,
    required JoinRoom   joinRoom,
    required StartRoom  startRoom,
    required WatchRoom  watchRoom,
  })  : _createRoom = createRoom,
        _joinRoom   = joinRoom,
        _startRoom  = startRoom,
        _watchRoom  = watchRoom,
        super(const RoomInitial()) {
    on<CreateRoomRequested>(_onCreate);
    on<JoinRoomRequested>(_onJoin);
    on<StartGameRequested>(_onStart);
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

  Future<void> _onStart(
      StartGameRequested event, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    final result = await _startRoom(event.code);
    result.fold(
      (f) {
        // Special case: "Match already in progress" = game was started by other player
        // Don't error out—the game IS started. WS listener will confirm via room_update.
        if (f is RoomFailure && 
            (f.message.toLowerCase().contains('already') || 
             f.message.toLowerCase().contains('in progress'))) {
          // Don't emit error; stay in loading until WS confirms game started
          return;
        }
        emit(RoomError(_mapFailure(f)));
      },
      (r) => emit(RoomGameStarted(r)),
    );
  }

  /// Opens WS and emits on every room_update.
  Future<void> _onWatchStarted(
      WatchRoomStarted event, Emitter<RoomState> emit) async {
    await emit.forEach(
      _watchRoom(event.code),
      onData: (result) => result.fold(
        (f) => RoomError(_mapFailure(f)),
        (room) {
          // Auto-navigate trigger: game appeared in WS update
          if (room.isGameStarted) return RoomGameStarted(room);
          if (room.hasOpponent)   return RoomPlayerJoined(room);
          return RoomWaiting(room);
        },
      ),
      onError: (e, _) => RoomError(e.toString()),
    );
  }

  void _onWatchStopped(WatchRoomStopped _, Emitter<RoomState> emit) {
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