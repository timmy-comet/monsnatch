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
 
  @override
  List<Object?> get props => [code, createdBy, status, player1, player2, game, leftBy];
}