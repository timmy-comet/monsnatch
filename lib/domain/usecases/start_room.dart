import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class StartRoom {
  final RoomRepository repository;
  const StartRoom(this.repository);

  Future<Either<Failure, RoomEntity>> call(String code) =>
      repository.startRoom(code);
}