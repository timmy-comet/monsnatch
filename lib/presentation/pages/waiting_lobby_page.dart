import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/room_entity.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../widgets/mon_button.dart';
import '../widgets/room_code_card.dart';
import 'game_page.dart';

class WaitingLobbyPage extends StatefulWidget {
  final RoomEntity room;
  const WaitingLobbyPage({super.key, required this.room});

  @override
  State<WaitingLobbyPage> createState() => _WaitingLobbyState();
}

class _WaitingLobbyState extends State<WaitingLobbyPage> {
  late RoomEntity _room;
  bool _opponentJoined = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    // Open WebSocket to watch for player2 joining
    context.read<RoomBloc>().add(WatchRoomStarted(_room.code));
  }

  @override
  void dispose() {
    context.read<RoomBloc>().add(const WatchRoomStopped());
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GamePage(room: _room),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state is RoomPlayerJoined) {
          setState(() {
            _room            = state.room;
            _opponentJoined  = true;
          });
        }
        if (state is RoomError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:         Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          backgroundColor:  Colors.transparent,
          elevation:        0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.primaryText),
            onPressed: () {
              context.read<RoomBloc>().add(const WatchRoomStopped());
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Image.asset(AppAssets.homeLogo, width: 100, height: 100),
                const SizedBox(height: 14),
                const Text('Waiting for players...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Share the code below with a friend',
                    style: TextStyle(fontSize: 13, color: AppColors.subtitleText)),
                const Spacer(),
                RoomCodeCard(code: _room.code),
                const Spacer(),

                // ── Player status banner ────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _opponentJoined
                      ? _JoinedBanner(key: const ValueKey('joined'))
                      : _WaitingSlots(key: const ValueKey('waiting')),
                ),

                const Spacer(),
                MonButton(
                  label:     'START GAME',
                  color:     AppColors.startBtn,
                  onPressed: _startGame,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinedBanner extends StatelessWidget {
  const _JoinedBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color:        const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: const Color(0xFF4CAF50)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: Color(0xFF388E3C), size: 20),
        SizedBox(width: 8),
        Text('A player has joined! Ready to start.',
            style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _WaitingSlots extends StatelessWidget {
  const _WaitingSlots({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _Slot(label: 'You', filled: true),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
      ),
      _Slot(label: 'Waiting...', filled: false),
    ],
  );
}

class _Slot extends StatelessWidget {
  final String label; final bool filled;
  const _Slot({required this.label, required this.filled});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  filled ? AppColors.createRoomBtn.withOpacity(0.15) : const Color(0xFFF5F5F5),
        border: Border.all(
          color: filled ? AppColors.createRoomBtn : Colors.grey.shade300, width: 2),
      ),
      child: Icon(
        filled ? Icons.person_rounded : Icons.person_add_alt_1_rounded,
        color: filled ? AppColors.createRoomBtn : Colors.grey.shade400, size: 26),
    ),
    const SizedBox(height: 6),
    Text(label, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: filled ? AppColors.primaryText : Colors.grey.shade400)),
  ]);
}