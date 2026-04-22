import 'package:get_it/get_it.dart';
import 'package:monsnatch/data/repositories/user_repository_impl.dart';
import 'data/repositories/mock_room_repository.dart';
import 'domain/repositories/room_repository.dart';
import 'domain/usecases/create_room.dart';
import 'domain/usecases/join_room.dart';
import 'presentation/blocs/room/room_bloc.dart';
import 'domain/repositories/user_repository.dart';
import 'data/datasources/user_local_data_source.dart';
import 'domain/usecases/get_user.dart';
import 'domain/usecases/save_user.dart';
import 'presentation/blocs/user/user_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
 

  // ── Repository ──────────────────────────────
  sl.registerLazySingleton<RoomRepository>(() => MockRoomRepository());

  // ── Use Cases ───────────────────────────────
  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => JoinRoom(sl()));

  // ── BLoC (factory = fresh instance per page) ─
  sl.registerFactory(() => RoomBloc(createRoom: sl(), joinRoom: sl()));

  // ── User ─────────────────────────────
  // ── Local Data Source ──────────────────────────────
  sl.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSource());
  
  // Repository
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));

  // Usecases
  sl.registerLazySingleton(() => GetUser(sl()));
  sl.registerLazySingleton(() => SaveUser(sl()));

  // Bloc
  sl.registerFactory(() => UserBloc(
    getUser: sl(),
    saveUser: sl(),
));
}