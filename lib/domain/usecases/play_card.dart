import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class PlayCardParams {
  final String code;
  final int    cellIndex;
  final int    cardId;
  const PlayCardParams({
    required this.code,
    required this.cellIndex,
    required this.cardId,
  });
}

class PlayCard {
  final RoomRepository repository;
  const PlayCard(this.repository);

  Future<Either<Failure, RoomEntity>> call(PlayCardParams params) =>
      repository.playCard(
        code:      params.code,
        cellIndex: params.cellIndex,
        cardId:    params.cardId,
      );
}