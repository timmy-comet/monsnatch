import 'package:equatable/equatable.dart';
import 'card_entity.dart';
import 'faction.dart';

class GridSlot extends Equatable {
  final int       index;
  final CardEntity?  card;
  /// The faction that currently OWNS this slot (can change via Snatch).
  final Faction?  ownerFaction;
  /// The faction that ORIGINALLY placed this card (never changes).
  final Faction?  originalFaction;

  const GridSlot({
    required this.index,
    this.card,
    this.ownerFaction,
    this.originalFaction,
  });

  bool get isEmpty  => card == null;

  GridSlot copyWith({CardEntity? card, Faction? ownerFaction, Faction? originalFaction}) =>
      GridSlot(
        index:           index,
        card:            card            ?? this.card,
        ownerFaction:    ownerFaction    ?? this.ownerFaction,
        originalFaction: originalFaction ?? this.originalFaction,
      );

  /// Flip ownership — used during Snatch resolution.
  GridSlot flipTo(Faction newOwner) =>
      GridSlot(index: index, card: card, ownerFaction: newOwner, originalFaction: originalFaction);

  @override
  List<Object?> get props => [index, card, ownerFaction, originalFaction];
}