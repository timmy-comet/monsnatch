import 'package:equatable/equatable.dart';

sealed class LobbyEvent extends Equatable {
  const LobbyEvent();
  @override
  List<Object> get props => [];
}

class WatchLobbyStarted extends LobbyEvent {
  final String lobbyId;
  const WatchLobbyStarted(this.lobbyId);
  @override
  List<Object> get props => [lobbyId];
}

class CardPlaced extends LobbyEvent {
  final String cardId;
  final int cellIndex;
  const CardPlaced(this.cardId, this.cellIndex);
  @override
  List<Object> get props => [cardId, cellIndex];
}