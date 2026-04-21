import 'package:dartz/dartz.dart';
import '../entities/lobby_entity.dart';
import '../../core/errors/failures.dart';

abstract class LobbyRepository {
  Stream<Either<Failure, LobbyEntity>> watchLobby(String lobbyId);
  Future<Either<Failure, void>> placeCard({
    required String lobbyId,
    required String cardId,
    required int cellIndex,
  });
}