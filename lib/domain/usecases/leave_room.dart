import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';
 
class LeaveRoom {
  final RoomRepository repository;
  const LeaveRoom(this.repository);
  Future<Either<Failure, RoomEntity>> call(String code) =>
      repository.leaveRoom(code);
}