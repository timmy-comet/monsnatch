import 'package:equatable/equatable.dart';
import '../../../domain/entities/lobby_entity.dart';

sealed class LobbyState extends Equatable {
  const LobbyState();
  @override
  List<Object?> get props => [];
}

class LobbyInitial   extends LobbyState { const LobbyInitial(); }
class LobbyLoading   extends LobbyState { const LobbyLoading(); }

class LobbyLoaded extends LobbyState {
  final LobbyEntity lobby;
  const LobbyLoaded(this.lobby);
  @override
  List<Object> get props => [lobby];
}

class LobbyError extends LobbyState {
  final String message;
  const LobbyError(this.message);
  @override
  List<Object> get props => [message];
}