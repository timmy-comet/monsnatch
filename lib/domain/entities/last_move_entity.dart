import 'package:equatable/equatable.dart';

class LastMoveEntity extends Equatable {
  final int    cellIndex;
  final int    cardId;
  final String placedBy;
  final List<int> captures; // cell indices that were flipped (for highlight)

  const LastMoveEntity({
    required this.cellIndex,
    required this.cardId,
    required this.placedBy,
    required this.captures,
  });

  @override
  List<Object> get props => [cellIndex, cardId, placedBy, captures];
}
