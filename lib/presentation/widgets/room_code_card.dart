import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class RoomCodeCard extends StatefulWidget {
  final String code;
  const RoomCodeCard({super.key, required this.code});

  @override
  State<RoomCodeCard> createState() => _RoomCodeCardState();
}

class _RoomCodeCardState extends State<RoomCodeCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:       Colors.black.withOpacity(0.08),
            blurRadius:  20,
            offset:      const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ROOM CODE',
            style: TextStyle(
              fontSize:      12,
              fontWeight:    FontWeight.w700,
              letterSpacing: 2,
              color:         AppColors.subtitleText,
            ),
          ),
          const SizedBox(height: 12),
          // Code characters displayed as individual tiles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.code.split('').map((ch) => _CodeTile(ch)).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _copy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color:        _copied
                    ? AppColors.createRoomBtn.withOpacity(0.15)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size:  16,
                    color: _copied ? Colors.green : AppColors.subtitleText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _copied ? 'Copied!' : 'Copy code',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      _copied ? Colors.green : AppColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  final String char;
  const _CodeTile(this.char);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 40, height: 48,
      decoration: BoxDecoration(
        color:        const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: const TextStyle(
          fontSize:      22,
          fontWeight:    FontWeight.w900,
          color:         AppColors.primaryText,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
