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
  static const primaryYellow  = Color(0xFFF9CC4A);
  static const primaryBrown   = Color(0xFFB16016);
  static const secondaryBrown = Color(0xFF8D5A37);
  static const lightBlueBg    = Color(0xFFD8E5F8);
  static const lightYellowBg  = Color(0x4DF7CF48); 
  static const primaryText    = Color(0xFF333333);
  static const subtitleText   = Color(0xFF888888);
  static const darkGrey       = Color(0xFF6C6D6F);


  // Game
  static const gridBg         = Color(0xFFE8E8E8);
  static const cellBorder     = Color(0xFFCCCCCC);
  static const cellHighlight  = Color(0xFFF5C842);
  static const cellInvalidBg  = Color(0xFFFF988A); // salmon — rejected drop hover
  static const scoreBg        = Color.fromARGB(121, 93, 198, 202);
  static const Color starFaction = Color(0xFFF5C842);
  static const Color moonFaction = Color(0xFF3D4EA0);
  static const Color gridCellBg  = Color(0xFF7080B8);

  // Board (matches fix-config-game-page palette)
  static const boardCellBg     = Color(0xE5787891);
  static const boardCellBorder = Color(0xFF363B49);
  static const cellPlayable    = Color(0xFF38BDF8);
  static const lastMoveRing    = Color(0xFFFBBF24);
  static const captureRing     = Color(0xFFEC4899);

  // Score bar / countdown / hurry banner (matches fix-config-game-page)
  static const titleFill     = primaryYellow;
  static const titleStroke   = primaryBrown;
  static const scorePillBg   = Color(0x6659B5C2);
  static const scoreText     = secondaryBrown;
  static const timerRing     = primaryYellow;
  static const cardOutline   = Color(0xFFE5E7EB);
  static const hurryBg       = Color(0x4DF7CF48);
  static const hurryBorder   = secondaryBrown;
  static const hurryText     = secondaryBrown;
}
