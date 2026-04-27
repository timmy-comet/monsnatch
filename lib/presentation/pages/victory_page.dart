import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/game/game_state.dart';
 
class VictoryOverlay extends StatefulWidget {
  final GameBlocState state;
  final VoidCallback  onLeave;
  final VoidCallback  onPlayAgain;
 
  const VictoryOverlay({
    super.key,
    required this.state,
    required this.onLeave,
    required this.onPlayAgain,
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
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }
 
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
 
  @override
  Widget build(BuildContext context) {
    final state    = widget.state;
    final winner   = state.room?.currentGame?.winner;
    final isDraw   = winner == null;
    final iWin     = winner == state.myUid;
 
    final title   = isDraw ? 'Draw! 🤝' : (iWin ? 'You Win! 🎉' : 'You Lost!');
    final color   = isDraw
        ? Colors.grey
        : (iWin ? AppColors.createRoomBtn : const Color(0xFF3D4EA0));
 
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin:  const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: color.withOpacity(0.45), blurRadius: 40, spreadRadius: 4)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900,
                  color: color, letterSpacing: 1)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _ScoreChip(label: '⭐ ${state.iAmStar ? state.myScore : state.opponentScore}'),
                  const SizedBox(width: 16),
                  _ScoreChip(label: '🌙 ${state.iAmStar ? state.opponentScore : state.myScore}'),
                ]),
                const SizedBox(height: 24),
                // Play Again
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize:     const Size(220, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: widget.onPlayAgain,
                  child: const Text('PLAY AGAIN',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 14)),
                ),
                const SizedBox(height: 10),
                // Leave
                TextButton(
                  onPressed: widget.onLeave,
                  child: const Text('LEAVE ROOM',
                      style: TextStyle(color: AppColors.subtitleText, fontSize: 13)),
                ),
              ]),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(
      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
  );
}