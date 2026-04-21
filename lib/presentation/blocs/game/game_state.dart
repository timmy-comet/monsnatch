import 'package:equatable/equatable.dart';
import '../../../domain/entities/card_entity.dart';
import '../../../domain/entities/room_entity.dart';

class GameState extends Equatable {
  final int               player1Score;
  final int               player2Score;
  final int               timerSeconds;
  final bool              isPlayer1Turn;
  final List<CardEntity?> grid;
  final List<CardEntity>  hand;

  const GameState({
    this.player1Score = 6,
    this.player2Score = 5,
    this.timerSeconds = 30,
    this.isPlayer1Turn = true,
    this.grid = const [
      null,null,null,null,
      null,null,null,null,
      null,null,null,null,
      null,null,null,null,
    ],
    this.hand = const [],
  });

  factory GameState.fromRoom(RoomEntity room) => GameState(
        player1Score: room.player1Score,
        player2Score: room.player2Score,
        timerSeconds: room.timerSeconds,
        isPlayer1Turn: room.isPlayer1Turn,
        grid: room.grid,
        hand: room.hand,
      );

  GameState copyWith({
    int? player1Score, int? player2Score, int? timerSeconds,
    bool? isPlayer1Turn, List<CardEntity?>? grid, List<CardEntity>? hand,
  }) => GameState(
    player1Score:  player1Score  ?? this.player1Score,
    player2Score:  player2Score  ?? this.player2Score,
    timerSeconds:  timerSeconds  ?? this.timerSeconds,
    isPlayer1Turn: isPlayer1Turn ?? this.isPlayer1Turn,
    grid:          grid          ?? this.grid,
    hand:          hand          ?? this.hand,
  );

  @override
  List<Object?> get props =>
      [player1Score, player2Score, timerSeconds, isPlayer1Turn, grid, hand];
}
