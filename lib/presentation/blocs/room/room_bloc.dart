import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_room.dart';
import '../../../domain/usecases/join_room.dart';
import '../../../domain/usecases/start_room.dart';
import '../../../domain/usecases/leave_room.dart';
import '../../../domain/usecases/watch_room.dart';
import 'room_event.dart';
import 'room_state.dart';
 
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final CreateRoom _createRoom;
  final JoinRoom   _joinRoom;
  final StartRoom  _startRoom;
  final LeaveRoom  _leaveRoom;
  final WatchRoom  _watchRoom;
 
  RoomBloc({
    required CreateRoom createRoom,
    required JoinRoom   joinRoom,
    required StartRoom  startRoom,
    required LeaveRoom  leaveRoom,
    required WatchRoom  watchRoom,
  })  : _createRoom = createRoom,
        _joinRoom   = joinRoom,
        _startRoom  = startRoom,
        _leaveRoom  = leaveRoom,
        _watchRoom  = watchRoom,
        super(const RoomInitial()) {
    on<CreateRoomRequested>(_onCreate);
    on<JoinRoomRequested>  (_onJoin);
    on<StartGameRequested> (_onStart);
    on<LeaveRoomRequested> (_onLeave);
    on<WatchRoomStarted>   (_onWatchStarted);
    on<WatchRoomStopped>   (_onWatchStopped);
  }
 
  Future<void> _onCreate(CreateRoomRequested _, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    (await _createRoom(const NoParams())).fold(
      (f) => emit(RoomError(_msg(f))),
      (r) => emit(RoomReady(r)),
    );
  }
 
  Future<void> _onJoin(JoinRoomRequested event, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    (await _joinRoom(event.code)).fold(
      (f) => emit(RoomError(_msg(f))),
      (r) => emit(RoomReady(r)),
    );
  }
 
  Future<void> _onStart(StartGameRequested event, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    (await _startRoom(event.code)).fold(
      (f) => emit(RoomError(_msg(f))),
      (r) => emit(RoomGameStarted(r)), // WS will push the real updated state
    );
  }
 
  Future<void> _onLeave(LeaveRoomRequested event, Emitter<RoomState> emit) async {
    await _leaveRoom(event.code); // best-effort, ignore failure
    _watchRoom.stop();
    emit(const RoomLeft());
  }
 
  /// KEY FIX: WS subscription stays alive across WaitingLobbyPage → GamePage.
  /// GamePage pipes RoomGameStarted updates to GameBloc — it does NOT open its own WS.
  Future<void> _onWatchStarted(WatchRoomStarted event, Emitter<RoomState> emit) async {
    await emit.forEach(
      _watchRoom(event.code),
      onData: (result) => result.fold(
        (f) => RoomError(_msg(f)),
        (room) {
          if (room.isOpponentLeft)  return RoomOpponentLeft(room);
          if (room.isGameStarted)   return RoomGameStarted(room);
          if (room.hasOpponent)     return RoomPlayerJoined(room);
          return RoomWaiting(room);
        },
      ),
      onError: (e, _) => RoomError(e.toString()),
    );
  }
 
  void _onWatchStopped(WatchRoomStopped _, Emitter<RoomState> emit) {
    _watchRoom.stop();
  }
 
  String _msg(Failure f) => switch (f) {
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