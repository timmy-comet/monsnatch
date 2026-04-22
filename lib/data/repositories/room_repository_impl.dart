import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_local_data_source.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomLocalDataSource localDataSource;

  RoomRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, RoomEntity>> createRoom() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final code = localDataSource.generateRoomCode();
    final hand = localDataSource.mockHand();

    return right(
      RoomEntity(
        code: code,
        hand: hand,
      ),
    );
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (code.length != 6) {
      return left(const RoomFailure('Invalid room code'));
    }

    final hand = localDataSource.mockHand();

    return right(
      RoomEntity(
        code: code,
        hand: hand,
      ),
    );
  }
}
