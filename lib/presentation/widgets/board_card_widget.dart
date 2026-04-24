import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/card_entity.dart';

class BoardCardWidget extends StatelessWidget {
  final int         cardId;
  final CardEntity? card;       // may be null if catalog not yet loaded
  final bool        isStarOwner;
  final Color?      borderColor;

  const BoardCardWidget({
    super.key,
    required this.cardId,
    required this.card,
    required this.isStarOwner,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokenColor = isStarOwner
        ? AppColors.starFaction
        : AppColors.moonFaction;
    final tokenIcon  = isStarOwner
        ? Icons.star_rounded
        : Icons.nightlight_round;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            borderColor != null ? 6.5 : 9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card art
            Image.asset(
              card?.imageAsset ?? 'assets/images/cards/card_$cardId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.gridCellBg,
                child: Center(
                  child: Text(
                    card?.name ?? '#$cardId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ),

            // Faction token badge — top-right
            Positioned(
              top: 3, right: 3,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color:  tokenColor,
                  shape:  BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color:      tokenColor.withOpacity(0.5),
                        blurRadius: 4)
                  ],
                ),
                child: Icon(tokenIcon,
                    color: Colors.white, size: 11),
              ),
            ),

            // Power badge — bottom-left
            if (card != null)
              Positioned(
                bottom: 3, left: 3,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.85),
                    shape:  BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${card!.power}',
                      style: TextStyle(
                        fontSize:   9,
                        fontWeight: FontWeight.w900,
                        color:      tokenColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
