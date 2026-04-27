import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/room_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remote;
  final AuthLocalDataSource  _auth;
  final UserRemoteDataSource _userRemote;

  const RoomRepositoryImpl(this._remote, this._auth, this._userRemote);

  Future<String?> _ensureFreshIdToken() async {
    final stored = await _auth.getIdToken();
    if (stored != null) return stored;
    final refresh = await _auth.getRefreshToken();
    if (refresh == null) return null;
    try {
      final tokens = await _userRemote.refresh(refresh);
      await _auth.saveTokens(
        idToken:      tokens.idToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.idToken;
    } catch (_) {
      await _auth.clearAuth();
      return null;
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> createRoom() =>
      _wrap(() => _remote.createRoom());

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) =>
      _wrap(() => _remote.joinRoom(code.toUpperCase()));

  @override
  Future<Either<Failure, RoomEntity>> startRoom(String code) =>
      _wrap(() => _remote.startRoom(code));

  @override
  Future<Either<Failure, RoomEntity>> leaveRoom(String code) =>
      _wrap(() => _remote.leaveRoom(code));    

  @override
  Future<Either<Failure, RoomEntity>> playCard({
    required String code,
    required int    cellIndex,
    required int    cardId,
  }) =>
      _wrap(() => _remote.playCard(
        code:      code,
        cellIndex: cellIndex,
        cardId:    cardId,
      ));

  @override
  Future<Either<Failure, List<CardEntity>>> getCards() async {
    try {
      final models = await _remote.getCards();
      return right(models);
    } on ServerException catch (e) {
      return left(RoomFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RoomEntity>> watchRoom(String code) async* {
    final token = await _ensureFreshIdToken();
    if (token == null) {
      yield left(const AuthFailure('Session expired. Please re-register.'));
      return;
    }
    try {
      await for (final model in _remote.watchRoom(code, token)) {
        yield right(model);
      }
    } catch (e) {
      yield left(NetworkFailure(e.toString()));
    }
  }

  @override
  void stopWatching() => _remote.stopWatching();

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<Either<Failure, RoomEntity>> _wrap(
      Future<RoomEntity> Function() call) async {
    try {
      return right(await call());
    } on ServerException catch (e) {
      if (e.statusCode == 401) return left(AuthFailure(e.message));
      return left(RoomFailure(e.message));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(NetworkFailure(e.toString()));
    }
  }
}