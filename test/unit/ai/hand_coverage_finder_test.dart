import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/ai/hand_coverage_finder.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

import '../../helpers/test_state.dart';

void main() {
  group('HandCoverageFinder.findFullCoverage', () {
    test('allowedLeftover=0: tam bölünebilen el için tüm perleri döndürür',
        () {
      final hand = [
        normalTile('r10', TileColor.red, 10),
        normalTile('r11', TileColor.red, 11),
        normalTile('r12', TileColor.red, 12),
        normalTile('b8', TileColor.blue, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('y8', TileColor.yellow, 8),
      ];

      final result = HandCoverageFinder.findFullCoverage(
        hand,
        0,
        combinationBudget: 1000,
      );

      expect(result, isNotNull);
      final coveredIds = result!.expand((g) => g).map((t) => t.id).toSet();
      expect(coveredIds, hand.map((t) => t.id).toSet());
    });

    test('allowedLeftover=1: bir taş dışında her şeyi perleyen çözümü bulur',
        () {
      final hand = [
        normalTile('r10', TileColor.red, 10),
        normalTile('r11', TileColor.red, 11),
        normalTile('r12', TileColor.red, 12),
        normalTile('y1', TileColor.yellow, 1),
      ];

      final result = HandCoverageFinder.findFullCoverage(
        hand,
        1,
        combinationBudget: 1000,
      );

      expect(result, isNotNull);
      final coveredIds = result!.expand((g) => g).map((t) => t.id).toSet();
      expect(coveredIds.length, 3);
      expect(coveredIds.contains('y1'), isFalse);
    });

    test('bölünemeyen el için null döner', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('b9', TileColor.blue, 9),
        normalTile('bl2', TileColor.black, 2),
      ];

      final result = HandCoverageFinder.findFullCoverage(
        hand,
        0,
        combinationBudget: 1000,
      );

      expect(result, isNull);
    });
  });
}
