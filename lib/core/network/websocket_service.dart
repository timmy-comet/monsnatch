import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

/// Status of the underlying WS link, surfaced to the UI via [connection].
enum WsConnectionStatus { idle, connected, reconnecting }

/// Connects to the room WS endpoint and exposes a single broadcast stream of
/// decoded JSON messages. The returned stream survives transient drops —
/// the underlying channel is silently re-opened with exponential backoff
/// (1s → 10s) and messages resume into the same stream once reconnected.
/// The stream only terminates when [disconnect] is called explicitly.
///
/// Also pings the server every 25s to keep the WS alive across upstream
/// idle timeouts (e.g. Cloudflare quick-tunnel ~30s). Backend ignores
/// unknown frames, so `{"type":"ping"}` is harmless.
class WebSocketService {
  WebSocketChannel?                       _channel;
  StreamSubscription?                     _channelSub;
  StreamController<Map<String, dynamic>>? _controller;

  String? _roomCode;
  String? _token;

  Timer? _reconnectTimer;
  Timer? _keepaliveTimer;
  int    _reconnectAttempt       = 0;
  bool   _explicitlyDisconnected = false;

  static const _maxBackoffSeconds = 10;
  static const _keepaliveInterval = Duration(seconds: 25);

  /// UI-facing connection status. Listen to this to show a "Reconnecting…"
  /// banner while the link is down.
  final ValueNotifier<WsConnectionStatus> connection =
      ValueNotifier(WsConnectionStatus.idle);

  Stream<Map<String, dynamic>> connect(String roomCode, String token) {
    disconnect();
    _explicitlyDisconnected = false;
    _roomCode               = roomCode;
    _token                  = token;
    _reconnectAttempt       = 0;
    _controller             = StreamController.broadcast();
    connection.value        = WsConnectionStatus.reconnecting;
    _openChannel();
    return _controller!.stream;
  }

  void _openChannel() {
    final code  = _roomCode;
    final token = _token;
    if (code == null || token == null) return;
    if (_explicitlyDisconnected) return;

    final uri = Uri.parse(
      '${ApiConstants.wsBaseUrl}/rooms/$code/ws?token=${Uri.encodeComponent(token)}',
    );
    developer.log('connect $code (attempt ${_reconnectAttempt + 1})', name: 'ws');

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (e, st) {
      developer.log('connect threw', name: 'ws', error: e, stackTrace: st);
      _scheduleReconnect();
      return;
    }

    _channelSub = _channel!.stream.listen(
      (raw) {
        if (_reconnectAttempt > 0) {
          developer.log('reconnected after $_reconnectAttempt attempts', name: 'ws');
          _reconnectAttempt = 0;
        }
        connection.value = WsConnectionStatus.connected;
        _startKeepalive();
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          final c = _controller;
          if (c != null && !c.isClosed) c.add(msg);
        } catch (e, st) {
          developer.log('decode failed', name: 'ws', error: e, stackTrace: st);
        }
      },
      onError: (e, st) {
        developer.log('stream error', name: 'ws', error: e, stackTrace: st);
        _scheduleReconnect();
      },
      onDone: () {
        developer.log('stream done', name: 'ws');
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _startKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      final ch = _channel;
      if (ch == null) return;
      try {
        ch.sink.add('{"type":"ping"}');
      } catch (e, st) {
        developer.log('keepalive failed', name: 'ws', error: e, stackTrace: st);
      }
    });
  }

  void _scheduleReconnect() {
    if (_explicitlyDisconnected) return;
    final c = _controller;
    if (c == null || c.isClosed) return;

    connection.value = WsConnectionStatus.reconnecting;
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _channelSub?.cancel();
    _channelSub = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;

    final exp  = _reconnectAttempt.clamp(0, 4);
    final secs = (1 << exp).clamp(1, _maxBackoffSeconds);
    _reconnectAttempt++;
    developer.log('reconnect in ${secs}s', name: 'ws');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: secs), _openChannel);
  }

  /// Force an immediate reconnect attempt — cancels the pending backoff
   /// timer and reopens the channel right now. No-op when the link is
   /// already healthy or has been explicitly closed.
   void retryNow() {
     if (_explicitlyDisconnected) return;
     final c = _controller;
     if (c == null || c.isClosed) return;
     if (connection.value != WsConnectionStatus.reconnecting) return;
     developer.log('manual retry', name: 'ws');
     _reconnectTimer?.cancel();
     _reconnectTimer   = null;
     _reconnectAttempt = 0;
     _openChannel();
   }

   void disconnect() {
    if (_channel != null) developer.log('disconnect', name: 'ws');
    _explicitlyDisconnected = true;
    _reconnectTimer?.cancel();
    _keepaliveTimer?.cancel();
    _channelSub?.cancel();
    try { _channel?.sink.close(); } catch (_) {}
    _controller?.close();

    _reconnectTimer   = null;
    _keepaliveTimer   = null;
    _channelSub       = null;
    _channel          = null;
    _controller       = null;
    _roomCode         = null;
    _token            = null;
    _reconnectAttempt = 0;
    connection.value  = WsConnectionStatus.idle;
  }
}
