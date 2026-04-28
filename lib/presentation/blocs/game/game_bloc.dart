import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/game_cell_entity.dart';
import '../../../domain/entities/hand_card_entity.dart';
import '../../../domain/entities/last_move_entity.dart';
import '../../../domain/services/capture_calculator.dart';
import '../../../domain/usecases/get_cards.dart';
import '../../../domain/usecases/get_user_by_id.dart';
import '../../../domain/usecases/play_card.dart';
import 'game_event.dart';
import 'game_state.dart';
 
class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final GetCards    _getCards;
  final GetUserById _getUserById;
  final PlayCard    _playCard;
 
  Timer? _countdownTimer;
 
  GameBloc({
    required GetCards    getCards,
    required GetUserById getUserById,
    required PlayCard    playCard,
  })  : _getCards    = getCards,
        _getUserById = getUserById,
        _playCard    = playCard,
        super(const GameBlocState()) {
    on<GameInitialized>      (_onInitialized);
    on<GameRoomUpdated>      (_onRoomUpdated);
    on<GameCardTapped>       (_onCardTapped);
    on<GameCellTapped>       (_onCellTapped);
    on<GameCardDroppedOnCell>(_onCardDroppedOnCell);
    on<GameTimerTick>        (_onTimerTick);
  }
 
  // ── Handlers ──────────────────────────────────────────────────────────────
 
  Future<void> _onInitialized(GameInitialized event, Emitter<GameBlocState> emit) async {
    emit(state.copyWith(
      room:  event.room,
      myUid: event.myUid,
      phase: GamePhase.playing,
    ));
 
    // 1. Load card catalog from GET /cards
    final cardsResult = await _getCards();
    cardsResult.fold(
      (f) => emit(state.copyWith(errorMessage: 'Card catalog: ${f.message}')),
      (cards) => emit(state.copyWith(
        catalog: {for (final c in cards) c.id: c},
      )),
    );
 
    // 2. Load opponent username
    final oppUid = event.room.player1 == event.myUid
        ? event.room.player2
        : event.room.player1;
    if (oppUid != null) {
      final userResult = await _getUserById(oppUid);
      userResult.fold(
        (_) {},
        (u) => emit(state.copyWith(opponentUsername: u.username)),
      );
    }
 
    // 3. Start countdown timer (500ms ticks)
    _startCountdown();
  }
 
  void _onRoomUpdated(GameRoomUpdated event, Emitter<GameBlocState> emit) {
    final newPhase = event.room.status == 'done'
        ? GamePhase.done
        : GamePhase.playing;

    // If the chosen card no longer exists in my active hand (e.g. just played),
    // clear the selection. Keep it if still active so the player can pre-select
    // while the opponent is thinking.
    final newActive = event.room.currentGame?.activeCardIds(state.myUid) ?? const <int>[];
    final keepSelection =
        state.selectedCardId != null && newActive.contains(state.selectedCardId);

    emit(state.copyWith(
      room:          event.room,
      phase:         newPhase,
      isSubmitting:  false,  // unlock UI on every server ack
      clearError:    true,
      clearSelected: !keepSelection,
    ));
  }
 
  void _onCardTapped(GameCardTapped event, Emitter<GameBlocState> emit) {
    // Toggle: tap same card → deselect
    if (state.selectedCardId == event.cardId) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedCardId: event.cardId));
    }
  }
 
  Future<void> _onCellTapped(GameCellTapped event, Emitter<GameBlocState> emit) async {
    final cardId = state.selectedCardId;
    if (cardId == null) return;
    await _placeCard(cellIndex: event.cellIndex, cardId: cardId, emit: emit);
  }

  Future<void> _onCardDroppedOnCell(
    GameCardDroppedOnCell event,
    Emitter<GameBlocState> emit,
  ) async {
    await _placeCard(cellIndex: event.cellIndex, cardId: event.cardId, emit: emit);
  }

  Future<void> _placeCard({
    required int cellIndex,
    required int cardId,
    required Emitter<GameBlocState> emit,
  }) async {
    if (!state.canPlay(cellIndex)) return;
    final snapshot = state.room;
    final game     = snapshot?.currentGame;
    final myUid    = state.myUid;
    final placed   = state.cardById(cardId);
    if (snapshot == null || game == null || placed == null) {
      return;
    }

    // Optimistic placement — apply the move locally so the UI feels instant.
    // Captures are also computed locally (port of backend `capture.ts`) so
    // flipped cards animate the moment the card lands. Server echo via WS
    // overrides on mismatch. On HTTP error we revert to the snapshot.
    final newBoard = List<GameCellEntity?>.from(game.board);
    newBoard[cellIndex] = GameCellEntity(
      cardId:   cardId,
      ownerUid: myUid,
      placedBy: myUid,
    );

    final isPlayer2 = snapshot.player2 == myUid;
    final captures  = CaptureCalculator.compute(
      placedCard: placed,
      cellIndex:  cellIndex,
      board:      newBoard,
      catalog:    state.catalog,
      isPlayer2:  isPlayer2,
    );
    for (final idx in captures) {
      final target = newBoard[idx];
      if (target != null) {
        newBoard[idx] = GameCellEntity(
          cardId:   target.cardId,
          ownerUid: myUid,                 // flip to my team
          placedBy: target.placedBy,       // immutable per backend
        );
      }
    }

    final myHand = game.hands[myUid] ?? const <HandCardEntity>[];
    final newMyHand = myHand
        .map((c) => c.cardId == cardId
            ? HandCardEntity(cardId: c.cardId, used: true)
            : c)
        .toList();
    final newHands = Map<String, List<HandCardEntity>>.from(game.hands)
      ..[myUid] = newMyHand;

    final oppUid   = state.opponentUid;
    // Recompute score by counting owners on the board — matches the way
    // the backend rebuilds it after each placement.
    final newScore = <String, int>{};
    for (final cell in newBoard) {
      if (cell == null) continue;
      newScore[cell.ownerUid] = (newScore[cell.ownerUid] ?? 0) + 1;
    }

    final optimisticGame = game.copyWith(
      board:    newBoard,
      hands:    newHands,
      score:    newScore,
      turn:     oppUid.isEmpty ? game.turn : oppUid,
      lastMove: LastMoveEntity(
        cellIndex: cellIndex,
        cardId:    cardId,
        placedBy:  myUid,
        captures:  captures,
      ),
    );
    final optimistic = snapshot.copyWith(game: optimisticGame);

    emit(state.copyWith(
      room:          optimistic,
      isSubmitting:  true,
      clearError:    true,
      clearSelected: true,
    ));

    // Tactile feedback: stronger thump if we captured anything.
    if (captures.isNotEmpty) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    final result = await _playCard(PlayCardParams(
      code:      snapshot.code,
      cellIndex: cellIndex,
      cardId:    cardId,
    ));

    result.fold(
      // On error: revert optimistic state, unlock, show error.
      (f) => emit(state.copyWith(
        room:         snapshot,
        isSubmitting: false,
        errorMessage: _mapFailure(f),
      )),
      // On success: WS echo via RoomBloc → GameRoomUpdated brings the
      // authoritative board. If captures or score differ slightly the echo
      // simply overwrites — usually it matches our optimistic copy.
      (_) {},
    );
  }
 
  void _onTimerTick(GameTimerTick _, Emitter<GameBlocState> emit) {
    final deadline = state.room?.currentGame?.turnDeadline;
    if (deadline == null) return;
    final secs = deadline.difference(DateTime.now()).inSeconds.clamp(0, 30);
    emit(state.copyWith(countdownSeconds: secs));
  }
 
  // ── Countdown ─────────────────────────────────────────────────────────────
 
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) { if (!isClosed) add(const GameTimerTick()); },
    );
  }
 
  String _mapFailure(Failure f) => switch (f) {
    AuthFailure()    => 'Session expired. Please re-open the app.',
    NetworkFailure() => 'No connection. Check your network.',
    RoomFailure()    => _humanizeRoomError(f.message),
    _                => f.message,
  };

  /// Rewrite the most common server messages to short, actionable lines.
  /// Falls back to the raw message if nothing matches.
  String _humanizeRoomError(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('not your turn')) {
      return "It's not your turn yet.";
    }
    if (m.contains('cell occupied') || m.contains('not empty')) {
      return 'That cell is already taken.';
    }
    if (m.contains('card already used') || m.contains('not in hand')) {
      return 'That card is no longer in your hand.';
    }
    if (m.contains('not adjacent')) {
      return 'You can only play next to a placed card.';
    }
    if (m.contains('game over') || m.contains('match over')) {
      return 'The match has ended.';
    }
    return raw;
  }
 
  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}