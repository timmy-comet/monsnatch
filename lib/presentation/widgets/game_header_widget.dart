import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/game/game_state.dart';

class GameHeaderWidget extends StatelessWidget {
  final GameBlocState state;
  const GameHeaderWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMyTurn   = state.isMyTurn;
    final countdown  = state.countdownSeconds;
    final urgent     = countdown <= 5;
    final warning    = countdown <= 10;
    final oppName    = state.opponentUsername ?? 'Opponent';

    return Container(
      color: AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text('MOMON SNATCH',
              style: TextStyle(
                fontSize:      18,
                fontWeight:    FontWeight.w900,
                color:         AppColors.primaryYellow,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 6),

          // Score row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Star side
              _FactionScore(
                isStar:   true,
                score:    state.iAmStar ? state.myScore : state.opponentScore,
                isActive: state.iAmStar ? isMyTurn : !isMyTurn,
              ),

              // Timer circle
              _TimerCircle(
                seconds:  countdown,
                urgent:   urgent,
                label:    warning
                    ? 'Hurry!'
                    : isMyTurn ? 'Your turn' : '$oppName\'s turn',
              ),

              // Moon side
              _FactionScore(
                isStar:   false,
                score:    state.iAmStar ? state.opponentScore : state.myScore,
                isActive: state.iAmStar ? !isMyTurn : isMyTurn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactionScore extends StatelessWidget {
  final bool isStar;
  final int  score;
  final bool isActive;
  const _FactionScore({
    required this.isStar,
    required this.score,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isStar ? AppColors.starFaction : AppColors.moonFaction;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow:    isActive
            ? [const BoxShadow(color: Colors.black12, blurRadius: 6)]
            : [],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius:          12,
            backgroundColor: isActive ? color : Colors.grey.shade300,
            child: Icon(
              isStar ? Icons.star_rounded : Icons.nightlight_round,
              color: Colors.white, size: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text('$score',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.primaryText : Colors.grey.shade400,
              )),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final int    seconds;
  final bool   urgent;
  final String label;
  const _TimerCircle({
    required this.seconds,
    required this.urgent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: urgent ? const Color(0xFFFFEEEE) : Colors.white,
          border: Border.all(
            color: urgent ? Colors.red : const Color(0xFFDDDDDD),
            width: 2,
          ),
          boxShadow: urgent
              ? [BoxShadow(
                  color: Colors.red.withOpacity(0.3), blurRadius: 10)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          '$seconds',
          style: TextStyle(
            fontSize:   20,
            fontWeight: FontWeight.w900,
            color: urgent ? Colors.red : AppColors.primaryText,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.subtitleText)),
    ],
  );
}
