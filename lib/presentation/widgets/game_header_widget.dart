import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../blocs/game/game_state.dart';
import 'hurry_banner.dart';

/// Top-of-screen header: stroked "MOMON SNATCH" title, a score pill with
/// the viewer's chip on the LEFT, opponent's on the RIGHT, a circular
/// countdown bubble in the middle, and a hurry banner during the
/// player's turn. Visual ported from `fix-config-game-page` so the look
/// stays consistent with the stash design.
class GameHeaderWidget extends StatelessWidget {
  static const _turnSecs = 30;
  static const _starIcon = 'assets/images/star_team_icon.svg';
  static const _moonIcon = 'assets/images/moon_team_icon.svg';

  final GameBlocState state;

  const GameHeaderWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = state.isMyTurn;
    final iAmStar  = state.iAmStar;
    final myIcon   = iAmStar ? _starIcon : _moonIcon;
    final oppIcon  = iAmStar ? _moonIcon : _starIcon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _GameTitle(),
        Container(
          margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color:        AppColors.scorePillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _ScoreChip(iconAsset: myIcon, score: state.myScore),
                  const Spacer(),
                  _TimerBubble(
                      seconds: state.countdownSeconds, max: _turnSecs),
                  const Spacer(),
                  _ScoreChip(
                    iconAsset: oppIcon,
                    score:     state.opponentScore,
                    reversed:  true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isMyTurn ? 'Your turn' : "${state.opponentUsername}'s turn",
                style: GoogleFonts.fredoka(
                  fontSize:      14,
                  fontWeight:    FontWeight.w700,
                  color:         Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible:           isMyTurn,
          maintainSize:      true,
          maintainAnimation: true,
          maintainState:     true,
          child: HurryBanner(seconds: state.countdownSeconds),
        ),
      ],
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.fredoka(
      fontSize:      24,
      fontWeight:    FontWeight.w700,
      letterSpacing: 1.5,
      height:        1,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'MOMON SNATCH',
            style: base.copyWith(
              foreground: Paint()
                ..style       = PaintingStyle.stroke
                ..strokeWidth = 4
                ..strokeJoin  = StrokeJoin.round
                ..color       = AppColors.titleStroke,
            ),
          ),
          Text('MOMON SNATCH', style: base.copyWith(color: AppColors.titleFill)),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String iconAsset;
  final int    score;
  final bool   reversed;

  const _ScoreChip({
    required this.iconAsset,
    required this.score,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconCircle = SizedBox(
      width:  40,
      height: 40,
      child:  SvgPicture.asset(iconAsset, fit: BoxFit.contain),
    );
    final number = Text(
      '$score',
      style: GoogleFonts.fredoka(
        fontSize:   24,
        fontWeight: FontWeight.w700,
        color:      AppColors.scoreText,
      ),
    );
    final children = reversed
        ? [number, const SizedBox(width: 12), iconCircle]
        : [iconCircle, const SizedBox(width: 12), number];

    return Transform.translate(
      offset: const Offset(0, 12),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _TimerBubble extends StatelessWidget {
  final int seconds;
  final int max;

  const _TimerBubble({required this.seconds, required this.max});

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / max).clamp(0.0, 1.0);
    return SizedBox(
      width:  56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width:  56,
            height: 56,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  Colors.white,
              border: Border.all(color: AppColors.cardOutline, width: 2),
            ),
          ),
          SizedBox(
            width:  64,
            height: 64,
            child: CircularProgressIndicator(
              value:           progress,
              strokeWidth:     6,
              backgroundColor: Colors.transparent,
              valueColor:      const AlwaysStoppedAnimation(AppColors.timerRing),
              strokeCap:       StrokeCap.round,
            ),
          ),
          Text(
            '$seconds',
            style: GoogleFonts.fredoka(
              fontSize:   22,
              fontWeight: FontWeight.w700,
              color:      AppColors.scoreText,
            ),
          ),
        ],
      ),
    );
  }
}
