enum CardElement { fire, water, nature, wind, earth, neutral }

extension CardElementX on CardElement {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get emoji => const {
    CardElement.fire:    '🔥',
    CardElement.water:   '💧',
    CardElement.nature:  '🌿',
    CardElement.wind:    '🌀',
    CardElement.earth:   '🪨',
    CardElement.neutral: '✨',
  }[this]!;
}