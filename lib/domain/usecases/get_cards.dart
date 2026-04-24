import 'package:dartz/dartz.dart';
import '../entities/card_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';

class GetCards {
  final RoomRepository repository;
  const GetCards(this.repository);

  Future<Either<Failure, List<CardEntity>>> call() => repository.getCards();
}
