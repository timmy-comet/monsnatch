import 'package:dartz/dartz.dart';
import '../../core/constants/app_assets.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/room_remote_datasource.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remote;
  final AuthLocalDataSource  _auth;

  const RoomRepositoryImpl(this._remote, this._auth);

  @override
  Future<Either<Failure, RoomEntity>> createRoom() async {
    try {
      final model = await _remote.createRoom();
      return right(_withHand(model));
    } on ServerException catch (e) {
      return left(RoomFailure(e.message));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) async {
    try {
      final model = await _remote.joinRoom(code.toUpperCase());
      return right(_withHand(model));
    } on ServerException catch (e) {
      return left(RoomFailure(e.message));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RoomEntity>> watchRoom(String code) async* {
    final token = await _auth.getIdToken();
    if (token == null) {
      yield left(const AuthFailure('Session expired. Please re-enter your name.'));
      return;
    }
    try {
      await for (final model in _remote.watchRoom(code, token)) {
        yield right(_withHand(model));
      }
    } catch (e) {
      yield left(NetworkFailure(e.toString()));
    }
  }

  @override
  void stopWatching() => _remote.stopWatching();

  /// Attach a mock hand to the server-returned room shell.
  /// Replace this with real card data when the backend supports it.
  RoomEntity _withHand(RoomModel model) {
    final hand = List.generate(7, (i) => CardEntity(
      id:         'card_$i',
      name:       'Momon ${i + 1}',
      imageAsset: AppAssets.cardPlaceholder,
      power:      (i + 1) * 10,
      isStarred:  i == 2,
    ));
    return model.copyWith(hand: hand);
  }
}