import 'package:equatable/equatable.dart';
import '../../../core/network/realtime_watcher.dart';

class ConnectivityState extends Equatable {
  final ConnectionQuality quality;
  const ConnectivityState({this.quality = ConnectionQuality.offline});
  @override
  List<Object> get props => [quality];
}