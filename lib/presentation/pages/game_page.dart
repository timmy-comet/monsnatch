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