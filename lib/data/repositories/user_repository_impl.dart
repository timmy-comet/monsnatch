import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final AuthLocalDataSource  _local;
  final UserRemoteDataSource _remote;

  const UserRepositoryImpl(this._local, this._remote);

  @override
  Future<UserEntity?> getUser() async {
    final uid      = await _local.getUid();
    final username = await _local.getUsername();
    if (uid == null || username == null) return null;
    final hasToken = await _local.hasValidAuth();
    if (!hasToken) { await _local.clearAuth(); return null; }
    return UserEntity(uid: uid, username: username);
  }

  @override
  Future<UserEntity> saveUser(String username) async {
    try {
      final response = await _remote.register(username);
      await _local.saveAuth(
        uid: response.uid, username: response.username, idToken: response.idToken);
      return UserEntity(uid: response.uid, username: response.username);
    } on ServerException catch (e) {
      // 409 = username taken; surface the server message directly
      throw UserFailure(e.message);
    }
  }
 
  @override
  Future<Either<Failure, UserEntity>> getUserById(String uid) async {
    try {
      final user = await _remote.getUserById(uid);
      return right(user);
    } on ServerException catch (e) {
      return left(UserFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }
}