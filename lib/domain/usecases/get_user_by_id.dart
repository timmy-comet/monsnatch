import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';
import '../../core/errors/failures.dart';

class GetUserById {
  final UserRepository repository;
  const GetUserById(this.repository);

  Future<Either<Failure, UserEntity>> call(String uid) =>
      repository.getUserById(uid);
}