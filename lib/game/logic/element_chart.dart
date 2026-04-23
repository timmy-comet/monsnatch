import '../../domain/entities/card_element.dart';

/// Circular advantage chain: Water > Fire > Nature > Wind > Earth > Water
class ElementChart {
  static const _beats = {
    CardElement.water:  CardElement.fire,
    CardElement.fire:   CardElement.nature,
    CardElement.nature: CardElement.wind,
    CardElement.wind:   CardElement.earth,
    CardElement.earth:  CardElement.water,
  };

  /// True if [attacker] has elemental advantage over [defender].
  static bool hasAdvantage(CardElement attacker, CardElement defender) {
    if (attacker == CardElement.neutral || defender == CardElement.neutral) {
      return false; // neutral never has elemental advantage
    }
    return _beats[attacker] == defender;
  }

  /// Tooltip string for the Lens overlay element chart.
  static String advantageText(CardElement e) {
    final beats   = _beats[e];
    final beatenBy = _beats.entries.firstWhere((entry) => entry.value == e,
        orElse: () => const MapEntry(CardElement.neutral, CardElement.neutral)).key;
    if (beats == null) return '${e.label}: Neutral type.';
    return '${e.emoji} ${e.label}: Counters ${beats.label}. Weak to ${beatenBy.label}.';
  }
}