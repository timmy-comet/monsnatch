import 'package:equatable/equatable.dart';
import '../../../domain/entities/faction.dart';
import '../../../domain/entities/grid_slot.dart';
import '../../../domain/entities/mon_card.dart';

enum GamePhase { waitingForSelection, placing, gameOver }

class GameState extends Equatable {
  // ── Board ──────────────────────────────────────────────
  final List<GridSlot>  grid;          // 16 slots
  final List<int>       lastFlipped;   // indices that flipped this turn

  // ── Players ────────────────────────────────────────────
  final Faction        playerFaction;
  final Faction        currentTurnFaction;
  final List<MonCard>  playerHand;
  final List<MonCard>  opponentHand;  // AI or remote hand (same mock for now)

  // ── Carousel ───────────────────────────────────────────
  final int            focusIndex;    // which card is center of carousel
  final int?           selectedIndex; // tapped card — null if none

  // ── Timer ──────────────────────────────────────────────
  final int            timerSeconds;  // 30 → 0
  final bool           isUrgent;      // true when ≤ 10s

  // ── Score ──────────────────────────────────────────────
  final int            starScore;
  final int            moonScore;

  // ── UI modes ──────────────────────────────────────────
  final bool           isLensOpen;
  final GamePhase      phase;
  final int            turnNumber;    // 1–16
  final Faction?       winner;        // set when phase == gameOver

  const GameState({
    required this.grid,
    required this.playerFaction,
    required this.currentTurnFaction,
    required this.playerHand,
    required this.opponentHand,
    this.lastFlipped      = const [],
    this.focusIndex       = 0,
    this.selectedIndex,
    this.timerSeconds     = 30,
    this.isUrgent         = false,
    this.starScore        = 0,
    this.moonScore        = 0,
    this.isLensOpen       = false,
    this.phase            = GamePhase.waitingForSelection,
    this.turnNumber       = 1,
    this.winner,
  });

  bool get isPlayerTurn   => currentTurnFaction == playerFaction;
  bool get isGameOver     => phase == GamePhase.gameOver;
  MonCard? get focusedCard =>
      playerHand.isNotEmpty && focusIndex < playerHand.length
          ? playerHand[focusIndex] : null;
  MonCard? get selectedCard =>
      selectedIndex != null && selectedIndex! < playerHand.length
          ? playerHand[selectedIndex!] : null;

  GameState copyWith({
    List<GridSlot>?  grid, List<int>? lastFlipped,
    Faction?        currentTurnFaction,
    List<MonCard>?  playerHand, List<MonCard>? opponentHand,
    int?            focusIndex, int?    selectedIndex,
    bool            clearSelected = false,
    int?            timerSeconds, bool? isUrgent,
    int?            starScore,   int?  moonScore,
    bool?           isLensOpen,
    GamePhase?      phase, int? turnNumber, Faction? winner,
  }) => GameState(
    grid:               grid               ?? this.grid,
    lastFlipped:        lastFlipped        ?? this.lastFlipped,
    playerFaction:      playerFaction,
    currentTurnFaction: currentTurnFaction ?? this.currentTurnFaction,
    playerHand:         playerHand         ?? this.playerHand,
    opponentHand:       opponentHand       ?? this.opponentHand,
    focusIndex:         focusIndex         ?? this.focusIndex,
    selectedIndex:      clearSelected ? null : selectedIndex ?? this.selectedIndex,
    timerSeconds:       timerSeconds       ?? this.timerSeconds,
    isUrgent:           isUrgent           ?? this.isUrgent,
    starScore:          starScore          ?? this.starScore,
    moonScore:          moonScore          ?? this.moonScore,
    isLensOpen:         isLensOpen         ?? this.isLensOpen,
    phase:              phase              ?? this.phase,
    turnNumber:         turnNumber         ?? this.turnNumber,
    winner:             winner             ?? this.winner,
  );

  @override
  List<Object?> get props => [
    grid, lastFlipped, playerFaction, currentTurnFaction, playerHand,
    focusIndex, selectedIndex, timerSeconds, isUrgent,
    starScore, moonScore, isLensOpen, phase, turnNumber, winner,
  ];
}