import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_cards.dart';
import '../../../domain/usecases/get_user_by_id.dart';
import '../../../domain/usecases/play_card.dart';
import '../../../domain/usecases/watch_room.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final GetCards       _getCards;
  final GetUserById    _getUserById;
  final PlayCard       _playCard;
  final WatchRoom      _watchRoom;

  Timer? _countdownTimer;
  StreamSubscription<dynamic>? _wsSub;

  GameBloc({
    required GetCards       getCards,
    required GetUserById    getUserById,
    required PlayCard       playCard,
    required WatchRoom      watchRoom,
  })  : _getCards    = getCards,
        _getUserById = getUserById,
        _playCard    = playCard,
        _watchRoom   = watchRoom,
        super(const GameBlocState()) {
    on<GameInitialized>(_onInitialized);
    on<GameRoomUpdated>(_onRoomUpdated);
    on<GameCardTapped>(_onCardTapped);
    on<GameCellTapped>(_onCellTapped);
    on<GameTimerTick>(_onTimerTick);
    on<GameExited>(_onExited);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onInitialized(
      GameInitialized event, Emitter<GameBlocState> emit) async {
    emit(state.copyWith(
      room:  event.room,
      myUid: event.myUid,
      phase: GamePhase.playing,
    ));

    // 1. Fetch card catalog
    final cardsResult = await _getCards();
    cardsResult.fold(
      (f) => emit(state.copyWith(errorMessage: 'Cards load failed: ${f.message}')),
      (cards) => emit(state.copyWith(catalog: cards)),
    );

    // 2. Fetch opponent username
    final opponentUid = event.room.player1 == event.myUid
        ? event.room.player2
        : event.room.player1;
    if (opponentUid != null) {
      final userResult = await _getUserById(opponentUid);
      userResult.fold(
        (_) {},
        (user) => emit(state.copyWith(opponentUsername: user.username)),
      );
    }

    // 3. Open WebSocket — replace state on every update
    _listenToRoom(event.room.code);

    // 4. Start 500ms countdown timer
    _startCountdownTimer();
  }

  Future<void> _onRoomUpdated(
      GameRoomUpdated event, Emitter<GameBlocState> emit) async {
    final newPhase = event.room.status == 'done'
        ? GamePhase.done
        : GamePhase.playing;

    emit(state.copyWith(
      room:         event.room,
      phase:        newPhase,
      isSubmitting: false,   // unlock UI on every server ack
      clearError:   true,
    ));
  }

  void _onCardTapped(GameCardTapped event, Emitter<GameBlocState> emit) {
    // Toggle: tap same card → deselect; tap new card → select.
    final newId = state.selectedCardId == event.cardId ? null : event.cardId;
    emit(state.copyWith(selectedCardId: newId, clearSelected: newId == null));
  }

  Future<void> _onCellTapped(
      GameCellTapped event, Emitter<GameBlocState> emit) async {
    if (!state.canPlay(event.cellIndex)) return;
    if (state.room == null || state.selectedCardId == null) return;

    // Lock UI immediately; do NOT change board locally — wait for WS echo.
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _playCard(PlayCardParams(
      code:      state.room!.code,
      cellIndex: event.cellIndex,
      cardId:    state.selectedCardId!,
    ));

    result.fold(
      (f) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: f.message,
      )),
      // Success: do nothing — WS will push the new state.
      (_) => {},
    );
  }

  void _onTimerTick(GameTimerTick _, Emitter<GameBlocState> emit) {
    final deadline = state.room?.game?.turnDeadline;
    if (deadline == null) return;
    final seconds = deadline.difference(DateTime.now()).inSeconds.clamp(0, 30);
    emit(state.copyWith(countdownSeconds: seconds));
  }

  void _onExited(GameExited _, Emitter<GameBlocState> emit) {
    _cleanup();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _listenToRoom(String code) {
    _wsSub?.cancel();
    final stream = _watchRoom(code);
    // We use a subscription rather than emit.forEach so it can be cancelled independently.
    _wsSub = stream.listen(
      (result) => result.fold(
        (f) => add(GameRoomUpdated(state.room!)), // keep existing on error
        (room) => add(GameRoomUpdated(room)),
      ),
    );
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => add(const GameTimerTick()),
    );
  }

  void _cleanup() {
    _countdownTimer?.cancel();
    _wsSub?.cancel();
    _watchRoom.stop();
    _countdownTimer = null;
    _wsSub = null;
  }

  @override
  Future<void> close() {
    _cleanup();
    return super.close();
  }
}