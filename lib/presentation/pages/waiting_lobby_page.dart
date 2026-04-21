import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/room_entity.dart';
import '../widgets/mon_button.dart';
import '../widgets/room_code_card.dart';
import 'game_page.dart';

class WaitingLobbyPage extends StatelessWidget {
  final RoomEntity room;
  const WaitingLobbyPage({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor:  Colors.transparent,
        elevation:        0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Logo (smaller)
              Image.asset(
                AppAssets.homeLogo,
                width:  110,
                height: 110,
                fit:    BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for players...',
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share the code below with a friend',
                style: TextStyle(
                  fontSize: 13,
                  color:    AppColors.subtitleText,
                ),
              ),
              const Spacer(flex: 1),
              // Room code card
              RoomCodeCard(code: room.code),
              const Spacer(flex: 1),
              // Player slots
              const _PlayerSlots(),
              const Spacer(flex: 1),
              // START GAME
              MonButton(
                label:     'START GAME',
                color:     AppColors.startBtn,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GamePage(room: room),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSlots extends StatelessWidget {
  const _PlayerSlots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Slot(label: 'You', filled: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('VS',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize:   14,
                  color:      Colors.grey.shade400)),
        ),
        const _Slot(label: 'Waiting...', filled: false),
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
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? AppColors.createRoomBtn.withOpacity(0.2)
                : const Color(0xFFF5F5F5),
            border: Border.all(
              color: filled
                  ? AppColors.createRoomBtn
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            filled ? Icons.person_rounded : Icons.person_add_alt_1_rounded,
            size:  28,
            color: filled ? AppColors.createRoomBtn : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      filled ? AppColors.primaryText : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
