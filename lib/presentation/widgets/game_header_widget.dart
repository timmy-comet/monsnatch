import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monsnatch/core/constants/app_colors.dart';
import '../../domain/entities/faction.dart';

class GameHeaderWidget extends StatelessWidget {
  final int starScore, moonScore, timerSeconds;
  final bool isPlayerTurn, isUrgent;
  final Faction playerFaction;

  const GameHeaderWidget({
    super.key,
    required this.starScore,
    required this.moonScore,
    required this.timerSeconds,
    required this.isPlayerTurn,
    required this.isUrgent,
    required this.playerFaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStrokedTitle('MOMON SNATCH'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10 ),
          decoration: BoxDecoration(
            color: AppColors.scoreBg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FactionScore(faction: Faction.star, score: starScore),
              const Spacer(),
              _TimerBubble(seconds: timerSeconds, isUrgent: isUrgent),
              const Spacer(),
              _FactionScore(faction: Faction.moon, score: moonScore, reversed: true),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusMessage(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStrokedTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Stack(
        children: [
          // Stroke Layer
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,            
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..strokeJoin = StrokeJoin.round
                ..color = AppColors.primaryBrown,
            ),
          ),
          // Fill Layer
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,            
              color: AppColors.primaryYellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget  _buildStatusMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(isUrgent),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isUrgent ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryBrown.withValues(alpha: 0.5),
          ),
        ),
        child: Text( 
          isUrgent ? 'Hurry! Card will auto-select in 10s' : 'Select a card to play',
          style: TextStyle(
            color: isUrgent ? const Color(0xFFE65100) : AppColors.primaryBrown,
            fontSize: 12,
            fontWeight: isUrgent ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FactionScore extends StatelessWidget {
  final Faction faction;
  final int score;
  final bool reversed;
  const _FactionScore({required this.faction, required this.score, this.reversed = false});
 
  @override
  Widget build(BuildContext context) {
    final children = [
      Container(   
        width: 40, 
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.lightBlueBg, 
          shape: BoxShape.circle ,
          border: Border.all(
            color: AppColors.darkGrey.withValues(alpha: 0.7), 
            width: 1 ),
            ),
        padding: const EdgeInsets.all(7),
        child: SvgPicture.asset(faction.iconAsset),
      ),
      const SizedBox(width: 8),
      Text('$score', 
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.secondaryBrown,
          )), 
    ];
    return Row(children: reversed ? children.reversed.toList() : children);
  }
}

class _TimerBubble extends StatelessWidget {
  final int seconds;
  final bool isUrgent;
  const _TimerBubble({required this.seconds, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final veryUrgent = seconds <= 5;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: veryUrgent ? 1.12 : 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child!),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: veryUrgent ? const Color(0xFFFF5252) : AppColors.createRoomBtn,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (veryUrgent ? Colors.red : AppColors.createRoomBtn).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$seconds',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: isUrgent ? Colors.white : AppColors.primaryBrown,),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isUrgent ? 'Hurry!' : 'Your turn',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isUrgent ? Colors.red : Colors.white,
          ),
        ),
      ],
    );
  }
}