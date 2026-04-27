import 'package:equatable/equatable.dart';
import 'game_state_entity.dart';
 
class RoomEntity extends Equatable {
  final String  code;
  final String  createdBy;   // uid of room creator (host)
  final String  status;      // 'available' | 'unavailable' | 'done'
  final String? player1;
  final String? player2;
  final GameStateEntity? game;
  final List<String>? playAgainVotes;
  final String?  leftBy;     // set when a player explicitly leaves

  const RoomEntity({
    required this.code,
    required this.createdBy,
    required this.status,
    this.player1,
    this.player2,
    this.game,
    this.playAgainVotes,
    this.leftBy,
  });

  bool get hasOpponent   => player2 != null;
  bool get isGameStarted => game != null;
  bool get isOpponentLeft => leftBy != null;

  GameStateEntity? get currentGame => game;

  bool hasVotedPlayAgain(String uid) =>
      playAgainVotes?.contains(uid) ?? false;

  RoomEntity copyWith({
    String?          code,
    String?          createdBy,
    String?          status,
    String?          player1,
    String?          player2,
    GameStateEntity? game,
    List<String>?    playAgainVotes,
    String?          leftBy,
  }) =>
      RoomEntity(
        code:           code           ?? this.code,
        createdBy:      createdBy      ?? this.createdBy,
        status:         status         ?? this.status,
        player1:        player1        ?? this.player1,
        player2:        player2        ?? this.player2,
        game:           game           ?? this.game,
        playAgainVotes: playAgainVotes ?? this.playAgainVotes,
        leftBy:         leftBy         ?? this.leftBy,
      );

  @override
  List<Object?> get props => [code, createdBy, status, player1, player2, game, leftBy];
}