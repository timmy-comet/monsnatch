import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';

class HandCardWidget extends StatelessWidget {
  final int         cardId;
  final CardEntity? card;
  final bool        isSelected;
  final bool        enabled;
  final VoidCallback? onTap;

  const HandCardWidget({
    super.key,
    required this.cardId,
    required this.card,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width:  60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.cellHighlight, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:      AppColors.cellHighlight.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [
                  const BoxShadow(
                      color: Colors.black26, blurRadius: 4)
                ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Image.asset(
                card?.imageAsset ??
                    'assets/images/cards/card_$cardId.png',
                width: 60, height: 84, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60, height: 84,
                  color: AppColors.gridCellBg,
                  child: Center(
                    child: Text(
                      card?.name ?? '#$cardId',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 7),
                    ),
                  ),
                ),
              ),
              // Power badge
              if (card != null)
                Positioned(
                  bottom: 3, left: 3,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${card!.power}',
                          style: const TextStyle(
                            fontSize: 8, fontWeight: FontWeight.w900,
                            color: AppColors.primaryText,
                          )),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
