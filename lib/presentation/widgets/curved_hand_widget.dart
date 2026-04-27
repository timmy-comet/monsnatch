import 'package:flutter/material.dart';
import '../../domain/entities/card_entity.dart';
import 'hand_card_widget.dart';

class CurvedHandWidget extends StatefulWidget {
  /// Full hand (active + used) so positions stay stable as cards are played.
  final List<int>            cardIds;
  final Map<int, CardEntity> catalog;
  final Set<int>             usedCardIds;
  final int?                 selectedCardId;
  final bool                 isPlayerTurn;
  final ValueChanged<int>    onCardTapped; // emits cardId

  const CurvedHandWidget({
    super.key,
    required this.cardIds,
    required this.catalog,
    required this.usedCardIds,
    required this.selectedCardId,
    required this.isPlayerTurn,
    required this.onCardTapped,
  });

  @override
  State<CurvedHandWidget> createState() => _CurvedHandState();
}

class _CurvedHandState extends State<CurvedHandWidget> {
  late int _focus;
  double _dragStart = 0;

  static const double _cardW        = 69;
  static const double _cardH        = 98;
  static const double _cardGap      = 65;
  static const double _arcDepth     = 6.0;
  static const double _rotationStep = 0.08;
  static const double _focusScale   = 1.6;
  static const Duration _animDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _focus = _initialFocus(widget.cardIds.length);
  }

  @override
  void didUpdateWidget(CurvedHandWidget old) {
    super.didUpdateWidget(old);
    if (widget.cardIds.length != old.cardIds.length) {
      setState(() {
        _focus = _focus.clamp(0, (widget.cardIds.length - 1).clamp(0, 999));
      });
    }
  }

  int _initialFocus(int n) {
    if (n == 0) return 0;
    if (n >= 5) return (n ~/ 2) + 1;
    return (n - 1).clamp(0, 99);
  }

  void _shiftFocus(int delta) {
    if (!widget.isPlayerTurn) return;
    final next = (_focus + delta).clamp(0, widget.cardIds.length - 1);
    if (next == _focus) return;
    setState(() => _focus = next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardIds.isEmpty) return const SizedBox(height: 220);

    // Render order: outer cards first so the focused one stays on top.
    final sortedIndices = List.generate(widget.cardIds.length, (i) => i)
      ..sort((a, b) {
        final da = (a - _focus).abs();
        final db = (b - _focus).abs();
        return db.compareTo(da);
      });

    return GestureDetector(
      onHorizontalDragStart: (d) {
        if (widget.isPlayerTurn) _dragStart = d.globalPosition.dx;
      },
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
          alignment:     Alignment.bottomCenter,
          clipBehavior:  Clip.none,
          children: sortedIndices.map(_buildAnimatedCard).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int i) {
    final dist    = i - _focus;
    final isFocus = dist == 0;
    final cardId  = widget.cardIds[i];
    final card    = widget.catalog[cardId];
    final isUsed  = widget.usedCardIds.contains(cardId);
    final isSel   = widget.selectedCardId == cardId;

    return AnimatedPositioned(
      key: ValueKey(cardId),
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
                if (!widget.isPlayerTurn || isUsed) return;
                if (isFocus) {
                  widget.onCardTapped(cardId);
                } else {
                  _shiftFocus(dist);
                }
              },
              child: HandCardWidget(
                cardId:     cardId,
                card:       card,
                isFocused:  isFocus,
                isSelected: isSel,
                isUsed:     isUsed,
                width:      _cardW,
                height:     _cardH,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
