import 'package:get_it/get_it.dart';
import 'data/repositories/mock_room_repository.dart';
import 'domain/repositories/room_repository.dart';
import 'domain/usecases/create_room.dart';
import 'domain/usecases/join_room.dart';
import 'presentation/blocs/room/room_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  // ── Repository ──────────────────────────────
  sl.registerLazySingleton<RoomRepository>(() => MockRoomRepository());

  // ── Use Cases ───────────────────────────────
  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => JoinRoom(sl()));

  // ── BLoC (factory = fresh instance per page) ─
  sl.registerFactory(() => RoomBloc(createRoom: sl(), joinRoom: sl()));
}