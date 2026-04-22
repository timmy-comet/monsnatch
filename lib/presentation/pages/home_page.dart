import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../injection_container.dart';

// Room
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';

// Guest
import '../blocs/user/user_bloc.dart';
import '../../domain/entities/user_entity.dart';

// UI
import '../widgets/mon_button.dart';
import '../widgets/username_dialog.dart';
import 'waiting_lobby_page.dart';
import 'join_room_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RoomBloc>()),
        BlocProvider(create: (_) => sl<UserBloc>()..loadUser()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── User Listener ───────────────────────────────
        BlocListener<UserBloc, UserEntity?>(
          listener: (context, user) {
            if (user == null) {
              _showUsernameDialog(context);
            }
          },
        ),

        // ── Room Listener ────────────────────────────────
        BlocListener<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomReady) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WaitingLobbyPage(room: state.room),
                ),
              );
            } else if (state is RoomError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── main content ───────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      AppAssets.homeLogo,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 48),

                    // CREATE ROOM
                    BlocBuilder<RoomBloc, RoomState>(
                      builder: (context, state) => MonButton(
                        label: 'CREATE ROOM',
                        color: AppColors.createRoomBtn,
                        isLoading: state is RoomLoading,
                        onPressed: () {
                          final user = context.read<UserBloc>().state;

                          // Prevent action if no username yet
                          if (user == null) {
                            _showUsernameDialog(context);
                            return;
                          }

                          context
                              .read<RoomBloc>()
                              .add(const CreateRoomRequested());
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // JOIN ROOM
                    MonButton(
                      label: 'JOIN ROOM',
                      color: AppColors.joinRoomBtn,
                      onPressed: () {
                        final user = context.read<UserBloc>().state;

                        if (user == null) {
                          _showUsernameDialog(context);
                          return;
                        }

                        _showJoinSheet(context);
                      },
                    ),
                  ],
                ),
              ),

              // ── bottom buttons ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      color: AppColors.orangeCircle,
                      icon: Icons.person_outline_rounded,
                      onTap: () {
                        _showUsernameDialog(context); // allow rename later
                      },
                    ),
                    _CircleButton(
                      color: Colors.white,
                      icon: Icons.settings_outlined,
                      onTap: () {},
                      outlined: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<RoomBloc>(),
        child: const JoinRoomSheet(),
      ),
    );
  }

  void _showUsernameDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
      value: context.read<UserBloc>(),
      child: UsernameDialog(),
    ),
    );
  }
}

// ── Circle Button ─────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _CircleButton({
    required this.color,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: outlined
              ? Border.all(color: const Color(0xFFDDDDDD), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: outlined ? AppColors.subtitleText : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}