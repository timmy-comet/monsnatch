import 'package:equatable/equatable.dart';
import 'card_entity.dart';

class LobbyEntity extends Equatable {
  final String lobbyId;
  final int player1Score;
  final int player2Score;
  final int timerSeconds;
  final bool isPlayer1Turn;

  /// 16-element list, null means empty cell
  final List<CardEntity?> grid;
  final List<CardEntity> hand;

  const LobbyEntity({
    required this.lobbyId,
    required this.player1Score,
    required this.player2Score,
    required this.timerSeconds,
    required this.isPlayer1Turn,
    required this.grid,
    required this.hand,
  });

  @override
  List<Object?> get props =>
      [lobbyId, player1Score, player2Score, timerSeconds, isPlayer1Turn, grid, hand];
}