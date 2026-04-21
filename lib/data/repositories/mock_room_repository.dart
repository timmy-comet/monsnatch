import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_assets.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';

class MockRoomRepository implements RoomRepository {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _rng = Random();

  String _generateCode() =>
      String.fromCharCodes(
        List.generate(6, (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length))),
      );

  List<CardEntity> _mockHand() => List.generate(
    7,
    (i) => CardEntity(
      id:         'card_$i',
      name:       'Momon ${i + 1}',
      imageAsset: AppAssets.cardPlaceholder,
      power:      (i + 1) * 10,
      isStarred:  i == 2,
    ),
  );

  @override
  Future<Either<Failure, RoomEntity>> createRoom() async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 400));
    return right(RoomEntity(
      code: _generateCode(),
      hand: _mockHand(),
    ));
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (code.length != 6) {
      return left(const RoomFailure('Invalid room code'));
    }
    return right(RoomEntity(code: code, hand: _mockHand()));
  }
}
