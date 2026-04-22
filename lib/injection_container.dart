import 'package:get_it/get_it.dart';
import 'core/network/api_client.dart';
import 'core/network/websocket_service.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/user_remote_datasource.dart';
import 'data/datasources/room_remote_datasource.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/room_repository_impl.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/room_repository.dart';
import 'domain/usecases/get_user.dart';
import 'domain/usecases/save_user.dart';
import 'domain/usecases/create_room.dart';
import 'domain/usecases/join_room.dart';
import 'domain/usecases/watch_room.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/room/room_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  // ── Infrastructure ──────────────────────────────────────
  sl.registerLazySingleton(() => AuthLocalDataSource());
  sl.registerLazySingleton(() => WebSocketService());
  sl.registerLazySingleton(() => ApiClient(sl()));

  // ── DataSources ─────────────────────────────────────────
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(sl(), sl()));

  // ── Repositories ────────────────────────────────────────
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(sl(), sl()));

  // ── Use Cases ───────────────────────────────────────────
  sl.registerLazySingleton(() => GetUser(sl()));
  sl.registerLazySingleton(() => SaveUser(sl()));
  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => JoinRoom(sl()));
  sl.registerLazySingleton(() => WatchRoom(sl()));

  // ── BLoC (factory → fresh instance per page) ────────────
  sl.registerLazySingleton(() => UserBloc(
    getUser:   sl(),
    saveUser:  sl(),
    authLocal: sl(),
  ));
  sl.registerFactory(() => RoomBloc(
    createRoom: sl(),
    joinRoom:   sl(),
    watchRoom:  sl(),
  ));
}