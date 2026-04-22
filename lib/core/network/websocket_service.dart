import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  /// Connect and return a broadcast stream of decoded JSON messages.
  Stream<Map<String, dynamic>> connect(String roomCode, String token) {
    disconnect(); // close any existing connection first

    final uri = Uri.parse(
      '${ApiConstants.wsBaseUrl}/rooms/$roomCode/ws?token=${Uri.encodeComponent(token)}',
    );

    _channel    = WebSocketChannel.connect(uri);
    _controller = StreamController.broadcast();

    _channel!.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (!_controller!.isClosed) _controller!.add(msg);
        } catch (_) {}
      },
      onError: (e) {
        if (!_controller!.isClosed) _controller!.addError(e);
      },
      onDone: () {
        if (!_controller!.isClosed) _controller!.close();
      },
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  void disconnect() {
    _channel?.sink.close();
    _controller?.close();
    _channel    = null;
    _controller = null;
  }
}