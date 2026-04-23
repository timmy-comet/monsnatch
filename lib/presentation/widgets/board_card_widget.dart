import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/grid_slot.dart';
import '../../domain/entities/faction.dart';

class BoardCardWidget extends StatefulWidget {
  final GridSlot slot;
  final bool     isFlipped;
  const BoardCardWidget({super.key, required this.slot, required this.isFlipped});

  @override
  State<BoardCardWidget> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _flip;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _flip = Tween<double>(begin: 0, end: pi).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BoardCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped && !old.isFlipped) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (_, __) {
        final angle = _flip.value;
        final showFront = angle < pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(showFront ? angle : angle - pi),
          child: showFront ? _CardFace(slot: widget.slot) : _CardBack(slot: widget.slot),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  final GridSlot slot;
  const _CardFace({required this.slot});

  @override
  Widget build(BuildContext context) {
    final faction = slot.ownerFaction!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(slot.card!.imageAsset, fit: BoxFit.cover),
          ),
        ),
        // Faction badge — top-right corner
        Positioned(
          top: 2, right: 2,
          child: Container(
            width: 16, height: 16,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: faction == Faction.star
                  ? const Color(0xFFF5C842)
                  : const Color(0xFF3949AB),
              shape:      BoxShape.circle,
              boxShadow:  [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
            ),
            child: SvgPicture.asset(faction.iconAsset),
          ),
        ),
        // Power badge
        Positioned(
          bottom: 2, left: 2,
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${slot.card!.power}',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF222222))),
          ),
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  final GridSlot slot;
  const _CardBack({required this.slot});

  @override
  Widget build(BuildContext context) {
    return _CardFace(slot: slot); // after 180°, shows same card with new badge
  }
}