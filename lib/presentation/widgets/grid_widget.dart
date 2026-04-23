import 'package:flutter/material.dart';
import '../../domain/entities/grid_slot.dart';
import '../../domain/entities/mon_card.dart';

class GridWidget extends StatelessWidget {
  final List<GridSlot> slots;
  final List<int> lastFlipped;
  final MonCard? selectedCard;
  final ValueChanged<int> onCellTapped;
  final Function(int, MonCard) onCardDropped;

  const GridWidget({
    super.key,
    required this.slots,
    required this.lastFlipped,
    required this.selectedCard,
    required this.onCellTapped,
    required this.onCardDropped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 4.0;
        const double ratio = 0.75;
        const double outerMargin = 12.0;

        // Use the height provided by the parent to determine the scale
        // We don't hardcode cellHeight anymore to avoid rounding overflows
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          margin: const EdgeInsets.symmetric(horizontal: outerMargin),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA), Color(0xFF65CC9C)],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(spacing),
            // Center ensures that if the cards are narrower than the screen, 
            // the background still fills the width.
            child: Center(
              child: AspectRatio(
                // The total grid aspect ratio: (4 cols * 0.75) / 4 rows = 0.75
                aspectRatio: ratio, 
                child: Column(
                  children: List.generate(4, (rowIndex) {
                    return Expanded(
                      child: Row(
                        children: List.generate(4, (colIndex) {
                          final int index = (rowIndex * 4) + colIndex;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(spacing / 2),
                              child: _GridCell(
                                slot: slots[index],
                                isFlipped: lastFlipped.contains(index),
                                canPlace: selectedCard != null && slots[index].isEmpty,
                                onTap: () => onCellTapped(index),
                                onCardDropped: (card) => onCardDropped(index, card),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  final GridSlot slot;
  final bool isFlipped, canPlace;
  final VoidCallback onTap;
  final ValueChanged<MonCard> onCardDropped;

  const _GridCell({
    required this.slot,
    required this.isFlipped,
    required this.canPlace,
    required this.onTap,
    required this.onCardDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<MonCard>(
      onAcceptWithDetails: (details) => onCardDropped(details.data),
      builder: (_, candidates, __) {
        final isDragOver = candidates.isNotEmpty;
        return GestureDetector(
          onTap: slot.isEmpty ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDragOver
                  ? const Color(0x4DF5C842)
                  : canPlace
                      ? const Color(0x33FFFFFF)
                      : const Color(0x44546E9F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDragOver 
                    ? const Color(0xFFF5C842) 
                    : Colors.white.withOpacity(canPlace ? 0.6 : 0.1),
                width: 1.2,
              ),
            ),
            child: slot.isEmpty
                ? const Center(
                    child: Icon(Icons.add, color: Colors.white24, size: 18))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      slot.card!.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
          ),
        );
      },
    );
  }
}