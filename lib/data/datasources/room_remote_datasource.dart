import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_service.dart';
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  Future<RoomModel> createRoom();
  Future<RoomModel> getRoom(String code);
  Future<RoomModel> joinRoom(String code);
  Stream<RoomModel> watchRoom(String code, String token);
  void              stopWatching();
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final ApiClient       _client;
  final WebSocketService _ws;

  const RoomRemoteDataSourceImpl(this._client, this._ws);

  @override
  Future<RoomModel> createRoom() async {
    try {
      final res = await _client.post<Map<String, dynamic>>('/rooms', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create room');
    }
  }

  @override
  Future<RoomModel> getRoom(String code) async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/rooms/$code');
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Room not found');
    }
  }

  @override
  Future<RoomModel> joinRoom(String code) async {
    try {
      final res = await _client
          .post<Map<String, dynamic>>('/rooms/$code/join', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to join room');
    }
  }

  @override
  Stream<RoomModel> watchRoom(String code, String token) {
    return _ws.connect(code, token)
        .where((msg) => msg['type'] == 'room_update')
        .map((msg) {
          final roomJson = msg['room'] as Map<String, dynamic>;
          return RoomModel.fromJson(roomJson);
        });
  }

  @override
  void stopWatching() => _ws.disconnect();

  ServerException _mapError(DioException e, String fallback) {
    String? msg;
    try { msg = (e.response?.data as Map)['error'] as String?; } catch (_) {}
    return ServerException(msg ?? fallback, statusCode: e.response?.statusCode);
  }
}