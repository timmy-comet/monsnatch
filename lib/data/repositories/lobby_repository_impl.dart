import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';

class LobbyRepositoryImpl implements LobbyRepository {
  /// Returns a mock lobby stream for frontend development
  @override
  Stream<Either<Failure, LobbyEntity>> watchLobby(String lobbyId) async* {
    // Mock hand of cards
    final mockHand = [
      const CardEntity(
        id: '1',
        name: 'Fire Dragon',
        imageAsset: 'assets/images/cards/fire_dragon.png',
        power: 5,
      ),
      const CardEntity(
        id: '2',
        name: 'Ice Wizard',
        imageAsset: 'assets/images/cards/ice_wizard.png',
        power: 3,
      ),
      const CardEntity(
        id: '3',
        name: 'Thunder Knight',
        imageAsset: 'assets/images/cards/thunder_knight.png',
        power: 7,
      ),
      const CardEntity(
        id: '4',
        name: 'Shadow Assassin',
        imageAsset: 'assets/images/cards/shadow_assassin.png',
        power: 2,
      ),
    ];

    // Initial lobby state with mock data
    yield Right(LobbyEntity(
      lobbyId: lobbyId,
      player1Score: 0,
      player2Score: 0,
      timerSeconds: 120,
      isPlayer1Turn: true,
      grid: List<CardEntity?>.filled(16, null),
      hand: mockHand,
    ));

    // Simulate timer updates
    int seconds = 120;
    while (seconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      seconds--;
      yield Right(LobbyEntity(
        lobbyId: lobbyId,
        player1Score: 0,
        player2Score: 0,
        timerSeconds: seconds,
        isPlayer1Turn: true,
        grid: List<CardEntity?>.filled(16, null),
        hand: mockHand,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> placeCard({
    required String lobbyId,
    required String cardId,
    required int cellIndex,
  }) async {
    // Mock implementation: just return success
    return const Right(null);
  }
}
