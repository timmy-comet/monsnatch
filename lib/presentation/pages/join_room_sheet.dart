import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_event.dart';
import '../blocs/room/room_state.dart';
import '../widgets/mon_button.dart';
import 'waiting_lobby_page.dart';

class JoinRoomSheet extends StatefulWidget {
  const JoinRoomSheet({super.key});

  @override
  State<JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<JoinRoomSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomBloc, RoomState>(
      listener: (ctx, state) {
        if (state is RoomReady) {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WaitingLobbyPage(room: state.room),
          ));
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24,
            24 + MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Enter Room Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(
              controller:    _ctrl,
              textCapitalization: TextCapitalization.characters,
              textAlign:     TextAlign.center,
              maxLength:     6,
              style: const TextStyle(
                fontSize:   26,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText:      'XXXXXX',
                counterText:   '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:   BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.joinRoomBtn, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<RoomBloc, RoomState>(
              builder: (ctx, state) => MonButton(
                label:     'JOIN',
                color:     AppColors.joinRoomBtn,
                isLoading: state is RoomLoading,
                onPressed: () {
                  final code = _ctrl.text.trim().toUpperCase();
                  if (code.length == 6) {
                    ctx.read<RoomBloc>().add(JoinRoomRequested(code));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
