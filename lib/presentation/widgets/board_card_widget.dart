import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _starAsset = 'assets/images/ui/star.svg';
const String _moonAsset = 'assets/images/ui/moon.svg';

class BoardCardWidget extends StatefulWidget {
  final String? cardImage;
  final bool    isStarOwner;
  final bool    isFlipped;

  const BoardCardWidget({
    super.key,
    required this.cardImage,
    required this.isStarOwner,
    required this.isFlipped,
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
    return AnimatedBuilder(
      animation: _flip,
      builder: (_, __) {
        final angle = _flip.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(angle < pi / 2 ? angle : angle - pi),
          child: _CardFace(
            cardImage:   widget.cardImage,
            isStarOwner: widget.isStarOwner,
          ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  final String? cardImage;
  final bool    isStarOwner;
  const _CardFace({required this.cardImage, required this.isStarOwner});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: cardImage != null
                ? Image.asset(
                    cardImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white24),
                    ),
                  )
                : Container(color: Colors.black26),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 16,
            height: 16,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStarOwner
                  ? const Color(0xFFF5C842)
                  : const Color(0xFF3949AB),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
              ],
            ),
            child: SvgPicture.asset(isStarOwner ? _starAsset : _moonAsset),
          ),
        ),
      ],
    );
  }
}
