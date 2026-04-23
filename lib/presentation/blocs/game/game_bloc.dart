import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/faction.dart';
import '../../../domain/entities/grid_slot.dart';
import '../../../domain/entities/mon_card.dart';
import '../../../game/logic/snatch_engine.dart';
import '../../../game/data/mock_cards.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  Timer? _timer;

  GameBloc({Faction playerFaction = Faction.star})
      : super(_initialState(playerFaction)) {
    on<CardSelected>    (_onCardSelected);
    on<HandSwipedTo>    (_onHandSwiped);
    on<CardPlacedOnGrid> (_onCardPlaced, transformer: sequential());
    on<TimerTicked>     (_onTimerTick);
    on<AutoPlayTriggered>(_onAutoPlay);
    on<LensToggled>     (_onLensToggled);
    _startTimer();
  }

  static GameState _initialState(Faction pf) {
    final deck = MockCards.deck();
    return GameState(
      grid:               List.generate(16, (i) => GridSlot(index: i)),
      playerFaction:      pf,
      currentTurnFaction: Faction.star, // Star always goes first
      playerHand:         deck,
      opponentHand:       MockCards.deck(),
    );
  }

  // ── Timer ─────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const TimerTicked());
    });
  }

  void _onTimerTick(TimerTicked _, Emitter<GameState> emit) {
    if (state.phase == GamePhase.gameOver) return;
    final newSecs = state.timerSeconds - 1;
    if (newSecs <= 0) {
      add(const AutoPlayTriggered());
      return;
    }
    emit(state.copyWith(timerSeconds: newSecs, isUrgent: newSecs <= 10));
  }

  void _onAutoPlay(AutoPlayTriggered _, Emitter<GameState> emit) {
    if (!state.isPlayerTurn || state.playerHand.isEmpty) return;
    // Select focused card, place in first available slot
    final card = state.focusedCard;
    if (card == null) return;
    final firstEmpty = state.grid.indexWhere((s) => s.isEmpty);
    if (firstEmpty == -1) return;
    add(CardPlacedOnGrid(firstEmpty, card));
  }

  // ── Selection ─────────────────────────────────────────
  void _onCardSelected(CardSelected event, Emitter<GameState> emit) {
    emit(state.copyWith(
      selectedIndex: event.handIndex,
      focusIndex:    event.handIndex,
      isLensOpen:    false,
    ));
  }

  void _onHandSwiped(HandSwipedTo event, Emitter<GameState> emit) {
    emit(state.copyWith(
      focusIndex:    event.focusIndex,
      selectedIndex: event.focusIndex, // auto-select focused card
    ));
  }

  void _onLensToggled(LensToggled _, Emitter<GameState> emit) {
    emit(state.copyWith(isLensOpen: !state.isLensOpen));
  }

  // ── Core placement + Snatch resolution ───────────────
  void _onCardPlaced(CardPlacedOnGrid event, Emitter<GameState> emit) {
    final slot = state.grid[event.cellIndex];
    if (!slot.isEmpty || state.phase == GamePhase.gameOver) return;

    // Run snatch engine
    final result = SnatchEngine.resolve(
      grid:        state.grid,
      placedIndex: event.cellIndex,
      card:        event.card,
      faction:     state.currentTurnFaction,
    );

    // Remove card from appropriate hand
    final newPlayerHand = state.isPlayerTurn
        ? state.playerHand.where((c) => c.id != event.card.id).toList()
        : state.playerHand;
    final newOpponentHand = !state.isPlayerTurn
        ? state.opponentHand.where((c) => c.id != event.card.id).toList()
        : state.opponentHand;

    // Update scores
    final scores = SnatchEngine.countScores(result.grid);

    // Check game over: all 16 slots filled
    final nextTurn    = state.turnNumber + 1;
    final isGameOver  = nextTurn > 16;
    final nextFaction = state.currentTurnFaction.opponent;

    Faction? winner;
    if (isGameOver) {
      if      (scores.star >  scores.moon) winner = Faction.star;
      else if (scores.moon > scores.star)  winner = Faction.moon;
      // else draw — winner stays null
    }

    emit(state.copyWith(
      grid:               result.grid,
      lastFlipped:        result.flippedIndices,
      playerHand:         newPlayerHand,
      opponentHand:       newOpponentHand,
      currentTurnFaction: isGameOver ? state.currentTurnFaction : nextFaction,
      focusIndex:         0,
      clearSelected:      true,
      timerSeconds:       30,
      isUrgent:           false,
      starScore:          scores.star,
      moonScore:          scores.moon,
      isLensOpen:         false,
      phase:              isGameOver ? GamePhase.gameOver : GamePhase.waitingForSelection,
      turnNumber:         nextTurn,
      winner:             winner,
    ));

    if (!isGameOver) _startTimer();
    else _timer?.cancel();

    // Simple AI: if next turn is opponent, auto-place after delay
    if (!isGameOver && nextFaction != state.playerFaction) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!isClosed) _aiTurn();
      });
    }
  }

  /// Minimal AI: places its first card in the first empty slot.
  void _aiTurn() {
    if (state.opponentHand.isEmpty) return;
    final card      = state.opponentHand.first;
    final emptySlot = state.grid.indexWhere((s) => s.isEmpty);
    if (emptySlot != -1) add(CardPlacedOnGrid(emptySlot, card));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

/// Ensures CardPlacedOnGrid events are processed one at a time (no race with AI).
EventTransformer<T> sequential<T>() => (events, mapper) => events.asyncExpand(mapper);