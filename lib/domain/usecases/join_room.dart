import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class JoinRoom implements FutureUseCase<RoomEntity, String> {
  final RoomRepository repository;
  const JoinRoom(this.repository);

  @override
  Future<Either<Failure, RoomEntity>> call(String code) =>
      repository.joinRoom(code);
}
