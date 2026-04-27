import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
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
    on<GameInitialized>  (_onInitialized);
    on<GameRoomUpdated>  (_onRoomUpdated);
    on<GameCardTapped>   (_onCardTapped);
    on<GameCellTapped>   (_onCellTapped);
    on<GameTimerTick>    (_onTimerTick);
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
    emit(state.copyWith(
      room:         event.room,
      phase:        newPhase,
      isSubmitting: false,  // unlock UI on every server ack
      clearError:   true,
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
    if (!state.canPlay(event.cellIndex)) return;
    final roomCode = state.room?.code;
    final cardId   = state.selectedCardId;
    if (roomCode == null || cardId == null) return;
 
    // Lock UI — do NOT mutate board locally; wait for WS echo
    emit(state.copyWith(isSubmitting: true, clearError: true));
 
    final result = await _playCard(PlayCardParams(
      code:      roomCode,
      cellIndex: event.cellIndex,
      cardId:    cardId,
    ));
 
    result.fold(
      // On error: unlock + show message. Board NOT updated — WS will push correct state.
      (f) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: _mapFailure(f),
      )),
      // On success: do nothing — WS echo via RoomBloc → GameRoomUpdated will arrive.
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
    AuthFailure()    => 'Session expired.',
    NetworkFailure() => 'No connection.',
    _                => f.message,
  };
 
  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}