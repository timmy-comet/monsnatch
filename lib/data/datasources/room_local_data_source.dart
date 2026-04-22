import 'dart:math';
import '../../core/constants/app_assets.dart';
import '../../domain/entities/card_entity.dart';

class RoomLocalDataSource {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _rng = Random();

  String generateRoomCode() {
    // mock data, pls replace
    return String.fromCharCodes(
      List.generate(6, (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length))),
    );
  }

  List<CardEntity> mockHand() {
    // mock data, pls replace
    return List.generate(
      7,
      (i) => CardEntity(
        id: 'card_$i',
        name: 'Momon ${i + 1}',
        imageAsset: AppAssets.cardPlaceholder,
        power: (i + 1) * 10,
        isStarred: i == 2,
      ),
    );
  }
}