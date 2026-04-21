import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/watch_lobby.dart';
import '../../../domain/usecases/place_card.dart';
import 'lobby_event.dart';
import 'lobby_state.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  final WatchLobby _watchLobby;
  final PlaceCard _placeCard;
  StreamSubscription? _sub;

  LobbyBloc({required WatchLobby watchLobby, required PlaceCard placeCard})
      : _watchLobby = watchLobby,
        _placeCard = placeCard,
        super(const LobbyInitial()) {
    on<WatchLobbyStarted>(_onWatchStarted);
    on<CardPlaced>(_onCardPlaced);
  }

  Future<void> _onWatchStarted(WatchLobbyStarted event, Emitter<LobbyState> emit) async {
    emit(const LobbyLoading());
    await _sub?.cancel();
    await emit.forEach(
      _watchLobby(event.lobbyId),
      onData: (result) => result.fold(
        (f) => LobbyError(f.message),
        (lobby) => LobbyLoaded(lobby),
      ),
      onError: (e, _) => LobbyError(e.toString()),
    );
  }

  Future<void> _onCardPlaced(CardPlaced event, Emitter<LobbyState> emit) async {
    final currentLobbyId = (state as LobbyLoaded?)?.lobby.lobbyId;
    if (currentLobbyId == null) return;
    await _placeCard(PlaceCardParams(
      lobbyId: currentLobbyId,
      cardId: event.cardId,
      cellIndex: event.cellIndex,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}