import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Game-themed popup shown when the WS link has been down long enough
/// to warrant asking the player what they want to do. Mirrors the look
/// of [VictoryOverlay] — rounded card, elastic scale-in, golden CTA.
class ConnectionLostOverlay extends StatefulWidget {
  /// Whether a manual retry is currently in flight. Drives the spinner
  /// state on the Reconnect button. The overlay itself only renders
  /// while the parent says the link is down — see [_ConnectionLostGate].
  final bool         isRetrying;
  final VoidCallback onReconnect;
  final VoidCallback onLeave;

  const ConnectionLostOverlay({
    super.key,
    required this.isRetrying,
    required this.onReconnect,
    required this.onLeave,
  });

  @override
  State<ConnectionLostOverlay> createState() => _ConnectionLostOverlayState();
}

class _ConnectionLostOverlayState extends State<ConnectionLostOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isTrying = widget.isRetrying;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin:  const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color:        AppColors.createRoomBtn.withValues(alpha: 0.45),
                  blurRadius:   40,
                  spreadRadius: 4,
                )],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width:  84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightYellowBg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.createRoomBtn.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔌', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Oh no!',
                  style: TextStyle(
                    fontSize:   28,
                    fontWeight: FontWeight.w900,
                    color:      AppColors.primaryBrown,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "We lost connection to\nthe game. Try again?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height:   1.4,
                      color:    AppColors.secondaryBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.createRoomBtn,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.createRoomBtn.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size(220, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isTrying ? null : widget.onReconnect,
                  child: isTrying
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width:  18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('TRYING…',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  fontSize: 14,
                                )),
                          ],
                        )
                      : const Text('🔄  RECONNECT',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          )),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: widget.onLeave,
                  child: const Text(
                    'LEAVE GAME',
                    style: TextStyle(
                      color:    AppColors.subtitleText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

