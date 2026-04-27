import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/game_cell_entity.dart';
import '../../domain/entities/card_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../blocs/user/user_bloc.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/grid_widget.dart';
import '../widgets/hand_card_widget.dart';
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
 
    // Get the current room from the latest RoomBloc state
    final roomState = _roomBloc.state;
    final room = roomState is RoomGameStarted ? roomState.room : null;
 
    if (room != null) {
      _gameBloc.add(GameInitialized(room: room, myUid: widget.myUid));
    }
  }
 
  @override
  void dispose() {
    // GamePage owns WS lifecycle — stop it here
    _roomBloc.add(const WatchRoomStopped());
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Pipe RoomBloc updates → GameBloc ──────────────────────────
            BlocListener<RoomBloc, RoomState>(
              listener: (ctx, roomState) {
                if (roomState is RoomGameStarted) {
                  _gameBloc.add(GameRoomUpdated(roomState.room));
                }
                if (roomState is RoomOpponentLeft || roomState is RoomError) {
                  // Show snackbar — game will end naturally via WS
                  final msg = roomState is RoomOpponentLeft
                      ? 'Opponent left the room.'
                      : (roomState as RoomError).message;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.orange.shade700),
                  );
                }
              },
              child: BlocBuilder<GameBloc, GameBlocState>(
                builder: (ctx, state) {
                  if (state.phase == GamePhase.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      GameHeaderWidget(state: state),
                      _OpponentStrip(state: state),
                      Expanded(child: GridWidget(state: state)),
                      if (state.errorMessage != null) _ErrorBanner(msg: state.errorMessage!),
                      _MyHandStrip(state: state),
                    ],
                  );
                },
              ),
            ),
 
            // ── Victory overlay ──────────────────────────────────────────
            BlocBuilder<GameBloc, GameBlocState>(
              buildWhen: (prev, curr) => prev.phase != curr.phase,
              builder: (ctx, state) => state.phase == GamePhase.done
                  ? VictoryOverlay(
                      state:    state,
                      onLeave: () {
                        ctx.read<RoomBloc>().add(
                          LeaveRoomRequested(state.room?.code ?? ''));
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      onPlayAgain: () {
                        ctx.read<RoomBloc>().add(
                          StartGameRequested(state.room?.code ?? ''));
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Opponent face-down strip ──────────────────────────────────────────────────
class _OpponentStrip extends StatelessWidget {
  final GameBlocState state;
  const _OpponentStrip({required this.state});
 
  @override
  Widget build(BuildContext context) {
    final count      = state.opponentActiveCardIds.length;
    final isOppStar  = !state.iAmStar;
    final tokenColor = isOppStar ? AppColors.createRoomBtn : const Color(0xFF3D4EA0);
 
    return Container(
      color: AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: tokenColor,
            child: Icon(
              isOppStar ? Icons.star_rounded : Icons.nightlight_round,
              color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(state.opponentUsername,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('Cards: $count',
                style: const TextStyle(fontSize: 11, color: AppColors.subtitleText)),
          ]),
          const Spacer(),
          Text('${state.opponentScore}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          // Face-down placeholders
          SizedBox(
            height: 28,
            child: Row(
              children: List.generate(count.clamp(0, 10), (_) =>
                Container(
                  width: 14, height: 22,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3)),
                )),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── My hand strip ─────────────────────────────────────────────────────────────
class _MyHandStrip extends StatelessWidget {
  final GameBlocState state;
  const _MyHandStrip({required this.state});
 
  @override
  Widget build(BuildContext context) {
    final isStar     = state.iAmStar;
    final tokenColor = isStar ? AppColors.createRoomBtn : const Color(0xFF3D4EA0);
 
    return Container(
      color: AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              CircleAvatar(
                radius: 14, backgroundColor: tokenColor,
                child: Icon(
                  isStar ? Icons.star_rounded : Icons.nightlight_round,
                  color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text('You', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('${state.myScore}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.myAllCardIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final cardId     = state.myAllCardIds[i];
                final isUsed     = !state.myActiveCardIds.contains(cardId);
                final card       = state.cardById(cardId);
                final isSelected = state.selectedCardId == cardId;
                final canInteract = state.isMyTurn && !state.isSubmitting && !isUsed;
 
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
 
// ── Error banner ──────────────────────────────────────────────────────────────
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
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: Colors.red))),
    ]),
  );
}