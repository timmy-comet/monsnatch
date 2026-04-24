import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/game/game_state.dart';

class VictoryOverlay extends StatefulWidget {
  final GameBlocState state;
  final VoidCallback  onReturn;
  const VictoryOverlay({
    super.key,
    required this.state,
    required this.onReturn,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 650));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state   = widget.state;
    final winner  = state.room?.game?.winner;
    final isDraw  = winner == null;
    final iWin    = winner == state.myUid;

    final title  = isDraw ? 'Draw!' : (iWin ? 'You Win! 🎉' : 'You Lost!');
    final color  = isDraw
        ? Colors.grey
        : (iWin ? AppColors.starFaction : AppColors.moonFaction);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin:  const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color:      color.withOpacity(0.5),
                    blurRadius: 40, spreadRadius: 4)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize:      32,
                        fontWeight:    FontWeight.w900,
                        color:         color,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 16),
                  // Final scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScoreChip(
                          label: '⭐ ${state.iAmStar ? state.myScore : state.opponentScore}'),
                      const SizedBox(width: 20),
                      _ScoreChip(
                          label: '🌙 ${state.iAmStar ? state.opponentScore : state.myScore}'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize:     const Size(200, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: widget.onReturn,
                    child: const Text('BACK TO LOBBY',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  const _ScoreChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color:        const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize:   18,
            fontWeight: FontWeight.w800,
            color:      AppColors.primaryText)),
  );
}