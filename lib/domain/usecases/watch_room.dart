import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class WatchRoom {
  final RoomRepository repository;
  const WatchRoom(this.repository);

  Stream<Either<Failure, RoomEntity>> call(String code) =>
      repository.watchRoom(code);

  void stop() => repository.stopWatching();
}