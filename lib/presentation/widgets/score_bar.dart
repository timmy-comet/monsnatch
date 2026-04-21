import 'package:flutter/material.dart';

class ScoreBar extends StatelessWidget {
  final int p1Score, p2Score, timerSeconds;
  final bool isPlayer1Turn;

  const ScoreBar({
    super.key,
    required this.p1Score,
    required this.p2Score,
    required this.timerSeconds,
    required this.isPlayer1Turn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E0E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ScoreBox(score: p1Score, icon: Icons.star, isActive: isPlayer1Turn),
          const Spacer(),
          _TimerCircle(seconds: timerSeconds),
          const Spacer(),
          _ScoreBox(score: p2Score, icon: Icons.nightlight_round, isActive: !isPlayer1Turn),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  final IconData icon;
  final bool isActive;

  const _ScoreBox({required this.score, required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFFCCCCCC),
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: const Color(0xFF6A1B9A), width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6A1B9A)),
          const SizedBox(width: 6),
          Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final int seconds;
  const _TimerCircle({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 10;
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFE8EAF6),
            border: Border.all(
              color: isUrgent ? Colors.red : const Color(0xFF7986CB),
              width: 2.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$seconds',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isUrgent ? Colors.red : const Color(0xFF3F51B5),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text('Your turn', style: TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}