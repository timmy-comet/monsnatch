import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/lobby_repository.dart';

class PlaceCard extends FutureUseCase<void, PlaceCardParams> {
  final LobbyRepository repository;

  PlaceCard(this.repository);

  @override
  Future<Either<Failure, void>> call(PlaceCardParams params) {
    return repository.placeCard(
      lobbyId: params.lobbyId,
      cardId: params.cardId,
      cellIndex: params.cellIndex,
    );
  }
}

class PlaceCardParams {
  final String lobbyId;
  final String cardId;
  final int cellIndex;

  const PlaceCardParams({
    required this.lobbyId,
    required this.cardId,
    required this.cellIndex,
  });
}
