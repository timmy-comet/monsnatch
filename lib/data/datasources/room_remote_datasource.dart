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
  Future<RoomModel> leaveRoom(String code);
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
  Future<RoomModel> createRoom() => _post('/rooms', {});
 
  @override
  Future<RoomModel> getRoom(String code) async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/rooms/$code');
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) { throw _map(e, 'Room not found'); }
  }
 
  @override
  Future<RoomModel> joinRoom(String code)   => _post('/rooms/$code/join',  {});
 
  @override
  Future<RoomModel> startRoom(String code)  => _post('/rooms/$code/start', {});
 
  @override
  Future<RoomModel> leaveRoom(String code)  => _post('/rooms/$code/leave', {});
 
  @override
  Future<RoomModel> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  }) => _post('/rooms/$code/play', {'cellIndex': cellIndex, 'cardId': cardId});
 
  /// GET /cards — full 12-card catalog, static (fetch once per session)
  @override
  Future<List<CardModel>> getCards() async {
    try {
      final res = await _client.get<List<dynamic>>('/cards');
      return (res.data ?? [])
          .map((j) => CardModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw _map(e, 'Failed to load card catalog'); }
  }
 
  /// WS — streams room_update messages; all other messages ignored
  @override
  Stream<RoomModel> watchRoom(String code, String token) =>
      _ws.connect(code, token)
          .where((msg) => msg['type'] == 'room_update')
          .map((msg) => RoomModel.fromJson(msg['room'] as Map<String, dynamic>));
 
  @override
  void stopWatching() => _ws.disconnect();
 
  // ── helpers ───────────────────────────────────────────────────────────────
 
  Future<RoomModel> _post(String path, Object body) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(path, data: body);
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) { throw _map(e, 'Request failed'); }
  }
 
  ServerException _map(DioException e, String fallback) {
    String? msg;
    try { msg = (e.response?.data as Map?)?['error'] as String?; } catch (_) {}
    return ServerException(msg ?? fallback, statusCode: e.response?.statusCode);
  }
}