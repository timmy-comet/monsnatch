import 'package:equatable/equatable.dart';
import 'card_entity.dart';

class RoomEntity extends Equatable {
  final String            code;           // 6-char room code
  final int               player1Score;
  final int               player2Score;
  final int               timerSeconds;
  final bool              isPlayer1Turn;
  final List<CardEntity?> grid;           // 16 cells
  final List<CardEntity>  hand;

  const RoomEntity({
    required this.code,
    this.player1Score = 0,
    this.player2Score = 0,
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

  @override
  List<Object?> get props =>
      [code, player1Score, player2Score, timerSeconds, isPlayer1Turn, grid, hand];
}