enum CardKeyword { incite, ward, swift }

extension CardKeywordX on CardKeyword {
  String get description => const {
    CardKeyword.incite: 'On Snatch, the captured card performs its own Snatch check.',
    CardKeyword.ward:   'This card cannot be snatched by enemy cards.',
    CardKeyword.swift:  'Placed card resolves before opponent can react.',
  }[this]!;
}