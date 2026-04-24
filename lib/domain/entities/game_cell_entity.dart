import 'package:equatable/equatable.dart';

class GameCellEntity extends Equatable {
  final int    cardId;     // 1-12 — used to look up art + card data
  final String ownerUid;  // current token holder — changes on capture
  final String placedBy;  // immutable after placement

  const GameCellEntity({
    required this.cardId,
    required this.ownerUid,
    required this.placedBy,
  });

  @override
  List<Object> get props => [cardId, ownerUid, placedBy];
}