import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> getUser();
  Future<UserEntity> saveUser(String username);
}