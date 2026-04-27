import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import 'board_card_widget.dart';
 
class GridWidget extends StatelessWidget {
  final GameBlocState state;
  const GridWidget({super.key, required this.state});
 
  @override
  Widget build(BuildContext context) {
    final lastMove  = state.room?.currentGame?.lastMove;
 
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF9FD2E0), Color(0xFF72B8CA)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.count(
            crossAxisCount:   4,
            crossAxisSpacing: 7,
            mainAxisSpacing:  7,
            shrinkWrap:       true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(16, (i) {
              final cell    = state.board[i];
              final canPlay = state.canPlay(i);
 
              // Highlight borders
              Color? borderColor;
              if (lastMove?.cellIndex == i) borderColor = Colors.amber.shade500;
              else if (lastMove?.captures.contains(i) == true) borderColor = Colors.pinkAccent.shade200;
 
              if (cell != null) {
                return BoardCardWidget(
                  cardId:      cell.cardId,
                  card:        state.cardById(cell.cardId),
                  isStarOwner: state.cellIsStarOwned(i),
                  borderColor: borderColor,
                );
              }
 
              return _EmptyCell(
                canPlay:     canPlay,
                borderColor: borderColor,
                onTap: canPlay
                    ? () => context.read<GameBloc>().add(GameCellTapped(i))
                    : null,
              );
            }),
          ),
        ),
      ),
    );
  }
}
 
class _EmptyCell extends StatelessWidget {
  final bool      canPlay;
  final Color?    borderColor;
  final VoidCallback? onTap;
  const _EmptyCell({required this.canPlay, this.borderColor, this.onTap});
 
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color:        canPlay
            ? const Color(0xFF7080B8)
            : const Color(0xFF7080B8).withOpacity(0.5),
        borderRadius: BorderRadius.circular(9),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2.5)
            : null,
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: canPlay
              ? AppColors.cellHighlight.withOpacity(0.85)
              : AppColors.cellBorder.withOpacity(0.4),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: canPlay
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.25),
            size: 22),
        ),
      ),
    ),
  );
}
 
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});
 
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path()..addRRect(
        RRect.fromLTRBR(1, 1, size.width - 1, size.height - 1, const Radius.circular(9)));
    const dash = 6.0, gap = 4.5;
    for (final m in path.computeMetrics()) {
      double d = 0; bool draw = true;
      while (d < m.length) {
        final len = draw ? dash : gap;
        if (draw) canvas.drawPath(m.extractPath(d, d + len), p);
        d += len; draw = !draw;
      }
    }
  }
 
  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}