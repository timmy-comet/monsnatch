import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthLocalDataSource   _local;
  final UserRemoteDataSource  _remote;

  const UserRepositoryImpl(this._local, this._remote);

  @override
  Future<UserEntity?> getUser() async {
    final uid      = await _local.getUid();
    final username = await _local.getUsername();
    if (uid == null || username == null) return null;

    // Token expired → treat as "no user" so the app re-registers
    final hasToken = await _local.hasValidAuth();
    if (!hasToken) {
      await _local.clearAuth();
      return null;
    }

    return UserEntity(uid: uid, username: username);
  }

  @override
  Future<UserEntity> saveUser(String username) async {
    try {
      final response = await _remote.register(username);
      await _local.saveAuth(
        uid:      response.uid,
        username: response.username,
        idToken:  response.idToken,
      );
      return UserEntity(uid: response.uid, username: response.username);
    } on ServerException catch (e) {
      throw const UserFailure('Registration failed. Try again.');
    }
  }
}