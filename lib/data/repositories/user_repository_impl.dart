import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl(this.localDataSource);

  @override
  Future<UserEntity?> getUser() async {
    final name = await localDataSource.getUsername();

    if (name == null) return null;

    final isGuest = await localDataSource.getIsGuest();

    return UserEntity(
      username: name,
      isGuest: isGuest,
    );
  }

  @override
  Future<UserEntity> saveUser(String username) async {
    await localDataSource.saveUser(username);

    return UserEntity(
      username: username,
      isGuest: true,
    );
  }
}