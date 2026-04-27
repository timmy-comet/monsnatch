import 'package:flutter/material.dart';
import '../../domain/entities/card_entity.dart';

class HandCardWidget extends StatelessWidget {
  final CardEntity? card;
  final int         cardId;
  final bool        isFocused;
  final bool        isSelected;
  final bool        isUsed;
  final double      width, height;

  const HandCardWidget({
    super.key,
    required this.card,
    required this.cardId,
    this.isFocused  = false,
    this.isSelected = false,
    this.isUsed     = false,
    this.width  = 68,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUsed ? 0.4 : 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width:  width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFFF5C842), width: 2.5)
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF5C842).withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            clipBehavior: Clip.hardEdge,
            child: card != null
                ? Image.asset(
                    card!.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          if (card != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width:  20,
                height: 20,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${card!.power}',
                    style: const TextStyle(
                      color:      Color(0xFF333333),
                      fontSize:   9,
                      fontWeight: FontWeight.w900,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF7080B8),
        alignment: Alignment.center,
        child: Text(
          card?.name ?? '#$cardId',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 8),
        ),
      );
}
