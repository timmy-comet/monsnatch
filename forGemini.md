lib/domain/entities/card_entity.dart

import 'package:equatable/equatable.dart';

/// Matches CardPublic from GET /cards.
/// Directions use the server's 8-compass notation.
class CardEntity extends Equatable {
  final int    id;        // 1..12
  final String name;
  final String element;  // "fire"|"water"|"earth"|"wind"|"light"|"dark"|...
  final int    power;    // 4..7
  final List<String> directions; // "t"|"tr"|"r"|"br"|"b"|"bl"|"l"|"tl"

  const CardEntity({
    required this.id,
    required this.name,
    required this.element,
    required this.power,
    required this.directions,
  });

  /// Asset path — bundle cards as assets/images/cards/card_<id>.png
  String get imageAsset => 'assets/images/cards/card_$id.png';

  @override
  List<Object> get props => [id];
}

lib/domain/entities/room_entity.dart
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

lib/domain/entities/game_state_entity.dart

import 'package:equatable/equatable.dart';
import 'game_cell_entity.dart';
import 'last_move_entity.dart';

/// Full game state from the server (GameStatePublic).
/// Arrives inside RoomPublic.game via WS or REST response.
class GameStateEntity extends Equatable {
  final List<GameCellEntity?> board;      // 16 slots; null = empty
  final Map<String, List<int>> hands;    // uid → list of cardIds remaining
  final String turn;                     // uid of player whose turn it is
  final int    turnNumber;               // 0-based; 0 = first move
  final DateTime turnDeadline;           // UTC — countdown = deadline - now()
  final DateTime startedAt;
  final Map<String, int> score;          // uid → cells owned
  final String? winner;                  // null = ongoing or draw
  final LastMoveEntity? lastMove;

  const GameStateEntity({
    required this.board,
    required this.hands,
    required this.turn,
    required this.turnNumber,
    required this.turnDeadline,
    required this.startedAt,
    required this.score,
    this.winner,
    this.lastMove,
  });

  @override
  List<Object?> get props => [
    board, hands, turn, turnNumber, turnDeadline, score, winner, lastMove,
  ];
}

lib/domain/entities/game_cell_entity.dart

import 'package:equatable/equatable.dart';

/// A single occupied cell on the 4×4 board.
/// Mirrors the server's GameCell shape.
/// ownerUid drives the star/moon token — compare with room.createdBy.
class GameCellEntity extends Equatable {
  final int    cardId;     // 1-12 — used to look up art + card data
  final String ownerUid;  // current token holder — changes on capture
  final String placedBy;  // immutable after placement

  const GameCellEntity({
    required this.cardId,
    required this.ownerUid,
    required this.placedBy,
  });

  @override
  List<Object> get props => [cardId, ownerUid, placedBy];
}

lib/domain/repositories/room_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/card_entity.dart';
import '../entities/room_entity.dart';
import '../../core/errors/failures.dart';

abstract class RoomRepository {
  Future<Either<Failure, RoomEntity>> createRoom();
  Future<Either<Failure, RoomEntity>> joinRoom(String code);
  Future<Either<Failure, RoomEntity>> startRoom(String code);
  Future<Either<Failure, RoomEntity>> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  });
  Future<Either<Failure, List<CardEntity>>> getCards();
  Stream<Either<Failure, RoomEntity>> watchRoom(String code);
  void stopWatching();
}

lib/data/models/card_model.dart
import '../../domain/entities/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.name,
    required super.element,
    required super.power,
    required super.directions,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id:         json['id']      as int,
    name:       json['name']    as String,
    element:    json['element'] as String,
    power:      json['power']   as int,
    directions: (json['directions'] as List<dynamic>)
        .map((d) => d as String)
        .toList(),
  );
}

lib/data/models/room_model.dart
import '../../domain/entities/room_entity.dart';
import 'game_state_model.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.code,
    required super.createdBy,
    required super.status,
    super.player1,
    super.player2,
    super.game,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    code:      json['code']      as String,
    createdBy: json['createdBy'] as String,
    status:    json['status']    as String,
    player1:   json['player1']   as String?,
    player2:   json['player2']   as String?,
    game:      json['game'] == null
        ? null
        : GameStateModel.fromJson(json['game'] as Map<String, dynamic>),
  );
}

lib/data/models/game_state_model.dart

import '../../domain/entities/game_state_entity.dart';
import 'game_cell_model.dart';
import 'last_move_model.dart';

class GameStateModel extends GameStateEntity {
  const GameStateModel({
    required super.board,
    required super.hands,
    required super.turn,
    required super.turnNumber,
    required super.turnDeadline,
    required super.startedAt,
    required super.score,
    super.winner,
    super.lastMove,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    // board: (GameCell | null)[16]
    final rawBoard = json['board'] as List<dynamic>;
    final board = rawBoard.map((cell) {
      if (cell == null) return null;
      return GameCellModel.fromJson(cell as Map<String, dynamic>);
    }).toList();

    // hands: { uid: number[] }
    final rawHands = json['hands'] as Map<String, dynamic>? ?? {};
    final hands = rawHands.map((uid, cardIds) => MapEntry(
      uid,
      (cardIds as List<dynamic>).map((id) => id as int).toList(),
    ));

    // score: { uid: number }
    final rawScore = json['score'] as Map<String, dynamic>? ?? {};
    final score = rawScore.map((uid, s) => MapEntry(uid, s as int));

    return GameStateModel(
      board:        board,
      hands:        hands,
      turn:         json['turn'] as String,
      turnNumber:   json['turnNumber'] as int,
      turnDeadline: DateTime.parse(json['turnDeadline'] as String).toLocal(),
      startedAt:    DateTime.parse(json['startedAt']    as String).toLocal(),
      score:        score,
      winner:       json['winner'] as String?,
      lastMove:     json['lastMove'] == null
          ? null
          : LastMoveModel.fromJson(json['lastMove'] as Map<String, dynamic>),
    );
  }
}

lib/data/datasources/room_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_service.dart';
import '../models/card_model.dart';
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  Future<RoomModel> createRoom();
  Future<RoomModel> getRoom(String code);
  Future<RoomModel> joinRoom(String code);
  Future<RoomModel> startRoom(String code);
  Future<RoomModel> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  });
  Future<List<CardModel>> getCards();
  Stream<RoomModel>  watchRoom(String code, String token);
  void              stopWatching();
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final ApiClient       _client;
  final WebSocketService _ws;

  const RoomRemoteDataSourceImpl(this._client, this._ws);

  // ── REST ─────────────────────────────────────────────────────────────────

  @override
  Future<RoomModel> createRoom() async {
    try {
      final res = await _client.post<Map<String, dynamic>>('/rooms', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create room');
    }
  }

  @override
  Future<RoomModel> getRoom(String code) async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/rooms/$code');
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Room not found');
    }
  }

  @override
  Future<RoomModel> joinRoom(String code) async {
    try {
      final res = await _client
          .post<Map<String, dynamic>>('/rooms/$code/join', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to join room');
    }
  }

  /// POST /rooms/:code/start — host only.
  @override
  Future<RoomModel> startRoom(String code) async {
    try {
      final res = await _client
          .post<Map<String, dynamic>>('/rooms/$code/start', data: {});
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to start game');
    }
  }

  /// POST /rooms/:code/play — { cellIndex, cardId }.
  /// Do NOT update local state after this returns; wait for the WS echo.
  @override
  Future<RoomModel> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/rooms/$code/play',
        data: {'cellIndex': cellIndex, 'cardId': cardId},
      );
      return RoomModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Move rejected');
    }
  }

  /// GET /cards — full card catalog (12 cards), fetch once per session.
  @override
  Future<List<CardModel>> getCards() async {
    try {
      final res = await _client.get<List<dynamic>>('/cards');
      return (res.data ?? [])
          .map((json) => CardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to load cards');
    }
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  @override
  Stream<RoomModel> watchRoom(String code, String token) {
    return _ws
        .connect(code, token)
        .where((msg) => msg['type'] == 'room_update')
        .map((msg) {
          final roomJson = msg['room'] as Map<String, dynamic>;
          return RoomModel.fromJson(roomJson);
        });
  }

  @override
  void stopWatching() => _ws.disconnect();

  // ── Error mapping ─────────────────────────────────────────────────────────

  ServerException _mapError(DioException e, String fallback) {
    String? msg;
    try {
      msg = (e.response?.data as Map?)?['error'] as String?;
    } catch (_) {}
    return ServerException(msg ?? fallback, statusCode: e.response?.statusCode);
  }
}

lib/data/repositories/room_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/room_remote_datasource.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remote;
  final AuthLocalDataSource  _auth;

  const RoomRepositoryImpl(this._remote, this._auth);

  @override
  Future<Either<Failure, RoomEntity>> createRoom() =>
      _wrap(() => _remote.createRoom());

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) =>
      _wrap(() => _remote.joinRoom(code.toUpperCase()));

  @override
  Future<Either<Failure, RoomEntity>> startRoom(String code) =>
      _wrap(() => _remote.startRoom(code));

  @override
  Future<Either<Failure, RoomEntity>> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  }) =>
      _wrap(() => _remote.playCard(
        code:      code,
        cellIndex: cellIndex,
        cardId:    cardId,
      ));

  @override
  Future<Either<Failure, List<CardEntity>>> getCards() async {
    try {
      final models = await _remote.getCards();
      return right(models);
    } on ServerException catch (e) {
      return left(RoomFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RoomEntity>> watchRoom(String code) async* {
    final token = await _auth.getIdToken();
    if (token == null) {
      yield left(const AuthFailure('Session expired. Please re-register.'));
      return;
    }
    try {
      await for (final model in _remote.watchRoom(code, token)) {
        yield right(model);
      }
    } catch (e) {
      yield left(NetworkFailure(e.toString()));
    }
  }

  @override
  void stopWatching() => _remote.stopWatching();

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<Either<Failure, RoomEntity>> _wrap(
      Future<RoomEntity> Function() call) async {
    try {
      return right(await call());
    } on ServerException catch (e) {
      if (e.statusCode == 401) return left(AuthFailure(e.message));
      return left(RoomFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }
}

lib/presentation/blocs/game/game_bloc.dart
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

lib/presentation/pages/game_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/room_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/grid_widget.dart';
import '../widgets/hand_card_widget.dart';
import 'victory_page.dart';

class GamePage extends StatefulWidget {
  final RoomEntity room;
  final String     myUid;
  const GamePage({super.key, required this.room, required this.myUid});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  void initState() {
    super.initState();
    // Kick off loading: card catalog, opponent name, WS, countdown
    context.read<GameBloc>().add(GameInitialized(
      room:  widget.room,
      myUid: widget.myUid,
    ));
  }

  @override
  void dispose() {
    context.read<GameBloc>().add(const GameExited());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<GameBloc, GameBlocState>(
          builder: (ctx, state) {
            // Loading splash
            if (state.phase == GamePhase.loading ||
                state.room?.game == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // ── Header: title, timer, scores ──
                    GameHeaderWidget(state: state),

                    // ── Opponent hand (face-down) ──
                    _OpponentStrip(state: state),

                    // ── 4×4 Board ──
                    Expanded(child: GridWidget(state: state)),

                    // ── Error toast ──
                    if (state.errorMessage != null)
                      Container(
                        color:   Colors.red.shade50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(state.errorMessage!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        ]),
                      ),

                    // ── My hand ──
                    _MyHand(state: state),
                  ],
                ),

                // ── Game-over overlay ──
                if (state.phase == GamePhase.done)
                  VictoryOverlay(
                    state:    state,
                    onReturn: () => Navigator.of(context).pop(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Opponent strip (top) ──────────────────────────────────────────────────────
class _OpponentStrip extends StatelessWidget {
  final GameBlocState state;
  const _OpponentStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final handCount = state.opponentHand.length;
    final isOppStar = !state.iAmStar;

    return Container(
      color:   AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Token badge
          CircleAvatar(
            radius:          14,
            backgroundColor: isOppStar
                ? AppColors.starFaction
                : AppColors.moonFaction,
            child: Icon(
              isOppStar ? Icons.star_rounded : Icons.nightlight_round,
              color: Colors.white, size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              state.opponentUsername ?? 'Opponent',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text('Cards: $handCount',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.subtitleText)),
          ]),
          const Spacer(),
          Text('${state.opponentScore}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),

          // Face-down hand placeholders
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap:      true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:    handCount.clamp(0, 12),
              separatorBuilder: (_, __) => const SizedBox(width: 3),
              itemBuilder: (_, __) => Container(
                width: 16,
                decoration: BoxDecoration(
                  color:        Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My hand (bottom) ──────────────────────────────────────────────────────────
class _MyHand extends StatelessWidget {
  final GameBlocState state;
  const _MyHand({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My score + team label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              CircleAvatar(
                radius:          14,
                backgroundColor: state.iAmStar
                    ? AppColors.starFaction
                    : AppColors.moonFaction,
                child: Icon(
                  state.iAmStar
                      ? Icons.star_rounded
                      : Icons.nightlight_round,
                  color: Colors.white, size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text('You  ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('${state.myScore}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 6),

          // Scrollable hand
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount:    state.myHand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cardId = state.myHand[i];
                final card   = state.cardById(cardId);
                final isSelected = state.selectedCardId == cardId;
                final canInteract = state.isMyTurn && !state.isSubmitting;

                return HandCardWidget(
                  cardId:     cardId,
                  card:       card,
                  isSelected: isSelected,
                  enabled:    canInteract,
                  onTap:      canInteract
                      ? () => ctx.read<GameBloc>().add(GameCardTapped(cardId))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

lib/presentation/widgets/board_card_widget.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';

class BoardCardWidget extends StatelessWidget {
  final int         cardId;
  final CardEntity? card;       // may be null if catalog not yet loaded
  final bool        isStarOwner;
  final Color?      borderColor;

  const BoardCardWidget({
    super.key,
    required this.cardId,
    required this.card,
    required this.isStarOwner,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokenColor = isStarOwner
        ? AppColors.starFaction
        : AppColors.moonFaction;
    final tokenIcon  = isStarOwner
        ? Icons.star_rounded
        : Icons.nightlight_round;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            borderColor != null ? 6.5 : 9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card art
            Image.asset(
              card?.imageAsset ?? 'assets/images/cards/card_$cardId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.gridCellBg,
                child: Center(
                  child: Text(
                    card?.name ?? '#$cardId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ),

            // Faction token badge — top-right
            Positioned(
              top: 3, right: 3,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color:  tokenColor,
                  shape:  BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color:      tokenColor.withOpacity(0.5),
                        blurRadius: 4)
                  ],
                ),
                child: Icon(tokenIcon,
                    color: Colors.white, size: 11),
              ),
            ),

            // Power badge — bottom-left
            if (card != null)
              Positioned(
                bottom: 3, left: 3,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.85),
                    shape:  BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${card!.power}',
                      style: TextStyle(
                        fontSize:   9,
                        fontWeight: FontWeight.w900,
                        color:      tokenColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

lib/presentation/widgets/hand_card_widget.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';

class HandCardWidget extends StatelessWidget {
  final int         cardId;
  final CardEntity? card;
  final bool        isSelected;
  final bool        enabled;
  final VoidCallback? onTap;

  const HandCardWidget({
    super.key,
    required this.cardId,
    required this.card,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width:  60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.cellHighlight, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:      AppColors.cellHighlight.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [
                  const BoxShadow(
                      color: Colors.black26, blurRadius: 4)
                ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Image.asset(
                card?.imageAsset ??
                    'assets/images/cards/card_$cardId.png',
                width: 60, height: 84, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60, height: 84,
                  color: AppColors.gridCellBg,
                  child: Center(
                    child: Text(
                      card?.name ?? '#$cardId',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 7),
                    ),
                  ),
                ),
              ),
              // Power badge
              if (card != null)
                Positioned(
                  bottom: 3, left: 3,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${card!.power}',
                          style: const TextStyle(
                            fontSize: 8, fontWeight: FontWeight.w900,
                            color: AppColors.primaryText,
                          )),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

lib/presentation/widgets/timer_circle.dart

empty

lib/domain/usecases/play_card.dart
import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class PlayCardParams {
  final String code;
  final int    cellIndex;
  final int    cardId;
  const PlayCardParams({
    required this.code,
    required this.cellIndex,
    required this.cardId,
  });
}

class PlayCard {
  final RoomRepository repository;
  const PlayCard(this.repository);

  Future<Either<Failure, RoomEntity>> call(PlayCardParams params) =>
      repository.playCard(
        code:      params.code,
        cellIndex: params.cellIndex,
        cardId:    params.cardId,
      );
}

lib/domain/usecases/start_room.dart
import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class StartRoom {
  final RoomRepository repository;
  const StartRoom(this.repository);

  Future<Either<Failure, RoomEntity>> call(String code) =>
      repository.startRoom(code);
}


lib/domain/usecases/get_cards.dart

import 'package:dartz/dartz.dart';
import '../entities/card_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class GetCards {
  final RoomRepository repository;
  const GetCards(this.repository);

  Future<Either<Failure, List<CardEntity>>> call() => repository.getCards();
}

lib/core/network/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  /// Connect and return a broadcast stream of decoded JSON messages.
  Stream<Map<String, dynamic>> connect(String roomCode, String token) {
    disconnect(); // close any existing connection first

    final uri = Uri.parse(
      '${ApiConstants.wsBaseUrl}/rooms/$roomCode/ws?token=${Uri.encodeComponent(token)}',
    );

    _channel    = WebSocketChannel.connect(uri);
    _controller = StreamController.broadcast();

    _channel!.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (!_controller!.isClosed) _controller!.add(msg);
        } catch (_) {}
      },
      onError: (e) {
        if (!_controller!.isClosed) _controller!.addError(e);
      },
      onDone: () {
        if (!_controller!.isClosed) _controller!.close();
      },
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  void disconnect() {
    _channel?.sink.close();
    _controller?.close();
    _channel    = null;
    _controller = null;
  }
}

lib/core/constants/api_constants.dart

abstract class ApiConstants {
  /// Change this one line to switch environments.
  /// Local dev : 'http://localhost:4001'
  /// Cloudflare : 'https://taste-truth-landscape-levy.trycloudflare.com'
  static const String baseUrl ='https://robot-olive-architectural-information.trycloudflare.com';

  /// WebSocket base — same host, protocol swapped https → wss
  static String get wsBaseUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
}


=========
1. Domain Layer (Entities & Use Cases)
lib/domain/entities/game_cell_entity.dart (✦ New): Define the 4x4 grid cell.

int? cardId, String? ownerUid.

lib/domain/entities/game_state_entity.dart (✦ New): Define the game metadata.

List<GameCellEntity> board (fixed length 16).

String turnUid, int turnNumber, DateTime turnDeadline.

lib/domain/usecases/play_card.dart (✦ New): Executes POST /rooms/:code/play.

lib/domain/usecases/start_room.dart (✦ New): Executes POST /rooms/:code/start.

lib/domain/usecases/get_cards.dart (✦ New): Fetches the 12-card global catalog.

2. Data Layer (Models & Data Sources)
lib/data/models/game_cell_model.dart (✦ New): JSON serialization for the cell.

lib/data/models/game_state_model.dart (✦ New): JSON serialization for the game object.

lib/data/models/room_model.dart (✎ Update): Update the fromMap factory to parse the new game field into a GameStateModel.

lib/data/datasources/room_remote_datasource.dart (✎ Update):

Add playCard(String code, int cardId, int cellIndex).

Add startRoom(String code).

Add getCards() to retrieve the catalog from GET /cards.

3. Presentation Layer (BLoC & UI)
lib/presentation/blocs/game/game_bloc.dart (✎ Update):

Integrate WebsocketService to listen for room_update events.

Handle GameCellTapped event: check if isMyTurn and isAdjacent before calling the PlayCard use case.

Implement a 500ms ticker to update the remainingSeconds UI state based on the server's turnDeadline.

lib/presentation/pages/game_page.dart (✎ Update):

Refactor to a GridView.count(crossAxisCount: 4) for the 4x4 board.

Add a "Start Game" overlay/button for the host when the room status is available and player2 is present.

lib/presentation/widgets/game_cell_widget.dart (✎ Update):

Render the card asset if cardId is present.

Overlay the Star or Moon token based on whether ownerUid == room.createdBy.

Phase 3: Bug Audit & Adversarial Review
Race Conditions: Ensure that the submitting state in the BLoC prevents a user from tapping multiple cells while a POST /play request is in flight.

Token Expiry: The WebsocketService uses the Firebase ID token. Since these expire in ~1 hour, implement a listener in the Data layer to trigger a re-connection with a fresh token if the WebSocket yields an authentication error.

Memory Management: The WebSocket stream and any local Timer objects used for the 30-second countdown must be explicitly cancelled in the dispose() or close() methods to prevent memory leaks on the Mac mini or target mobile devices.

Edge Case (Turn 0): Adjacency validation must be bypassed for turnNumber == 0, as the first card can be placed anywhere on the 16-cell grid.