import 'package:equatable/equatable.dart';
import 'game_state_entity.dart';

class RoomEntity extends Equatable {
  final String  code;
  final String  createdBy;  // uid of host = Player 1 = Star
  final String  status;     // 'available' | 'unavailable' | 'done'
  final String? player1;    // uid
  final String? player2;    // uid
  final GameStateEntity? game; // null until host calls POST /start

  const RoomEntity({
    required this.code,
    required this.createdBy,
    required this.status,
    this.player1,
    this.player2,
    this.game,
  });

  bool get hasOpponent => player2 != null;
  bool get isGameStarted => game != null;

  @override
  List<Object?> get props => [code, createdBy, status, player1, player2, game];
}