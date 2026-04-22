import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<RegisterResponse> register(String username);
  Future<UserModel>          getUser(String uid);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient _client;

  const UserRemoteDataSourceImpl(this._client);

  @override
  Future<RegisterResponse> register(String username) async {
    try {
      final res = await _client.post<Map<String, dynamic>>('/register', data: {'username': username});
      return RegisterResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw ServerException(
        _extractError(e) ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> getUser(String uid) async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/users/$uid');
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw ServerException(
        _extractError(e) ?? 'User not found',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String? _extractError(DioException e) {
    try { return (e.response?.data as Map)['error'] as String?; } catch (_) { return null; }
  }
}
