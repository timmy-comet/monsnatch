import 'package:dartz/dartz.dart';
import '../entities/card_entity.dart';
import '../entities/room_entity.dart';
import '../../core/errors/failures.dart';

abstract class RoomRepository {
  Future<Either<Failure, RoomEntity>> createRoom();
  Future<Either<Failure, RoomEntity>> joinRoom(String code);
  Future<Either<Failure, RoomEntity>> startRoom(String code);
  Future<Either<Failure, RoomEntity>> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  });
  Future<Either<Failure, RoomEntity>> leaveRoom(String code);
  Future<Either<Failure, List<CardEntity>>> getCards();
  Stream<Either<Failure, RoomEntity>> watchRoom(String code);
  void stopWatching();
}
