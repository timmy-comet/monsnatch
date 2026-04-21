import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

abstract class FutureUseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {
  const NoParams();
}