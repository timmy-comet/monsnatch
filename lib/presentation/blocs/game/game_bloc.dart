import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/room_entity.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc(RoomEntity room) : super(GameState.fromRoom(room)) {
    on<CardDropped>(_onCardDropped);
  }

  void _onCardDropped(CardDropped event, Emitter<GameState> emit) {
    final newGrid = [...state.grid];
    final card = state.hand.where((c) => c.id == event.cardId).firstOrNull;
    if (card == null || newGrid[event.cellIndex] != null) return;

    newGrid[event.cellIndex] = card;
    final newHand = state.hand.where((c) => c.id != event.cardId).toList();
    emit(state.copyWith(
      grid:          newGrid,
      hand:          newHand,
      isPlayer1Turn: !state.isPlayer1Turn,
    ));
  }
}
