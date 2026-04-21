import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import '../../injection_container.dart';
import '../blocs/lobby/lobby_bloc.dart';
import '../blocs/lobby/lobby_event.dart';
import '../blocs/lobby/lobby_state.dart';
import '../blocs/connectivity/connectivity_bloc.dart';
import '../widgets/score_bar.dart';
import '../widgets/ping_indicator.dart';
import '../../game/momon_snatch_game.dart';

class LobbyPage extends StatefulWidget {
  final String lobbyId;
  const LobbyPage({super.key, required this.lobbyId});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late final MonSnatchGame _game;

  @override
  void initState() {
    super.initState();
    _game = MonSnatchGame();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<LobbyBloc>()..add(WatchLobbyStarted(widget.lobbyId)),
        ),
        BlocProvider(create: (_) => sl<ConnectivityBloc>()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('MOMON SNATCH',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                    const Spacer(),
                    const PingIndicator(),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              // ─── Score bar ───
              BlocBuilder<LobbyBloc, LobbyState>(
                buildWhen: (p, c) => c is LobbyLoaded,
                builder: (context, state) {
                  if (state is! LobbyLoaded) {
                    return const LinearProgressIndicator();
                  }
                  return ScoreBar(
                    p1Score: state.lobby.player1Score,
                    p2Score: state.lobby.player2Score,
                    timerSeconds: state.lobby.timerSeconds,
                    isPlayer1Turn: state.lobby.isPlayer1Turn,
                  );
                },
              ),
              // ─── Instruction text ───
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Select a card to play',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ),
              // ─── Flame GameWidget ───
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