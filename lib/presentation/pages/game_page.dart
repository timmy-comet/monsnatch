import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
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
      
              BlocBuilder<GameBloc, GameBlocState>(
                buildWhen: (prev, curr) => prev.phase != curr.phase,
                builder: (ctx, state) => state.phase == GamePhase.done
                    ? VictoryOverlay(
                        state: state,
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
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  final GameBlocState state;
  const _GameView({required this.state});

  @override
  Widget build(BuildContext context) {
    final allCardIds = state.myAllCardIds.cast<int>();
    final activeIds  = state.myActiveCardIds.toSet();
    final usedIds    = allCardIds.where((id) => !activeIds.contains(id)).toSet();

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
            cardIds:        allCardIds,
            catalog:        state.catalog,
            usedCardIds:    usedIds,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cards: ${activeIds.length}',
            style: const TextStyle(
              fontSize:   12,
              color:      AppColors.primaryBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('|',
                style: TextStyle(fontSize: 12, color: Colors.black26)),
          ),
          Text(
            'Total Power: $totalPower',
            style: const TextStyle(
              fontSize:   12,
              color:      AppColors.primaryBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
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
