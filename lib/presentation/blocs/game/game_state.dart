import 'package:equatable/equatable.dart';
import '../../../domain/entities/card_entity.dart';
import '../../../domain/entities/game_cell_entity.dart';
import '../../../domain/entities/room_entity.dart';
 
enum GamePhase { loading, playing, done }
 
class GameBlocState extends Equatable {
  // ── Server state (replaced wholesale on every WS update) ──────────────────
  final RoomEntity?     room;
  final GamePhase       phase;
  final String          myUid;
 
  // ── Card catalog (fetched once from GET /cards) ───────────────────────────
  final Map<int, CardEntity> catalog; // cardId → CardEntity
 
  // ── Local UI state (never sent to server) ─────────────────────────────────
  final int?   selectedCardId;  // tapped card in hand; null = none selected
  final bool   isSubmitting;    // prevent double-tap after POST /play
  final int    countdownSeconds;
  final String opponentUsername;
  final String? errorMessage;
 
  const GameBlocState({
    this.room,
    this.phase           = GamePhase.loading,
    this.myUid           = '',
    this.catalog         = const {},
    this.selectedCardId,
    this.isSubmitting    = false,
    this.countdownSeconds = 30,
    this.opponentUsername = 'Opponent',
    this.errorMessage,
  });
 
  // ── Convenience getters ───────────────────────────────────────────────────
 
  GameStateLocal? get _g => room?.currentGame != null
      ? GameStateLocal(room!.currentGame!)
      : null;
 
  /// ★ KEY FIX: Star is determined by game.starUid, NOT createdBy
  bool get iAmStar => _g?.game.starUid == myUid;
 
  bool get isMyTurn =>
      room?.currentGame != null && room!.currentGame!.turn == myUid;
 
  String get opponentUid {
    if (room == null) return '';
    return room!.player1 == myUid
        ? (room!.player2 ?? '')
        : (room!.player1 ?? '');
  }
 
  /// Active (not yet played) card IDs for my hand
  List<int> get myActiveCardIds =>
      _g?.game.activeCardIds(myUid) ?? [];
 
  /// All hand cards (including used) for rendering the full hand row
  List<dynamic> get myAllCardIds =>
      (_g?.game.hands[myUid] ?? []).map((c) => c.cardId).toList();
 
  List<int> get opponentActiveCardIds =>
      _g?.game.activeCardIds(opponentUid) ?? [];
 
  int get myScore       => room?.currentGame?.score[myUid]       ?? 0;
  int get opponentScore => room?.currentGame?.score[opponentUid] ?? 0;
  int get totalMoves    => room?.currentGame?.turnNumber         ?? 0;
 
  List<GameCellEntity?> get board =>
      room?.currentGame?.board ?? List.filled(16, null);
 
  CardEntity? cardById(int id) => catalog[id];
 
  bool get isUrgent   => countdownSeconds <= 10;
  bool get isCritical => countdownSeconds <= 5;
 
  /// Client-side validation (spec §10) — server re-validates; this is for UX only
  bool canPlay(int cellIndex) {
    if (!isMyTurn || isSubmitting) return false;
    if (selectedCardId == null)     return false;
    if (board[cellIndex] != null)   return false;      // cell occupied
    final turnNum = room?.currentGame?.turnNumber ?? 0;
    if (turnNum == 0) return true;                     // first move: any empty cell
    return _isAdjacentToPlaced(cellIndex);             // subsequent: 8-way adjacency
  }
 
  /// 8-direction adjacency (spec §10) — includes diagonals
  bool _isAdjacentToPlaced(int cellIndex) {
    const dirs = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)];
    final row = cellIndex ~/ 4;
    final col = cellIndex %  4;
    for (final (dr, dc) in dirs) {
      final r = row + dr, c = col + dc;
      if (r >= 0 && r <= 3 && c >= 0 && c <= 3) {
        if (board[r * 4 + c] != null) return true;
      }
    }
    return false;
  }
 
  /// Token ownership: ownerUid == game.starUid → Star token; else Moon
  bool cellIsStarOwned(int cellIndex) {
    final cell = board[cellIndex];
    if (cell == null) return false;
    return cell.ownerUid == room?.currentGame?.starUid;
  }
 
  GameBlocState copyWith({
    RoomEntity?         room,
    GamePhase?          phase,
    String?             myUid,
    Map<int, CardEntity>? catalog,
    int?                selectedCardId,
    bool?               isSubmitting,
    int?                countdownSeconds,
    String?             opponentUsername,
    String?             errorMessage,
    bool                clearSelected = false,
    bool                clearError    = false,
  }) =>
      GameBlocState(
        room:              room              ?? this.room,
        phase:             phase             ?? this.phase,
        myUid:             myUid             ?? this.myUid,
        catalog:           catalog           ?? this.catalog,
        selectedCardId:    clearSelected ? null : selectedCardId ?? this.selectedCardId,
        isSubmitting:      isSubmitting      ?? this.isSubmitting,
        countdownSeconds:  countdownSeconds  ?? this.countdownSeconds,
        opponentUsername:  opponentUsername  ?? this.opponentUsername,
        errorMessage:      clearError ? null : errorMessage ?? this.errorMessage,
      );
 
  @override
  List<Object?> get props => [
    room, phase, myUid, catalog, selectedCardId,
    isSubmitting, countdownSeconds, opponentUsername, errorMessage,
  ];
}
 
/// Helper wrapper — avoids null-checking game everywhere
class GameStateLocal {
  final dynamic game; // GameStateEntity
  GameStateLocal(this.game);
}
 