import '../entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

abstract class UserRepository {
  Future<UserEntity?> getUser();
  Future<UserEntity>  saveUser(String username);
  Future<Either<Failure, UserEntity>> getUserById(String uid);
}