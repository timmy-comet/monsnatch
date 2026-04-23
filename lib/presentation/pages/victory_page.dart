import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/faction.dart';
import '../../core/constants/app_colors.dart';
import 'home_page.dart';

class VictoryPage extends StatelessWidget {
  final Faction?  winner;          // null = draw
  final int       starScore, moonScore;
  final Faction   playerFaction;

  const VictoryPage({
    super.key,
    required this.winner,
    required this.starScore,
    required this.moonScore,
    required this.playerFaction,
  });

  @override
  Widget build(BuildContext context) {
    final playerWon = winner == playerFaction;
    final isDraw    = winner == null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: isDraw
                ? [const Color(0xFF37474F), const Color(0xFF263238)]
                : playerWon
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              if (winner != null)
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(20),
                  child: SvgPicture.asset(winner!.iconAsset),
                ),
              const SizedBox(height: 24),
              Text(
                isDraw  ? 'DRAW!'  :
                playerWon ? 'CHAMPION!' : 'DEFEATED',
                style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 4),
              ),
              const SizedBox(height: 12),
              Text(
                '⭐ $starScore  vs  🌙 $moonScore',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C842),
                    foregroundColor: const Color(0xFF333333),
                    minimumSize:    const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (_) => false,
                  ),
                  child: const Text('PLAY AGAIN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}