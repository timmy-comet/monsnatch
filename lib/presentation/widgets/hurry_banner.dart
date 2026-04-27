import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Soft yellow banner shown during the player's turn that counts down the
/// remaining seconds. Ported from `fix-config-game-page`'s HurryBanner.
class HurryBanner extends StatelessWidget {
  final int seconds;

  const HurryBanner({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(32, 3, 32, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColors.hurryBg,
        borderRadius: BorderRadius.circular(28),
        border:       Border.all(color: AppColors.hurryBorder, width: 1),
      ),
      child: Text(
        'Hurry! Card will auto-select in ${seconds}s',
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 13,
          color:    AppColors.hurryText,
        ),
      ),
    );
  }
}
