import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monsnatch/presentation/blocs/game/game_bloc.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/room_entity.dart';
import '../../injection_container.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../blocs/user/user_bloc.dart';
import '../widgets/mon_button.dart';
import '../widgets/room_code_card.dart';
import 'game_page.dart';
 
class WaitingLobbyPage extends StatefulWidget {
  final RoomEntity room;
  const WaitingLobbyPage({super.key, required this.room});
 
  @override
  State<WaitingLobbyPage> createState() => _WaitingLobbyPageState();
}
 
class _WaitingLobbyPageState extends State<WaitingLobbyPage> {
  late final RoomBloc _roomBloc;   // stored in initState — safe for dispose
  late RoomEntity     _room;
  bool _opponentJoined  = false;
  bool _navigatedToGame = false;   // prevent WS stop on forward navigation
 
  @override
  void initState() {
    super.initState();
    _room     = widget.room;
    _roomBloc = context.read<RoomBloc>();
    _roomBloc.add(WatchRoomStarted(_room.code));
  }

  @override
  void dispose() {
    // Only stop WS if we didn't navigate forward to GamePage.
    // GamePage.dispose() will stop it instead.
    if (!_navigatedToGame) {
      _roomBloc.add(const WatchRoomStopped());
    }
    super.dispose();
  }
 
  void _navigateToGame(RoomEntity room, String myUid) {
    _navigatedToGame = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            // Pass the same RoomBloc — WS stays open, no re-connection needed
            BlocProvider.value(value: _roomBloc),
            // Fresh GameBloc — no WS, REST only
            BlocProvider(create: (_) => sl<GameBloc>()),
          ],
          child: GamePage(myUid: myUid),
        ),
      ),
    );
  }
 
  bool _isHost(String myUid) => _room.createdBy == myUid;
 
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomBloc, RoomState>(
      listener: (ctx, state) {
        if (state is RoomPlayerJoined) {
          setState(() { _room = state.room; _opponentJoined = true; });
        }
 
        if (state is RoomGameStarted) {
          // Read myUid synchronously — no async, no mounted risk
          final userState = context.read<UserBloc>().state;
          if (userState is UserLoaded) {
            _navigateToGame(state.room, userState.user.uid);
          }
        }
 
        if (state is RoomError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red.shade700),
          );
        }
 
        if (state is RoomLeft) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      builder: (ctx, state) {
        final loading = state is RoomLoading;
 
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText),
              onPressed: () {
                // Explicit back — stop WS then pop
                _navigatedToGame = false;
                _roomBloc.add(const WatchRoomStopped());
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                  const SizedBox(height: 4),
                  const Text('Share the code with a friend',
                      style: TextStyle(fontSize: 13, color: AppColors.subtitleText)),
                  const Spacer(),
                  RoomCodeCard(code: _room.code),
                  const Spacer(),
                  _PlayerSlots(opponentJoined: _opponentJoined),
                  const Spacer(),
 
                  // ── Host-only start button ─────────────────────────────
                  BlocBuilder<UserBloc, UserState>(
                    builder: (ctx2, userState) {
                      final myUid = userState is UserLoaded ? userState.user.uid : '';
                      final isHost = _isHost(myUid);
 
                      if (isHost && _opponentJoined) {
                        return MonButton(
                          label:     'START GAME',
                          color:     AppColors.startBtn,
                          isLoading: loading,
                          onPressed: () => _roomBloc.add(StartGameRequested(_room.code)),
                        );
                      }
                      if (!isHost && myUid.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Waiting for host to start...',
                              style: TextStyle(color: AppColors.subtitleText, fontSize: 13)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
 
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
 
class _PlayerSlots extends StatelessWidget {
  final bool opponentJoined;
  const _PlayerSlots({required this.opponentJoined});
 
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _Slot(label: 'You', filled: true),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
      ),
      _Slot(label: opponentJoined ? 'Joined! ✓' : 'Waiting...', filled: opponentJoined),
    ],
  );
}
 
class _Slot extends StatelessWidget {
  final String label;
  final bool   filled;
  const _Slot({required this.label, required this.filled});
 
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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