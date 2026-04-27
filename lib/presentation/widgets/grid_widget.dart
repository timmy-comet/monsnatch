import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_cell_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import 'board_card_widget.dart';

class GridWidget extends StatelessWidget {
  final GameBlocState state;

  const GridWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 4.0;
        const double ratio = 0.75;
        const double outerMargin = 12.0;

        final lastMove = state.room?.currentGame?.lastMove;
        final flipped = <int>{
          if (lastMove != null) ...lastMove.captures,
        };

        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          margin: const EdgeInsets.symmetric(horizontal: outerMargin),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA), Color(0xFF65CC9C)],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(spacing),
            child: Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: Column(
                  children: List.generate(4, (rowIndex) {
                    return Expanded(
                      child: Row(
                        children: List.generate(4, (colIndex) {
                          final int index = (rowIndex * 4) + colIndex;
                          final GameCellEntity? cell = state.board[index];
                          final canPlace = state.canPlay(index);
                          final isLastPlaced = lastMove?.cellIndex == index;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(spacing / 2),
                              child: _GridCell(
                                cell:        cell,
                                isFlipped:   flipped.contains(index),
                                isLastPlaced: isLastPlaced,
                                canPlace:    canPlace,
                                isStarOwner: state.cellIsStarOwned(index),
                                cardImage:   cell == null
                                    ? null
                                    : state.cardById(cell.cardId)?.imageAsset,
                                onTap: canPlace
                                    ? () => context
                                        .read<GameBloc>()
                                        .add(GameCellTapped(index))
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  final GameCellEntity? cell;
  final bool   isFlipped;
  final bool   isLastPlaced;
  final bool   canPlace;
  final bool   isStarOwner;
  final String? cardImage;
  final VoidCallback? onTap;

  const _GridCell({
    required this.cell,
    required this.isFlipped,
    required this.isLastPlaced,
    required this.canPlace,
    required this.isStarOwner,
    required this.cardImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = cell == null;

    Color borderColor = Colors.white.withValues(alpha: canPlace ? 0.6 : 0.1);
    if (isLastPlaced) borderColor = const Color(0xFFF5C842);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: canPlace
              ? const Color(0x33FFFFFF)
              : const Color(0x44546E9F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: isEmpty
            ? Center(
                child: Icon(
                  Icons.add,
                  color: canPlace ? Colors.white70 : Colors.white24,
                  size: 18,
                ),
              )
            : BoardCardWidget(
                cardImage:   cardImage,
                isStarOwner: isStarOwner,
                isFlipped:   isFlipped,
              ),
      ),
    );
  }
}
