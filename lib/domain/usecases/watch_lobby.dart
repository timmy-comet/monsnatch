import 'package:dartz/dartz.dart';
import '../entities/lobby_entity.dart';
import '../repositories/lobby_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class WatchLobby implements StreamUseCase<LobbyEntity, String> {
  final LobbyRepository repository;
  const WatchLobby(this.repository);

  @override
  Stream<Either<Failure, LobbyEntity>> call(String lobbyId) =>
      repository.watchLobby(lobbyId);
}