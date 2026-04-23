import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monsnatch/core/constants/app_colors.dart';
import '../../domain/entities/faction.dart';
import '../../domain/entities/mon_card.dart';
import '../../domain/entities/room_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/grid_widget.dart';
import '../widgets/curved_hand_widget.dart';
import '../widgets/lens_overlay_widget.dart';
import 'victory_page.dart';

class GamePage extends StatefulWidget {
  final RoomEntity room;
  const GamePage({super.key, required this.room});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameBloc _bloc;

  @override
  void initState() {
    super.initState();
    final faction = (widget.room.player2 != null) ? Faction.moon : Faction.star;
    _bloc = GameBloc(playerFaction: faction);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listenWhen: (p, c) => c.isGameOver && !p.isGameOver,
      listener: (context, state) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => VictoryPage(
            winner: state.winner,
            starScore: state.starScore,
            moonScore: state.moonScore,
            playerFaction: state.playerFaction,
          ),
        ));
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F0),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    GameHeaderWidget(
                      starScore: state.starScore,
                      moonScore: state.moonScore,
                      timerSeconds: state.timerSeconds,
                      isPlayerTurn: state.isPlayerTurn,
                      isUrgent: state.isUrgent,
                      playerFaction: state.playerFaction,
                    ),
                    Expanded(
                      child: GridWidget(
                        slots: state.grid,
                        lastFlipped: state.lastFlipped,
                        selectedCard: state.selectedCard,
                        onCellTapped: (i) => _handleCellTap(context, state, i),
                        onCardDropped: (i, card) => _handleCardDrop(context, state, i, card),
                      ),
                    ),
                    const SizedBox(height: 90), // space for hand
                    _buildStatusBar(state),
                  ],
                ),
                Positioned(
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: CurvedHandWidget(
                    cards: state.playerHand,
                    focusIndex: state.focusIndex,
                    selectedIndex: state.selectedIndex,
                    isPlayerTurn: state.isPlayerTurn,
                    onSwipedTo: (i) => context.read<GameBloc>().add(HandSwipedTo(i)),
                    onCardTapped: (i) => context.read<GameBloc>().add(CardSelected(i)),
                    onLensTapped: () => context.read<GameBloc>().add(const LensToggled()),
                  ),
                ),
                if (state.selectedCard != null && state.isPlayerTurn)
                  _buildDragFeedback(state),
                // if (state.isLensOpen && state.focusedCard != null)
                  // Positioned.fill(
                  //   child: LensOverlayWidget(
                  //     card: state.focusedCard!,
                  //     onClose: () => context.read<GameBloc>().add(const LensToggled()),
                  //   ),
                  // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCellTap(BuildContext context, GameState state, int index) {
    final card = state.selectedCard;
    if (card != null && state.isPlayerTurn) {
      context.read<GameBloc>().add(CardPlacedOnGrid(index, card));
    }
  }

  void _handleCardDrop(BuildContext context, GameState state, int index, MonCard card) {
    if (state.isPlayerTurn) {
      context.read<GameBloc>().add(CardPlacedOnGrid(index, card));
    }
  }

  Widget _buildStatusBar(GameState state) {
    final totalStars = state.playerHand.fold(0, (s, c) => s + c.rarityStars);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Text(
            'Cards: ${state.playerHand.length}', 
            style: const TextStyle(fontSize: 12, color: AppColors.primaryBrown, fontWeight: FontWeight.w600),
          ),
          
          // Vertical divider or just a gap
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('|', style: TextStyle(fontSize: 12, color: Colors.black26)),
          ),
          
          Text(
            'Total Stars: $totalStars', 
            style: const TextStyle(fontSize: 12, color: AppColors.primaryBrown, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(GameState state) {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Draggable<MonCard>(
          data: state.selectedCard!,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.createRoomBtn.withOpacity(0.6), blurRadius: 20)],
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(state.selectedCard!.imageAsset, fit: BoxFit.cover),
            ),
          ),
          childWhenDragging: const SizedBox(),
          child: const SizedBox(),
        ),
      ),
    );
  }
}