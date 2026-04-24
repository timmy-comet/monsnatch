import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_service.dart';
import '../models/card_model.dart';
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  Future<RoomModel> createRoom();
  Future<RoomModel> getRoom(String code);
  Future<RoomModel> joinRoom(String code);
  Future<RoomModel> startRoom(String code);
  Future<RoomModel> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  });
  Future<List<CardModel>> getCards();
  Stream<RoomModel>  watchRoom(String code, String token);
  void              stopWatching();
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final ApiClient       _client;
  final WebSocketService _ws;

  const RoomRemoteDataSourceImpl(this._client, this._ws);

  // ── REST ─────────────────────────────────────────────────────────────────

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

  /// POST /rooms/:code/start — host only.
  @override
  Future<RoomModel> startRoom(String code) async {
    try {
      final res = await _client
          .post<Map<String, dynamic>>('/rooms/$code/start', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to start game');
    }
  }

  /// POST /rooms/:code/play — { cellIndex, cardId }.
  /// Do NOT update local state after this returns; wait for the WS echo.
  @override
  Future<RoomModel> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/rooms/$code/play',
        data: {'cellIndex': cellIndex, 'cardId': cardId},
      );
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Move rejected');
    }
  }

  /// GET /cards — full card catalog (12 cards), fetch once per session.
  @override
  Future<List<CardModel>> getCards() async {
    try {
      final res = await _client.get<List<dynamic>>('/cards');
      return (res.data ?? [])
          .map((json) => CardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to load cards');
    }
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  @override
  Stream<RoomModel> watchRoom(String code, String token) {
    return _ws
        .connect(code, token)
        .where((msg) => msg['type'] == 'room_update')
        .map((msg) {
          final roomJson = msg['room'] as Map<String, dynamic>;
          return RoomModel.fromJson(roomJson);
        });
  }

  @override
  void stopWatching() => _ws.disconnect();

  // ── Error mapping ─────────────────────────────────────────────────────────

  ServerException _mapError(DioException e, String fallback) {
    String? msg;
    try {
      msg = (e.response?.data as Map?)?['error'] as String?;
    } catch (_) {}
    return ServerException(msg ?? fallback, statusCode: e.response?.statusCode);
  }
}