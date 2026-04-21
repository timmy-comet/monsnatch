import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../../core/errors/failures.dart';

abstract class RoomRepository {
  Future<Either<Failure, RoomEntity>> createRoom();
  Future<Either<Failure, RoomEntity>> joinRoom(String code);
}
