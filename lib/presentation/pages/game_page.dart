import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/room_entity.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_state.dart';
import '../../game/momon_snatch_game.dart';

class GamePage extends StatefulWidget {
  final RoomEntity room;
  const GamePage({super.key, required this.room});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MonSnatchGame _game;
  late final GameBloc      _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GameBloc(widget.room);
    _game = MonSnatchGame(bloc: _bloc);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'MOMON SNATCH',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize:   18,
                    letterSpacing: 2,
                    color:      AppColors.primaryText,
                  ),
                ),
              ),
              // Score / Timer bar — bound to GameBloc
              BlocBuilder<GameBloc, GameState>(
                builder: (_, state) => _ScoreBar(
                  p1Score:      state.player1Score,
                  p2Score:      state.player2Score,
                  timer:        state.timerSeconds,
                  isP1Turn:     state.isPlayer1Turn,
                ),
              ),
              // Instruction
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Select a card to play',
                  style: TextStyle(
                      fontSize: 13,
                      color:    AppColors.subtitleText),
                ),
              ),
              // Flame game
              Expanded(
                child: GameWidget(game: _game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score bar ──────────────────────────────────────────────
class _ScoreBar extends StatelessWidget {
  final int  p1Score, p2Score, timer;
  final bool isP1Turn;

  const _ScoreBar({
    required this.p1Score,
    required this.p2Score,
    required this.timer,
    required this.isP1Turn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scoreBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ScoreChip(
            score: p1Score,
            icon:  Icons.star_rounded,
            active: isP1Turn,
          ),
          const Spacer(),
          _TimerBubble(seconds: timer),
          const Spacer(),
          _ScoreChip(
            score: p2Score,
            icon:  Icons.nightlight_round,
            active: !isP1Turn,
            reversed: true,
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int      score;
  final IconData icon;
  final bool     active;
  final bool     reversed;

  const _ScoreChip({
    required this.score,
    required this.icon,
    required this.active,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:        active ? Colors.white : const Color(0xFFDDDDDD),
          shape:        BoxShape.circle,
          border: active
              ? Border.all(color: AppColors.createRoomBtn, width: 1.5)
              : null,
        ),
        child: Icon(icon, size: 16,
            color: active ? AppColors.createRoomBtn : AppColors.subtitleText),
      ),
      const SizedBox(width: 6),
      Text(
        '$score',
        style: const TextStyle(
          fontSize:   20,
          fontWeight: FontWeight.w900,
          color:      AppColors.primaryText,
        ),
      ),
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: reversed ? children.reversed.toList() : children,
      ),
    );
  }
}

class _TimerBubble extends StatelessWidget {
  final int seconds;
  const _TimerBubble({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    return Column(
      children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: urgent ? const Color(0xFFFFEEEE) : Colors.white,
            border: Border.all(
              color: urgent ? Colors.red : const Color(0xFFCCCCCC),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$seconds',
            style: TextStyle(
              fontSize:   22,
              fontWeight: FontWeight.w900,
              color: urgent ? Colors.red : AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Your turn',
          style: TextStyle(fontSize: 10, color: AppColors.subtitleText),
        ),
      ],
    );
  }
}