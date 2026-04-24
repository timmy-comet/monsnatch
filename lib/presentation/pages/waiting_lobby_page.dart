import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../domain/entities/room_entity.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../blocs/game/game_bloc.dart';
import '../widgets/mon_button.dart';
import '../widgets/room_code_card.dart';
import 'game_page.dart';
import '../../injection_container.dart';

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
    context.read<RoomBloc>().add(WatchRoomStarted(_room.code));
  }

  @override
  void dispose() {
    context.read<RoomBloc>().add(const WatchRoomStopped());
    super.dispose();
  }

  bool _isHost(String myUid) => _room.createdBy == myUid;

  Future<String> _getMyUid() async {
    final auth = sl<AuthLocalDataSource>();
    return await auth.getUid() ?? '';
  }

  void _navigateToGame(RoomEntity room, String myUid) {
    final gameBloc = sl<GameBloc>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: gameBloc,
          child: GamePage(room: room, myUid: myUid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomBloc, RoomState>(
      listener: (context, state) async {
        if (state is RoomPlayerJoined) {
          setState(() {
            _room = state.room;
            _opponentJoined = true;
          });
        }
        if (state is RoomGameStarted) {
          final myUid = await _getMyUid();
          if (!mounted) return;
          _navigateToGame(state.room, myUid);
        }
        if (state is RoomError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is RoomLoading;
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                  Image.asset('assets/images/ui/logo.png', width: 100, height: 100),
                  const SizedBox(height: 14),
                  const Text('Waiting for players...',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText)),
                  const SizedBox(height: 4),
                  const Text('Share the code below with a friend',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.subtitleText)),
                  const Spacer(),
                  RoomCodeCard(code: _room.code),
                  const Spacer(),

                  // Player status
                  _PlayerSlots(opponentJoined: _opponentJoined),

                  const Spacer(),

                  // ── Host-only: Start Game button (appears when p2 joined)
                  FutureBuilder<String>(
                    future: _getMyUid(),
                    builder: (ctx, snap) {
                      final myUid = snap.data ?? '';
                      final isHost = _isHost(myUid);
                      if (isHost && _opponentJoined) {
                        return MonButton(
                          label:     'START GAME',
                          color:     AppColors.startBtn,
                          isLoading: loading,
                          onPressed: () => context
                              .read<RoomBloc>()
                              .add(StartGameRequested(_room.code)),
                        );
                      }
                      if (!isHost) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Waiting for host to start...',
                            style: TextStyle(
                                color:    AppColors.subtitleText,
                                fontSize: 13),
                          ),
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Slot(label: 'You', filled: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('VS',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
        ),
        _Slot(
          label: opponentJoined ? 'Joined!' : 'Waiting...',
          filled: opponentJoined,
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final bool   filled;
  const _Slot({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          color:  filled
              ? AppColors.createRoomBtn.withOpacity(0.15)
              : const Color(0xFFF5F5F5),
          border: Border.all(
            color: filled ? AppColors.createRoomBtn : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Icon(
          filled ? Icons.person_rounded : Icons.person_add_alt_1_rounded,
          color: filled ? AppColors.createRoomBtn : Colors.grey.shade400,
          size: 26,
        ),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.primaryText : Colors.grey.shade400,
          )),
    ]);
  }
}