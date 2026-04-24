import 'package:equatable/equatable.dart';
import '../../../domain/entities/card_entity.dart';
import '../../../domain/entities/room_entity.dart';

enum GamePhase { loading, playing, done }

class GameBlocState extends Equatable {
  // ── Server state (replace-not-merge on every WS update) ──────────────────
  final RoomEntity?       room;
  final GamePhase         phase;
  final String            myUid;

  // ── Card catalog (fetched once from GET /cards) ───────────────────────────
  final List<CardEntity>  catalog;   // id → card data

  // ── Local UI state (never sent to server) ─────────────────────────────────
  final int?              selectedCardId;  // tapped card in hand
  final bool              isSubmitting;    // prevent double-tap
  final int               countdownSeconds; // computed from turnDeadline
  final String?           opponentUsername;
  final String?           errorMessage;

  const GameBlocState({
    this.room,
    this.phase           = GamePhase.loading,
    this.myUid           = '',
    this.catalog         = const [],
    this.selectedCardId,
    this.isSubmitting    = false,
    this.countdownSeconds = 30,
    this.opponentUsername,
    this.errorMessage,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isMyTurn =>
      room?.game != null && room!.game!.turn == myUid;

  /// Star faction = room creator.
  bool get iAmStar => room != null && room!.createdBy == myUid;

  String get opponentUid {
    if (room == null) return '';
    return room!.player1 == myUid
        ? (room!.player2 ?? '')
        : (room!.player1 ?? '');
  }

  List<int> get myHand {
    if (room?.game == null) return [];
    return room!.game!.hands[myUid] ?? [];
  }

  List<int> get opponentHand {
    final uid = opponentUid;
    if (uid.isEmpty || room?.game == null) return [];
    return room!.game!.hands[uid] ?? [];
  }

  int get myScore {
    if (room?.game == null) return 0;
    return room!.game!.score[myUid] ?? 0;
  }

  int get opponentScore {
    final uid = opponentUid;
    if (uid.isEmpty || room?.game == null) return 0;
    return room!.game!.score[uid] ?? 0;
  }

  CardEntity? cardById(int id) {
    try { return catalog.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  /// Client-side: cell is valid to play if it's empty AND (first move OR adjacent).
  bool canPlay(int cellIndex) {
    if (!isMyTurn || isSubmitting || selectedCardId == null) return false;
    if (room?.game == null) return false;
    final game = room!.game!;
    if (game.board[cellIndex] != null) return false;
    if (game.turnNumber == 0) return true;
    return _isAdjacentToPlaced(game.board, cellIndex);
  }

  /// 8-direction adjacency check (spec §10).
  bool _isAdjacentToPlaced(List board, int cellIndex) {
    const dirs = [
      (-1,-1),(-1,0),(-1,1),
      ( 0,-1),       ( 0,1),
      ( 1,-1),( 1,0),( 1,1),
    ];
    final row = cellIndex ~/ 4;
    final col = cellIndex % 4;
    for (final (dr, dc) in dirs) {
      final r = row + dr, c = col + dc;
      if (r >= 0 && r <= 3 && c >= 0 && c <= 3) {
        if (board[r * 4 + c] != null) return true;
      }
    }
    return false;
  }

  /// Token ownership: ownerUid === createdBy → Star, else Moon.
  bool cellIsStarOwned(int cellIndex) {
    final cell = room?.game?.board[cellIndex];
    if (cell == null) return false;
    return cell.ownerUid == room!.createdBy;
  }

  GameBlocState copyWith({
    RoomEntity?       room,
    GamePhase?        phase,
    String?           myUid,
    List<CardEntity>? catalog,
    int?              selectedCardId,
    bool?             isSubmitting,
    int?              countdownSeconds,
    String?           opponentUsername,
    String?           errorMessage,
    bool              clearSelected  = false,
    bool              clearError     = false,
  }) => GameBlocState(
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
    room, phase, myUid, catalog,
    selectedCardId, isSubmitting, countdownSeconds, opponentUsername, errorMessage,
  ];
}
