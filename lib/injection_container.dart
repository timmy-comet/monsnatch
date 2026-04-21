import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/network/realtime_watcher.dart';

import 'data/repositories/lobby_repository_impl.dart';
import 'domain/repositories/lobby_repository.dart';
import 'domain/usecases/watch_lobby.dart';
import 'domain/usecases/place_card.dart';
import 'presentation/blocs/lobby/lobby_bloc.dart';
import 'presentation/blocs/connectivity/connectivity_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── Core ───
  sl.registerLazySingleton(() => RealtimeConnectivityWatcher());
  sl.registerLazySingleton(() => Connectivity());

  // ─── Data ───
  sl.registerLazySingleton<LobbyRepository>(
    () => LobbyRepositoryImpl());

  // ─── Domain ───
  sl.registerLazySingleton(() => WatchLobby(sl()));
  sl.registerLazySingleton(() => PlaceCard(sl()));

  // ─── BLoC (factory = new instance per page) ───
  sl.registerFactory(() => LobbyBloc(watchLobby: sl(), placeCard: sl()));
  sl.registerFactory(() => ConnectivityBloc(watcher: sl(), connectivity: sl()));
}