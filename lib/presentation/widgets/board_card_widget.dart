import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _starAsset = 'assets/images/ui/star.svg';
const String _moonAsset = 'assets/images/ui/moon.svg';

class BoardCardWidget extends StatefulWidget {
  final String? cardImage;
  final bool    isStarOwner;
  /// True for one frame after a capture — drives the Y-flip animation.
  final bool    isFlipped;
  /// True when the card was placed by Player 2 (matches backend's
  /// `rotate180(directions)` rule). The whole tile (card art + token)
  /// rotates 180°. Combined with the board container's own rotation for
  /// the Player 2 viewer, the net effect is: each viewer sees their own
  /// cards upright with the team token anchored to the top-right of the
  /// cell as drawn from their perspective.
  final bool    flipArt;

  const BoardCardWidget({
    super.key,
    required this.cardImage,
    required this.isStarOwner,
    required this.isFlipped,
    this.flipArt = false,
  });

  @override
  State<BoardCardWidget> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _flip;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _flip = Tween<double>(begin: 0, end: pi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BoardCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped && !old.isFlipped) {
      _ctrl.forward(from: 0);
    } else if (widget.isStarOwner != old.isStarOwner) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.flipArt ? pi : 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card art runs the Y-flip animation on capture/ownership change.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _flip,
              builder: (_, __) {
                final angle = _flip.value;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(
                      angle < pi / 2 ? angle : angle - pi),
                  child: _CardArt(cardImage: widget.cardImage),
                );
              },
            ),
          ),
          // Token badge — anchored to the top-right of the cell. When
          // `flipArt` is true the outer rotation moves it to bottom-left
          // in absolute coords; combined with the board's 180° rotation
          // for the Player 2 viewer it lands back at top-right of their
          // viewport.
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFECECEC),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4),
                ],
              ),
              child: SvgPicture.asset(
                  widget.isStarOwner ? _starAsset : _moonAsset),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  final String? cardImage;
  const _CardArt({required this.cardImage});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: cardImage != null
            ? Image.asset(
                cardImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black26,
                  child:
                      const Icon(Icons.broken_image, color: Colors.white24),
                ),
              )
            : Container(color: Colors.black26),
      );
}
