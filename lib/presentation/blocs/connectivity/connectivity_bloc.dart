import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/realtime_watcher.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final RealtimeConnectivityWatcher _watcher;
  final Connectivity _conn;
  StreamSubscription? _qualSub;
  StreamSubscription? _netSub;

  ConnectivityBloc({
    required RealtimeConnectivityWatcher watcher,
    Connectivity? connectivity,
  })  : _watcher = watcher,
        _conn = connectivity ?? Connectivity(),
        super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<QualityChanged>((e, emit) => emit(ConnectivityState(quality: e.quality)));
    add(const ConnectivityStarted());
  }

  Future<void> _onStarted(ConnectivityStarted _, Emitter<ConnectivityState> emit) async {
    _watcher.start();
    _qualSub = _watcher.qualityStream
        .listen((q) => add(QualityChanged(q)));

    // connectivity_plus: fall to offline fast if no network
    _netSub = _conn.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        add(const QualityChanged(ConnectionQuality.offline));
      }
    });
  }

  @override
  Future<void> close() {
    _qualSub?.cancel();
    _netSub?.cancel();
    _watcher.dispose();
    return super.close();
  }
}