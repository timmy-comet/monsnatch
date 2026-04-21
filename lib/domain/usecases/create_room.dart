import 'package:dartz/dartz.dart';
import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class CreateRoom implements FutureUseCase<RoomEntity, NoParams> {
  final RoomRepository repository;
  const CreateRoom(this.repository);

  @override
  Future<Either<Failure, RoomEntity>> call(NoParams _) =>
      repository.createRoom();
}
