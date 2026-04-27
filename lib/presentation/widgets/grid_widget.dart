import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/game_cell_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import 'board_card_widget.dart';
import 'dashed_border.dart';

/// Board grid styled to match `fix-config-game-page`:
/// - background image fills the play area
/// - 4×4 cells laid out manually with proportional padding/gap
/// - empty cells use a dashed border that swaps colour for valid /
///   invalid drag-hover states
/// - filled cells get a coloured ring for last-move (yellow) and capture
///   (pink) highlights
class GridWidget extends StatelessWidget {
  static const String _bgAsset = 'assets/images/ui/boardgame_bg.png';

  final GameBlocState state;
  const GridWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final lastMove   = state.room?.currentGame?.lastMove;
    final captureSet = <int>{
      if (lastMove != null) ...lastMove.captures,
    };

    final viewerIsPlayer2 = state.myUid == state.room?.player2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: AspectRatio(
        aspectRatio: 0.82,
        child: RotatedBox(
          quarterTurns: viewerIsPlayer2 ? 2 : 0,
          child: LayoutBuilder(
          builder: (_, c) {
            final pX  = c.maxWidth  * 0.05;
            final pY  = c.maxHeight * 0.04;
            final gap = c.maxWidth  * 0.012;
            final cellW = (c.maxWidth  - 2 * pX - 3 * gap) / 4;
            final cellH = (c.maxHeight - 2 * pY - 3 * gap) / 4;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.asset(_bgAsset, fit: BoxFit.cover),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pX, vertical: pY),
                  child: Column(
                    children: [
                      for (int r = 0; r < 4; r++) ...[
                        if (r > 0) SizedBox(height: gap),
                        Row(
                          children: [
                            for (int col = 0; col < 4; col++) ...[
                              if (col > 0) SizedBox(width: gap),
                              SizedBox(
                                width:  cellW,
                                height: cellH,
                                child:  _buildCell(
                                  context,
                                  r * 4 + col,
                                  lastMoveCell: lastMove?.cellIndex,
                                  captureSet:   captureSet,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    int idx, {
    required int? lastMoveCell,
    required Set<int> captureSet,
  }) {
    final cell         = state.board[idx];
    final isLastPlaced = lastMoveCell == idx;
    final isCaptured   = captureSet.contains(idx);
    final canPlace     = state.canPlay(idx);

    if (cell == null) {
      return _EmptyCell(
        highlight:    canPlace,
        canAcceptDrop: canPlace,
        onTap: canPlace
            ? () => context.read<GameBloc>().add(GameCellTapped(idx))
            : null,
        onAcceptDrop: canPlace
            ? () => context.read<GameBloc>().add(GameCellTapped(idx))
            : null,
      );
    }

    // Player 2's cards are placed in the catalog's mirrored orientation —
    // backend `rotate180(directions)` (service.ts:368). The board itself is
    // also rotated 180° for the player2 viewer, so net for each viewer:
    // own cards stand upright, opponent's cards face the viewer.
    return _FilledCell(
      cell:         cell,
      cardImage:    state.cardById(cell.cardId)?.imageAsset,
      isStarOwner:  state.cellIsStarOwned(idx),
      isLastMove:   isLastPlaced,
      isCaptured:   isCaptured,
      flipArt:      cell.placedBy == state.room?.player2,
    );
  }
}

class _FilledCell extends StatelessWidget {
  final GameCellEntity cell;
  final String?        cardImage;
  final bool           isStarOwner;
  final bool           isLastMove;
  final bool           isCaptured;
  final bool           flipArt;

  const _FilledCell({
    required this.cell,
    required this.cardImage,
    required this.isStarOwner,
    required this.isLastMove,
    required this.isCaptured,
    required this.flipArt,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isCaptured
        ? AppColors.captureRing
        : isLastMove
            ? AppColors.lastMoveRing
            : Colors.transparent;
    final ringWidth = (isCaptured || isLastMove) ? 2.5 : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ringColor, width: ringWidth),
      ),
      padding: EdgeInsets.all(ringWidth > 0 ? 1.5 : 0),
      child: TweenAnimationBuilder<double>(
        key:      ValueKey('placed-${cell.cardId}-${cell.placedBy}'),
        duration: const Duration(milliseconds: 280),
        curve:    Curves.easeOutBack,
        tween:    Tween(begin: 0.82, end: 1.0),
        builder:  (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: BoardCardWidget(
          cardImage:   cardImage,
          isStarOwner: isStarOwner,
          isFlipped:   isCaptured,
          flipArt:     flipArt,
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  final bool highlight;
  final bool canAcceptDrop;
  final VoidCallback? onTap;
  final VoidCallback? onAcceptDrop;

  const _EmptyCell({
    required this.highlight,
    required this.canAcceptDrop,
    required this.onTap,
    required this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => canAcceptDrop,
      onAcceptWithDetails:     (_) => onAcceptDrop?.call(),
      builder: (_, candidate, rejected) {
        final hoveringInvalid = rejected.isNotEmpty;
        final hoveringValid   = candidate.isNotEmpty;

        final Color  borderColor;
        final Color  bgColor;
        final double borderWidth;
        if (hoveringInvalid) {
          borderColor = AppColors.primaryBrown;
          bgColor     = AppColors.cellInvalidBg;
          borderWidth = 2;
        } else if (highlight || hoveringValid) {
          borderColor = AppColors.cellPlayable;
          bgColor     = AppColors.boardCellBg;
          borderWidth = 2;
        } else {
          borderColor = AppColors.boardCellBorder;
          bgColor     = AppColors.boardCellBg;
          borderWidth = 1.5;
        }

        return GestureDetector(
          onTap: onTap,
          child: DashedBorderBox(
            radius:          12,
            borderColor:     borderColor,
            borderWidth:     borderWidth,
            backgroundColor: bgColor,
            child: const Center(
              child: Icon(Icons.add_rounded, size: 22, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
