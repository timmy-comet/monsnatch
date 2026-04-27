import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/websocket_service.dart';
import '../../injection_container.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../widgets/connection_lost_overlay.dart';
import '../widgets/curved_hand_widget.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/grid_widget.dart';
import 'victory_page.dart';

class GamePage extends StatefulWidget {
  final String myUid;
  const GamePage({super.key, required this.myUid});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final RoomBloc _roomBloc;
  late final GameBloc _gameBloc;

  @override
  void initState() {
    super.initState();
    _roomBloc = context.read<RoomBloc>();
    _gameBloc = context.read<GameBloc>();

    final roomState = _roomBloc.state;
    final room = roomState is RoomGameStarted ? roomState.room : null;
    if (room != null) {
      _gameBloc.add(GameInitialized(room: room, myUid: widget.myUid));
    }
  }

  @override
  void dispose() {
    _roomBloc.add(const WatchRoomStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/bg_image.png"), 
        fit: BoxFit.cover,
      ),
    ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0) , 
        body: SafeArea(
          child: Stack(
            children: [    
              BlocListener<RoomBloc, RoomState>(
                listener: (ctx, roomState) {
                  if (roomState is RoomGameStarted) {
                    _gameBloc.add(GameRoomUpdated(roomState.room));
                  }
                  if (roomState is RoomOpponentLeft || roomState is RoomError) {
                    final msg = roomState is RoomOpponentLeft
                        ? 'Opponent left the room.'
                        : (roomState as RoomError).message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.orange.shade700),
                    );
                  }
                },
                child: BlocBuilder<GameBloc, GameBlocState>(
                  builder: (ctx, state) {
                    if (state.phase == GamePhase.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _GameView(state: state);
                  },
                ),
              ),
      
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ReconnectBanner(),
              ),
              BlocBuilder<GameBloc, GameBlocState>(
                buildWhen: (prev, curr) =>
                    prev.phase != curr.phase || prev.room != curr.room,
                builder: (ctx, state) {
                  // Don't bother the player while the match is still loading
                  // or already over — the loading spinner / VictoryOverlay
                  // own the screen in those phases.
                  if (state.phase != GamePhase.playing) {
                    return const SizedBox.shrink();
                  }
                  return _ConnectionLostGate(
                    roomCode: state.room?.code ?? '',
                  );
                },
              ),
              BlocBuilder<GameBloc, GameBlocState>(
                buildWhen: (prev, curr) =>
                    prev.phase != curr.phase || prev.room != curr.room,
                builder: (ctx, state) {
                  if (state.phase != GamePhase.done) {
                    return const SizedBox.shrink();
                  }
                  final room     = state.room;
                  final myUid    = state.myUid;
                  final oppUid   = state.opponentUid;
                  final oppLeft  = room?.isOpponentLeft == true &&
                      room?.leftBy != myUid;
                  final iVoted   = room?.hasVotedPlayAgain(myUid) ?? false;
                  final oppVoted = oppUid.isNotEmpty &&
                      (room?.hasVotedPlayAgain(oppUid) ?? false);

                  String? statusLine;
                  if (oppLeft) {
                    statusLine = 'Your opponent left the room.';
                  } else if (iVoted && !oppVoted) {
                    statusLine = 'Waiting for opponent to play again…';
                  } else if (oppVoted && !iVoted) {
                    statusLine = 'Opponent wants to play again.';
                  }

                  return VictoryOverlay(
                    state:             state,
                    statusLine:        statusLine,
                    playAgainDisabled: oppLeft || iVoted,
                    playAgainBusy:     iVoted && !oppLeft,
                    onLeave: () {
                      ctx.read<RoomBloc>().add(
                          LeaveRoomRequested(room?.code ?? ''));
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    onPlayAgain: () {
                      ctx.read<RoomBloc>().add(
                          StartGameRequested(room?.code ?? ''));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  final GameBlocState state;
  const _GameView({required this.state});

  @override
  Widget build(BuildContext context) {
    // Used cards are filtered out — only active cards stay in the curved
    // hand, so a played card disappears and its neighbours close the gap.
    final activeIds = state.myActiveCardIds;

    return Stack(
      children: [
        Column(
          children: [
            GameHeaderWidget(state: state),
            Expanded(child: GridWidget(state: state)),
            const SizedBox(height: 90), // space for the curved hand overlay
            if (state.errorMessage != null) _ErrorBanner(msg: state.errorMessage!),
            _StatusBar(state: state),
          ],
        ),
        Positioned(
          bottom: 5,
          left: 0,
          right: 0,
          child: CurvedHandWidget(
            cardIds:        activeIds,
            catalog:        state.catalog,
            usedCardIds:    const <int>{},
            selectedCardId: state.selectedCardId,
            isPlayerTurn:   state.isMyTurn && !state.isSubmitting,
            onCardTapped:   (cardId) =>
                context.read<GameBloc>().add(GameCardTapped(cardId)),
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final GameBlocState state;
  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final activeIds = state.myActiveCardIds;
    final totalPower = activeIds.fold<int>(
        0, (s, id) => s + (state.cardById(id)?.power ?? 0));

    // "Fredoka One" was merged into the variable Fredoka family — use the
    // heaviest weight to get the same chunky look.
    final stripStyle = GoogleFonts.fredoka(
      fontSize:   12,
      color:      AppColors.primaryBrown,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cards: ${activeIds.length}', style: stripStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '|',
              style: stripStyle.copyWith(color: Colors.black26),
            ),
          ),
          Text('Total Power: $totalPower', style: stripStyle),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 14),
          const SizedBox(width: 6),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 12, color: Colors.red))),
        ]),
      );
}

/// Watches the WS [connection] notifier and, after the link has been
/// down for [_graceDuration], promotes the slim reconnect banner to a
/// full-screen "Connection Lost" overlay. The slim banner is enough for
/// quick blips (sub-4s); the popup is for genuine outages where the
/// player needs a clear choice — keep waiting, or bail out.
class _ConnectionLostGate extends StatefulWidget {
  final String roomCode;
  const _ConnectionLostGate({required this.roomCode});

  @override
  State<_ConnectionLostGate> createState() => _ConnectionLostGateState();
}

class _ConnectionLostGateState extends State<_ConnectionLostGate> {
  static const _graceDuration = Duration(seconds: 4);
  static const _retryDuration = Duration(milliseconds: 1500);

  late final WebSocketService _ws;
  Timer? _graceTimer;
  Timer? _retryTimer;
  bool   _showOverlay = false;
  bool   _isRetrying  = false;

  @override
  void initState() {
    super.initState();
    _ws = sl<WebSocketService>();
    _ws.connection.addListener(_onStatusChanged);
    _onStatusChanged(); // seed in case we entered already-disconnected
  }

  @override
  void dispose() {
    _ws.connection.removeListener(_onStatusChanged);
    _graceTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _onStatusChanged() {
    final status = _ws.connection.value;
    if (status == WsConnectionStatus.reconnecting) {
      if (_showOverlay) return;
      _graceTimer ??= Timer(_graceDuration, () {
        if (!mounted) return;
        if (_ws.connection.value == WsConnectionStatus.reconnecting) {
          setState(() => _showOverlay = true);
        }
      });
    } else {
      _graceTimer?.cancel();
      _graceTimer = null;
      _retryTimer?.cancel();
      _retryTimer = null;
      if (_showOverlay || _isRetrying) {
        setState(() {
          _showOverlay = false;
          _isRetrying  = false;
        });
      }
    }
  }

  void _handleReconnect() {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    _ws.retryNow();
    // Spinner state self-clears after a beat so the player can hit
    // Reconnect again if the channel is still flapping. If reconnect
    // succeeds in the meantime, _onStatusChanged will tear the overlay
    // down before this fires.
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDuration, () {
      if (!mounted) return;
      setState(() => _isRetrying = false);
    });
  }

  void _handleLeave() {
    context.read<RoomBloc>().add(LeaveRoomRequested(widget.roomCode));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) return const SizedBox.shrink();
    return ConnectionLostOverlay(
      isRetrying:  _isRetrying,
      onReconnect: _handleReconnect,
      onLeave:     _handleLeave,
    );
  }
}

/// Thin banner pinned to the top of the game page that shows when the WS
/// link is dropped + auto-reconnecting. Hidden in idle/connected states.
class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WsConnectionStatus>(
      valueListenable: sl<WebSocketService>().connection,
      builder: (_, status, __) {
        final visible = status == WsConnectionStatus.reconnecting;
        return AnimatedSlide(
          offset:   visible ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 220),
          curve:    Curves.easeOut,
          child: AnimatedOpacity(
            opacity:  visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color:   Colors.amber.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width:  14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:  AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Reconnecting…',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
