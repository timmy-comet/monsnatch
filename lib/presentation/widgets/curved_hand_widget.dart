import 'package:flutter/material.dart';
import '../../domain/entities/card_entity.dart';
import 'hand_card_widget.dart';

class CurvedHandWidget extends StatefulWidget {
  final List<CardEntity> cards;
  final int focusIndex;
  final int? selectedIndex;
  final bool isPlayerTurn; // Reintegrated check
  final ValueChanged<int> onSwipedTo;
  final ValueChanged<int> onCardTapped;
  final VoidCallback onLensTapped;

  const CurvedHandWidget({
    super.key,
    required this.cards,
    required this.focusIndex,
    required this.selectedIndex,
    required this.isPlayerTurn,
    required this.onSwipedTo,
    required this.onCardTapped,
    required this.onLensTapped,
  });

  @override
  State<CurvedHandWidget> createState() => _CurvedHandState();
}

class _CurvedHandState extends State<CurvedHandWidget> {
  late int _focus;
  double _dragStart = 0;

  static const double _cardGap = 65;
  static const double _arcDepth = 6.0;
  static const double _rotationStep = 0.08;
  static const double _focusScale = 1.6;
  static const Duration _animDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    // Default focus logic: Right-hand preference
    if (widget.cards.length >= 5) {
      _focus = (widget.cards.length ~/ 2) + 1;
    } else {
      _focus = (widget.cards.length - 1).clamp(0, 99).toInt();
    }
  }

  @override
  void didUpdateWidget(CurvedHandWidget old) {
    super.didUpdateWidget(old);
    
    // PHASE 3 AUDIT: Refocus logic when a card is placed
    if (widget.cards.length < old.cards.length) {
      _handleRefocusAfterPlacement();
    }
  }

  void _handleRefocusAfterPlacement() {
    setState(() {
      // Clamping keeps focus on the card that slid into the current index (the Right neighbor)
      _focus = _focus.clamp(0, (widget.cards.length - 1).clamp(0, 999));
    });
    widget.onSwipedTo(_focus);
  }

  void _shiftFocus(int delta) {
    // SECURITY GATE: Block swiping if it's not the player's turn
    if (!widget.isPlayerTurn) return;

    final next = (_focus + delta).clamp(0, widget.cards.length - 1);
    if (next == _focus) return;
    setState(() => _focus = next);
    widget.onSwipedTo(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox(height: 220);

    final sortedIndices = List.generate(widget.cards.length, (i) => i)
      ..sort((a, b) {
        final da = (a - _focus).abs();
        final db = (b - _focus).abs();
        return db.compareTo(da); 
      });

    return GestureDetector(
      // SECURITY GATE: Block drag interactions
      onHorizontalDragStart: (d) => widget.isPlayerTurn ? _dragStart = d.globalPosition.dx : null,
      onHorizontalDragUpdate: (d) {
        if (!widget.isPlayerTurn) return;
        final diff = d.globalPosition.dx - _dragStart;
        if (diff.abs() > 45) {
          _shiftFocus(diff < 0 ? 1 : -1);
          _dragStart = d.globalPosition.dx; 
        }
      },
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: sortedIndices.map((i) => _buildAnimatedCard(i)).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int i) {
    final dist = i - _focus;
    final isFocus = dist == 0;
    
    return AnimatedPositioned(
      key: ValueKey(widget.cards[i].id),
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      bottom: 30,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(dist * _cardGap, dist.abs() * dist.abs() * _arcDepth * 0.5)
          ..rotateZ(dist * _rotationStep),
        transformAlignment: Alignment.center,
        child: AnimatedScale(
          scale: isFocus ? _focusScale : (1.0 - dist.abs() * 0.05).clamp(0.7, 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          alignment: Alignment.bottomCenter,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // SECURITY GATE: Block card tapping/selection
                if (!widget.isPlayerTurn) return;
                isFocus ? widget.onCardTapped(i) : _shiftFocus(dist);
              },
              child: HandCardWidget(
                cardId: i,
                card: widget.cards[i],
                isSelected: widget.selectedIndex == i,
                enabled: widget.isPlayerTurn,
                onTap: isFocus ? (() => widget.onCardTapped(i)) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}