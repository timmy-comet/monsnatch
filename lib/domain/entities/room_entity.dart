import 'package:equatable/equatable.dart';
import 'card_entity.dart';

class RoomEntity extends Equatable {
  // ── Server fields ──────────────────────────────────
  final String  code;
  final String  status;      // 'available' | 'unavailable' | 'done'
  final String? player1;    // uid
  final String? player2;    // uid — null while waiting
  final String? createdBy;

  // ── Local game state (seeded locally for now) ──────
  final int               player1Score;
  final int               player2Score;
  final int               timerSeconds;
  final bool              isPlayer1Turn;
  final List<CardEntity?> grid;
  final List<CardEntity>  hand;

  const RoomEntity({
    required this.code,
    this.status       = 'available',
    this.player1,
    this.player2,
    this.createdBy,
    this.player1Score = 0,
    this.player2Score = 0,
    this.timerSeconds = 30,
    this.isPlayer1Turn = true,
    this.grid  = const [null,null,null,null,null,null,null,null,
                        null,null,null,null,null,null,null,null],
    this.hand  = const [],
  });

  bool get hasOpponent => player2 != null;

  RoomEntity copyWith({
    String? status, String? player1, String? player2,
    int? player1Score, int? player2Score, int? timerSeconds,
    bool? isPlayer1Turn, List<CardEntity?>? grid, List<CardEntity>? hand,
  }) => RoomEntity(
    code:          code,
    status:        status         ?? this.status,
    player1:       player1        ?? this.player1,
    player2:       player2        ?? this.player2,
    createdBy:     createdBy,
    player1Score:  player1Score   ?? this.player1Score,
    player2Score:  player2Score   ?? this.player2Score,
    timerSeconds:  timerSeconds   ?? this.timerSeconds,
    isPlayer1Turn: isPlayer1Turn  ?? this.isPlayer1Turn,
    grid:          grid           ?? this.grid,
    hand:          hand           ?? this.hand,
  );

  @override
  List<Object?> get props =>
      [code, status, player1, player2, player1Score, player2Score, hand, grid];
}