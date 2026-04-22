import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class SaveUser {
  final UserRepository repository;

  SaveUser(this.repository);

  Future<UserEntity> call(String username) {
    return repository.saveUser(username);
  }
}