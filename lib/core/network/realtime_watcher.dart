import 'dart:async';

enum ConnectionQuality { good, fair, poor, offline }

class RealtimeConnectivityWatcher {
  Timer? _timer;

  final StreamController<ConnectionQuality> _controller =
      StreamController.broadcast();

  Stream<ConnectionQuality> get qualityStream => _controller.stream;

  RealtimeConnectivityWatcher();

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _measure());
    _measure();
  }

  Future<void> _measure() async {
    final start = DateTime.now();
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final ms = DateTime.now().difference(start).inMilliseconds;
      if (!_controller.isClosed) {
        _controller.add(ms < 150
            ? ConnectionQuality.good
            : ms < 400
                ? ConnectionQuality.fair
                : ConnectionQuality.poor);
      }
    } catch (_) {
      if (!_controller.isClosed) _controller.add(ConnectionQuality.offline);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}