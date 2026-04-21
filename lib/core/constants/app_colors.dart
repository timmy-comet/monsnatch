import 'package:flutter/material.dart';

abstract class AppColors {
  // Background
  static const scaffoldBg     = Color(0xFFFFFFFF);

  // Buttons
  static const createRoomBtn  = Color(0xFFF5C842); // golden yellow
  static const joinRoomBtn    = Color(0xFF5BC8D4); // teal
  static const startBtn       = Color(0xFFF5C842);

  // Accents
  static const orangeCircle   = Color(0xFFF5A623);
  static const primaryText    = Color(0xFF333333);
  static const subtitleText   = Color(0xFF888888);

  // Game
  static const gridBg         = Color(0xFFE8E8E8);
  static const cellBorder     = Color(0xFFCCCCCC);
  static const cellHighlight  = Color(0xFFF5C842);
  static const scoreBg        = Color(0xFFEEEEEE);
}
