import 'package:equatable/equatable.dart';
import '../../../core/network/realtime_watcher.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent { const ConnectivityStarted(); }

class QualityChanged extends ConnectivityEvent {
  final ConnectionQuality quality;
  const QualityChanged(this.quality);
  @override
  List<Object> get props => [quality];
}