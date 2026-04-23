import '../../domain/entities/card_element.dart';
import '../../domain/entities/card_keyword.dart';
import '../../domain/entities/mon_card.dart';
import '../../domain/entities/snatch_direction.dart';

class MockCards {
  /// Returns a shuffled 10-card mock deck.
  static List<MonCard> deck() => [
    const MonCard(
      id:          'sherox',
      name:        'Sherox',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.water,
      power:       7, rarityStars: 3, level: 5,
      snatchDirs:  [SnatchDir.north, SnatchDir.east, SnatchDir.south],
      abilityText: 'Balanced type. Counters Fire.',
      defense: 7, attack: 6,
    ),
    const MonCard(
      id:          'rembark',
      name:        'Rembark',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.nature,
      power:       5, rarityStars: 2, level: 3,
      snatchDirs:  [SnatchDir.north, SnatchDir.west],
      keywords:    [CardKeyword.incite],
      abilityText: 'Incite: Captured cards continue the snatch chain.',
      defense: 5, attack: 7,
    ),
    const MonCard(
      id:          'comet',
      name:        'Comet',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.fire,
      power:       9, rarityStars: 4, level: 7,
      snatchDirs:  [SnatchDir.north, SnatchDir.south, SnatchDir.east, SnatchDir.west],
      abilityText: 'High attack power. Snatches in all directions.',
      defense: 4, attack: 9,
    ),
    const MonCard(
      id:          'laretail',
      name:        'Laretail',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.earth,
      power:       6, rarityStars: 2, level: 4,
      snatchDirs:  [SnatchDir.south, SnatchDir.east],
      keywords:    [CardKeyword.ward],
      abilityText: 'Ward: Cannot be snatched. High defense.',
      defense: 9, attack: 4,
    ),
    const MonCard(
      id:          'windara',
      name:        'Windara',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.wind,
      power:       6, rarityStars: 2, level: 4,
      snatchDirs:  [SnatchDir.north, SnatchDir.east],
      abilityText: 'Swift and elusive. Strong against Nature.',
      defense: 5, attack: 6,
    ),
    const MonCard(
      id:          'aquafin',
      name:        'Aquafin',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.water,
      power:       4, rarityStars: 1, level: 2,
      snatchDirs:  [SnatchDir.west, SnatchDir.south],
      abilityText: 'Low cost. Effective in the lower grid rows.',
      defense: 4, attack: 4,
    ),
    const MonCard(
      id:          'emberfox',
      name:        'Emberfox',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.fire,
      power:       8, rarityStars: 3, level: 6,
      snatchDirs:  [SnatchDir.north, SnatchDir.south],
      keywords:    [CardKeyword.swift],
      abilityText: 'Swift: Places before opponent reacts. Fierce vertical snatches.',
      defense: 5, attack: 8,
    ),
    const MonCard(
      id:          'rockhorn',
      name:        'Rockhorn',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.earth,
      power:       5, rarityStars: 2, level: 3,
      snatchDirs:  [SnatchDir.east, SnatchDir.west, SnatchDir.south],
      abilityText: 'Wide horizontal control. Effective against Water.',
      defense: 6, attack: 5,
    ),
    const MonCard(
      id:          'vinesprout',
      name:        'VineSprout',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.nature,
      power:       3, rarityStars: 1, level: 1,
      snatchDirs:  [SnatchDir.north],
      abilityText: 'Minimal power, but only 1 star cost. Fills budget gaps.',
      defense: 3, attack: 3,
    ),
    const MonCard(
      id:          'voidling',
      name:        'Voidling',
      imageAsset:  'assets/images/cards/Card.png',
      element:     CardElement.neutral,
      power:       6, rarityStars: 3, level: 4,
      snatchDirs:  [SnatchDir.north, SnatchDir.east, SnatchDir.west],
      abilityText: 'Neutral element. Snatch by power only. No elemental weakness.',
      defense: 6, attack: 6,
    ),
  ];

  /// Total rarity stars for a deck (must be ≤ 25).
  static int totalStars(List<MonCard> deck) =>
      deck.fold(0, (sum, c) => sum + c.rarityStars);
}