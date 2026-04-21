import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_room.dart';
import '../../../domain/usecases/join_room.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final CreateRoom _createRoom;
  final JoinRoom   _joinRoom;

  RoomBloc({
    required CreateRoom createRoom,
    required JoinRoom   joinRoom,
  })  : _createRoom = createRoom,
        _joinRoom   = joinRoom,
        super(const RoomInitial()) {
    on<CreateRoomRequested>(_onCreate);
    on<JoinRoomRequested>(_onJoin);
  }

  Future<void> _onCreate(CreateRoomRequested _, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    final result = await _createRoom(const NoParams());
    result.fold(
      (f) => emit(RoomError(f.message)),
      (r) => emit(RoomReady(r)),
    );
  }

  Future<void> _onJoin(JoinRoomRequested event, Emitter<RoomState> emit) async {
    emit(const RoomLoading());
    final result = await _joinRoom(event.code);
    result.fold(
      (f) => emit(RoomError(f.message)),
      (r) => emit(RoomReady(r)),
    );
  }
}
